import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/models/encounter_edit_meta.dart';
import 'package:helty/src/models/encounter_model.dart';
import 'package:helty/src/services/encounter_service.dart';
import 'package:helty/src/helper/date.formatter.dart';

/// Bottom sheet listing post-completion edit history for an encounter.
class EncounterEditHistorySheet extends StatefulWidget {
  const EncounterEditHistorySheet({
    super.key,
    required this.encounterId,
    this.encounter,
  });

  final String encounterId;
  final EncounterModel? encounter;

  static Future<void> show(
    BuildContext context, {
    required String encounterId,
    EncounterModel? encounter,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scrollController) => EncounterEditHistorySheet(
          encounterId: encounterId,
          encounter: encounter,
        ),
      ),
    );
  }

  @override
  State<EncounterEditHistorySheet> createState() =>
      _EncounterEditHistorySheetState();
}

class _EncounterEditHistorySheetState extends State<EncounterEditHistorySheet> {
  final _service = EncounterService();
  List<EncounterEditHistorySummary> _items = [];
  bool _loading = true;
  String? _error;

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
      final list = await _service.listEditHistory(widget.encounterId);
      if (!mounted) return;
      setState(() {
        _items = list;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Edit history',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          if (widget.encounter?.editMeta?.hasEdits == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Current chart shows the latest values. Each entry is the state before that amendment.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: _load,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _items.isEmpty
                        ? Center(
                            child: Text(
                              'No amendments recorded yet.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              final by = item.editedBy?.displayName ?? 'Staff';
                              final keys = item.changedKeys;
                              return Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: scheme.outline.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ),
                                child: ListTile(
                                  title: Text(DateFormatter.dateTime(item.editedAt)),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('By $by'),
                                      if (item.reason != null &&
                                          item.reason!.isNotEmpty)
                                        Text('Reason: ${item.reason}'),
                                      if (keys.isNotEmpty)
                                        Text(
                                          keys
                                              .map(
                                                EncounterClinicalSnapshotFields
                                                    .labelForKey,
                                              )
                                              .join(', '),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    Navigator.pop(context);
                                    context.router.push(
                                      EncounterEditHistoryDetailRoute(
                                        encounterId: widget.encounterId,
                                        historyId: item.id,
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
