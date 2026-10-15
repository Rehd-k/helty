import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/lab/models/lab_models.dart';
import 'package:helty/src/lab/providers/lab_providers.dart';
import 'package:helty/src/lab/services/lab_api_service.dart';
import 'package:helty/src/lab/ui/config/lab_config_detail.dart';
import 'package:helty/src/lab/ui/config/lab_config_forms.dart';
import 'package:helty/src/lab/ui/config/lab_config_lookup.dart';
import 'package:helty/src/lab/ui/config/lab_config_shared.dart';
import 'package:helty/src/lab/ui/config/lab_config_tree.dart';
import 'package:helty/src/lab/ui/widgets/lab_clinical_ui.dart';
import 'package:helty/src/widgets/helty_surface.dart';

const _uncategorizedId = '_uncategorized';

@RoutePage()
class LabConfigScreen extends ConsumerStatefulWidget {
  const LabConfigScreen({super.key});

  @override
  ConsumerState<LabConfigScreen> createState() => _LabConfigScreenState();
}

class _LabConfigScreenState extends ConsumerState<LabConfigScreen> {
  final _searchController = TextEditingController();

  LabConfigSection _section = LabConfigSection.catalog;
  String _query = '';
  String? _categoryFilterId;
  bool _activeOnly = false;

  bool _loading = true;
  bool _refreshing = false;
  String? _loadError;
  List<LabCategory> _categories = const [];
  List<LabTest> _tests = const [];
  List<LabAntibiotic> _antibiotics = const [];
  List<LabAstResultOption> _astOptions = const [];

  String? _selectedCategoryId;
  String? _selectedTestId;
  String? _selectedVersionId;
  bool _showDetail = false;
  final _expandedIds = <String>{};
  bool _appliedInitialExpand = false;

