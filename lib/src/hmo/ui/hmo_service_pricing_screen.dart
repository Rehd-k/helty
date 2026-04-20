import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/hmo_models.dart';
import '../../models/service_model.dart';
import '../../services/hmo_service.dart';
import '../../services/service_service.dart';
import '../../widgets/responsive_grid.dart';

@RoutePage()
class HmoServicePricingScreen extends StatefulWidget {
  const HmoServicePricingScreen({super.key, this.initialHmoId});

  final String? initialHmoId;

  @override
  State<HmoServicePricingScreen> createState() => _HmoServicePricingScreenState();
}

class _HmoServicePricingScreenState extends State<HmoServicePricingScreen> {
  final _hmoSvc = HmoService();
  final _srvSvc = ServiceService();

  List<HmoListItem> _hmoOptions = [];
  String? _selectedHmoId;
  bool _loadingHmos = true;

  ServiceModel? _selectedService;
  final _fullCost = TextEditingController();
  final _hmoPays = TextEditingController();
  final _patientPays = TextEditingController();

  Timer? _searchDebounce;
  final _serviceQuery = TextEditingController();
  List<ServiceModel> _serviceHits = [];
  bool _searchingServices = false;

  bool _saving = false;

  HmoDetail? _hmoDetail;
  bool _loadingDetail = false;

