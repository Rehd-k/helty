import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';

import '../../models/cmac_quality_safety_models.dart';
import '../../providers/cmac_providers.dart';
import '../../widgets/cmac_vibrant_backdrop.dart';

@RoutePage()
class CmacQualityDetailScreen extends ConsumerStatefulWidget {
  const CmacQualityDetailScreen({
    super.key,
    @PathParam('entity') required this.entity,
    @PathParam('recordId') required this.recordId,
  });

  final String entity;
  final String recordId;

  @override
  ConsumerState<CmacQualityDetailScreen> createState() =>
      _CmacQualityDetailScreenState();
}

class _CmacQualityDetailScreenState
    extends ConsumerState<CmacQualityDetailScreen> {
  final _statusCtrl = TextEditingController();
  bool _saving = false;

  QualitySafetyEntity get _entity {
    return QualitySafetyEntity.values.firstWhere(
      (e) => e.name == widget.entity,
      orElse: () => QualitySafetyEntity.referrals,
    );
  }

  @override
  void dispose() {
    _statusCtrl.dispose();
    super.dispose();
  }

  Future<void> _patch(String id) async {
    final status = _statusCtrl.text.trim();
    if (status.isEmpty) return;
    setState(() => _saving = true);
    try {
      final svc = ref.read(cmacQualitySafetyServiceProvider);
      await svc.patch(_entity, id, {'status': status});
      ref.invalidate(
        qualitySafetyDetailProvider((entity: _entity, id: widget.recordId)),
      );
      ref.invalidate(qualitySafetyListProvider(_entity));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final key = (entity: _entity, id: widget.recordId);
    final async = ref.watch(qualitySafetyDetailProvider(key));

    return Scaffold(
      body: CmacVibrantBackdrop(
        colors: const [Color(0xFF64748B), Color(0xFF94A3B8)],
        child: async.when(
          data: (record) {
            _statusCtrl.text = record.status ?? '';
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  automaticallyImplyLeading: false,
                  title: Text(record.displayTitle),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      ...record.raw.entries.map(
                        (e) => Card(
                          child: ListTile(
                            title: Text(e.key),
                            subtitle: Text(e.value?.toString() ?? '—'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _statusCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Status (PATCH)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _saving
                            ? null
                            : () => _patch(record.id),
                        child: _saving
                            ? const CircularProgressIndicator()
                            : const Text('Save status'),
                      ),
                      if (record.patientId != null &&
                          record.patientId!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => context.router.push(
                            PatientChartRoute(
                              patientUuid: record.patientId!,
                            ),
                          ),
                          icon: const Icon(Icons.person_rounded),
                          label: const Text('Open patient chart'),
                        ),
                      ],
                    ]),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: SelectableText('$e')),
        ),
      ),
    );
  }
}
