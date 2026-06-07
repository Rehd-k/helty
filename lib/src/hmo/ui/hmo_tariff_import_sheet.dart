import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/hmo_models.dart';
import '../../models/service_model.dart';
import '../../services/hmo_service.dart';
import '../../services/service_service.dart';
import '../hmo_tariff_csv_parser.dart';

enum HmoTariffImportMode { merge, replaceAll }

class HmoTariffResolvedRow {
  HmoTariffResolvedRow({
    required this.lineNumber,
    required this.serviceId,
    required this.serviceName,
    this.serviceCode,
    required this.cost,
    this.catalogCost,
    this.error,
  });

  final int lineNumber;
  final String serviceId;
  final String serviceName;
  final String? serviceCode;
  final double cost;
  final double? catalogCost;
  final String? error;

  bool get isValid => error == null && serviceId.isNotEmpty;
}

/// Bottom sheet for bulk CSV tariff import.
Future<void> showHmoTariffImportSheet(
  BuildContext context, {
  required String hmoId,
  required String hmoName,
  required VoidCallback onImported,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => HmoTariffImportSheet(
      hmoId: hmoId,
      hmoName: hmoName,
      onImported: onImported,
    ),
  );
}

class HmoTariffImportSheet extends StatefulWidget {
  const HmoTariffImportSheet({
    super.key,
    required this.hmoId,
    required this.hmoName,
    required this.onImported,
  });

  final String hmoId;
  final String hmoName;
  final VoidCallback onImported;

  @override
  State<HmoTariffImportSheet> createState() => _HmoTariffImportSheetState();
}

class _HmoTariffImportSheetState extends State<HmoTariffImportSheet> {
  final _hmoSvc = HmoService();
  final _srvSvc = ServiceService();

  bool _picking = false;
  bool _resolving = false;
  bool _importing = false;
  HmoTariffImportMode _mode = HmoTariffImportMode.merge;
  List<HmoTariffResolvedRow> _resolved = [];
  String? _fileName;
  bool _showHelp = false;

  Future<void> _pickFile() async {
    setState(() => _picking = true);
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv'],
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) return;

