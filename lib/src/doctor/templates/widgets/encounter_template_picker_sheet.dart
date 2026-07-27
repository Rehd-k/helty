import 'package:flutter/material.dart';
import 'package:helty/src/doctor/templates/encounter_template_applier.dart';
import 'package:helty/src/doctor/templates/encounter_template_fields.dart';
import 'package:helty/src/doctor/encounter/doctor_encounter_view_screen.dart';
import 'package:helty/src/models/encounter_template_model.dart';
import 'package:helty/src/services/encounter_template_service.dart';
import 'package:intl/intl.dart';

class EncounterTemplatePickerSheet extends StatefulWidget {
  const EncounterTemplatePickerSheet({
    super.key,
    required this.scope,
    required this.onApplied,
  });

  final EncounterScope scope;
  final VoidCallback onApplied;

  static Future<void> show(
    BuildContext context, {
    required EncounterScope scope,
    required VoidCallback onApplied,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (_, scrollController) => EncounterTemplatePickerSheet(
          scope: scope,
          onApplied: onApplied,
        ),
      ),
    );
  }

  @override
  State<EncounterTemplatePickerSheet> createState() =>
      _EncounterTemplatePickerSheetState();
}

class _EncounterTemplatePickerSheetState
    extends State<EncounterTemplatePickerSheet> {
  final _service = EncounterTemplateService();
  final _applier = EncounterTemplateApplier();

  List<EncounterTemplateModel> _templates = [];
  bool _loading = true;
  String? _error;
  bool _applying = false;

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
      final result = await _service.list(
        encounterType: widget.scope.encounterType,
      );
      if (!mounted) return;
      setState(() {
        _templates = result.templates;
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

  Future<void> _apply(EncounterTemplateModel template) async {
    setState(() => _applying = true);
    try {
      final ok = await _applier.apply(
        context: context,
        scope: widget.scope,
        template: template,
      );
      if (!mounted) return;
      setState(() => _applying = false);
      if (ok) {
        widget.onApplied();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Template "${template.name}" applied')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _applying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to apply template: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Load template',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.scope.encounterType != null)
                      Text(
                        'Filtered: ${encounterTemplateTypeLabel(widget.scope.encounterType)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        if (_applying)
          const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: _buildBody(theme, scheme),
        ),
      ],
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme scheme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_templates.isEmpty) {
      return Center(
        child: Text(
          'No templates found. Create one from the Templates menu or save the current encounter.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: _templates.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final t = _templates[index];
        final updated = t.updatedAt ?? t.createdAt;
        return Card(
          child: ListTile(
            title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (t.description != null && t.description!.trim().isNotEmpty)
                  Text(
                    t.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Text(
                  '${encounterTemplateTypeLabel(t.encounterType)} • ${t.populatedFieldCount} fields'
                  '${updated != null ? ' • ${DateFormat.yMMMd().format(updated.toLocal())}' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _applying ? null : () => _apply(t),
          ),
        );
      },
    );
  }
}
