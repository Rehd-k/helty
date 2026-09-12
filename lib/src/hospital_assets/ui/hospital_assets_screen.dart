import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_router.gr.dart';
import '../../auth/department_head_permissions.dart';
import '../../core/responsive.dart';
import '../../models/staff_model.dart';
import '../../providers/auth_provider.dart';
import '../models/hospital_asset_models.dart';
import '../services/hospital_assets_api_service.dart';
import 'asset_theme.dart';

@RoutePage()
class HospitalAssetsScreen extends ConsumerStatefulWidget {
  const HospitalAssetsScreen({super.key});

  @override
  ConsumerState<HospitalAssetsScreen> createState() =>
      _HospitalAssetsScreenState();
}

class _HospitalAssetsScreenState extends ConsumerState<HospitalAssetsScreen> {
  final _api = HospitalAssetsApiService();
  final _search = TextEditingController();
  bool _loading = true;
  String? _error;
  List<HospitalAsset> _assets = [];
  HospitalAssetKind? _kind;
  HospitalAssetStatus? _status;
  String? _departmentFilter;
  HospitalAssetAccessMe? _access;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.list(
          kind: _kind?.apiValue,
          accountType: _departmentFilter,
          q: _search.text,
        ),
        _api.me(),
      ]);
      if (!mounted) return;
      setState(() {
        _assets = results[0] as List<HospitalAsset>;
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

  Map<String, List<HospitalAsset>> get _grouped {
    final map = <String, List<HospitalAsset>>{};
    for (final a in _visible) {
      map.putIfAbsent(a.accountType, () => []).add(a);
    }
    return map;
  }

  List<HospitalAsset> get _visible {
    if (_status == null) return _assets;
    return _assets.where((a) => a.status == _status).toList();
  }

  Map<HospitalAssetStatus, int> get _statusCounts {
    final counts = {for (final s in HospitalAssetStatus.values) s: 0};
    for (final a in _assets) {
      counts[a.status] = (counts[a.status] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> _create() async {
    final staff = ref.read(authProvider).staff;
    final hospitalWide = isHospitalWideInventoryViewer(staff);
    final name = TextEditingController();
    final tag = TextEditingController();
    final location = TextEditingController();
    var kind = HospitalAssetKind.equipment;
    var accountType = staff?.accountType?.apiValue;
    final allowedDepartments = {
      for (final t in kInventoryDepartments) t.apiValue,
    };
    if (accountType == null || !allowedDepartments.contains(accountType)) {
      accountType = AccountType.store.apiValue;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final accent = colorForAccountType(
          accountType ?? staff?.accountType?.apiValue ?? '',
        );
        return AlertDialog(
          title: const Text('Register asset'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: tag,
                  decoration: const InputDecoration(
                    labelText: 'Asset tag',
                    prefixIcon: Icon(Icons.qr_code_2_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: location,
                  decoration: const InputDecoration(
                    labelText: 'Location (optional)',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<HospitalAssetKind>(
                  initialValue: kind,
                  items: HospitalAssetKind.values
                      .map(
                        (k) => DropdownMenuItem(value: k, child: Text(k.label)),
                      )
                      .toList(),
                  onChanged: (v) => kind = v ?? kind,
                  decoration: const InputDecoration(labelText: 'Kind'),
                ),
                if (hospitalWide) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: accountType,
                    items: kInventoryDepartments
                        .map(
                          (t) => DropdownMenuItem(
                            value: t.apiValue,
                            child: Text(t.label),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => accountType = v,
                    decoration: InputDecoration(
                      labelText: 'Department',
                      prefixIcon: Icon(Icons.apartment_outlined, color: accent),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: accent),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    final payloadName = name.text.trim();
    final payloadTag = tag.text.trim();
    final payloadLocation = location.text.trim();
    name.dispose();
    tag.dispose();
    location.dispose();
    if (ok != true || payloadName.isEmpty || payloadTag.isEmpty) return;
    await _api.create({
      'name': payloadName,
      'assetTag': payloadTag,
      'kind': kind.apiValue,
      if (accountType != null) 'accountType': accountType,
      if (payloadLocation.isNotEmpty) 'locationNote': payloadLocation,
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(authProvider).staff;
    final hospitalWide = isHospitalWideInventoryViewer(staff);
    final accent = colorForAccountType(
      hospitalWide ? 'CMD' : (staff?.accountType?.apiValue ?? ''),
    );
    final grouped = _grouped;
    final counts = _statusCounts;
    final deptLabel = hospitalWide
        ? 'Hospital-wide'
        : (staff?.accountType?.label ?? 'Department');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          hospitalWide ? 'Hospital inventory' : '$deptLabel inventory',
        ),
        backgroundColor: accent.withValues(alpha: 0.12),
        foregroundColor: accent,
        actions: [
          if (_access?.canManage == true)
            IconButton(
              tooltip: 'Logging grants',
              onPressed: () =>
                  context.router.push(const HospitalAssetAccessRoute()),
              icon: const Icon(Icons.manage_accounts_outlined),
            ),
        ],
      ),
      floatingActionButton: _access?.canManage == true
          ? FloatingActionButton.extended(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              onPressed: _create,
              icon: const Icon(Icons.add),
              label: const Text('Register asset'),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : ResponsiveBody(
              expand: true,
              bottomPadding: 0,
              builder: (context, bp) {
                final fabClearance = _access?.canManage == true ? 96.0 : 32.0;
                final listBottomPad =
                    MediaQuery.paddingOf(context).bottom + fabClearance + 80;
                return RefreshIndicator(
                  onRefresh: _load,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(0, 0, 0, bp.paddingV),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              InventoryScopeBanner(
                                accent: accent,
                                title: hospitalWide
                                    ? 'All department inventories'
                                    : '$deptLabel equipment & assets',
                                subtitle: hospitalWide
                                    ? 'CMD, CMAC, and Director of Admin (coming soon) can view every department. Staff only see their own.'
                                    : 'This list is limited to $deptLabel. Other departments cannot see these assets.',
                              ),
                              const SizedBox(height: 14),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final wide = constraints.maxWidth >= 720;
                                  final cards = [
                                    for (final status
                                        in HospitalAssetStatus.values)
                                      StatusCountCard(
                                        status: status,
                                        count: counts[status] ?? 0,
                                        selected: _status == status,
                                        onTap: () {
                                          setState(() {
                                            _status = _status == status
                                                ? null
                                                : status;
                                          });
                                        },
                                      ),
                                  ];
                                  if (wide) {
                                    return Row(
                                      children: [
                                        for (
                                          var i = 0;
                                          i < cards.length;
                                          i++
                                        ) ...[
                                          if (i > 0) const SizedBox(width: 8),
                                          Expanded(child: cards[i]),
                                        ],
                                      ],
                                    );
                                  }
                                  return Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final card in cards)
                                        SizedBox(width: 160, child: card),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _search,
                                decoration: InputDecoration(
                                  hintText: 'Search name, tag, or serial',
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: _search.text.isEmpty
                                      ? null
                                      : IconButton(
                                          onPressed: () {
                                            _search.clear();
                                            _load();
                                          },
                                          icon: const Icon(Icons.clear),
                                        ),
                                  border: const OutlineInputBorder(),
                                ),
                                onChanged: (_) => setState(() {}),
                                onSubmitted: (_) => _load(),
                              ),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    FilterChip(
                                      label: const Text('All kinds'),
                                      selected: _kind == null,
                                      onSelected: (_) {
                                        setState(() => _kind = null);
                                        _load();
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    for (final k
                                        in HospitalAssetKind.values) ...[
                                      FilterChip(
                                        avatar: Icon(
                                          iconForAssetKind(k),
                                          size: 16,
                                        ),
                                        label: Text(k.label),
                                        selected: _kind == k,
                                        onSelected: (_) {
                                          setState(() => _kind = k);
                                          _load();
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                  ],
                                ),
                              ),
                              if (hospitalWide) ...[
                                const SizedBox(height: 8),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      FilterChip(
                                        label: const Text('All departments'),
                                        selected: _departmentFilter == null,
                                        onSelected: (_) {
                                          setState(
                                            () => _departmentFilter = null,
                                          );
                                          _load();
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      for (final dept
                                          in kInventoryDepartments) ...[
                                        FilterChip(
                                          label: Text(dept.label),
                                          selected:
                                              _departmentFilter ==
                                              dept.apiValue,
                                          selectedColor: colorForAccountType(
                                            dept.apiValue,
                                          ).withValues(alpha: 0.22),
                                          side: BorderSide(
                                            color: colorForAccountType(
                                              dept.apiValue,
                                            ),
                                          ),
                                          onSelected: (_) {
                                            setState(
                                              () => _departmentFilter =
                                                  dept.apiValue,
                                            );
                                            _load();
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (_visible.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 48),
                              SizedBox(height: 12),
                              Text('No assets in this view'),
                            ],
                          ),
                        )
                      else
                        SliverPadding(
                          padding: EdgeInsets.only(bottom: listBottomPad),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              if (hospitalWide)
                                for (final entry in grouped.entries) ...[
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      4,
                                      12,
                                      4,
                                      8,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: colorForAccountType(
                                              entry.key,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          labelForAccountType(entry.key),
                                          style: TextStyle(
                                            color: colorForAccountType(
                                              entry.key,
                                            ),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${entry.value.length}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  for (final asset in entry.value) ...[
                                    AssetListCard(
                                      asset: asset,
                                      showDepartment: false,
                                      onTap: () => context.router.push(
                                        HospitalAssetDetailRoute(
                                          assetId: asset.id,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ]
                              else
                                for (final asset in _visible) ...[
                                  AssetListCard(
                                    asset: asset,
                                    onTap: () => context.router.push(
                                      HospitalAssetDetailRoute(
                                        assetId: asset.id,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                            ]),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
