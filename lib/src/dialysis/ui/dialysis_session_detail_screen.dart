import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/auth/dialysis_permissions.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/core/widgets/patient_avatar.dart';
import 'package:helty/src/dialysis/models/dialysis_models.dart';
import 'package:helty/src/dialysis/providers/dialysis_providers.dart';
import 'package:helty/src/dialysis/widgets/dialysis_add_consumable_sheet.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/providers/auth_provider.dart';

@RoutePage()
class DialysisSessionDetailScreen extends ConsumerStatefulWidget {
  const DialysisSessionDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<DialysisSessionDetailScreen> createState() =>
      _DialysisSessionDetailScreenState();
}

class _DialysisSessionDetailScreenState
    extends ConsumerState<DialysisSessionDetailScreen> {
  DialysisSession? _session;
  bool _loading = true;
  String? _error;
  bool _updating = false;
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await ref
          .read(dialysisApiServiceProvider)
          .getSessionById(widget.sessionId);
      if (!mounted) return;
      setState(() {
        _session = session;
        _loading = false;
      });
      _notesCtrl.text = session.notes ?? '';
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _updateStatus(DialysisSessionStatus status) async {
    setState(() => _updating = true);
    try {
      final staffId = ref.read(authProvider).staff?.id;
      final updated = await ref.read(dialysisApiServiceProvider).updateSession(
            widget.sessionId,
            status: status,
            performedById: staffId,
          );
      if (!mounted) return;
      setState(() {
        _session = updated;
        _updating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Session marked ${status.displayLabel.toLowerCase()}')),
      );
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _updating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _updating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _saveNotes() async {
    setState(() => _updating = true);
    try {
      final notes = _notesCtrl.text.trim();
      final updated = await ref.read(dialysisApiServiceProvider).updateSession(
            widget.sessionId,
            notes: notes,
          );
      if (!mounted) return;
      setState(() {
        _session = updated;
        _updating = false;
      });
      _notesCtrl.text = updated.notes ?? notes;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notes saved')),
      );
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _updating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _updating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _addConsumable() async {
    final session = _session;
    if (session == null) return;
    if (session.status == DialysisSessionStatus.pending) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Start the session before adding consumables.'),
        ),
      );
      return;
    }
    if (session.status == DialysisSessionStatus.cancelled) {
      return;
    }

    final added = await showDialysisAddConsumableSheet(
      context: context,
      ref: ref,
      sessionId: session.id,
      patientId: session.patientId,
    );
    if (added != null) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consumable added to bill')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Session detail')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Session detail')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error ?? 'Session not found'),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final session = _session!;
    final staff = ref.watch(authProvider).staff;
    final canClinical = canPerformDialysisClinical(staff);
    final canCancel = canCancelDialysisSession(staff);
    final patientName = session.patient?.displayName ?? session.patientId;
    final serviceName = session.service?.name ?? 'Dialysis session';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dialysis session'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: ResponsiveBody(
        expand: false,
        builder: (context, bp) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        PatientAvatar(
                          avatarUrl: session.patient?.avatarUrl,
                          firstName: session.patient?.firstName,
                          surname: session.patient?.surname,
                          displayName: patientName,
                          size: 48,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            patientName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(serviceName),
                    const SizedBox(height: 4),
                    Text('Status: ${session.status.displayLabel}'),
                    if (session.createdAt != null)
                      Text(
                        'Created: ${DateFormatter.dateTime(session.createdAt!)}',
                      ),
                    if (session.doctor != null)
                      Text('Doctor: ${session.doctor!.displayName}'),
                    const SizedBox(height: 12),
                    Text(
                      'Notes',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (canClinical &&
                        session.status != DialysisSessionStatus.cancelled) ...[
                      TextField(
                        controller: _notesCtrl,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Session notes…',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.tonal(
                          onPressed: _updating ? null : _saveNotes,
                          child: const Text('Save notes'),
                        ),
                      ),
                    ] else if (session.notes != null &&
                        session.notes!.isNotEmpty)
                      Text(session.notes!)
                    else
                      Text(
                        'No notes.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildStatusActions(
              session,
              canClinical: canClinical,
              canCancel: canCancel,
            ),
            if (!canClinical) ...[
              const SizedBox(height: 8),
              Text(
                'Clinical actions (start, complete, consumables) require '
                'dialysis nurse, tech, or head role.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Consumables billed',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (canClinical)
                  FilledButton.tonalIcon(
                    onPressed: _updating ? null : _addConsumable,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add consumable'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (session.consumables.isEmpty)
              Text(
                'No consumables added yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...session.consumables.map(
                (c) => Card(
                  child: ListTile(
                    title: Text(c.consumable?.name ?? c.consumableId),
                    subtitle: Text('Qty ${c.quantity} · ${c.unitPrice} each'),
                  ),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildStatusActions(
    DialysisSession session, {
    required bool canClinical,
    required bool canCancel,
  }) {
    if (_updating) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (session.status) {
      case DialysisSessionStatus.pending:
        if (!canClinical) {
          return const Chip(
            avatar: Icon(Icons.schedule_rounded, size: 18),
            label: Text('Awaiting start'),
          );
        }
        return FilledButton.icon(
          onPressed: () => _updateStatus(DialysisSessionStatus.inProgress),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Start session'),
        );
      case DialysisSessionStatus.inProgress:
        if (!canClinical && !canCancel) {
          return const Chip(
            avatar: Icon(Icons.play_circle_outline_rounded, size: 18),
            label: Text('In progress'),
          );
        }
        return Row(
          children: [
            if (canClinical)
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      _updateStatus(DialysisSessionStatus.completed),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Complete session'),
                ),
              ),
            if (canClinical && canCancel) const SizedBox(width: 12),
            if (canCancel)
              OutlinedButton(
                onPressed: () => _updateStatus(DialysisSessionStatus.cancelled),
                child: const Text('Cancel'),
              ),
          ],
        );
      case DialysisSessionStatus.completed:
        return const Chip(
          avatar: Icon(Icons.check_circle, size: 18),
          label: Text('Session completed'),
        );
      case DialysisSessionStatus.cancelled:
        return const Chip(
          avatar: Icon(Icons.cancel_outlined, size: 18),
          label: Text('Session cancelled'),
        );
    }
  }
}
