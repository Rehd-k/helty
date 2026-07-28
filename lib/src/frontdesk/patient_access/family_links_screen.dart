import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/frontdesk/patient_access/patient_access_models.dart';
import 'package:helty/src/frontdesk/patient_access/patient_access_providers.dart';
import 'package:helty/src/frontdesk/patient_access_permissions.dart';
import 'package:helty/src/paitients/patient_model.dart';
import 'package:helty/src/widgets/empty.widget.dart';
import 'package:helty/src/providers/auth_provider.dart';

@RoutePage()
class FamilyLinksScreen extends ConsumerStatefulWidget {
  const FamilyLinksScreen({super.key});

  @override
  ConsumerState<FamilyLinksScreen> createState() => _FamilyLinksScreenState();
}

class _FamilyLinksScreenState extends ConsumerState<FamilyLinksScreen> {
  final _parentSearchCtrl = TextEditingController();
  final _childSearchCtrl = TextEditingController();
  Timer? _parentDebounce;
  Timer? _childDebounce;

  Patient? _parent;
  List<Patient> _parentResults = [];
  List<Patient> _childResults = [];
  List<FamilyChildRow> _children = [];

  bool _searchingParent = false;
  bool _searchingChild = false;
  bool _loadingChildren = false;
  bool _linking = false;
  String? _parentSearchError;
  String? _childSearchError;
  String? _childrenError;
  String? _unlinkingId;

  @override
  void dispose() {
    _parentDebounce?.cancel();
    _childDebounce?.cancel();
    _parentSearchCtrl.dispose();
    _childSearchCtrl.dispose();
    super.dispose();
  }