  final _versionsByTest = <String, List<LabTestVersion>>{};
  final _fieldsByVersion = <String, List<LabTestField>>{};
  bool _loadingVersions = false;
  bool _loadingFields = false;
  String? _detailError;
  int _detailToken = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final next = _searchController.text.trim();
      if (next == _query) return;
      setState(() => _query = next);
    });
    _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  LabApiService get _api => ref.read(labApiServiceProvider);

  Future<List<T>> _fetchAll<T>({
    required Future<({List<T> data, int total})> Function(int skip, int take)
    page,
  }) async {
    const take = 500;
    final first = await page(0, take);
    final all = [...first.data];
    while (all.length < first.total) {
      final next = await page(all.length, take);
      if (next.data.isEmpty) break;
      all.addAll(next.data);
      if (next.data.length < take) break;
    }
    return all;
  }

  Future<void> _reload() async {
    final showFullLoader = _categories.isEmpty && _tests.isEmpty;
    setState(() {
      _loading = showFullLoader;
      _refreshing = !showFullLoader;
      _loadError = null;
    });
    try {
      final api = _api;
      final categoriesFuture = _fetchAll<LabCategory>(
        page: (skip, take) async {
          final response = await api.getCategories(skip: skip, take: take);
          return (data: response.data, total: response.total);
        },
      );
      final testsFuture = _fetchAll<LabTest>(
        page: (skip, take) async {
          final response = await api.getTests(skip: skip, take: take);
          return (data: response.data, total: response.total);
        },
      );
      final antibioticsFuture = _fetchAll<LabAntibiotic>(
        page: (skip, take) async {
          final response = await api.getAntibiotics(skip: skip, take: take);
          return (data: response.data, total: response.total);
        },
      );
      final astFuture = _fetchAll<LabAstResultOption>(
        page: (skip, take) async {
          final response = await api.getAstResultOptions(
            skip: skip,
            take: take,
          );
          return (data: response.data, total: response.total);
        },
      );
      final categories = await categoriesFuture;
      final tests = await testsFuture;
      final antibiotics = await antibioticsFuture;
      final astOptions = await astFuture;
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _tests = tests;
        _antibiotics = antibiotics;
        _astOptions = astOptions;
        _loading = false;
        _refreshing = false;
        _pruneSelection();
        if (!_appliedInitialExpand) {
          _appliedInitialExpand = true;
          if (categories.length <= 6) {
            _expandedIds
              ..addAll(categories.map((category) => category.id))
              ..add(_uncategorizedId);
          }
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
        _loadError = labConfigErrorMessage(error);
      });
    }
  }

  void _invalidateShared() {
    ref.invalidate(labCategoriesFutureProvider);
    ref.invalidate(labTestsFutureProvider);
    ref.invalidate(labAntibioticsFutureProvider);
    ref.invalidate(labAstResultOptionsFutureProvider);
  }

  void _snack(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(labConfigErrorMessage(error))));
  }

  void _pruneSelection() {
    if (_selectedTest != null) {
      _selectedCategoryId = _selectedTest!.category?.id ?? _selectedCategoryId;
    } else if (_selectedTestId != null) {
      _selectedTestId = null;
      _selectedVersionId = null;
      _showDetail = false;
    }
    if (_selectedCategoryId != null &&
        _selectedCategoryId != _uncategorizedId &&
        !_categories.any((category) => category.id == _selectedCategoryId)) {
      _selectedCategoryId = _selectedTest?.category?.id;
    }
  }

  LabTest? get _selectedTest {
    final id = _selectedTestId;
    if (id == null) return null;
    for (final test in _tests) {
      if (test.id == id) return test;
    }
    return null;
  }

  LabCategory? _categoryById(String? id) {
    if (id == null || id == _uncategorizedId) return null;
    for (final category in _categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  List<LabConfigGroup> get _visibleGroups {
    final query = _query.trim().toLowerCase();
    final buckets = <String, List<LabTest>>{};
    for (final test in _tests) {
      final id = test.category?.id;
      final key = (id == null || id.isEmpty) ? _uncategorizedId : id;
      buckets.putIfAbsent(key, () => []).add(test);
    }

    List<LabTest> visibleTests(List<LabTest> tests, {required bool nameMatch}) {
      final scoped = _activeOnly
          ? tests.where((test) => test.isActive).toList()
          : tests;
      if (query.isEmpty || nameMatch) {
        scoped.sort((a, b) => compareLabText(a.name, b.name));
        return scoped;
      }
      final matched = scoped.where((test) {
        return test.name.toLowerCase().contains(query) ||
            test.sampleType.toLowerCase().contains(query) ||
            (test.description ?? '').toLowerCase().contains(query);
      }).toList()..sort((a, b) => compareLabText(a.name, b.name));
      return matched;
    }

    final groups = <LabConfigGroup>[];
    final categories = [..._categories]
      ..sort((a, b) => compareLabText(a.name, b.name));
    for (final category in categories) {
      if (_categoryFilterId != null && category.id != _categoryFilterId) {
        continue;
      }
      final all = buckets[category.id] ?? const <LabTest>[];
      final nameMatch =
          query.isEmpty ||
          category.name.toLowerCase().contains(query) ||
          (category.description ?? '').toLowerCase().contains(query);
      final tests = visibleTests(all, nameMatch: nameMatch);
      final scopedCount = _activeOnly
          ? all.where((test) => test.isActive).length
          : all.length;
      if (query.isNotEmpty && !nameMatch && tests.isEmpty) continue;
      groups.add(
        LabConfigGroup(
          id: category.id,
          name: category.name,
          description: category.description,
          category: category,
          tests: tests,
          totalTests: scopedCount,
        ),
      );
    }

    if (_categoryFilterId == null) {
      final known = {for (final category in _categories) category.id};
      for (final entry in buckets.entries) {
        if (known.contains(entry.key)) continue;
        final name = entry.key == _uncategorizedId
            ? 'Uncategorized'
            : (entry.value.first.category?.name ?? 'Unknown category');
        final nameMatch = query.isEmpty || name.toLowerCase().contains(query);
        final tests = visibleTests(entry.value, nameMatch: nameMatch);
        if (query.isNotEmpty && !nameMatch && tests.isEmpty) continue;
        groups.add(
          LabConfigGroup(
            id: entry.key,
            name: name,
            tests: tests,
            totalTests: _activeOnly
                ? entry.value.where((test) => test.isActive).length
                : entry.value.length,
          ),
        );
      }
    }
    return groups;
  }

  Set<String> get _effectiveExpanded {
    if (_query.trim().isEmpty && _categoryFilterId == null) return _expandedIds;
    return {for (final group in _visibleGroups) group.id};
  }

  String get _catalogFooter {
    final groups = _visibleGroups;
    final shown = groups.fold<int>(
      0,
      (count, group) => count + group.tests.length,
    );
    final filtering =
        _query.trim().isNotEmpty || _categoryFilterId != null || _activeOnly;
    if (filtering) {
      return '${groups.length} categories · $shown tests match';
    }
    return '${_categories.length} categories · ${_tests.length} tests';
  }

  int _activeCount<T>(List<T> items, bool Function(T item) active) =>
      items.where(active).length;

  List<LabConfigLookupRow> get _lookupRows {
    final query = _query.trim().toLowerCase();
    if (_section == LabConfigSection.antibiotics) {
      final rows = [..._antibiotics]
        ..sort((a, b) {
          final byPosition = a.position.compareTo(b.position);
          return byPosition != 0 ? byPosition : compareLabText(a.name, b.name);
        });
      return [
        for (final item in rows)
          if ((!_activeOnly || item.isActive) &&
              (query.isEmpty ||
                  item.name.toLowerCase().contains(query) ||
                  (item.code ?? '').toLowerCase().contains(query)))
            LabConfigLookupRow(
              id: item.id,
              title: item.name,
              subtitle: [
                if (item.code != null && item.code!.isNotEmpty) item.code!,
                'Position ${item.position}',
                if (!item.isActive) 'Inactive',
              ].join(' · '),
              active: item.isActive,
            ),
      ];
    }
    final rows = [..._astOptions]
      ..sort((a, b) {
        final byPosition = a.position.compareTo(b.position);
        return byPosition != 0 ? byPosition : compareLabText(a.label, b.label);
      });
    return [
      for (final item in rows)
        if ((!_activeOnly || item.isActive) &&
            (query.isEmpty ||
                item.label.toLowerCase().contains(query) ||
                (item.code ?? '').toLowerCase().contains(query)))
          LabConfigLookupRow(
            id: item.id,
            title: item.label,
            subtitle: [
              if (item.code != null && item.code!.isNotEmpty) item.code!,
              'Position ${item.position}',
              if (!item.isActive) 'Inactive',
            ].join(' · '),
            active: item.isActive,
          ),
    ];
  }

  String get _lookupFooter {
    final shown = _lookupRows.length;
    final total = _section == LabConfigSection.antibiotics
        ? _antibiotics.length
        : _astOptions.length;
    final noun = _section == LabConfigSection.antibiotics
        ? 'antibiotics'
        : 'AST options';
    if (shown == total) return '$total $noun';
    return '$shown of $total $noun';
  }

  bool get _expansionLocked =>
      _query.trim().isNotEmpty || _categoryFilterId != null;

  void _toggleGroup(String id) {
    if (_expansionLocked) return;
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  void _selectCategory(LabConfigGroup group) {
    if (group.category == null) {
      _toggleGroup(group.id);
      return;
    }
    setState(() {
      _selectedCategoryId = group.id;
      _selectedTestId = null;
      _selectedVersionId = null;
      _showDetail = false;
      _expandedIds.add(group.id);
    });
  }

  void _selectTest(LabTest test, String groupId) {
    setState(() {
      _selectedTestId = test.id;
      _selectedCategoryId = test.category?.id ?? groupId;
      _selectedVersionId = null;
      _showDetail = true;
      _expandedIds.add(groupId);
      _detailError = null;
    });
    _loadVersions(test.id);
  }

  Future<void> _loadVersions(String testId, {bool force = false}) async {
    if (!force && _versionsByTest.containsKey(testId)) {
      _selectDefaultVersion(testId);
      return;
    }
    final token = ++_detailToken;
    setState(() {
      _loadingVersions = true;
      _detailError = null;
    });
    try {
      final versions = await _api.getTestVersions(testId);
      if (!mounted || token != _detailToken) return;
      versions.sort((a, b) => b.versionNumber.compareTo(a.versionNumber));
      setState(() {
        _versionsByTest[testId] = versions;
        _loadingVersions = false;
      });
      _selectDefaultVersion(testId);
    } catch (error) {
      if (!mounted || token != _detailToken) return;
      setState(() {
        _loadingVersions = false;
        _loadingFields = false;
        _detailError = labConfigErrorMessage(error);
      });
    }
  }

  void _selectDefaultVersion(String testId) {
    if (_selectedTestId != testId) return;
    final versions = _versionsByTest[testId];
    if (versions == null || versions.isEmpty) {
      setState(() {
        _selectedVersionId = null;
        _loadingFields = false;
      });
      return;
    }
    final current = versions
        .where((version) => version.id == _selectedVersionId)
        .firstOrNull;
    final next =
        current ??
        versions.where((version) => version.isActive).firstOrNull ??
        versions.first;
    setState(() => _selectedVersionId = next.id);
    _loadFields(next.id);
  }

  Future<void> _loadFields(String versionId, {bool force = false}) async {
    if (!force && _fieldsByVersion.containsKey(versionId)) {
      if (_loadingFields && mounted) setState(() => _loadingFields = false);
      return;
    }
    final token = _detailToken;
    setState(() {
      _loadingFields = true;
      _detailError = null;
    });
    try {
      final fields = await _api.getTestFields(versionId);
      if (!mounted ||
          token != _detailToken ||
          _selectedVersionId != versionId) {
        return;
      }
      setState(() {
        _fieldsByVersion[versionId] = fields;
        _loadingFields = false;
      });
    } catch (error) {
      if (!mounted || token != _detailToken) return;
      setState(() {
        _loadingFields = false;
        _detailError = labConfigErrorMessage(error);
      });
    }
  }

  Future<void> _afterCatalogChange() async {
    _invalidateShared();
    await _reload();
  }

  Future<void> _addCategory() async {
    final created = await showLabCategoryForm(context: context, api: _api);
    if (created == null) return;
    await _afterCatalogChange();
    if (!mounted) return;
    setState(() {
      _section = LabConfigSection.catalog;
      _selectedCategoryId = created.id;
      _selectedTestId = null;
      _expandedIds.add(created.id);
    });
  }

  Future<void> _editCategory(LabCategory category) async {
    final saved = await showLabCategoryForm(
      context: context,
      api: _api,
      existing: category,
    );
    if (saved == null) return;
    await _afterCatalogChange();
  }

  Future<void> _deleteCategory(LabCategory category) async {
    final confirmed = await confirmLabConfigDelete(
      context: context,
      title: 'Delete category',
      message:
          'Delete "${category.name}"? Tests in this category may be affected.',
    );
    if (!confirmed || !mounted) return;
    try {
      await _api.deleteCategory(category.id);
      if (_selectedCategoryId == category.id) {
        setState(() {
          _selectedCategoryId = null;
          _selectedTestId = null;
          _showDetail = false;
        });
      }
      await _afterCatalogChange();
    } catch (error) {
      _snack(error);
    }
  }

  Future<void> _addTest(LabCategory? category) async {
    if (_categories.isEmpty) {
      _snack('Add a category before adding a test.');
      return;
    }
    final created = await showLabTestForm(
      context: context,
      api: _api,
      categories: _categories,
      initialCategoryId: category?.id ?? _selectedCategoryId,
    );
    if (created == null) return;
    await _afterCatalogChange();
    if (!mounted) return;
    final groupId = created.category?.id;
    if (groupId != null) _expandedIds.add(groupId);
    _selectTest(
      _tests.where((test) => test.id == created.id).firstOrNull ?? created,
      groupId ?? _uncategorizedId,
    );
  }

  Future<void> _editTest(LabTest test) async {
    final saved = await showLabTestForm(
      context: context,
      api: _api,
      categories: _categories,
      existing: test,
    );
    if (saved == null) return;
    await _afterCatalogChange();
  }

  Future<void> _deleteTest(LabTest test) async {
    final confirmed = await confirmLabConfigDelete(
      context: context,
      title: 'Delete test',
      message:
          'Delete "${test.name}"? Its versions, result fields, and related order lines will be removed.',
    );
    if (!confirmed || !mounted) return;
    try {
      await _api.deleteTest(test.id);
      _versionsByTest.remove(test.id);
      if (_selectedTestId == test.id) {
        setState(() {
          _selectedTestId = null;
          _selectedVersionId = null;
          _showDetail = false;
        });
      }
      await _afterCatalogChange();
    } catch (error) {
      _snack(error);
    }
  }

  Future<void> _createVersion() async {
    final test = _selectedTest;
    if (test == null) return;
    final versions = _versionsByTest[test.id] ?? const <LabTestVersion>[];
    final source =
        versions.where((version) => version.isActive).firstOrNull ??
        versions.firstOrNull;
    var copyFields = false;
    List<LabTestField> sourceFields = const [];
    try {
      if (source != null) {
        sourceFields =
            _fieldsByVersion[source.id] ?? await _api.getTestFields(source.id);
        if (!mounted) return;
        if (sourceFields.isNotEmpty) {
          final choice = await showLabVersionCreateChoice(
            context: context,
            testName: test.name,
            fromVersion: source.versionNumber,
            fieldCount: sourceFields.length,
          );
          if (choice == null || !mounted) return;
          copyFields = choice == LabVersionCreateChoice.copyFields;
        }
      }
      final created = await _api.createTestVersion(test.id, setActive: true);
      if (copyFields) {
        for (final field in sourceFields) {
          await _api.createTestField(
            testVersionId: created.id,
            label: field.label,
            fieldType: field.fieldType.name.toUpperCase(),
            unit: field.unit,
            referenceRange: field.referenceRange,
            required: field.required,
            position: field.position,
            optionsJson: field.optionsJson,
          );
        }
      }
      if (!mounted) return;
      _versionsByTest.remove(test.id);
      _fieldsByVersion.remove(created.id);
      setState(() => _selectedVersionId = created.id);
      await _loadVersions(test.id, force: true);
      await _loadFields(created.id, force: true);
      if (!mounted) return;
      _invalidateShared();
      final copied = copyFields ? sourceFields.length : 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            copied == 0
                ? 'Version ${created.versionNumber} is active. Add result fields.'
                : 'Version ${created.versionNumber} is active, with $copied fields copied.',
          ),
        ),
      );
    } catch (error) {
      _snack(error);
    }
  }

  Future<void> _addField() async {
    final versionId = _selectedVersionId;
    if (versionId == null) return;
    final fields = _fieldsByVersion[versionId] ?? const <LabTestField>[];
    final saved = await showLabFieldForm(
      context: context,
      api: _api,
      versionId: versionId,
      nextPosition: fields.length,
    );
    if (!saved) return;
    _invalidateShared();
    _fieldsByVersion.remove(versionId);
    _versionsByTest.remove(_selectedTestId);
    await _loadFields(versionId, force: true);
    final testId = _selectedTestId;
    if (testId != null) await _loadVersions(testId, force: true);
  }

  Future<void> _editField(LabTestField field) async {
    final versionId = _selectedVersionId;
    if (versionId == null) return;
    final saved = await showLabFieldForm(
      context: context,
      api: _api,
      versionId: versionId,
      nextPosition: field.position,
      existing: field,
    );
    if (!saved) return;
    _invalidateShared();
    await _loadFields(versionId, force: true);
  }

  Future<void> _deleteField(LabTestField field) async {
    final versionId = _selectedVersionId;
    if (versionId == null) return;
    final confirmed = await confirmLabConfigDelete(
      context: context,
      title: 'Delete field',
      message: 'Remove "${field.label}" from this version?',
    );
    if (!confirmed || !mounted) return;
    try {
      await _api.deleteTestField(field.id);
      _invalidateShared();
      await _loadFields(versionId, force: true);
      final testId = _selectedTestId;
      if (testId != null) {
        _versionsByTest.remove(testId);
        await _loadVersions(testId, force: true);
      }
    } catch (error) {
      _snack(error);
    }
  }

  Future<void> _moveField(LabTestField field, int delta) async {
    final versionId = _selectedVersionId;
    if (versionId == null) return;
    final fields = [...?_fieldsByVersion[versionId]]
      ..sort((a, b) {
        final byPosition = a.position.compareTo(b.position);
        if (byPosition != 0) return byPosition;
        return compareLabText(a.label, b.label);
      });
    final index = fields.indexWhere((item) => item.id == field.id);
    final target = index + delta;
    if (index < 0 || target < 0 || target >= fields.length) return;
    final reordered = [...fields];
    final moved = reordered.removeAt(index);
    reordered.insert(target, moved);
    try {
      for (var i = 0; i < reordered.length; i++) {
        if (reordered[i].position != i) {
          await _api.updateTestField(reordered[i].id, position: i);
        }
      }
      _invalidateShared();
      await _loadFields(versionId, force: true);
    } catch (error) {
      _snack(error);
    }
  }

  Future<void> _addAntibiotic() async {
    final next = _antibiotics.isEmpty
        ? 0
        : _antibiotics
                  .map((item) => item.position)
                  .reduce((a, b) => a > b ? a : b) +
              1;
    final created = await showLabAntibioticForm(
      context: context,
      api: _api,
      nextPosition: next,
    );
    if (created == null) return;
    await _afterCatalogChange();
  }

  Future<void> _editAntibiotic(String id) async {
    final existing = _antibiotics.where((item) => item.id == id).firstOrNull;
    if (existing == null) return;
    final saved = await showLabAntibioticForm(
      context: context,
      api: _api,
      existing: existing,
    );
    if (saved == null) return;
    await _afterCatalogChange();
  }

  Future<void> _deleteAntibiotic(String id) async {
    final existing = _antibiotics.where((item) => item.id == id).firstOrNull;
    if (existing == null) return;
    final confirmed = await confirmLabConfigDelete(
      context: context,
      title: 'Delete antibiotic',
      message:
          'Delete "${existing.name}"? If it is used on AST reports, deactivate it instead.',
    );
    if (!confirmed || !mounted) return;
    try {
      await _api.deleteAntibiotic(id);
      await _afterCatalogChange();
    } catch (error) {
      _snack(error);
    }
  }

  Future<void> _addAstOption() async {
    final next = _astOptions.isEmpty
        ? 0
        : _astOptions
                  .map((item) => item.position)
                  .reduce((a, b) => a > b ? a : b) +
              1;
    final created = await showLabAstOptionForm(
      context: context,
      api: _api,
      nextPosition: next,
    );
    if (created == null) return;
    await _afterCatalogChange();
  }

  Future<void> _editAstOption(String id) async {
    final existing = _astOptions.where((item) => item.id == id).firstOrNull;
    if (existing == null) return;
    final saved = await showLabAstOptionForm(
      context: context,
      api: _api,
      existing: existing,
    );
    if (saved == null) return;
    await _afterCatalogChange();
  }

  Future<void> _deleteAstOption(String id) async {
    final existing = _astOptions.where((item) => item.id == id).firstOrNull;
    if (existing == null) return;
    final confirmed = await confirmLabConfigDelete(
      context: context,
      title: 'Delete AST option',
      message:
          'Delete "${existing.label}"? If it is used on AST reports, deactivate it instead.',
    );
    if (!confirmed || !mounted) return;
    try {
      await _api.deleteAstResultOption(id);
      await _afterCatalogChange();
    } catch (error) {
      _snack(error);
    }
  }

  void _openAddMenu() {
    switch (_section) {
      case LabConfigSection.catalog:
        return;
      case LabConfigSection.antibiotics:
        _addAntibiotic();
      case LabConfigSection.ast:
        _addAstOption();
    }
  }

  void _openFilters(bool showCategoryFilter) {
    var activeOnly = _activeOnly;
    var categoryId = _categoryFilterId;
    showLabFilterMenu(
      context,
      StatefulBuilder(
        builder: (context, setLocal) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showCategoryFilter &&
                  _section == LabConfigSection.catalog) ...[
                _categoryDropdown(
                  value: categoryId,
                  onChanged: (value) {
                    setLocal(() => categoryId = value);
                    setState(() => _categoryFilterId = value);
                  },
                ),
                const SizedBox(height: 8),
              ],
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active only'),
                value: activeOnly,
                onChanged: (value) {
                  setLocal(() => activeOnly = value);
                  setState(() => _activeOnly = value);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _categoryDropdown({
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    final categories = [..._categories]
      ..sort((a, b) => compareLabText(a.name, b.name));
    return DropdownButtonFormField<String?>(
      key: ValueKey(value),
      initialValue: value,
      isExpanded: true,
      decoration: labConfigFieldDecoration(context, label: 'Category'),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('All categories'),
        ),
        for (final category in categories)
          DropdownMenuItem<String?>(
            value: category.id,
            child: Text(category.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) {
          final width = bp.maxWidth > 0
              ? bp.maxWidth
              : MediaQuery.sizeOf(context).width;
          final compact = width < LabClinicalUi.cardBreakpoint;
          final split = width >= LabClinicalUi.sidebarBreakpoint;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(compact),
              const SizedBox(height: 10),
              LabKpiStrip(
                useSnapStrip: width < 520,
                items: [
                  LabKpiItem(
                    label: 'Categories',
                    value: _loading ? '—' : '${_categories.length}',
                    caption: 'Groups of tests',
                    icon: Icons.folder_rounded,
                    accent: LabClinicalUi.iconBlue,
                  ),
                  LabKpiItem(
                    label: 'Tests',
                    value: _loading ? '—' : '${_tests.length}',
                    caption: _loading
                        ? '—'
                        : '${_activeCount(_tests, (test) => test.isActive)} active',
                    icon: Icons.science_rounded,
                    accent: LabClinicalUi.iconTeal,
                  ),
                  LabKpiItem(
                    label: 'Antibiotics',
                    value: _loading ? '—' : '${_antibiotics.length}',
                    caption: _loading
                        ? '—'
                        : '${_activeCount(_antibiotics, (item) => item.isActive)} active',
                    icon: Icons.medication_rounded,
                    accent: LabClinicalUi.iconPink,
                  ),
                  LabKpiItem(
                    label: 'AST options',
                    value: _loading ? '—' : '${_astOptions.length}',
                    caption: _loading
                        ? '—'
                        : '${_activeCount(_astOptions, (item) => item.isActive)} active',
                    icon: Icons.grid_view_rounded,
                    accent: LabClinicalUi.iconPurple,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _sectionChips(),
              const SizedBox(height: 10),
              _filterRow(compact),
              const SizedBox(height: 10),
              Expanded(
                child: _body(split: split, useCards: compact),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _header(bool compact) {
    final header = LabPageHeader(
      title: 'Lab configuration',
      subtitle: 'See what sits under each category, test, and version',
      icon: Icons.account_tree_outlined,
      iconColor: LabClinicalUi.iconAmber,
      compact: compact,
    );
    if (!context.router.canPop()) return header;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: () => context.router.maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        Expanded(child: header),
      ],
    );
  }

  Widget _sectionChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final section in LabConfigSection.values)
          ChoiceChip(
            label: Text(section.label),
            selected: _section == section,
            visualDensity: VisualDensity.compact,
            onSelected: (_) => setState(() => _section = section),
          ),
      ],
    );
  }

  Widget _filterRow(bool compact) {
    final showCategory = !compact && _section == LabConfigSection.catalog;
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 12),
            decoration: labConfigFieldDecoration(
              context,
              label: 'Search',
              hint: _section.searchHint,
              icon: Icons.search,
              iconColor: LabClinicalUi.iconIndigo,
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.close, size: 18),
                    ),
            ),
          ),
        ),
        if (showCategory) ...[
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _categoryDropdown(
              value: _categoryFilterId,
              onChanged: (value) => setState(() => _categoryFilterId = value),
            ),
          ),
        ],
        const SizedBox(width: 8),
        LabConfigIconButton(
          tooltip: 'Filters',
          icon: Icons.tune,
          color: LabClinicalUi.iconPurple,
          onPressed: () => _openFilters(compact),
        ),
        const SizedBox(width: 8),
        if (_section == LabConfigSection.catalog)
          PopupMenuButton<String>(
            tooltip: 'Add',
            enabled: !_loading,
            padding: EdgeInsets.zero,
            onSelected: (action) {
              if (action == 'category') {
                _addCategory();
              }
              if (action == 'test') {
                _addTest(_categoryById(_selectedCategoryId));
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'category', child: Text('Add category')),
              PopupMenuItem(value: 'test', child: Text('Add test')),
            ],
            icon: const HeltySolidIcon(
              icon: Icons.add_rounded,
              color: LabClinicalUi.iconTeal,
              size: 32,
              iconSize: 16,
              radius: 8,
            ),
          )
        else
          LabConfigIconButton(
            tooltip: 'Add',
            icon: Icons.add_rounded,
            color: LabClinicalUi.iconTeal,
            onPressed: _loading ? null : _openAddMenu,
          ),
        const SizedBox(width: 8),
        LabConfigIconButton(
          tooltip: 'Refresh',
          icon: Icons.refresh_rounded,
          color: LabClinicalUi.iconBlue,
          onPressed: _refreshing ? null : _reload,
        ),
      ],
    );
  }

  Widget _body({required bool split, required bool useCards}) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_loadError != null && _categories.isEmpty && _tests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _reload, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_section != LabConfigSection.catalog) {
      final isAst = _section == LabConfigSection.ast;
      return LabConfigLookupList(
        title: isAst
            ? 'Susceptibility values used when entering AST results'
            : 'Antibiotics used on the susceptibility panel',
        icon: isAst ? Icons.grid_view_rounded : Icons.medication_rounded,
        accent: isAst ? LabClinicalUi.iconPurple : LabClinicalUi.iconPink,
        rows: _lookupRows,
        footerLabel: _lookupFooter,
        emptyLabel: _query.isEmpty
            ? 'Nothing here yet.'
            : 'Nothing matches this search.',
        onEdit: isAst ? _editAstOption : _editAntibiotic,
        onDelete: isAst ? _deleteAstOption : _deleteAntibiotic,
      );
    }

    final groups = _visibleGroups;
    final tree = LabConfigTree(
      groups: groups,
      expandedIds: _effectiveExpanded,
      selectedCategoryId: _selectedCategoryId,
      selectedTestId: _selectedTestId,
      useCards: useCards,
      footerLabel: _catalogFooter,
      expansionLocked: _expansionLocked,
      onToggle: _toggleGroup,
      onSelectCategory: _selectCategory,
      onSelectTest: _selectTest,
      onEditCategory: _editCategory,
      onDeleteCategory: _deleteCategory,
      onAddTest: _addTest,
      onEditTest: _editTest,
      onDeleteTest: _deleteTest,
    );
    final test = _selectedTest;
    final category = _categoryById(test?.category?.id ?? _selectedCategoryId);
    final group = groups
        .where((item) => item.id == (category?.id ?? _selectedCategoryId))
        .firstOrNull;
    final detail = LabConfigDetail(
      category: category,
      test: test,
      categoryTests: group?.tests ?? const [],
      versions: test == null ? null : _versionsByTest[test.id],
      fields: _selectedVersionId == null
          ? null
          : _fieldsByVersion[_selectedVersionId],
      selectedVersionId: _selectedVersionId,
      loadingVersions: _loadingVersions,
      loadingFields: _loadingFields,
      error: _detailError,
      useCards: useCards,
      showBack: !split,
      actions: LabConfigDetailActions(
        onBack: () => setState(() => _showDetail = false),
        onOpenCategory: () => setState(() {
          _selectedTestId = null;
          _selectedVersionId = null;
          _showDetail = false;
        }),
        onSelectTest: (item) =>
            _selectTest(item, item.category?.id ?? _uncategorizedId),
        onSelectVersion: (version) {
          setState(() => _selectedVersionId = version.id);
          _loadFields(version.id);
        },
        onEditCategory: category == null
            ? () {}
            : () => _editCategory(category),
        onDeleteCategory: category == null
            ? () {}
            : () => _deleteCategory(category),
        onAddTest: () => _addTest(category),
        onEditTest: test == null ? () {} : () => _editTest(test),
        onDeleteTest: test == null ? () {} : () => _deleteTest(test),
        onCreateVersion: _createVersion,
        onRetry: () {
          final testId = _selectedTestId;
          final versionId = _selectedVersionId;
          if (testId != null) _loadVersions(testId, force: true);
          if (versionId != null) _loadFields(versionId, force: true);
        },
        onAddField: _addField,
        onEditField: _editField,
        onDeleteField: _deleteField,
        onMoveField: _moveField,
      ),
    );

    if (split) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 5, child: tree),
          const SizedBox(width: 10),
          Expanded(flex: 6, child: detail),
        ],
      );
    }
    if (_showDetail && test != null) return detail;
    return tree;
  }
}
