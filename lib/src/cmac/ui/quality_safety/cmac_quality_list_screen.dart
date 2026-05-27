import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';

import '../../cmac_palette.dart';
import '../../models/cmac_quality_safety_models.dart';
import '../../providers/cmac_providers.dart';
import '../../widgets/cmac_vibrant_backdrop.dart';
import 'cmac_quality_form_sheet.dart';

@RoutePage()
class CmacQualityReferralsScreen extends ConsumerWidget {
  const CmacQualityReferralsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _QualityListPage(entity: QualitySafetyEntity.referrals);
}

@RoutePage()
class CmacQualityComplaintsScreen extends ConsumerWidget {
  const CmacQualityComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _QualityListPage(entity: QualitySafetyEntity.complaints);
}

@RoutePage()
class CmacQualityIncidentsScreen extends ConsumerWidget {
  const CmacQualityIncidentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _QualityListPage(entity: QualitySafetyEntity.incidents);
}

@RoutePage()
class CmacQualityInfectionsScreen extends ConsumerWidget {
  const CmacQualityInfectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _QualityListPage(entity: QualitySafetyEntity.infections);
}

class _QualityListPage extends ConsumerWidget {
  const _QualityListPage({required this.entity});

  final QualitySafetyEntity entity;

  String get _title {
    switch (entity) {
      case QualitySafetyEntity.referrals:
        return 'Referrals';
      case QualitySafetyEntity.complaints:
        return 'Complaints';
      case QualitySafetyEntity.incidents:
        return 'Incidents';
      case QualitySafetyEntity.infections:
        return 'Infections';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(qualitySafetyListProvider(entity));
    void refresh() => ref.invalidate(qualitySafetyListProvider(entity));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await showCmacQualityFormSheet(
            context: context,
            ref: ref,
            entity: entity,
          );
          if (created == true) refresh();
        },
        icon: const Icon(Icons.add_rounded),
        label: Text('New $_title'),
      ),
      body: CmacVibrantBackdrop(
        colors: CmacPalette.qualitySafety,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: false,
              title: Text(_title),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: refresh,
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _ListFilters(onChanged: () => refresh()),
              ),
            ),
            async.when(
              data: (items) {
                if (items.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('No records yet.')),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, i) {
                    final r = items[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: ListTile(
                        title: Text(r.displayTitle),
                        subtitle: Text(
                          [
                            if (r.status != null) r.status,
                            if (r.createdAt != null) r.createdAt.toString(),
                          ].whereType<String>().join(' · '),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.router.push(
                          CmacQualityDetailRoute(
                            entity: entity.name,
                            recordId: r.id,
                          ),
                        ),
                      ),
                    );
                  }, childCount: items.length),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(child: SelectableText('$e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListFilters extends ConsumerWidget {
  const _ListFilters({required this.onChanged});

  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = ref.watch(qualitySafetyListQueryProvider);
    final statusCtrl = TextEditingController(text: q.status ?? '');

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: () async {
            final from = await showDatePicker(
              context: context,
              initialDate: q.from ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (from != null) {
              ref.read(qualitySafetyListQueryProvider.notifier).state =
                  QualitySafetyListQuery(
                from: from,
                to: q.to,
                status: q.status,
                skip: q.skip,
                take: q.take,
              );
              onChanged();
            }
          },
          icon: const Icon(Icons.date_range),
          label: Text(q.from == null ? 'From' : 'From ${q.from!.toLocal()}'),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            final to = await showDatePicker(
              context: context,
              initialDate: q.to ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (to != null) {
              ref.read(qualitySafetyListQueryProvider.notifier).state =
                  QualitySafetyListQuery(
                from: q.from,
                to: to,
                status: q.status,
                skip: q.skip,
                take: q.take,
              );
              onChanged();
            }
          },
          icon: const Icon(Icons.event),
          label: Text(q.to == null ? 'To' : 'To ${q.to!.toLocal()}'),
        ),
        SizedBox(
          width: 140,
          child: TextField(
            controller: statusCtrl,
            decoration: const InputDecoration(
              labelText: 'Status',
              isDense: true,
            ),
            onSubmitted: (v) {
              ref.read(qualitySafetyListQueryProvider.notifier).state =
                  QualitySafetyListQuery(
                from: q.from,
                to: q.to,
                status: v.isEmpty ? null : v,
                skip: q.skip,
                take: q.take,
              );
              onChanged();
            },
          ),
        ),
      ],
    );
  }
}