  Future<void> _refreshHmoDetail({bool silent = false}) async {
    final id = _selectedHmoId;
    if (id == null || id.isEmpty) {
      if (mounted) {
        setState(() {
          _hmoDetail = null;
          _loadingDetail = false;
        });
      }
      return;
    }
    if (!silent && mounted) setState(() => _loadingDetail = true);
    try {
      final d = await _hmoSvc.getById(id);
      if (!mounted) return;
      setState(() {
        _hmoDetail = d;
        _loadingDetail = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingDetail = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  void initState() {
    super.initState();
    _loadHmos();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _fullCost.dispose();
    _hmoPays.dispose();
    _patientPays.dispose();
    _serviceQuery.dispose();
    super.dispose();
  }

  Future<void> _loadHmos() async {
    setState(() => _loadingHmos = true);
    try {
      final r = await _hmoSvc.list(take: 100);
      if (!mounted) return;
      setState(() {
        _hmoOptions = r.items;
        _loadingHmos = false;
        if (widget.initialHmoId != null &&
            widget.initialHmoId!.isNotEmpty &&
            r.items.any((e) => e.id == widget.initialHmoId)) {
          _selectedHmoId = widget.initialHmoId;
        }
      });
      if (_selectedHmoId != null && _selectedHmoId!.isNotEmpty) {
        await _refreshHmoDetail();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingHmos = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  void _onServiceSearchChanged(String q) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      final query = q.trim();
      if (query.length < 2) {
        if (mounted) setState(() => _serviceHits = []);
        return;
      }
      setState(() => _searchingServices = true);
      try {
        final page = await _srvSvc.findAll(skip: 0, take: 30, search: query);
        if (!mounted) return;
        setState(() {
          _serviceHits = page.services;
          _searchingServices = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _searchingServices = false);
      }
    });
  }

  static double? _parseMoney(String s) {
    final t = s.trim().replaceAll(',', '');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  static bool _sameMoney(double a, double b) {
    return (a * 100).round() == (b * 100).round();
  }

  Future<void> _applyPricing() async {
    final hmoId = _selectedHmoId;
    if (hmoId == null || hmoId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an HMO plan')),
      );
      return;
    }
    final svc = _selectedService;
    if (svc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a service')),
      );
      return;
    }
    final full = _parseMoney(_fullCost.text);
    final hmo = _parseMoney(_hmoPays.text);
    final pat = _parseMoney(_patientPays.text);
    if (full == null || hmo == null || pat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid amounts')),
      );
      return;
    }
    if (!_sameMoney(full, hmo + pat)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'HMO pays + patient pays must equal full cost '
            '(got ${(hmo + pat).toStringAsFixed(2)} vs ${full.toStringAsFixed(2)})',
          ),
        ),
      );
      return;
    }

    final serviceUuid = svc.id.trim().isNotEmpty ? svc.id : svc.serviceId;
    if (serviceUuid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service id missing')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final current = await _hmoSvc.getById(hmoId);
      final rows = List<HmoServicePriceRow>.from(current.servicePrices);
      final idx = rows.indexWhere(
        (r) => r.serviceId == serviceUuid,
      );
      final row = HmoServicePriceRow(
        serviceId: serviceUuid,
        fullCost: full,
        hmoPays: hmo,
        patientPays: pat,
        service: HmoNestedService(id: serviceUuid, name: svc.name, cost: full),
      );
      if (idx >= 0) {
        rows[idx] = row;
      } else {
        rows.add(row);
      }
      await _hmoSvc.replaceServicePrices(hmoId, rows);
      if (!mounted) return;
      await _refreshHmoDetail(silent: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service pricing saved')),
      );
      _fullCost.clear();
      _hmoPays.clear();
      _patientPays.clear();
      setState(() {
        _selectedService = null;
        _serviceQuery.clear();
        _serviceHits = [];
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildFormCard(ThemeData theme) {
    return ModernFormCard(
      title: 'Add or update a priced service',
      leadingIcon: Icons.price_change_outlined,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey(_selectedHmoId ?? 'no_hmo'),
          initialValue: _selectedHmoId,
          decoration: const InputDecoration(
            labelText: 'HMO plan *',
            border: OutlineInputBorder(),
          ),
          isExpanded: true,
          items: _hmoOptions
              .map(
                (h) => DropdownMenuItem(
                  value: h.id,
                  child: Text(
                    h.code != null && h.code!.isNotEmpty
                        ? '${h.name} (${h.code})'
                        : h.name,
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            setState(() => _selectedHmoId = v);
            _refreshHmoDetail();
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Service (search)',
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _serviceQuery,
          decoration: InputDecoration(
            hintText: 'Type at least 2 characters to search',
            prefixIcon: _searchingServices
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.medical_services_outlined),
            border: const OutlineInputBorder(),
          ),
          onChanged: _onServiceSearchChanged,
        ),
        if (_serviceHits.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(top: 8),
            child: Column(
              children: _serviceHits.map((s) {
                final label = '${s.name} · ${s.cost.toStringAsFixed(2)}';
                return ListTile(
                  dense: true,
                  title: Text(label),
                  onTap: () {
                    setState(() {
                      _selectedService = s;
                      _serviceQuery.text = s.name;
                      _fullCost.text = s.cost.toStringAsFixed(2);
                      _serviceHits = [];
                    });
                  },
                );
              }).toList(),
            ),
          ),
        if (_selectedService != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                avatar: const Icon(Icons.check_circle, size: 18),
                label: Text(_selectedService!.name),
                onDeleted: () => setState(() => _selectedService = null),
              ),
            ),
          ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _fullCost,
          decoration: const InputDecoration(
            labelText: 'Full cost *',
            border: OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
          ],
        ),
        TextFormField(
          controller: _hmoPays,
          decoration: const InputDecoration(
            labelText: 'Amount covered by HMO *',
            border: OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
          ],
        ),
        TextFormField(
          controller: _patientPays,
          decoration: const InputDecoration(
            labelText: 'Amount paid by patient *',
            border: OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
          ],
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _saving ? null : _applyPricing,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('Save pricing'),
          ),
        ),
      ],
    );
  }

  Widget _buildPricesPanel(ThemeData theme) {
    final id = _selectedHmoId;
    if (id == null || id.isEmpty) {
      return ModernFormCard(
        title: 'Priced services',
        leadingIcon: Icons.list_alt_outlined,
        children: [
          Text(
            'Choose an HMO plan on the left to see services and amounts for that plan.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    if (_loadingDetail) {
      return ModernFormCard(
        title: 'Priced services',
        leadingIcon: Icons.list_alt_outlined,
        children: [
          const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    final rows = _hmoDetail?.servicePrices ?? [];
    final planLabel = _hmoDetail?.name ?? '';

    return ModernFormCard(
      title: rows.isEmpty ? 'Priced services' : 'Priced services (${rows.length})',
      leadingIcon: Icons.list_alt_outlined,
      headerAction: IconButton(
        tooltip: 'Refresh list',
        onPressed: _loadingDetail ? null : () => _refreshHmoDetail(),
        icon: const Icon(Icons.refresh_outlined),
      ),
      children: [
        if (planLabel.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(Icons.business_outlined, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    planLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (rows.isEmpty)
          Text(
            'No priced services yet. Search for a service on the left and save.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          ...rows.map((p) {
            final name = p.service?.name ?? 'Service';
            final code = p.service?.serviceCode;
            final subtitle = code != null && code.isNotEmpty ? '$name · $code' : name;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subtitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        children: [
                          _priceChip(theme, 'Full cost', p.fullCost),
                          _priceChip(theme, 'HMO pays', p.hmoPays),
                          _priceChip(theme, 'Patient pays', p.patientPays),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _priceChip(ThemeData theme, String label, double amount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          amount.toStringAsFixed(2),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('HMO service pricing'),
      ),
      body: _loadingHmos
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 960;
                final pad = const EdgeInsets.all(20);
                final form = _buildFormCard(theme);
                final prices = _buildPricesPanel(theme);

                if (!wide) {
                  return SingleChildScrollView(
                    padding: pad,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        form,
                        const SizedBox(height: 20),
                        prices,
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: pad,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(child: form),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: SingleChildScrollView(child: prices),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