      final file = picked.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read file contents')),
        );
        return;
      }

      final text = utf8.decode(bytes, allowMalformed: true);
      final parsed = parseHmoTariffCsv(text);
      if (!mounted) return;
      setState(() {
        _fileName = file.name;
        _resolved = [];
      });
      await _resolveRows(parsed);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<Map<String, ServiceModel>> _loadCatalogByCode() async {
    final byCode = <String, ServiceModel>{};
    var skip = 0;
    const take = 20;
    while (true) {
      final page = await _srvSvc.findAll(skip: skip, take: take);
      for (final s in page.services) {
        final code = s.serviceCode?.trim();
        if (code != null && code.isNotEmpty) {
          byCode.putIfAbsent(code.toLowerCase(), () => s);
        }
        final id = s.id.trim().isNotEmpty ? s.id.trim() : s.serviceId.trim();
        if (id.isNotEmpty) {
          byCode.putIfAbsent(id.toLowerCase(), () => s);
        }
      }
      if (page.services.length < take) break;
      skip += take;
      if (skip >= page.total && page.total > 0) break;
    }
    return byCode;
  }

  Future<void> _resolveRows(HmoTariffCsvParseResult parsed) async {
    setState(() => _resolving = true);
    try {
      final catalog = await _loadCatalogByCode();
      final resolved = <HmoTariffResolvedRow>[];

      for (final row in parsed.rows) {
        if (!row.isValid) {
          resolved.add(
            HmoTariffResolvedRow(
              lineNumber: row.lineNumber,
              serviceId: row.serviceId ?? '',
              serviceName: row.serviceCode ?? row.serviceId ?? '—',
              serviceCode: row.serviceCode,
              cost: row.cost ?? 0,
              error: row.error ?? 'Invalid row',
            ),
          );
          continue;
        }

        ServiceModel? match;
        if (row.serviceId != null && row.serviceId!.isNotEmpty) {
          match = catalog[row.serviceId!.toLowerCase()];
        } else if (row.serviceCode != null && row.serviceCode!.isNotEmpty) {
          match = catalog[row.serviceCode!.toLowerCase()];
        }

        if (match == null) {
          resolved.add(
            HmoTariffResolvedRow(
              lineNumber: row.lineNumber,
              serviceId: row.serviceId ?? '',
              serviceName: row.serviceCode ?? row.serviceId ?? '—',
              serviceCode: row.serviceCode,
              cost: row.cost!,
              error: 'Service not found in catalog',
            ),
          );
          continue;
        }

        final sid = match.id.trim().isNotEmpty
            ? match.id.trim()
            : match.serviceId.trim();
        resolved.add(
          HmoTariffResolvedRow(
            lineNumber: row.lineNumber,
            serviceId: sid,
            serviceName: match.name,
            serviceCode: match.serviceCode,
            cost: row.cost!,
            catalogCost: match.cost,
          ),
        );
      }

      if (!mounted) return;
      setState(() => _resolved = resolved);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to resolve services: $e')));
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  Future<void> _copyTemplate() async {
    await Clipboard.setData(const ClipboardData(text: hmoTariffCsvTemplate));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV template copied to clipboard')),
    );
  }

  Future<bool> _confirmReplace() async {
    final valid = _resolved.where((r) => r.isValid).length;
    final invalid = _resolved.where((r) => !r.isValid).length;
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Replace entire tariff?'),
            content: Text(
              'This will remove all existing prices for ${widget.hmoName} '
              'and replace them with $valid row(s) from the file.\n\n'
              '${invalid > 0 ? '$invalid invalid row(s) will be skipped.\n\n' : ''}'
              'This cannot be undone except by re-importing.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Replace all'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _runImport() async {
    final validRows = _resolved.where((r) => r.isValid).toList();
    if (validRows.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No valid rows to import')));
      return;
    }

    if (_mode == HmoTariffImportMode.replaceAll) {
      final ok = await _confirmReplace();
      if (!ok || !mounted) return;
    }

    setState(() => _importing = true);
    try {
      final priceRows = validRows
          .map(
            (r) => HmoServicePriceRow(
              serviceId: r.serviceId,
              fullCost: r.cost,
              hmoPays: r.cost,
              patientPays: 0,
              service: HmoNestedService(
                id: r.serviceId,
                name: r.serviceName,
                serviceCode: r.serviceCode,
                cost: r.catalogCost,
              ),
            ),
          )
          .toList();

      if (_mode == HmoTariffImportMode.merge) {
        await _hmoSvc.upsertServicePrices(widget.hmoId, priceRows);
      } else {
        await _hmoSvc.replaceServicePrices(widget.hmoId, priceRows);
      }

      final skipped = _resolved.where((r) => !r.isValid).length;
      if (!mounted) return;
      widget.onImported();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported ${validRows.length} price(s)'
            '${skipped > 0 ? ', skipped $skipped' : ''}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final validCount = _resolved.where((r) => r.isValid).length;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Import tariff',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.hmoName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _picking || _resolving || _importing
                        ? null
                        : _pickFile,
                    icon: _picking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file_outlined),
                    label: Text(_fileName ?? 'Choose CSV file'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _copyTemplate,
                    icon: const Icon(Icons.copy_outlined, size: 18),
                    label: const Text('Template'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => setState(() => _showHelp = !_showHelp),
                child: Row(
                  children: [
                    Icon(
                      _showHelp ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text('CSV format help', style: theme.textTheme.labelLarge),
                  ],
                ),
              ),
              if (_showHelp)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Text(
                    'Columns: serviceCode (or serviceId) and cost. '
                    'Excel users: Save As → CSV UTF-8.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              RadioListTile<HmoTariffImportMode>(
                title: const Text('Merge (recommended)'),
                subtitle: const Text('Add or update rows; keep other prices'),
                value: HmoTariffImportMode.merge,
                groupValue: _mode,
                onChanged: _importing
                    ? null
                    : (v) {
                        if (v != null) setState(() => _mode = v);
                      },
              ),
              RadioListTile<HmoTariffImportMode>(
                title: const Text('Replace entire tariff'),
                subtitle: const Text('Remove prices not in the file'),
                value: HmoTariffImportMode.replaceAll,
                groupValue: _mode,
                onChanged: _importing
                    ? null
                    : (v) {
                        if (v != null) setState(() => _mode = v);
                      },
              ),
              if (_resolving)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: LinearProgressIndicator(),
                ),
              if (_resolved.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '$validCount valid · ${_resolved.length - validCount} skipped',
                    style: theme.textTheme.labelLarge,
                  ),
                ),
              Expanded(
                child: _resolved.isEmpty
                    ? Center(
                        child: Text(
                          'Pick a CSV file to preview rows before importing.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _resolved.length,
                        itemBuilder: (context, i) {
                          final r = _resolved[i];
                          final ok = r.isValid;
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              ok
                                  ? Icons.check_circle_outline
                                  : Icons.error_outline,
                              color: ok
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.error,
                            ),
                            title: Text(r.serviceName),
                            subtitle: Text(
                              ok
                                  ? '${r.serviceCode ?? r.serviceId} · ${r.cost.toStringAsFixed(2)}'
                                  : (r.error ?? 'Invalid'),
                            ),
                          );
                        },
                      ),
              ),
              FilledButton(
                onPressed: _importing || _resolving || validCount == 0
                    ? null
                    : _runImport,
                child: _importing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Import $validCount price(s)'),
              ),
            ],
          ),
        );
      },
    );
  }
}
