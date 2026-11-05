import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/responsive.dart';
import '../../helper/app_timezone.dart';
import '../../helper/date.formatter.dart';
import '../../models/admin_audit_log.dart';
import '../../providers/admin_audit_provider.dart';

@RoutePage()
class SuperAdminAuditLogScreen extends ConsumerStatefulWidget {
  const SuperAdminAuditLogScreen({super.key, this.staffId});

  /// When opened from a staff profile, limits the log to that Staff.id.
  final String? staffId;

  @override
  ConsumerState<SuperAdminAuditLogScreen> createState() =>
      _SuperAdminAuditLogScreenState();
}

enum _Range { day, week, month, custom }

class _SuperAdminAuditLogScreenState
    extends ConsumerState<SuperAdminAuditLogScreen> {
  static const _actions = [
    'CREATE',
    'UPDATE',
    'DELETE',
    'UPSERT',
    'LOGIN',
    'LOGIN_FAILED',
  ];

  final _searchCtrl = TextEditingController();
  final _entityCtrl = TextEditingController();

  _Range _range = _Range.week;
  DateTime? _customFrom;
  DateTime? _customTo;
  String? _action;
  String? _performedById;
  List<AdminAuditEntry> _items = [];
  String? _nextCursor;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _performedById = widget.staffId;
    _load(reset: true);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _entityCtrl.dispose();
    super.dispose();
  }

  String _ymd(DateTime date) {
    final local = AppTimezone.toLocal(date);
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  ({String from, String to}) _bounds() {
    final now = AppTimezone.now();
    switch (_range) {
      case _Range.day:
        return (
          from: now.subtract(const Duration(hours: 24)).toUtc().toIso8601String(),
          to: now.toUtc().toIso8601String(),
        );
      case _Range.week:
        return (
          from: _ymd(now.subtract(const Duration(days: 6))),
          to: _ymd(now),
        );
      case _Range.month:
        return (
          from: _ymd(now.subtract(const Duration(days: 29))),
          to: _ymd(now),
        );
      case _Range.custom:
        final from = _customFrom ?? now.subtract(const Duration(days: 6));
        final to = _customTo ?? now;
        return (from: _ymd(from), to: _ymd(to));
    }
  }

  Future<void> _load({required bool reset}) async {
    if (!reset && (_loadingMore || _nextCursor == null)) return;
    final requestId = ++_requestId;
    final bounds = _bounds();
    final cursor = reset ? null : _nextCursor;
    if (reset && mounted && !_loading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else if (!reset && mounted) {
      setState(() => _loadingMore = true);
    }
    try {
      final page = await ref.read(adminAuditServiceProvider).fetch(
            from: bounds.from,
            to: bounds.to,
            performedById: _performedById,
            action: _action,
            entity: _entityCtrl.text.trim().isEmpty
                ? null
                : _entityCtrl.text.trim(),
            query: _searchCtrl.text.trim().isEmpty
                ? null
                : _searchCtrl.text.trim(),
            cursor: cursor,
          );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _items = reset ? page.items : [..._items, ...page.items];
        _nextCursor = page.nextCursor;
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = '$e';
      });
    }
  }

  Future<void> _pickCustom(bool isFrom) async {
    final now = DateTime.now();
    final initial = isFrom
        ? (_customFrom ?? now.subtract(const Duration(days: 6)))
        : (_customTo ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() {
      _range = _Range.custom;
      if (isFrom) {
        _customFrom = picked;
      } else {
        _customTo = picked;
      }
    });
    await _load(reset: true);
  }

  void _openDetail(AdminAuditEntry entry) {
    final staff = entry.staff?.displayName ?? 'Unknown staff';
    final role = entry.staffRole ?? entry.staff?.staffRole ?? '—';
    final department = entry.departmentName ?? '—';
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${entry.action} ${entry.entity}'),
        content: SizedBox(
          width: 720,
          child: SingleChildScrollView(
            child: SelectableText(
              [
                'When: ${DateFormatter.dateTimeWithSeconds(entry.createdAt)}',
                'Staff: $staff',
                'Role: $role',
                'Department: $department',
                'Account: ${entry.accountType ?? entry.staff?.accountType ?? '—'}',
                'Record: ${entry.entityId}',
                'Request: ${entry.httpMethod ?? '—'} ${entry.route ?? '—'}',
                'IP: ${entry.ipAddress ?? '—'}',
                'Summary: ${entry.summary ?? '—'}',
                '',
                'Before:',
                _pretty(entry.oldValue),
                '',
                'After:',
                _pretty(entry.newValue),
              ].join('\n'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Audit log')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create, update, and delete activity for every staff member, including sign-in.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SegmentedButton<_Range>(
                      segments: const [
                        ButtonSegment(value: _Range.day, label: Text('24 hours')),
                        ButtonSegment(value: _Range.week, label: Text('7 days')),
                        ButtonSegment(value: _Range.month, label: Text('30 days')),
                        ButtonSegment(value: _Range.custom, label: Text('Custom')),
                      ],
                      selected: {_range},
                      onSelectionChanged: (value) {
                        setState(() => _range = value.first);
                        if (value.first != _Range.custom) _load(reset: true);
                      },
                    ),
                    if (_range == _Range.custom) ...[
                      OutlinedButton(
                        onPressed: () => _pickCustom(true),
                        child: Text(
                          _customFrom == null
                              ? 'From'
                              : 'From ${_ymd(_customFrom!)}',
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => _pickCustom(false),
                        child: Text(
                          _customTo == null ? 'To' : 'To ${_ymd(_customTo!)}',
                        ),
                      ),
                    ],
                    DropdownButton<String>(
                      value: _action ?? '',
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('All actions'),
                        ),
                        for (final action in _actions)
                          DropdownMenuItem(value: action, child: Text(action)),
                      ],
                      onChanged: (value) {
                        setState(
                          () => _action =
                              (value == null || value.isEmpty) ? null : value,
                        );
                        _load(reset: true);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 260,
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: const InputDecoration(
                          isDense: true,
                          labelText: 'Search staff, summary, or record',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _load(reset: true),
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: TextField(
                        controller: _entityCtrl,
                        decoration: const InputDecoration(
                          isDense: true,
                          labelText: 'Record type',
                          hintText: 'Patient, Invoice',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _load(reset: true),
                      ),
                    ),
                    FilledButton(
                      onPressed: _loading ? null : () => _load(reset: true),
                      child: const Text('Apply'),
                    ),
                  ],
                ),
                if (_performedById != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InputChip(
                      label: const Text('One staff member'),
                      onDeleted: () {
                        setState(() => _performedById = null);
                        _load(reset: true);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(child: Text('No activity in this range.'))
                    : ResponsiveDataTable(
                        minWidth: 1100,
                        child: DataTable(
                          showCheckboxColumn: false,
                          columns: const [
                            DataColumn(label: Text('Time')),
                            DataColumn(label: Text('Staff')),
                            DataColumn(label: Text('Role')),
                            DataColumn(label: Text('Action')),
                            DataColumn(label: Text('What changed')),
                            DataColumn(label: Text('Record')),
                          ],
                          rows: [
                            for (final entry in _items)
                              DataRow(
                                onSelectChanged: (_) => _openDetail(entry),
                                cells: [
                                  DataCell(Text(
                                    DateFormatter.dateTimeWithSeconds(
                                      entry.createdAt,
                                    ),
                                  )),
                                  DataCell(Text(entry.staff?.displayName ?? '—')),
                                  DataCell(Text(
                                    entry.staffRole ??
                                        entry.staff?.staffRole ??
                                        '—',
                                  )),
                                  DataCell(Text(entry.action)),
                                  DataCell(Text(entry.summary ?? entry.entity)),
                                  DataCell(Text(
                                    '${entry.entity} ${entry.entityId}',
                                  )),
                                ],
                              ),
                          ],
                        ),
                      ),
          ),
          if (_nextCursor != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.center,
                child: _loadingMore
                    ? const CircularProgressIndicator()
                    : OutlinedButton(
                        onPressed: () => _load(reset: false),
                        child: const Text('Load more'),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

String _pretty(Object? value) {
  if (value == null) return '—';
  try {
    return const JsonEncoder.withIndent('  ').convert(value);
  } catch (_) {
    return value.toString();
  }
}
