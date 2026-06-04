import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_router.gr.dart';
import '../../models/staff_model.dart';
import '../../providers/staff_providers.dart';

@RoutePage()
class SuperAdminStaffListScreen extends ConsumerStatefulWidget {
  const SuperAdminStaffListScreen({super.key});

  @override
  ConsumerState<SuperAdminStaffListScreen> createState() =>
      _SuperAdminStaffListScreenState();
}

class _SuperAdminStaffListScreenState
    extends ConsumerState<SuperAdminStaffListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applySearch() {
    setState(() => _query = _searchCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final asyncStaff = ref.watch(
      staffListProvider((
        query: _query.isEmpty ? null : _query,
        role: null,
        departmentId: null,
        limit: 500,
      )),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Staff Directory')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search by name, ID, email…',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _applySearch(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _applySearch,
                  child: const Text('Search'),
                ),
              ],
            ),
          ),
          Expanded(
            child: asyncStaff.when(
              data: (list) => RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(
                    staffListProvider((
                      query: _query.isEmpty ? null : _query,
                      role: null,
                      departmentId: null,
                      limit: 500,
                    )),
                  );
                  await ref.read(
                    staffListProvider((
                      query: _query.isEmpty ? null : _query,
                      role: null,
                      departmentId: null,
                      limit: 500,
                    )).future,
                  );
                },
                child: list.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 120),
                          Icon(
                            Icons.groups_outlined,
                            size: 48,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No staff found',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final w = constraints.maxWidth;
                          final cross = w >= 1100
                              ? 3
                              : w >= 720
                              ? 2
                              : 1;
                          return GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cross,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: cross >= 2 ? 1.85 : 2.1,
                                ),
                            itemCount: list.length,
                            itemBuilder: (context, i) {
                              final s = list[i];
                              return _StaffCard(
                                staff: s,
                                onTap: () => context.router.push(
                                  SuperAdminStaffDetailRoute(staffId: s.id),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, color: cs.error, size: 40),
                      const SizedBox(height: 12),
                      Text(e.toString(), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {
                          ref.invalidate(
                            staffListProvider((
                              query: _query.isEmpty ? null : _query,
                              role: null,
                              departmentId: null,
                              limit: 500,
                            )),
                          );
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffCard extends StatefulWidget {
  const _StaffCard({required this.staff, required this.onTap});

  final Staff staff;
  final VoidCallback onTap;

  @override
  State<_StaffCard> createState() => _StaffCardState();
}

class _StaffCardState extends State<_StaffCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = widget.staff;
    final subtitle = [
      if (s.email != null && s.email!.isNotEmpty) s.email!,
      '${s.role} · ${s.staffId}',
    ].join('\n');

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Semantics(
        button: true,
        label: '${s.fullName}, ${s.role}',
        child: Material(
          color: cs.surfaceContainerLow,
          elevation: _hover ? 2 : 0,
          shadowColor: cs.shadow.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: _hover
                  ? cs.primary.withValues(alpha: 0.45)
                  : cs.outlineVariant.withValues(alpha: 0.65),
            ),
          ),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: cs.primaryContainer,
                        foregroundColor: cs.onPrimaryContainer,
                        child: Text(
                          s.firstName.isNotEmpty
                              ? s.firstName[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          s.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (!s.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: cs.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Inactive',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: cs.onErrorContainer),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
