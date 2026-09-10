import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../core/responsive.dart';
import '../../helper/date.formatter.dart';
import '../../models/staff_model.dart';
import '../../auth/department_head_permissions.dart';
import '../models/hospital_asset_models.dart';
import '../services/hospital_assets_api_service.dart';
import 'asset_theme.dart';

@RoutePage()
class HospitalAssetDetailScreen extends StatefulWidget {
  const HospitalAssetDetailScreen({super.key, required this.assetId});

  final String assetId;

  @override
  State<HospitalAssetDetailScreen> createState() =>
      _HospitalAssetDetailScreenState();
}

class _HospitalAssetDetailScreenState extends State<HospitalAssetDetailScreen> {
  final _api = HospitalAssetsApiService();
  bool _loading = true;
  String? _error;
  HospitalAsset? _asset;
  HospitalAssetAccessMe? _access;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.getById(widget.assetId),
        _api.me(),
      ]);
      if (!mounted) return;
      setState(() {
        _asset = results[0] as HospitalAsset;
        _access = results[1] as HospitalAssetAccessMe;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _addLog() async {
    var type = HospitalAssetLogType.usage;
    var toStatus = _asset?.status;
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add log'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<HospitalAssetLogType>(
                  initialValue: type,
                  items: HospitalAssetLogType.values
                      .where((t) => t != HospitalAssetLogType.created)
                      .map(
                        (t) => DropdownMenuItem(value: t, child: Text(t.label)),
                      )
                      .toList(),
                  onChanged: (v) => type = v ?? type,
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<HospitalAssetStatus>(
                  initialValue: toStatus,
                  items: HospitalAssetStatus.values
                      .map(
                        (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                      )
                      .toList(),
                  onChanged: (v) => toStatus = v,
                  decoration: const InputDecoration(
                    labelText: 'Status after this log (optional)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: note,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    final noteText = note.text.trim();
    note.dispose();
    if (ok != true) return;
    await _api.addLog(widget.assetId, {
      'type': type.apiValue,
      if (noteText.isNotEmpty) 'note': noteText,
      if (toStatus != null && toStatus != _asset?.status)
        'toStatus': toStatus!.apiValue,
    });
    await _load();
  }

  Future<void> _transfer() async {
    var dest = AccountType.fromString(_asset?.accountType);
    if (!kInventoryDepartments.contains(dest)) {
      dest = AccountType.store;
    }
    final external = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Transfer asset'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<AccountType>(
                  initialValue: dest,
                  items: kInventoryDepartments
                      .map(
                        (t) => DropdownMenuItem(value: t, child: Text(t.label)),
                      )
                      .toList(),
                  onChanged: (v) => dest = v ?? dest,
                  decoration: const InputDecoration(
                    labelText: 'Internal department',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: external,
                  decoration: const InputDecoration(
                    labelText: 'Or other hospital / destination',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Transfer'),
            ),
          ],
        );
      },
    );
    final destNote = external.text.trim();
    external.dispose();
    if (ok != true) return;
    await _api.transfer(widget.assetId, {
      if (destNote.isEmpty) 'toAccountType': dest.apiValue,
      if (destNote.isNotEmpty) 'transferredToNote': destNote,
    });
    await _load();
  }

  Widget _infoTile(IconData icon, String label, String? value, Color color) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asset = _asset;
    final accent = colorForAccountType(asset?.accountType ?? '');
    return Scaffold(
      appBar: AppBar(
        title: Text(asset?.name ?? 'Asset'),
        backgroundColor: accent.withValues(alpha: 0.12),
        foregroundColor: accent,
        actions: [
          if (_access?.canManage == true)
            TextButton(
              onPressed: _transfer,
              child: Text('Transfer', style: TextStyle(color: accent)),
            ),
        ],
      ),
      floatingActionButton: _access?.canLog == true
          ? FloatingActionButton.extended(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              onPressed: _addLog,
              icon: const Icon(Icons.note_add_outlined),
              label: const Text('Add log'),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : asset == null
          ? const SizedBox.shrink()
          : ResponsiveBody(
              expand: false,
              builder: (context, bp) {
                return ListView(
                  children: [
                    InventoryScopeBanner(
                      accent: accent,
                      title: asset.name,
                      subtitle:
                          '${labelForAccountType(asset.accountType)} · ${asset.assetTag}',
                    ),
                    const SizedBox(height: 14),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                KindChip(kind: asset.kind, color: accent),
                                const Spacer(),
                                StatusChip(status: asset.status),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _infoTile(
                              Icons.qr_code_2_outlined,
                              'Asset tag',
                              asset.assetTag,
                              accent,
                            ),
                            _infoTile(
                              Icons.apartment_outlined,
                              'Department',
                              labelForAccountType(asset.accountType),
                              accent,
                            ),
                            _infoTile(
                              Icons.place_outlined,
                              'Location',
                              asset.locationNote,
                              accent,
                            ),
                            _infoTile(
                              Icons.numbers_outlined,
                              'Serial',
                              asset.serialNumber,
                              accent,
                            ),
                            _infoTile(
                              Icons.precision_manufacturing_outlined,
                              'Make / model',
                              [
                                asset.manufacturer,
                                asset.model,
                              ].where((s) => (s ?? '').isNotEmpty).join(' · '),
                              accent,
                            ),
                            _infoTile(
                              Icons.notes_outlined,
                              'Notes',
                              asset.notes,
                              accent,
                            ),
                            _infoTile(
                              Icons.swap_horiz_outlined,
                              'Transferred to',
                              asset.transferredToNote,
                              accent,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'History',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (asset.logs.isEmpty)
                      const Text('No history yet.')
                    else
                      for (final log in asset.logs)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                margin: const EdgeInsets.only(top: 6),
                                decoration: BoxDecoration(
                                  color: colorForLogType(log.type),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      log.type.label,
                                      style: TextStyle(
                                        color: colorForLogType(log.type),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      [
                                        if (log.fromStatus != null &&
                                            log.toStatus != null)
                                          '${HospitalAssetStatus.fromString(log.fromStatus).label} → ${HospitalAssetStatus.fromString(log.toStatus).label}',
                                        if (log.note != null &&
                                            log.note!.isNotEmpty)
                                          log.note!,
                                        if (log.createdByName != null)
                                          log.createdByName!,
                                        if (log.createdAt != null)
                                          DateFormatter.dateTime(
                                            log.createdAt!,
                                          ),
                                      ].join(' · '),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    const SizedBox(height: 80),
                  ],
                );
              },
            ),
    );
  }
}
