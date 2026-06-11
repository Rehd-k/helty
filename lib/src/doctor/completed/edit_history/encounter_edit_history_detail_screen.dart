import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/models/encounter_edit_meta.dart';
import 'package:helty/src/models/encounter_model.dart';
import 'package:helty/src/services/encounter_service.dart';
import 'package:helty/src/helper/date.formatter.dart';

@RoutePage()
class EncounterEditHistoryDetailScreen extends StatefulWidget {
  const EncounterEditHistoryDetailScreen({
    super.key,
    required this.encounterId,
    required this.historyId,
  });

  final String encounterId;
  final String historyId;

  @override
  State<EncounterEditHistoryDetailScreen> createState() =>
      _EncounterEditHistoryDetailScreenState();
}

class _EncounterEditHistoryDetailScreenState
    extends State<EncounterEditHistoryDetailScreen> {
  final _service = EncounterService();
  EncounterEditHistoryDetail? _detail;
  EncounterModel? _currentEncounter;
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
      final results = await Future.wait([
        _service.getEditHistoryDetail(widget.encounterId, widget.historyId),
        _service.getById(widget.encounterId),
      ]);
      if (!mounted) return;
      setState(() {
        _detail = results[0] as EncounterEditHistoryDetail;
        _currentEncounter = results[1] as EncounterModel?;
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

  String? _currentValueForKey(String key) {
    final enc = _currentEncounter;
    if (enc == null) return null;
    switch (key) {
      case 'chiefComplaint':
        return enc.chiefComplaint;
      case 'hpi':
        return enc.hpi;
      case 'pmh':
        return enc.pmh;
      case 'surgicalHistory':
        return enc.surgicalHistory;
      case 'drugHistory':
        return enc.drugHistory;
      case 'allergyHistory':
        return enc.allergyHistory;
      case 'familyHistory':
        return enc.familyHistory;
      case 'socialHistory':
        return enc.socialHistory;
      case 'examinationNotes':
        return enc.examinationNotes;
      case 'soapSubjective':
        return enc.soapSubjective;
      case 'soapObjective':
        return enc.soapObjective;
      case 'soapAssessment':
        return enc.soapAssessment;
      case 'soapPlan':
        return enc.soapPlan;
      case 'proceduresJson':
        return enc.proceduresJson;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Amendment detail'),
      ),
      body: _loading
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
              : _buildBody(context, theme, scheme),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    final detail = _detail!;
    final snap = detail.snapshot.encounter;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          DateFormatter.dateTime(detail.editedAt),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (detail.editedBy != null) ...[
          const SizedBox(height: 4),
          Text('By ${detail.editedBy!.displayName}'),
        ],
        if (detail.reason != null && detail.reason!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Reason: ${detail.reason}'),
        ],
        const SizedBox(height: 24),
        Text(
          'Changed fields',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        ...detail.changedKeys.map((key) {
          final label = EncounterClinicalSnapshotFields.labelForKey(key);
          final before = snap.valueForKey(key);
          final after = _currentValueForKey(key);
          return _DiffCard(
            label: label,
            before: before,
            after: after,
            theme: theme,
            scheme: scheme,
          );
        }),
        if (detail.snapshot.diagnoses.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Diagnoses (before)',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...detail.snapshot.diagnoses.map(
            (d) => ListTile(
              title: Text(d.primaryIcdDescription ?? d.primaryIcdCode ?? '—'),
              subtitle: Text(d.primaryIcdCode ?? ''),
            ),
          ),
        ],
      ],
    );
  }
}

class _DiffCard extends StatelessWidget {
  const _DiffCard({
    required this.label,
    required this.before,
    required this.after,
    required this.theme,
    required this.scheme,
  });

  final String label;
  final String? before;
  final String? after;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _row('Before', before ?? '—', scheme.errorContainer, scheme.onErrorContainer),
            const SizedBox(height: 8),
            _row('Current', after ?? '—', scheme.primaryContainer, scheme.onPrimaryContainer),
          ],
        ),
      ),
    );
  }

  Widget _row(String title, String value, Color bg, Color fg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value.isEmpty ? '—' : value,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