  String _errorMessage(Object e, {String? conflictMessage}) {
    if (e is DioException) {
      if (e.response?.statusCode == 409) {
        return conflictMessage ?? 'This family link already exists.';
      }
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        final msg = data['message'];
        if (msg is List) return msg.join(', ');
        return msg.toString();
      }
      if (e.response?.statusCode == 403) {
        return 'You do not have permission to manage family links.';
      }
      if (e.response?.statusCode == 401) {
        return 'Session expired. Please sign in again.';
      }
      return e.message ?? e.toString();
    }
    return e.toString();
  }

  void _onParentSearchChanged(String query) {
    _parentDebounce?.cancel();
    _parentDebounce = Timer(const Duration(milliseconds: 350), () {
      _runParentSearch(query);
    });
  }

  void _onChildSearchChanged(String query) {
    _childDebounce?.cancel();
    _childDebounce = Timer(const Duration(milliseconds: 350), () {
      _runChildSearch(query);
    });
  }

  Future<void> _runParentSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _parentResults = [];
        _parentSearchError = null;
        _searchingParent = false;
      });
      return;
    }
    setState(() {
      _searchingParent = true;
      _parentSearchError = null;
    });
    try {
      final patients = await ref
          .read(patientAccessPatientServiceProvider)
          .searchPatients(q, true);
      if (!mounted) return;
      setState(() {
        _parentResults = patients;
        _searchingParent = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchingParent = false;
        _parentSearchError = _errorMessage(e);
        _parentResults = [];
      });
    }
  }

  Future<void> _runChildSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _childResults = [];
        _childSearchError = null;
        _searchingChild = false;
      });
      return;
    }
    setState(() {
      _searchingChild = true;
      _childSearchError = null;
    });
    try {
      final patients = await ref
          .read(patientAccessPatientServiceProvider)
          .searchPatients(q, true);
      if (!mounted) return;
      setState(() {
        _childResults = patients;
        _searchingChild = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchingChild = false;
        _childSearchError = _errorMessage(e);
        _childResults = [];
      });
    }
  }

  Future<void> _selectParent(Patient patient) async {
    final id = patient.id;
    if (id == null || id.isEmpty) return;
    setState(() {
      _parent = patient;
      _parentResults = [];
      _parentSearchCtrl.clear();
      _children = [];
      _childrenError = null;
      _loadingChildren = true;
      _childResults = [];
      _childSearchCtrl.clear();
    });
    await _loadChildren();
  }

  Future<void> _loadChildren() async {
    final parentId = _parent?.id;
    if (parentId == null || parentId.isEmpty) return;
    setState(() {
      _loadingChildren = true;
      _childrenError = null;
    });
    try {
      final children = await ref
          .read(patientAccessServiceProvider)
          .listChildren(parentId);
      if (!mounted) return;
      setState(() {
        _children = children;
        _loadingChildren = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingChildren = false;
        _childrenError = _errorMessage(e);
      });
    }
  }

  Future<void> _linkChild(Patient child) async {
    final parent = _parent;
    final parentId = parent?.id;
    final childId = child.id;
    if (parentId == null || parentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a parent patient first.')),
      );
      return;
    }
    if (childId == null || childId.isEmpty) return;
    if (childId == parentId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot link a patient to themselves.')),
      );
      return;
    }

    setState(() => _linking = true);
    try {
      await ref
          .read(patientAccessServiceProvider)
          .linkChild(parentId: parentId, childPatientId: childId);
      if (!mounted) return;
      setState(() {
        _linking = false;
        _childResults = [];
        _childSearchCtrl.clear();
      });
      await _loadChildren();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Linked ${child.displayName} as child.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _linking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _errorMessage(
              e,
              conflictMessage: 'This child is already linked to this parent.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _unlinkChild(FamilyChildRow child) async {
    final parentId = _parent?.id;
    if (parentId == null || parentId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unlink child?'),
        content: Text(
          'Remove ${child.displayName} from this parent\'s family list?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _unlinkingId = child.id);
    try {
      await ref
          .read(patientAccessServiceProvider)
          .unlinkChild(parentId: parentId, childId: child.id);
      if (!mounted) return;
      setState(() {
        _children = _children.where((c) => c.id != child.id).toList();
        _unlinkingId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Child unlinked.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _unlinkingId = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(e))));
    }
  }

  void _clearParent() {
    setState(() {
      _parent = null;
      _children = [];
      _childrenError = null;
      _childResults = [];
      _childSearchCtrl.clear();
    });
  }

  Widget _patientSubtitle(Patient p) {
    return Text(
      [
        if (p.patientId.isNotEmpty) p.patientId,
        if (p.cardNo.isNotEmpty) 'Card ${p.cardNo}',
      ].join(' · '),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(currentStaffProvider);
    if (!canManagePatientAppAccess(staff)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Family links')),
        body: const Center(child: Text('Access denied for this account.')),
      );
    }

    final theme = Theme.of(context);
    final parent = _parent;

    return Scaffold(
      appBar: AppBar(title: const Text('Family links')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Link a parent patient to existing child records so the parent '
            'can see the child’s appointments and results in the patient app.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '1. Select parent',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (parent != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(parent.displayName),
                subtitle: _patientSubtitle(parent),
                trailing: IconButton(
                  tooltip: 'Change parent',
                  icon: const Icon(Icons.close),
                  onPressed: _clearParent,
                ),
              ),
            )
          else ...[
            TextField(
              controller: _parentSearchCtrl,
              decoration: InputDecoration(
                labelText: 'Search parent patient',
                hintText: 'Name, card no, or patient ID',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchingParent
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              onChanged: _onParentSearchChanged,
            ),
            if (_parentSearchError != null) ...[
              const SizedBox(height: 8),
              Text(
                _parentSearchError!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            if (_parentResults.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._parentResults.map((p) {
                final id = p.id;
                if (id == null || id.isEmpty) return const SizedBox.shrink();
                return ListTile(
                  dense: true,
                  title: Text(p.displayName),
                  subtitle: _patientSubtitle(p),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _selectParent(p),
                );
              }),
            ],
          ],
          if (parent != null) ...[
            const SizedBox(height: 24),
            Text(
              '2. Linked children',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (_loadingChildren)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_childrenError != null)
              Text(
                _childrenError!,
                style: TextStyle(color: theme.colorScheme.error),
              )
            else if (_children.isEmpty)
              const EmptyStateWidget(
                icon: Icons.family_restroom_outlined,
                title: 'No children linked yet',
                message:
                    'Search and add child patients to grant family app access.',
              )
            else
              ..._children.map((child) {
                final busy = _unlinkingId == child.id;
                final subtitleParts = <String>[
                  if (child.patientId.isNotEmpty) child.patientId,
                  if (child.createdByName != null &&
                      child.createdByName!.trim().isNotEmpty)
                    'Created by: ${child.createdByName}',
                ];
                return Card(
                  child: ListTile(
                    title: Text(child.displayName),
                    subtitle: subtitleParts.isEmpty
                        ? null
                        : Text(
                            subtitleParts.join('\n'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                    trailing: busy
                        ? const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            tooltip: 'Unlink',
                            icon: const Icon(Icons.link_off),
                            onPressed: () => _unlinkChild(child),
                          ),
                  ),
                );
              }),
            const SizedBox(height: 24),
            Text(
              '3. Add child',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _childSearchCtrl,
              enabled: !_linking,
              decoration: InputDecoration(
                labelText: 'Search child patient',
                hintText: 'Name, card no, or patient ID',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: (_searchingChild || _linking)
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              onChanged: _onChildSearchChanged,
            ),
            if (_childSearchError != null) ...[
              const SizedBox(height: 8),
              Text(
                _childSearchError!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            if (_childResults.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._childResults.map((p) {
                final id = p.id;
                if (id == null || id.isEmpty) return const SizedBox.shrink();
                final alreadyLinked = _children.any((c) => c.id == id);
                final isSelf = id == parent.id;
                return ListTile(
                  dense: true,
                  title: Text(p.displayName),
                  subtitle: _patientSubtitle(p),
                  trailing: Icon(
                    alreadyLinked || isSelf
                        ? Icons.block
                        : Icons.person_add_alt_1_outlined,
                  ),
                  onTap: (alreadyLinked || isSelf || _linking)
                      ? () {
                          if (isSelf) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Cannot link a patient to themselves.',
                                ),
                              ),
                            );
                          } else if (alreadyLinked) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Already linked.'),
                              ),
                            );
                          }
                        }
                      : () => _linkChild(p),
                );
              }),
            ],
          ],
        ],
      ),
    );
  }
}
