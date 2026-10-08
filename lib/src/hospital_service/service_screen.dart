import 'dart:async';

import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/helper/date.formatter.dart';

import '../core/extensions/number.extention.dart';
import '../models/service_category_model.dart';
import '../models/service_model.dart';
import '../models/staff_model.dart';
import '../services/department_service.dart';
import '../services/service_category_service.dart';
import '../services/service_service.dart';
import '../services/staff_service.dart';
import 'package:helty/src/core/responsive.dart';
import '../auth/hospital_service_permissions.dart';
import '../providers/auth_provider.dart';
import 'setup_widgets/setup_form_widgets.dart';
import 'setup_widgets/setup_table_widgets.dart';

// ── helpers ──────────────────────────────────────────────────────────────────

/// Format any ISO-8601 / DateTime string consistently across the screen.
String _fmtDate(dynamic raw) {
  if (raw == null) return '—';
  try {
    final dt = raw is DateTime ? raw : DateTime.parse(raw.toString());
    return DateFormatter.shortDate(dt);
  } catch (_) {
    return raw.toString();
  }
}

// ── tab enum ─────────────────────────────────────────────────────────────────

enum SetupTab { departments, categories, services }

// ─────────────────────────────────────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────────────────────────────────────
@RoutePage()
class SystemSetupScreen extends ConsumerStatefulWidget {
  const SystemSetupScreen({super.key});

  @override
  ConsumerState<SystemSetupScreen> createState() => _SystemSetupScreenState();
}

class _SystemSetupScreenState extends ConsumerState<SystemSetupScreen> {
  // ── services ──────────────────────────────────────────────────────────────
  final _deptSvc = DepartmentService();
  final _catSvc = ServiceCategoryService();
  final _srvSvc = ServiceService();
  final _staffSvc = StaffService();

  // ── tab ───────────────────────────────────────────────────────────────────
  SetupTab _currentTab = SetupTab.departments;
  bool _mobileFormOpen = false;

  // ── list data (loaded from API) ───────────────────────────────────────────
  List<Department> _departments = [];
  List<ServiceCategory> _categories = [];
  List<Staff> _staffList = [];
  bool _loading = false;

  /// Bumped after service create/update/delete so the services table refetches quietly.
  final ValueNotifier<int> _serviceTableRefreshSignal = ValueNotifier(0);

  // ── form controllers ──────────────────────────────────────────────────────

  // Department form
  final _deptNameCtrl = TextEditingController();
  String? _selectedHeadId; // Staff.id of selected head

  // Category form
  final _catNameCtrl = TextEditingController();
  final _catDescCtrl = TextEditingController();

  // Service form
  final _srvNameCtrl = TextEditingController();
  final _srvCodeCtrl = TextEditingController();
  final _srvDescCtrl = TextEditingController();
  final _srvCostCtrl = TextEditingController();
  String? _srvCatId;
  String? _srvDeptId;

  // edit-mode IDs (null → create mode)
  String? _editingDeptId;
  String? _editingCatId;
  String? _editingSrvId;

  // ── lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _deptNameCtrl.dispose();
    _catNameCtrl.dispose();
    _catDescCtrl.dispose();
    _srvNameCtrl.dispose();
    _srvDescCtrl.dispose();
    _srvCostCtrl.dispose();
    _serviceTableRefreshSignal.dispose();
    super.dispose();
  }

  // ── API calls ─────────────────────────────────────────────────────────────

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _deptSvc.fetchDepartments(),
        _catSvc.fetchCategories(),
        _staffSvc.fetchStaff(),
      ]);
      debugPrint('Loaded: ${results.map((r) => (r as List).length).toList()}');
      if (!mounted) return;
      setState(() {
        _departments = results[0] as List<Department>;
        _categories = results[1] as List<ServiceCategory>;
        _staffList = results[2] as List<Staff>;
      });
    } catch (e) {
      _snack('Failed to load data: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── Departments ──────────────────────────────────────────────────────────

  Future<void> _saveDepartment() async {
    final name = _deptNameCtrl.text.trim();
    if (name.isEmpty) {
      _snack('Department name is required');
      return;
    }
    // description field stores the head ID so the API can resolve it
    final d = Department(
      id: _editingDeptId ?? '',
      name: name,
      headId: _selectedHeadId,
    );
    try {
      if (_editingDeptId != null) {
        await _deptSvc.updateDepartment(d);
        _snack('Department updated');
      } else {
        await _deptSvc.createDepartment(d);
        _snack('Department created');
      }
      _clearDeptForm();
      await _loadAll();
    } catch (e) {
      _snack('Error: $e');
    }
  }

  Future<void> _deleteDepartment(String id) async {
    await _confirmDelete(() async {
      await _deptSvc.deleteDepartment(id);
      await _loadAll();
    });
  }

  void _editDepartment(Department d) => setState(() {
    _currentTab = SetupTab.departments;
    _mobileFormOpen = true;
    _editingDeptId = d.id;
    _deptNameCtrl.text = d.name;
    _selectedHeadId = d.description; // head stored as description
  });

  void _clearDeptForm() => setState(() {
    _mobileFormOpen = false;
    _editingDeptId = null;
    _deptNameCtrl.clear();
    _selectedHeadId = null;
  });

  // ─── Categories ───────────────────────────────────────────────────────────

  Future<void> _saveCategory() async {
    final name = _catNameCtrl.text.trim();
    if (name.isEmpty) {
      _snack('Category name is required');
      return;
    }
    final c = ServiceCategory(
      id: _editingCatId ?? '',
      name: name,
      description: _catDescCtrl.text.trim(),
    );
    try {
      if (_editingCatId != null) {
        await _catSvc.updateCategory(c);
        _snack('Category updated');
      } else {
        await _catSvc.createCategory(c);
        _snack('Category created');
      }
      _clearCatForm();
      await _loadAll();
    } catch (e) {
      _snack('Error: $e');
    }
  }

  Future<void> _deleteCategory(String id) async {
    await _confirmDelete(() async {
      await _catSvc.deleteCategory(id);
      await _loadAll();
    });
  }

  void _editCategory(ServiceCategory c) => setState(() {
    _currentTab = SetupTab.categories;
    _mobileFormOpen = true;
    _editingCatId = c.id;
    _catNameCtrl.text = c.name;
    _catDescCtrl.text = c.description ?? '';
  });

  void _clearCatForm() => setState(() {
    _mobileFormOpen = false;
    _editingCatId = null;
    _catNameCtrl.clear();
    _catDescCtrl.clear();
  });

  // ─── Services ─────────────────────────────────────────────────────────────

  Future<void> _saveService() async {
    if (!canManageHospitalServices(ref.read(authProvider).staff)) {
      _snack(
        'Only billing head, accounting head, or super admin can add or edit services.',
      );
      return;
    }
    final name = _srvNameCtrl.text.trim();
    final cost = double.tryParse(_srvCostCtrl.text.replaceAll(',', '')) ?? 0.0;
    if (name.isEmpty) {
      _snack('Service name is required');
      return;
    }
    final s = ServiceModel(
      id: _editingSrvId ?? '',
      serviceCode: _srvCodeCtrl.text.trim().isEmpty
          ? null
          : _srvCodeCtrl.text.trim(),
      serviceId: _editingSrvId ?? '',
      name: name,
      description: _srvDescCtrl.text.trim(),
      cost: cost,
      categoryId: _srvCatId,
      departmentId: _srvDeptId,
    );
    try {
      if (_editingSrvId != null) {
        await _srvSvc.updateService(s);
        _snack('Service updated');
      } else {
        await _srvSvc.createService(s);
        _snack('Service created');
      }
      _clearSrvForm();
      _serviceTableRefreshSignal.value++;
    } catch (e) {
      _snack('Error: $e');
    }
  }

  Future<void> _deleteService(String id) async {
    if (!canManageHospitalServices(ref.read(authProvider).staff)) {
      _snack(
        'Only billing head, accounting head, or super admin can delete services.',
      );
      return;
    }
    await _confirmDelete(() async {
      await _srvSvc.deleteService(id);
      if (mounted) _serviceTableRefreshSignal.value++;
    });
  }

  void _editService(ServiceModel s) => setState(() {
    _currentTab = SetupTab.services;
    _mobileFormOpen = true;
    _editingSrvId = s.id;
    _srvNameCtrl.text = s.name;
    _srvDescCtrl.text = s.description ?? '';
    _srvCostCtrl.text = s.cost.toString();
    _srvCatId = s.categoryId;
    _srvDeptId = s.departmentId;
  });

  void _clearSrvForm() => setState(() {
    _mobileFormOpen = false;
    _editingSrvId = null;
    _srvNameCtrl.clear();
    _srvDescCtrl.clear();
    _srvCostCtrl.clear();
    _srvCatId = null;
    _srvDeptId = null;
  });

  // ── utilities ─────────────────────────────────────────────────────────────

  Future<void> _confirmDelete(Future<void> Function() action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('This record will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await action();
        _snack('Deleted successfully');
      } catch (e) {
        _snack('Delete failed: $e');
      }
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final canManageServices = canManageHospitalServices(
      ref.watch(authProvider).staff,
    );

    return Scaffold(
      backgroundColor: cs.surface,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ResponsiveBody(
              center: false,
              builder: (context, bp) {
                final formOpen = bp.isMobile && _mobileFormOpen;
                final addLabel = switch (_currentTab) {
                  SetupTab.departments => 'Add department',
                  SetupTab.categories => 'Add category',
                  SetupTab.services => 'Add service',
                };
                void closeForm() {
                  switch (_currentTab) {
                    case SetupTab.departments:
                      _clearDeptForm();
                    case SetupTab.categories:
                      _clearCatForm();
                    case SetupTab.services:
                      _clearSrvForm();
                  }
                }

                final tabs = bp.isMobile
                    ? SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (final tab in SetupTab.values)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(_setupTabLabel(tab)),
                                  selected: _currentTab == tab,
                                  onSelected: (_) => setState(() {
                                    _currentTab = tab;
                                    _mobileFormOpen = false;
                                  }),
                                ),
                              ),
                          ],
                        ),
                      )
                    : SegmentedButton<SetupTab>(
                        segments: [
                          for (final tab in SetupTab.values)
                            ButtonSegment(
                              value: tab,
                              label: Text(
                                _setupTabLabel(tab),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                        ],
                        selected: {_currentTab},
                        onSelectionChanged: (s) =>
                            setState(() => _currentTab = s.first),
                      );

                return PopScope(
                  canPop: !formOpen,
                  onPopInvokedWithResult: (didPop, _) {
                    if (didPop || !formOpen) return;
                    closeForm();
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!formOpen)
                        ResponsiveToolbar(
                          leading: Text(
                            'System Configuration',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: bp.isMobile ? 20 : 24,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                          actions: [tabs],
                        ),
                      SizedBox(height: bp.isMobile ? 12 : 24),
                      Expanded(
                        child: formOpen
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        tooltip: 'Back to list',
                                        onPressed: closeForm,
                                        icon: const Icon(Icons.arrow_back),
                                      ),
                                      Expanded(
                                        child: Text(
                                          addLabel,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: _setupPanel(
                                      child: _buildCurrentForm(
                                        canManageServices,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : bp.isMobile
                            ? _setupPanel(
                                child: _buildCurrentTable(canManageServices),
                              )
                            : ResponsiveRowColumn(
                                firstFlex: 1,
                                secondFlex: 2,
                                gap: 24,
                                first: _setupPanel(
                                  padding: const EdgeInsets.all(24),
                                  child: _buildCurrentForm(canManageServices),
                                ),
                                second: _setupPanel(
                                  child: _buildCurrentTable(canManageServices),
                                ),
                              ),
                      ),
                      if (bp.isMobile && !formOpen)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: FilledButton.icon(
                            onPressed: () =>
                                setState(() => _mobileFormOpen = true),
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(addLabel),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // ── form router ───────────────────────────────────────────────────────────

  String _setupTabLabel(SetupTab tab) {
    switch (tab) {
      case SetupTab.departments:
        return 'Departments';
      case SetupTab.categories:
        return 'Categories';
      case SetupTab.services:
        return 'Services';
    }
  }

  Widget _setupPanel({required Widget child, EdgeInsetsGeometry? padding}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
      ),
      child: child,
    );
  }

  Widget _buildCurrentForm(bool canManageServices) {
    switch (_currentTab) {
      case SetupTab.departments:
        return _DepartmentForm(
          nameCtrl: _deptNameCtrl,
          selectedHeadId: _selectedHeadId,
          staffList: _staffList,
          isEditing: _editingDeptId != null,
          onHeadChanged: (v) => setState(() => _selectedHeadId = v),
          onSave: _saveDepartment,
          onCancel: _clearDeptForm,
        );
      case SetupTab.categories:
        return _CategoryForm(
          nameCtrl: _catNameCtrl,
          descCtrl: _catDescCtrl,
          isEditing: _editingCatId != null,
          onSave: _saveCategory,
          onCancel: _clearCatForm,
        );
      case SetupTab.services:
        return _ServiceForm(
          nameCtrl: _srvNameCtrl,
          codeCtrl: _srvCodeCtrl,
          descCtrl: _srvDescCtrl,
          costCtrl: _srvCostCtrl,
          selectedCatId: _srvCatId,
          selectedDeptId: _srvDeptId,
          categories: _categories,
          departments: _departments,
          isEditing: _editingSrvId != null,
          canManageServices: canManageServices,
          onCatChanged: (v) => setState(() => _srvCatId = v),
          onDeptChanged: (v) => setState(() => _srvDeptId = v),
          onSave: _saveService,
          onCancel: _clearSrvForm,
        );
    }
  }

  // ── table router ──────────────────────────────────────────────────────────

  Widget _buildCurrentTable(bool canManageServices) {
    switch (_currentTab) {
      case SetupTab.departments:
        return _DepartmentTable(
          rows: _departments,
          staffList: _staffList,
          onEdit: _editDepartment,
          onDelete: (d) => _deleteDepartment(d.id),
        );
      case SetupTab.categories:
        return _CategoryTable(
          rows: _categories,
          onEdit: _editCategory,
          onDelete: (c) => _deleteCategory(c.id),
        );
      case SetupTab.services:
        return _ServiceTable(
          serviceApi: _srvSvc,
          categories: _categories,
          departments: _departments,
          canManageServices: canManageServices,
          refreshSignal: _serviceTableRefreshSignal,
          onEdit: _editService,
          onDelete: (s) => _deleteService(s.id),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  FORM WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _DepartmentForm extends StatelessWidget {
  const _DepartmentForm({
    required this.nameCtrl,
    required this.selectedHeadId,
    required this.staffList,
    required this.isEditing,
    required this.onHeadChanged,
    required this.onSave,
    required this.onCancel,
  });

  final TextEditingController nameCtrl;
  final String? selectedHeadId;
  final List<Staff> staffList;
  final bool isEditing;
  final ValueChanged<String?> onHeadChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SetupFormHeader(
        icon: Icons.domain,
        title: 'Add New Department',
        subtitle: '__',
      ),
      const SizedBox(height: 24),
      SetupTextField(label: 'Department Name', controller: nameCtrl),
      const SizedBox(height: 16),
      SetupDropdown(
        label: 'Head of Department',
        value: selectedHeadId,
        items: staffList.map((s) => s.id).toList(),
        itemLabels: staffList.map((s) => s.fullName).toList(),
        onChanged: onHeadChanged,
      ),
      const Spacer(),
      if (isEditing) ...[
        OutlinedButton(onPressed: onCancel, child: const Text('Cancel Edit')),
        const SizedBox(height: 8),
      ],
      SetupSubmitButton(
        label: isEditing ? 'Update Department' : 'Add Department',
        onPressed: onSave,
      ),
    ],
  );
}

class _CategoryForm extends StatelessWidget {
  const _CategoryForm({
    required this.nameCtrl,
    required this.descCtrl,
    required this.isEditing,
    required this.onSave,
    required this.onCancel,
  });

  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final bool isEditing;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SetupFormHeader(
        icon: Icons.category,
        title: 'Add New Category',
        subtitle: '__',
      ),
      const SizedBox(height: 24),
      SetupTextField(label: 'Category Name', controller: nameCtrl),
      const SizedBox(height: 16),
      SetupTextField(label: 'Description', controller: descCtrl, maxLines: 3),
      const Spacer(),
      if (isEditing) ...[
        OutlinedButton(onPressed: onCancel, child: const Text('Cancel Edit')),
        const SizedBox(height: 8),
      ],
      SetupSubmitButton(
        label: isEditing ? 'Update Category' : 'Add Category',
        onPressed: onSave,
      ),
    ],
  );
}

class _ServiceForm extends StatelessWidget {
  const _ServiceForm({
    required this.nameCtrl,
    required this.codeCtrl,
    required this.descCtrl,
    required this.costCtrl,
    required this.selectedCatId,
    required this.selectedDeptId,
    required this.categories,
    required this.departments,
    required this.isEditing,
    required this.canManageServices,
    required this.onCatChanged,
    required this.onDeptChanged,
    required this.onSave,
    required this.onCancel,
  });

  final TextEditingController nameCtrl;
  final TextEditingController codeCtrl;
  final TextEditingController descCtrl;
  final TextEditingController costCtrl;
  final String? selectedCatId;
  final String? selectedDeptId;
  final List<ServiceCategory> categories;
  final List<Department> departments;
  final bool isEditing;
  final bool canManageServices;
  final ValueChanged<String?> onCatChanged;
  final ValueChanged<String?> onDeptChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final fields = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SetupFormHeader(
          icon: Icons.medical_services,
          title: 'Add New Service',
          subtitle: '_',
        ),
        const SizedBox(height: 12),
        SetupTextField(label: 'Service Code', controller: codeCtrl),
        const SizedBox(height: 24),
        SetupTextField(label: 'Service Name', controller: nameCtrl),
        const SizedBox(height: 16),
        SetupTextField(label: 'Description', controller: descCtrl, maxLines: 2),
        const SizedBox(height: 16),
        SetupTextField(label: 'Cost (₦)', controller: costCtrl, isNumber: true),
        const SizedBox(height: 16),
        SetupDropdown(
          label: 'Category',
          value: selectedCatId,
          items: categories.map((c) => c.id).toList(),
          itemLabels: categories.map((c) => c.name).toList(),
          onChanged: onCatChanged,
        ),
        const SizedBox(height: 16),
        SetupDropdown(
          label: 'Department',
          value: selectedDeptId,
          items: departments.map((d) => d.id).toList(),
          itemLabels: departments.map((d) => d.name).toList(),
          onChanged: onDeptChanged,
        ),
      ],
    );

    final actions = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isEditing) ...[
          OutlinedButton(onPressed: onCancel, child: const Text('Cancel Edit')),
          const SizedBox(height: 8),
        ],
        if (!canManageServices)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              isEditing
                  ? 'Updates require billing head, accounting head, or super admin.'
                  : 'Adding services requires billing head, accounting head, or super admin.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        SetupSubmitButton(
          label: isEditing ? 'Update Service' : 'Add Service',
          onPressed: !canManageServices ? null : onSave,
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Short panels used to clip the submit button. Keep it pinned and
        // let the fields scroll when the panel height is bounded.
        if (constraints.maxHeight.isFinite) {
          return SizedBox(
            height: constraints.maxHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: SingleChildScrollView(child: fields)),
                const SizedBox(height: 16),
                actions,
              ],
            ),
          );
        }
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [fields, const SizedBox(height: 24), actions],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TABLE WIDGETS  (bidirectional scrolling, fixed-width cells)
// ─────────────────────────────────────────────────────────────────────────────

class _DepartmentTable extends StatefulWidget {
  const _DepartmentTable({
    required this.rows,
    required this.staffList,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Department> rows;
  final List<Staff> staffList;
  final ValueChanged<Department> onEdit;
  final ValueChanged<Department> onDelete;

  @override
  State<_DepartmentTable> createState() => _DepartmentTableState();
}

class _DepartmentTableState extends State<_DepartmentTable> {
  final _scrollCtrl = ScrollController();

  static const _cols = [
    SetupColumn(label: 'DEPARTMENT NAME', width: 200),
    SetupColumn(label: 'HEAD OF DEPT', width: 200),
    SetupColumn(label: 'DATE ADDED', width: 150),
    SetupColumn(label: 'INITIATOR', width: 150),
  ];

  String _headName(String? headId) {
    if (headId == null) return '—';
    try {
      return widget.staffList.firstWhere((s) => s.id == headId).fullName;
    } catch (_) {
      return headId;
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final totalW = _cols.fold(0.0, (s, c) => s + c.width) + 40;
    if (MediaQuery.sizeOf(context).width < 768) {
      return _narrowSetupList(
        emptyLabel: 'No departments yet.',
        itemCount: widget.rows.length,
        cardBuilder: (index) {
          final item = widget.rows[index];
          return _narrowSetupCard(
            title: item.name,
            lines: [
              'Head: ${_headName(item.description)}',
              if (item.createdAt != null)
                _fmtDate(item.createdAt!.toIso8601String()),
              if ((item.createdByName ?? '').isNotEmpty)
                'Added by ${item.createdByName}',
            ],
            onEdit: () => widget.onEdit(item),
            onDelete: () => widget.onDelete(item),
          );
        },
      );
    }

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalW,
            child: SetupTableHeader(columns: _cols),
          ),
        ),
        Expanded(
          child: Scrollbar(
            controller: _scrollCtrl,
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: totalW,
                  child: Column(
                    children: widget.rows
                        .map(
                          (item) => Column(
                            children: [
                              SetupRowGesture(
                                onEdit: () => widget.onEdit(item),
                                onDelete: () => widget.onDelete(item),
                                child: SetupTableRow(
                                  cells: [
                                    _cell(
                                      item.name,
                                      200,
                                      cs.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    _cell(
                                      _headName(item.description),
                                      200,
                                      cs.onSurface.withValues(alpha: 0.8),
                                    ),
                                    _cell(
                                      item.createdByName ?? '',
                                      150,
                                      cs.onSurface.withValues(alpha: 0.6),
                                      fontSize: 12,
                                    ),
                                    _cell(
                                      item.createdAt != null
                                          ? _fmtDate(
                                              item.createdAt!.toIso8601String(),
                                            )
                                          : '',
                                      150,
                                      cs.onSurface.withValues(alpha: 0.6),
                                      fontSize: 12,
                                    ),
                                  ],
                                ),
                              ),
                              Divider(
                                height: 1,
                                color: cs.outline.withValues(alpha: 0.05),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryTable extends StatefulWidget {
  const _CategoryTable({
    required this.rows,
    required this.onEdit,
    required this.onDelete,
  });

  final List<ServiceCategory> rows;
  final ValueChanged<ServiceCategory> onEdit;
  final ValueChanged<ServiceCategory> onDelete;

  @override
  State<_CategoryTable> createState() => _CategoryTableState();
}

class _CategoryTableState extends State<_CategoryTable> {
  final _scrollCtrl = ScrollController();

  static const _cols = [
    SetupColumn(label: 'CATEGORY NAME', width: 180),
    SetupColumn(label: 'DESCRIPTION', width: 240),
    SetupColumn(label: 'DATE ADDED', width: 140),
    SetupColumn(label: 'INITIATOR', width: 140),
  ];

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final totalW = _cols.fold(0.0, (s, c) => s + c.width) + 40;
    if (MediaQuery.sizeOf(context).width < 768) {
      return _narrowSetupList(
        emptyLabel: 'No categories yet.',
        itemCount: widget.rows.length,
        cardBuilder: (index) {
          final item = widget.rows[index];
          final description = (item.description ?? '').trim();
          return _narrowSetupCard(
            title: item.name,
            lines: [if (description.isNotEmpty) description],
            onEdit: () => widget.onEdit(item),
            onDelete: () => widget.onDelete(item),
          );
        },
      );
    }

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalW,
            child: SetupTableHeader(columns: _cols),
          ),
        ),
        Expanded(
          child: Scrollbar(
            controller: _scrollCtrl,
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: totalW,
                  child: Column(
                    children: widget.rows
                        .map(
                          (item) => Column(
                            children: [
                              SetupRowGesture(
                                onEdit: () => widget.onEdit(item),
                                onDelete: () => widget.onDelete(item),
                                child: SetupTableRow(
                                  cells: [
                                    _cell(
                                      item.name,
                                      180,
                                      cs.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    _cell(
                                      item.description ?? '—',
                                      240,
                                      cs.onSurface.withValues(alpha: 0.7),
                                      fontSize: 12,
                                      maxLines: 2,
                                    ),
                                    _cell(
                                      '—',
                                      140,
                                      cs.onSurface.withValues(alpha: 0.6),
                                      fontSize: 12,
                                    ),
                                    _cell(
                                      '—',
                                      140,
                                      cs.onSurface.withValues(alpha: 0.6),
                                      fontSize: 12,
                                    ),
                                  ],
                                ),
                              ),
                              Divider(
                                height: 1,
                                color: cs.outline.withValues(alpha: 0.05),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ServiceTable extends StatefulWidget {
  const _ServiceTable({
    required this.serviceApi,
    required this.categories,
    required this.departments,
    required this.canManageServices,
    required this.refreshSignal,
    required this.onEdit,
    required this.onDelete,
  });

  final ServiceService serviceApi;
  final List<ServiceCategory> categories;
  final List<Department> departments;
  final bool canManageServices;
  final ValueNotifier<int> refreshSignal;
  final ValueChanged<ServiceModel> onEdit;
  final ValueChanged<ServiceModel> onDelete;

  @override
  State<_ServiceTable> createState() => _ServiceTableState();
}

class _ServiceTableState extends State<_ServiceTable> {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  List<ServiceModel> _rows = [];
  int _total = 0;
  int _pageIndex = 0;
  int _pageSize = 20;
  bool _fetching = false;
  String? _error;

  static const _pageSizes = [20, 50, 100];

  static const _cols = [
    SetupColumn(label: 'SERVICE NAME', width: 200),
    SetupColumn(label: 'COST', width: 130),
    SetupColumn(label: 'CATEGORY', width: 160),
    SetupColumn(label: 'DEPARTMENT', width: 160),
    SetupColumn(label: 'DATE ADDED', width: 140),
    SetupColumn(label: 'INITIATOR', width: 140),
  ];

  int get _pageCount {
    if (_total == 0) return 1;
    return (_total + _pageSize - 1) ~/ _pageSize;
  }

  int get _clampedPageIndex =>
      _pageIndex.clamp(0, _pageCount > 0 ? _pageCount - 1 : 0);

  void _onParentRefresh() {
    _fetchPage(silent: true);
  }

  @override
  void initState() {
    super.initState();
    widget.refreshSignal.addListener(_onParentRefresh);
    _fetchPage(silent: false);
  }

  @override
  void didUpdateWidget(_ServiceTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      oldWidget.refreshSignal.removeListener(_onParentRefresh);
      widget.refreshSignal.addListener(_onParentRefresh);
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    widget.refreshSignal.removeListener(_onParentRefresh);
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchPage({bool silent = false}) async {
    if (!mounted) return;
    setState(() {
      _fetching = true;
      if (!silent) _error = null;
    });
    var page = _clampedPageIndex;
    var skip = page * _pageSize;
    try {
      var r = await widget.serviceApi.findAll(
        skip: skip,
        take: _pageSize,
        search: _searchCtrl.text.trim(),
      );
      if (!mounted) return;
      var rows = r.services;
      var total = r.total;
      var idx = page;
      final maxIdx = total == 0 ? 0 : (total + _pageSize - 1) ~/ _pageSize - 1;
      if (idx > maxIdx) {
        idx = maxIdx;
        r = await widget.serviceApi.findAll(
          skip: idx * _pageSize,
          take: _pageSize,
          search: _searchCtrl.text.trim(),
        );
        if (!mounted) return;
        rows = r.services;
        total = r.total;
      }
      if (rows.isEmpty && total > 0 && idx > 0) {
        idx -= 1;
        r = await widget.serviceApi.findAll(
          skip: idx * _pageSize,
          take: _pageSize,
          search: _searchCtrl.text.trim(),
        );
        if (!mounted) return;
        rows = r.services;
        total = r.total;
      }
      setState(() {
        _rows = rows;
        _total = total;
        _pageIndex = idx;
        _fetching = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _fetching = false;
        _error = e.toString();
      });
      if (!silent && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load services: $e')));
      }
    }
  }

  void _scheduleSearchRefetch() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() => _pageIndex = 0);
      _fetchPage(silent: _rows.isNotEmpty);
    });
  }

  String _catName(ServiceModel s) {
    if (s.categoryName != null && s.categoryName!.isNotEmpty) {
      return s.categoryName!;
    }
    if (s.categoryId == null) return '—';
    try {
      return widget.categories.firstWhere((c) => c.id == s.categoryId).name;
    } catch (_) {
      return s.categoryId!;
    }
  }

  String _deptName(ServiceModel s) {
    if (s.departmentName != null && s.departmentName!.isNotEmpty) {
      return s.departmentName!;
    }
    if (s.departmentId == null) return '—';
    try {
      return widget.departments.firstWhere((d) => d.id == s.departmentId).name;
    } catch (_) {
      return s.departmentId!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final totalW = _cols.fold(0.0, (s, c) => s + c.width) + 40;
    final page = _clampedPageIndex;
    final startItem = _total == 0 ? 0 : page * _pageSize + 1;
    final endItem = (page * _pageSize + _rows.length).clamp(0, _total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_fetching && _rows.isNotEmpty)
          const LinearProgressIndicator(minHeight: 2),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search by service name (server)',
              prefixIcon: const Icon(Icons.search, size: 22),
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchDebounce?.cancel();
                        _searchCtrl.clear();
                        setState(() => _pageIndex = 0);
                        _fetchPage(silent: _rows.isNotEmpty);
                      },
                    ),
              filled: true,
              fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.35),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: cs.outline.withValues(alpha: 0.25),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: cs.outline.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: cs.primary, width: 1.5),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            onChanged: (_) {
              setState(() {});
              _scheduleSearchRefetch();
            },
          ),
        ),
        if (MediaQuery.sizeOf(context).width >= 768)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: totalW,
              child: SetupTableHeader(columns: _cols),
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 768) {
                if (_fetching && _rows.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_error != null && _rows.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cs.error),
                      ),
                    ),
                  );
                }
                return _narrowSetupList(
                  emptyLabel: _searchCtrl.text.trim().isNotEmpty
                      ? 'No services match your search.'
                      : 'No services yet.',
                  itemCount: _rows.length,
                  cardBuilder: (index) {
                    final item = _rows[index];
                    return _narrowSetupCard(
                      title: item.name,
                      lines: [
                        item.cost.toFinancial(isMoney: true),
                        '${_catName(item)} · ${_deptName(item)}',
                        if ((item.description ?? '').trim().isNotEmpty)
                          item.description!.trim(),
                      ],
                      menuEnabled: widget.canManageServices,
                      onEdit: () => widget.onEdit(item),
                      onDelete: () => widget.onDelete(item),
                    );
                  },
                );
              }
              return _fetching && _rows.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null && _rows.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: cs.error),
                        ),
                      ),
                    )
                  : Scrollbar(
                      controller: _scrollCtrl,
                      child: SingleChildScrollView(
                        controller: _scrollCtrl,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: totalW,
                            child: Column(
                              children: _rows.isEmpty
                                  ? [
                                      Padding(
                                        padding: const EdgeInsets.all(32),
                                        child: Text(
                                          _searchCtrl.text.trim().isNotEmpty
                                              ? 'No services match your search.'
                                              : 'No services yet.',
                                          style: TextStyle(
                                            color: cs.onSurface.withValues(
                                              alpha: 0.6,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ]
                                  : _rows
                                        .map(
                                          (item) => Column(
                                            children: [
                                              SetupRowGesture(
                                                menuEnabled:
                                                    widget.canManageServices,
                                                onEdit: () =>
                                                    widget.onEdit(item),
                                                onDelete: () =>
                                                    widget.onDelete(item),
                                                child: SetupTableRow(
                                                  cells: [
                                                    SizedBox(
                                                      width: 200,
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            item.name,
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 13,
                                                              color:
                                                                  cs.onSurface,
                                                            ),
                                                          ),
                                                          Text(
                                                            item.description ??
                                                                '',
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              color: cs
                                                                  .onSurface
                                                                  .withValues(
                                                                    alpha: 0.5,
                                                                  ),
                                                            ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 130,
                                                      child: Text(
                                                        item.cost.toFinancial(
                                                          isMoney: true,
                                                        ),
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Colors.green[700],
                                                        ),
                                                      ),
                                                    ),
                                                    _cell(
                                                      _catName(item),
                                                      160,
                                                      cs.onSurface.withValues(
                                                        alpha: 0.8,
                                                      ),
                                                      fontSize: 12,
                                                    ),
                                                    _cell(
                                                      _deptName(item),
                                                      160,
                                                      cs.onSurface.withValues(
                                                        alpha: 0.8,
                                                      ),
                                                      fontSize: 12,
                                                    ),
                                                    _cell(
                                                      _fmtDate(
                                                        item.createdAtIso,
                                                      ),
                                                      140,
                                                      cs.onSurface.withValues(
                                                        alpha: 0.6,
                                                      ),
                                                      fontSize: 11,
                                                    ),
                                                    _cell(
                                                      item.createdByName ?? '',
                                                      140,
                                                      cs.onSurface.withValues(
                                                        alpha: 0.6,
                                                      ),
                                                      fontSize: 11,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Divider(
                                                height: 1,
                                                color: cs.outline.withValues(
                                                  alpha: 0.05,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                        .toList(),
                            ),
                          ),
                        ),
                      ),
                    );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Text(
                'Rows per page',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _pageSize,
                items: _pageSizes
                    .map(
                      (n) => DropdownMenuItem(
                        value: n,
                        child: Text('$n', style: const TextStyle(fontSize: 13)),
                      ),
                    )
                    .toList(),
                onChanged: _fetching
                    ? null
                    : (v) async {
                        if (v == null) return;
                        setState(() {
                          _pageSize = v;
                          _pageIndex = 0;
                        });
                        await _fetchPage(silent: _rows.isNotEmpty);
                      },
              ),
              const Spacer(),
              Expanded(
                child: Text(
                  _total == 0
                      ? 'No services'
                      : '$startItem–$endItem of $_total',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.75),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Previous page',
                visualDensity: VisualDensity.compact,
                onPressed: !_fetching && page > 0
                    ? () async {
                        setState(() => _pageIndex = page - 1);
                        await _fetchPage(silent: true);
                      }
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                tooltip: 'Next page',
                visualDensity: VisualDensity.compact,
                onPressed: !_fetching && page < _pageCount - 1
                    ? () async {
                        setState(() => _pageIndex = page + 1);
                        await _fetchPage(silent: true);
                      }
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── shared cell helper ────────────────────────────────────────────────────────

Widget _cell(
  String text,
  double width,
  Color color, {
  double fontSize = 13,
  FontWeight fontWeight = FontWeight.normal,
  int maxLines = 1,
}) => SizedBox(
  width: width,
  child: Text(
    text,
    style: TextStyle(fontSize: fontSize, color: color, fontWeight: fontWeight),
    maxLines: maxLines,
    overflow: TextOverflow.ellipsis,
  ),
);

Widget _narrowSetupList({
  required String emptyLabel,
  required int itemCount,
  required Widget Function(int index) cardBuilder,
}) {
  if (itemCount == 0) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(emptyLabel, textAlign: TextAlign.center),
      ),
    );
  }
  return ListView.separated(
    padding: const EdgeInsets.all(12),
    itemCount: itemCount,
    separatorBuilder: (_, _) => const SizedBox(height: 8),
    itemBuilder: (context, index) => cardBuilder(index),
  );
}

Widget _narrowSetupCard({
  required String title,
  required List<String> lines,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
  bool menuEnabled = true,
}) {
  return Card(
    margin: EdgeInsets.zero,
    child: SetupRowGesture(
      menuEnabled: menuEnabled,
      onEdit: onEdit,
      onDelete: onDelete,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            for (final line in lines)
              if (line.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    line,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
          ],
        ),
      ),
    ),
  );
}
