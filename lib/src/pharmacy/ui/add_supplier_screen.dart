import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/pharmacy/widgets/pharmacy_page_chrome.dart';
import 'package:helty/src/shared/department_colors.dart';
import 'package:helty/src/widgets/helty_surface.dart';

import '../inputs/morden.form.inpts.dart';
import '../models/pharmacy_model.dart';
import '../services/pharmacy_service.dart';

@RoutePage()
class AddSupplierScreen extends StatefulWidget {
  const AddSupplierScreen({super.key});

  @override
  State<AddSupplierScreen> createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends State<AddSupplierScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = PharmacyApiService();
  final _searchCtrl = TextEditingController();
  bool _isLoading = false;

  final _nameCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _creditTermsCtrl = TextEditingController();
  final _leadTimeCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _isBlacklisted = false;
  int _page = 1;
  static const int _pageSize = 20;

  PaginatedResponse<Supplier>? _suppliersPage;
  bool _isLoadingSuppliers = false;
  String? _suppliersError;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    _loadSuppliers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    _licenseCtrl.dispose();
    _creditTermsCtrl.dispose();
    _leadTimeCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    setState(() {
      _isLoadingSuppliers = true;
      _suppliersError = null;
    });

    try {
      final page = await _apiService.getSuppliers(
        PharmacyQueryParams(
          page: _page,
          pageSize: _pageSize,
          sortBy: 'name',
          sortOrder: SortOrder.asc,
        ),
      );
      if (mounted) {
        setState(() {
          _suppliersPage = page;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _suppliersError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSuppliers = false;
        });
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String? _contactField(Supplier supplier, String key) {
    final info = supplier.contactInfo;
    if (info == null) return null;
    final value = info[key];
    return value?.toString();
  }

  List<Supplier> get _visibleSuppliers {
    final suppliers = _suppliersPage?.items ?? [];
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return suppliers;
    return suppliers.where((s) {
      final phone = (_contactField(s, 'phone') ?? '').toLowerCase();
      final email = (_contactField(s, 'email') ?? '').toLowerCase();
      return s.name.toLowerCase().contains(q) ||
          phone.contains(q) ||
          email.contains(q);
    }).toList();
  }

  void _showSupplierSuppliesDialog(Supplier supplier) {
    final width = MediaQuery.sizeOf(context).width;
    showDialog(
      context: context,
      builder: (ctx) {
        if (supplier.id == null || supplier.id!.isEmpty) {
          return AlertDialog(
            title: const Text('Supplies'),
            content: const Text(
              'Supplier id is missing, unable to load supplies.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        }

        return Dialog(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: width < 560 ? width - 32 : 720,
              maxHeight: 480,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const HeltySolidIcon(
                        icon: Icons.inventory_2_outlined,
                        color: PharmacyAccent.teal,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: HeltyEllipsisText(
                          text: 'Supplies from ${supplier.name}',
                          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: FutureBuilder<PaginatedResponse<DrugBatch>>(
                      future: _apiService.getDrugBatches(
                        PharmacyQueryParams(
                          filters: {'supplierId': supplier.id},
                        ),
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text(snapshot.error.toString()));
                        }
                        final batches = snapshot.data?.items ?? [];
                        if (batches.isEmpty) {
                          return const Center(
                            child: Text('No supplies found for this supplier.'),
                          );
                        }
                        return ListView.separated(
                          itemCount: batches.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final b = batches[index];
                            final drug = b.drug;
                            final drugName =
                                (drug?.brandName.isNotEmpty == true)
                                ? drug!.brandName
                                : (drug?.genericName ?? '');
                            final cs = Theme.of(context).colorScheme;
                            return Material(
                              color: pharmacyZebra(cs, index),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    HeltyEllipsisText(
                                      text: drugName.isEmpty ? '—' : drugName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    HeltyEllipsisText(
                                      text:
                                          'Batch ${b.batchNumber ?? '—'} · Qty ${b.quantityReceived} · '
                                          '${b.costPrice != null ? b.costPrice!.toStringAsFixed(2) : '—'} · '
                                          'Exp ${_formatDate(b.expiryDate)}',
                                      style: TextStyle(
                                        color: cs.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final supplier = Supplier(
        name: _nameCtrl.text,
        licenseNumber: _licenseCtrl.text,
        creditTerms: _creditTermsCtrl.text,
        leadTimeDays: int.tryParse(_leadTimeCtrl.text),
        isBlacklisted: _isBlacklisted,
        contactInfo: {'phone': _phoneCtrl.text, 'email': _emailCtrl.text},
      );

      await _apiService.createSupplier(supplier);
      if (!mounted) return;
      _nameCtrl.clear();
      _licenseCtrl.clear();
      _creditTermsCtrl.clear();
      _leadTimeCtrl.clear();
      _phoneCtrl.clear();
      _emailCtrl.clear();
      setState(() {
        _isBlacklisted = false;
        _page = 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supplier added successfully!')),
      );
      await _loadSuppliers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final suppliers = _suppliersPage?.items ?? [];
    final visible = _visibleSuppliers;
    final ready = !_isLoadingSuppliers && _suppliersError == null;
    final active = suppliers.where((s) => !s.isBlacklisted).length;
    final blocked = suppliers.where((s) => s.isBlacklisted).length;
    final total = _suppliersPage?.total ?? 0;
    final totalPages = (_suppliersPage?.totalPages ?? 1).clamp(1, 1000000);

    return Scaffold(
      backgroundColor: cs.surface,
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) {
          final width = bp.maxWidth > 0
              ? bp.maxWidth
              : MediaQuery.sizeOf(context).width;
          final showRail = width >= PharmacyAccent.railBreakpoint;
          final useCards = width < PharmacyAccent.cardBreakpoint;

          final header = PharmacyPageHeader(
            title: 'Add Supplier',
            subtitle: 'Register a supplier and review who can receive orders.',
            icon: Icons.local_shipping_outlined,
            iconColor: DepartmentColors.pharmacy,
            onRefresh: _isLoadingSuppliers ? null : _loadSuppliers,
          );
          final kpis = PharmacyKpiStrip(
            items: [
              PharmacyKpiItem(
                label: 'Suppliers',
                value: ready ? '$total' : '—',
                caption: 'Registered',
                icon: Icons.groups_outlined,
                accent: PharmacyAccent.blue,
              ),
              PharmacyKpiItem(
                label: 'On this page',
                value: ready ? '${suppliers.length}' : '—',
                caption: 'Loaded',
                icon: Icons.list_alt_outlined,
                accent: PharmacyAccent.teal,
              ),
              PharmacyKpiItem(
                label: 'Active',
                value: ready ? '$active' : '—',
                caption: 'On this page',
                icon: Icons.check_circle_outline,
                accent: PharmacyAccent.green,
              ),
              PharmacyKpiItem(
                label: 'Blacklisted',
                value: ready ? '$blocked' : '—',
                caption: 'On this page',
                icon: Icons.block_outlined,
                accent: PharmacyAccent.amber,
              ),
            ],
          );
          final filters = TextField(
            controller: _searchCtrl,
            style: const TextStyle(fontSize: 12),
            decoration: pharmacyFieldDecoration(
              context,
              label: 'Search',
              hint: 'Name, phone, or email on this page…',
              icon: Icons.search,
              iconColor: PharmacyAccent.indigo,
            ),
          );
          final list = _SupplierList(
            suppliers: visible,
            loading: _isLoadingSuppliers && suppliers.isEmpty,
            error: suppliers.isEmpty ? _suppliersError : null,
            useCards: useCards,
            total: total,
            page: _page,
            totalPages: totalPages,
            onPrev: _page > 1
                ? () {
                    setState(() => _page -= 1);
                    _loadSuppliers();
                  }
                : null,
            onNext: _page < totalPages
                ? () {
                    setState(() => _page += 1);
                    _loadSuppliers();
                  }
                : null,
            onView: _showSupplierSuppliesDialog,
            phoneOf: (s) => _contactField(s, 'phone') ?? '—',
            emailOf: (s) => _contactField(s, 'email') ?? '—',
            onRetry: _loadSuppliers,
          );
          final form = _SupplierForm(
            formKey: _formKey,
            nameCtrl: _nameCtrl,
            licenseCtrl: _licenseCtrl,
            emailCtrl: _emailCtrl,
            phoneCtrl: _phoneCtrl,
            creditTermsCtrl: _creditTermsCtrl,
            leadTimeCtrl: _leadTimeCtrl,
            isBlacklisted: _isBlacklisted,
            isLoading: _isLoading,
            onBlacklistChanged: (v) => setState(() => _isBlacklisted = v),
            onSubmit: _submitForm,
          );

          final main = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 10),
              kpis,
              const SizedBox(height: 10),
              filters,
              if (_suppliersError != null && suppliers.isNotEmpty) ...[
                const SizedBox(height: 10),
                HeltyEllipsisText(
                  text: _suppliersError!,
                  style: TextStyle(color: cs.error),
                ),
              ],
              const SizedBox(height: 10),
              Expanded(child: list),
            ],
          );

          if (showRail) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 9, child: main),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: SingleChildScrollView(child: form)),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: main),
              const SizedBox(height: 10),
              SizedBox(height: 280, child: SingleChildScrollView(child: form)),
            ],
          );
        },
      ),
    );
  }
}

class _SupplierForm extends StatelessWidget {
  const _SupplierForm({
    required this.formKey,
    required this.nameCtrl,
    required this.licenseCtrl,
    required this.emailCtrl,
    required this.phoneCtrl,
    required this.creditTermsCtrl,
    required this.leadTimeCtrl,
    required this.isBlacklisted,
    required this.isLoading,
    required this.onBlacklistChanged,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController licenseCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController creditTermsCtrl;
  final TextEditingController leadTimeCtrl;
  final bool isBlacklisted;
  final bool isLoading;
  final ValueChanged<bool> onBlacklistChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return HeltySurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const HeltySolidIcon(
                  icon: Icons.person_add_alt_1,
                  color: PharmacyAccent.green,
                  size: 26,
                  iconSize: 14,
                  radius: 7,
                ),
                const SizedBox(width: 8),
                Text(
                  'New supplier',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ModernTextField(
              label: 'Supplier Name',
              hint: 'e.g., Global Pharma Distributors',
              controller: nameCtrl,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            ModernTextField(
              label: 'License Number',
              hint: 'Operating license ID',
              controller: licenseCtrl,
            ),
            ModernTextField(
              label: 'Email Address',
              hint: 'contact@supplier.com',
              controller: emailCtrl,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            ModernTextField(
              label: 'Phone Number',
              hint: '+1 234 567 890',
              controller: phoneCtrl,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            ModernTextField(
              label: 'Credit Terms',
              hint: 'e.g., Net 30',
              controller: creditTermsCtrl,
            ),
            ModernTextField(
              label: 'Lead Time (Days)',
              hint: 'e.g., 5',
              controller: leadTimeCtrl,
              keyboardType: TextInputType.number,
            ),
            ModernSwitchCard(
              title: 'Blacklist Supplier',
              subtitle:
                  'Prevent future purchase orders from being issued to this supplier.',
              value: isBlacklisted,
              onChanged: onBlacklistChanged,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: isLoading ? null : onSubmit,
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save supplier'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupplierList extends StatelessWidget {
  const _SupplierList({
    required this.suppliers,
    required this.loading,
    required this.error,
    required this.useCards,
    required this.total,
    required this.page,
    required this.totalPages,
    required this.onPrev,
    required this.onNext,
    required this.onView,
    required this.phoneOf,
    required this.emailOf,
    required this.onRetry,
  });

  final List<Supplier> suppliers;
  final bool loading;
  final String? error;
  final bool useCards;
  final int total;
  final int page;
  final int totalPages;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final ValueChanged<Supplier> onView;
  final String Function(Supplier) phoneOf;
  final String Function(Supplier) emailOf;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final start = suppliers.isEmpty ? 0 : ((page - 1) * 20) + 1;
    final end = suppliers.isEmpty ? 0 : start + suppliers.length - 1;
    final footer = PharmacyPaginationFooter(
      label: suppliers.isEmpty
          ? 'No suppliers to display'
          : 'Showing $start–$end of $total',
      page: page,
      canPrev: onPrev != null,
      canNext: onNext != null,
      onPrev: onPrev,
      onNext: onNext,
    );

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final body = suppliers.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HeltySolidIcon(
                    icon: error == null
                        ? Icons.local_shipping_outlined
                        : Icons.error_outline,
                    color: error == null
                        ? DepartmentColors.pharmacy
                        : Theme.of(context).colorScheme.error,
                    size: 48,
                    iconSize: 26,
                    radius: 12,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    error ?? 'No suppliers found.',
                    textAlign: TextAlign.center,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: onRetry,
                      child: const Text('Retry'),
                    ),
                  ],
                ],
              ),
            ),
          )
        : useCards
        ? ListView.builder(
            itemCount: suppliers.length,
            itemBuilder: (context, index) => _SupplierCard(
              supplier: suppliers[index],
              phone: phoneOf(suppliers[index]),
              email: emailOf(suppliers[index]),
              onView: () => onView(suppliers[index]),
            ),
          )
        : _SupplierTable(
            suppliers: suppliers,
            phoneOf: phoneOf,
            emailOf: emailOf,
            onView: onView,
          );

    return HeltySurfaceCard(
      child: Column(
        children: [
          Expanded(child: body),
          footer,
        ],
      ),
    );
  }
}

class _SupplierTable extends StatelessWidget {
  const _SupplierTable({
    required this.suppliers,
    required this.phoneOf,
    required this.emailOf,
    required this.onView,
  });

  final List<Supplier> suppliers;
  final String Function(Supplier) phoneOf;
  final String Function(Supplier) emailOf;
  final ValueChanged<Supplier> onView;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, inner) {
        const minWidth = 860.0;
        final tableWidth = inner.maxWidth < minWidth
            ? minWidth
            : inner.maxWidth;
        final sheet = SizedBox(
          width: tableWidth,
          height: inner.maxHeight,
          child: Column(
            children: [
              Container(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(
                  children: [
                    _head(context, 'SUPPLIER', flex: 3),
                    const SizedBox(width: 20),
                    _head(context, 'PHONE', flex: 2),
                    const SizedBox(width: 20),
                    _head(context, 'EMAIL', flex: 3),
                    const SizedBox(width: 20),
                    _head(context, 'TERMS', flex: 2),
                    const SizedBox(width: 20),
                    _head(context, 'LEAD', flex: 1),
                    const SizedBox(width: 20),
                    _head(context, 'STATUS', flex: 2),
                    const SizedBox(width: 20),
                    _head(context, 'ACTIONS', flex: 2, alignEnd: true),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: suppliers.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: cs.outline.withValues(alpha: 0.08),
                  ),
                  itemBuilder: (context, index) {
                    final s = suppliers[index];
                    return Material(
                      color: pharmacyZebra(cs, index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: HeltyEllipsisText(
                                text: s.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 2,
                              child: HeltyEllipsisText(text: phoneOf(s)),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 3,
                              child: HeltyEllipsisText(text: emailOf(s)),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 2,
                              child: HeltyEllipsisText(
                                text: s.creditTerms?.trim().isNotEmpty == true
                                    ? s.creditTerms!
                                    : '—',
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 1,
                              child: HeltyEllipsisText(
                                text: s.leadTimeDays != null
                                    ? '${s.leadTimeDays}d'
                                    : '—',
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 2,
                              child: HeltyEllipsisChip(
                                label: s.isBlacklisted
                                    ? 'Blacklisted'
                                    : 'Active',
                                color: s.isBlacklisted
                                    ? cs.error
                                    : PharmacyAccent.green,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: OutlinedButton(
                                  onPressed: s.id == null || s.id!.isEmpty
                                      ? null
                                      : () => onView(s),
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    shape: const StadiumBorder(),
                                  ),
                                  child: const Text('View'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
        if (inner.maxWidth >= minWidth) return sheet;
        return _HScroll(child: sheet);
      },
    );
  }

  Widget _head(
    BuildContext context,
    String label, {
    required int flex,
    bool alignEnd = false,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: alignEnd ? TextAlign.end : TextAlign.start,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

class _HScroll extends StatefulWidget {
  const _HScroll({required this.child});

  final Widget child;

  @override
  State<_HScroll> createState() => _HScrollState();
}

class _HScrollState extends State<_HScroll> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _controller,
      thumbVisibility: true,
      notificationPredicate: (notification) => notification.depth == 0,
      child: SingleChildScrollView(
        controller: _controller,
        primary: false,
        scrollDirection: Axis.horizontal,
        child: widget.child,
      ),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  const _SupplierCard({
    required this.supplier,
    required this.phone,
    required this.email,
    required this.onView,
  });

  final Supplier supplier;
  final String phone;
  final String email;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return HeltySurfaceCard(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: supplier.id == null || supplier.id!.isEmpty ? null : onView,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: HeltyEllipsisText(
                    text: supplier.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                HeltyStatusChip(
                  label: supplier.isBlacklisted ? 'Blacklisted' : 'Active',
                  color: supplier.isBlacklisted
                      ? cs.error
                      : PharmacyAccent.green,
                ),
              ],
            ),
            const SizedBox(height: 4),
            HeltyEllipsisText(
              text: phone,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            HeltyEllipsisText(
              text: email,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            HeltyEllipsisText(
              text:
                  '${supplier.creditTerms?.trim().isNotEmpty == true ? supplier.creditTerms : 'No credit terms'}'
                  ' · ${supplier.leadTimeDays != null ? '${supplier.leadTimeDays}d lead' : '—'}',
              style: theme.textTheme.bodySmall,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: supplier.id == null || supplier.id!.isEmpty
                    ? null
                    : onView,
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  shape: const StadiumBorder(),
                ),
                child: const Text('View'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
