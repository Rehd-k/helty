import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/clinical_packages/models/clinical_package_models.dart';
import 'package:helty/src/clinical_packages/services/clinical_package_service.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/models/service_model.dart';
import 'package:helty/src/pharmacy/models/pharmacy_model.dart';
import 'package:helty/src/pharmacy/services/pharmacy_service.dart';
import 'package:helty/src/services/service_service.dart';

@RoutePage()
class ClinicalPackageManagementScreen extends StatefulWidget {
  const ClinicalPackageManagementScreen({super.key});

  @override
  State<ClinicalPackageManagementScreen> createState() =>
      _ClinicalPackageManagementScreenState();
}

class _ClinicalPackageManagementScreenState
    extends State<ClinicalPackageManagementScreen> {
  final _service = ClinicalPackageService();
  final _serviceCatalog = ServiceService();
  final _pharmacyApi = PharmacyApiService();

  bool _loading = true;
  String? _error;
  List<ClinicalPackage> _items = const [];

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
      final items = await _service.list();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<ServiceModel?> _pickService() async {
    final queryCtrl = TextEditingController();
    List<ServiceModel> results = [];
    bool searching = false;
    return showDialog<ServiceModel>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Add service'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: queryCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Search services',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) async {
                    setDialog(() => searching = true);
                    results = await _serviceCatalog.fetchServices(
                      query: queryCtrl.text.trim(),
                    );
                    setDialog(() => searching = false);
                  },
                ),
                if (searching) const LinearProgressIndicator(),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: results.length,
                    itemBuilder: (_, i) {
                      final s = results[i];
                      return ListTile(
                        title: Text(s.name),
                        onTap: () => Navigator.pop(ctx, s),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                setDialog(() => searching = true);
                results = await _serviceCatalog.fetchServices(
                  query: queryCtrl.text.trim(),
                );
                setDialog(() => searching = false);
              },
              child: const Text('Search'),
            ),
          ],
        ),
      ),
    );
  }

  Future<Drug?> _pickDrug() async {
    final queryCtrl = TextEditingController();
    List<Drug> results = [];
    bool searching = false;
    return showDialog<Drug>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Add drug'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: queryCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Search drugs',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (searching) const LinearProgressIndicator(),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: results.length,
                    itemBuilder: (_, i) {
                      final d = results[i];
                      return ListTile(
                        title: Text(d.brandName),
                        onTap: () => Navigator.pop(ctx, d),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                setDialog(() => searching = true);
                final response = await _pharmacyApi.searchDrugs(
                  SearchDrugParams(
                    search: queryCtrl.text.trim(),
                    limit: 30,
                    page: 1,
                    pageSize: 30,
                  ),
                );
                results = response.items;
                setDialog(() => searching = false);
              },
              child: const Text('Search'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _upsert({ClinicalPackage? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    var active = existing?.active ?? true;
    var isDefaultAntenatal = existing?.isDefaultAntenatal ?? false;
    final items = List<ClinicalPackageItem>.from(existing?.items ?? []);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(existing == null ? 'Create package' : 'Edit package'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SwitchListTile(
                    value: active,
                    onChanged: (v) => setDialog(() => active = v),
                    title: const Text('Active'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    value: isDefaultAntenatal,
                    onChanged: (v) => setDialog(() => isDefaultAntenatal = v),
                    title: const Text('Default antenatal package'),
                    subtitle: const Text('Only one default at a time (API enforced)'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  Text('Items (${items.length})',
                      style: Theme.of(ctx).textTheme.titleSmall),
                  ...List.generate(items.length, (index) {
                    final item = items[index];
                    return ListTile(
                      key: ValueKey('${item.serviceId}_${item.drugId}_$index'),
                      dense: true,
                      title: Text(
                        item.serviceName ??
                            item.drugName ??
                            item.serviceId ??
                            item.drugId ??
                            'Item',
                      ),
                      subtitle: Text(
                        [
                          if (item.serviceId != null) 'service: ${item.serviceId}',
                          if (item.drugId != null) 'drug: ${item.drugId}',
                        ].join(' · '),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          setDialog(() => items.removeAt(index));
                        },
                      ),
                    );
                  }),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          final s = await _pickService();
                          if (s == null) return;
                          setDialog(() {
                            items.add(
                              ClinicalPackageItem(
                                serviceId: s.serviceId.isNotEmpty
                                    ? s.serviceId
                                    : s.id,
                                serviceName: s.name,
                              ),
                            );
                          });
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Service'),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final d = await _pickDrug();
                          if (d == null) return;
                          setDialog(() {
                            items.add(
                              ClinicalPackageItem(
                                drugId: d.id,
                                drugName: d.brandName,
                              ),
                            );
                          });
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Drug'),
                      ),
                    ],
                  ),
                ],
              ),
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
        ),
      ),
    );

    if (saved != true) return;

    final payload = ClinicalPackagePayload(
      name: nameCtrl.text.trim(),
      active: active,
      isDefaultAntenatal: isDefaultAntenatal,
      items: items,
    );

    if (existing == null) {
      await _service.create(payload);
    } else {
      await _service.patch(existing.id, payload);
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinical packages'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: () => _upsert(), icon: const Icon(Icons.add)),
        ],
      ),
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) => _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final p = _items[index];
                      return ListTile(
                        title: Text(p.name),
                        subtitle: Text(
                          [
                            '${p.items.length} item(s)',
                            if (p.isDefaultAntenatal) 'Default ANC',
                            if (!p.active) 'Inactive',
                            if (p.createdByName != null &&
                                p.createdByName!.trim().isNotEmpty)
                              'Created by: ${p.createdByName}',
                          ].join(' · '),
                        ),
                        trailing: IconButton(
                          onPressed: () => _upsert(existing: p),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
