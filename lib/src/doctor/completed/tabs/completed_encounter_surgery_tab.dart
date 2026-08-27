import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/doctor/completed/widgets/completed_encounter_scope.dart';
import 'package:helty/src/theatre/models/theatre_models.dart';
import 'package:helty/src/theatre/providers/theatre_providers.dart';
import 'package:helty/src/theatre/widgets/operative_notes_panel.dart';
import 'package:helty/src/theatre/widgets/theatre_status_chip.dart';

@RoutePage()
class CompletedEncounterSurgeryTab extends ConsumerStatefulWidget {
  const CompletedEncounterSurgeryTab({super.key});

  @override
  ConsumerState<CompletedEncounterSurgeryTab> createState() =>
      _CompletedEncounterSurgeryTabState();
}

class _CompletedEncounterSurgeryTabState
    extends ConsumerState<CompletedEncounterSurgeryTab> {
  List<SurgeryRequest> _requests = [];
  bool _loading = true;
  bool _loadScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadScheduled) {
      _loadScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
  }

  Future<void> _load() async {
    final scope = CompletedEncounterScope.of(context);
    if (scope == null) return;
    setState(() => _loading = true);
    try {
      final list = await ref
          .read(theatreApiServiceProvider)
          .getSurgeryRequestsForEncounter(scope.encounter.id);
      if (!mounted) return;
      setState(() {
        _requests = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _requests = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_requests.isEmpty) {
      return ResponsiveBody(
        center: false,
        builder: (context, bp) => Text(
          'No surgery requests for this encounter.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ResponsiveBody(
      center: false,
      expand: false,
      builder: (context, bp) => ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: _requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final request = _requests[index];
          final notes = request.theatreCase?.operativeNoteRecords ?? const [];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          request.service?.name ?? 'Surgery',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TheatreStatusChip(status: request.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OperativeNotesPanel(
                    request: request,
                    notes: notes,
                    canWrite: false,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
