import 'dart:convert';
import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/user_facing_error.dart';
import '../../core/responsive.dart';
import '../../helper/app_timezone.dart';
import '../../helper/date.formatter.dart';
import '../../helper/theme.dart';
import '../../models/admin_audit_log.dart';
import '../../providers/admin_audit_provider.dart';
import '../../widgets/empty.widget.dart';
import '../../widgets/helty_surface.dart';

const _kBlue = Color(0xFF2563EB);
const _kTeal = Color(0xFF0D9488);
const _kPurple = Color(0xFF7C3AED);
const _kPink = Color(0xFFDB2777);
const _kIndigo = Color(0xFF4F46E5);
const _kGreen = Color(0xFF16A34A);
const _kAmber = Color(0xFFEA580C);
const _kCardBreakpoint = 768.0;
const _kRailBreakpoint = 1100.0;
const _kColGap = 20.0;

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

  String get _rangeLabel {
    switch (_range) {
      case _Range.day:
        return 'Last 24 hours';
      case _Range.week:
        return 'Last 7 days';
      case _Range.month:
        return 'Last 30 days';
      case _Range.custom:
        final from = _customFrom;
        final to = _customTo;
        if (from == null && to == null) return 'Custom range';
        return '${from == null ? '…' : DateFormatter.shortDate(from)} – ${to == null ? '…' : DateFormatter.shortDate(to)}';
    }
  }

  ({String from, String to}) _bounds() {
    final now = AppTimezone.now();
    switch (_range) {
      case _Range.day:
        return (
          from: now
              .subtract(const Duration(hours: 24))
              .toUtc()
              .toIso8601String(),
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

  int _countAction(String action) =>
      _items.where((entry) => entry.action == action).length;

  String _pageCount(String action) => _loading ? '—' : '${_countAction(action)}';

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
        entity: _entityCtrl.text.trim().isEmpty ? null : _entityCtrl.text.trim(),
        query: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
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
        _error = userFacingErrorMessage(e);
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
    if (picked == null || !mounted) return;
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

  Future<void> _openFilters() async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.18),
      builder: (ctx) {
        final width = MediaQuery.sizeOf(ctx).width;
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return Dialog(
              alignment: Alignment.topRight,
              insetPadding: const EdgeInsets.fromLTRB(16, 72, 16, 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: math.min(360, width - 32),
                  maxHeight: MediaQuery.sizeOf(ctx).height * 0.8,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
                  child: _FilterMenu(
                    range: _range,
                    rangeLabel: _rangeLabel,
                    entityCtrl: _entityCtrl,
                    action: _action,
                    actions: _actions,
                    staffLimited: _performedById != null,
                    onAction: (value) {
                      _setAction(value);
                      setLocal(() {});
                    },
                    onRange: (range) {
                      setState(() => _range = range);
                      setLocal(() {});
                      if (range != _Range.custom) _load(reset: true);
                    },
                    onPickFrom: () async {
                      await _pickCustom(true);
                      setLocal(() {});
                    },
                    onPickTo: () async {
                      await _pickCustom(false);
                      setLocal(() {});
                    },
                    customFromLabel: _customFrom == null
                        ? 'From'
                        : DateFormatter.shortDate(_customFrom!),
                    customToLabel: _customTo == null
                        ? 'To'
                        : DateFormatter.shortDate(_customTo!),
                    onClearStaff: _performedById == null
                        ? null
                        : () {
                            setState(() => _performedById = null);
                            _load(reset: true);
                            Navigator.of(ctx).maybePop();
                          },
                    onApply: () {
                      Navigator.of(ctx).pop();
                      _load(reset: true);
                    },
                  ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openDetail(AdminAuditEntry entry) {
    final width = MediaQuery.sizeOf(context).width;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: math.min(560, width - 32),
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.8,
          ),
          child: _DetailDialog(entry: entry),
        ),
      ),
    );
  }

  void _setAction(String? value) {
    setState(() => _action = (value == null || value.isEmpty) ? null : value);
    _load(reset: true);
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
          final compact = width < _kCardBreakpoint;
          final showRail = width >= _kRailBreakpoint;
          final main = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                compact: compact,
                subtitle: _performedById == null
                    ? 'Create, update, delete, and sign-in for every staff member.'
                    : 'Limited to one staff member. $_rangeLabel.',
                canPop: context.router.canPop(),
                onBack: () => context.router.maybePop(),
              ),
              const SizedBox(height: 10),
              _KpiStrip(
                rows: _loading ? '—' : '${_items.length}',
                creates: _pageCount('CREATE'),
                updates: _pageCount('UPDATE'),
                deletes: _pageCount('DELETE'),
                snap: width < 520,
              ),
              const SizedBox(height: 10),
              _FilterRow(
                compact: compact,
                searchCtrl: _searchCtrl,
                action: _action,
                actions: _actions,
                onSearch: () => _load(reset: true),
                onAction: _setAction,
                onOpenFilters: _openFilters,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _LogPane(
                  compact: compact,
                  loading: _loading,
                  loadingMore: _loadingMore,
                  error: _error,
                  items: _items,
                  hasMore: _nextCursor != null,
                  onView: _openDetail,
                  onLoadMore: () => _load(reset: false),
                  onRetry: () => _load(reset: true),
                ),
              ),
            ],
          );
          if (!showRail) return main;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 9, child: main),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: _Rail(
                  rangeLabel: _rangeLabel,
                  action: _action ?? 'All actions',
                  entity: _entityCtrl.text.trim().isEmpty
                      ? 'All record types'
                      : _entityCtrl.text.trim(),
                  staffLimited: _performedById != null,
                  onClearStaff: _performedById == null
                      ? null
                      : () {
                          setState(() => _performedById = null);
                          _load(reset: true);
                        },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.compact,
    required this.subtitle,
    required this.canPop,
    required this.onBack,
  });

  final bool compact;
  final String subtitle;
  final bool canPop;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      children: [
        if (canPop) ...[
          IconButton(
            tooltip: 'Back',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: 4),
        ],
        const HeltySolidIcon(
          icon: Icons.fact_check_outlined,
          color: _kIndigo,
          size: 34,
          iconSize: 18,
          radius: AppTheme.radiusMd,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Audit log',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                  fontSize: compact ? 20 : null,
                ),
              ),
              HeltyEllipsisText(
                text: subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KpiStrip extends StatelessWidget {
  const _KpiStrip({
    required this.rows,
    required this.creates,
    required this.updates,
    required this.deletes,
    required this.snap,
  });

  final String rows;
  final String creates;
  final String updates;
  final String deletes;
  final bool snap;

  @override
  Widget build(BuildContext context) {
    final items = [
      (label: 'On this page', value: rows, caption: 'Loaded rows', icon: Icons.receipt_long_outlined, color: _kBlue),
      (label: 'Creates', value: creates, caption: 'This page', icon: Icons.add_box_outlined, color: _kGreen),
      (label: 'Updates', value: updates, caption: 'This page', icon: Icons.edit_outlined, color: _kTeal),
      (label: 'Deletes', value: deletes, caption: 'This page', icon: Icons.delete_outline, color: _kPink),
    ];
    if (snap) {
      return SizedBox(
        height: 78,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, i) =>
              SizedBox(width: 180, child: _KpiCard(item: items[i])),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 820) {
          return Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _KpiCard(item: items[i])),
              ],
            ],
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: 72,
          ),
          itemBuilder: (context, i) => _KpiCard(item: items[i]),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.item});

  final ({String label, String value, String caption, IconData icon, Color color})
  item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return HeltySurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          HeltySolidIcon(
            icon: item.icon,
            color: item.color,
            size: 30,
            iconSize: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HeltyEllipsisText(
                  text: item.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  item.value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                HeltyEllipsisText(
                  text: item.caption,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.compact,
    required this.searchCtrl,
    required this.action,
    required this.actions,
    required this.onSearch,
    required this.onAction,
    required this.onOpenFilters,
  });

  final bool compact;
  final TextEditingController searchCtrl;
  final String? action;
  final List<String> actions;
  final VoidCallback onSearch;
  final ValueChanged<String?> onAction;
  final VoidCallback onOpenFilters;

  InputDecoration _decoration(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color iconColor,
    String? hint,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      prefixIcon: Padding(
        padding: const EdgeInsets.all(6),
        child: HeltySolidIcon(
          icon: icon,
          color: iconColor,
          size: 22,
          iconSize: 13,
          radius: 6,
        ),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      filled: true,
      fillColor: cs.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      labelStyle: const TextStyle(fontSize: 11),
    );
  }

  @override
  Widget build(BuildContext context) {
    final search = TextField(
      controller: searchCtrl,
      style: const TextStyle(fontSize: 12),
      decoration: _decoration(
        context,
        label: 'Search',
        hint: 'Staff, summary, or record',
        icon: Icons.search,
        iconColor: _kIndigo,
      ),
      onSubmitted: (_) => onSearch(),
    );
    final filterButton = IconButton(
      tooltip: 'Filters',
      onPressed: onOpenFilters,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: const HeltySolidIcon(
        icon: Icons.tune,
        color: _kPurple,
        size: 32,
        iconSize: 16,
      ),
    );
    if (compact) {
      return Row(
        children: [
          Expanded(child: search),
          const SizedBox(width: 8),
          filterButton,
        ],
      );
    }
    return Row(
      children: [
        Expanded(flex: 3, child: search),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            key: ValueKey('action-${action ?? 'all'}'),
            initialValue: action ?? '',
            isExpanded: true,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            decoration: _decoration(
              context,
              label: 'Action',
              icon: Icons.bolt_outlined,
              iconColor: _kAmber,
            ),
            items: [
              const DropdownMenuItem(value: '', child: Text('All actions')),
              for (final item in actions)
                DropdownMenuItem(
                  value: item,
                  child: Text(item, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: onAction,
          ),
        ),
        const SizedBox(width: 8),
        filterButton,
      ],
    );
  }
}

class _FilterMenu extends StatelessWidget {
  const _FilterMenu({
    required this.range,
    required this.rangeLabel,
    required this.entityCtrl,
    required this.action,
    required this.actions,
    required this.onAction,
    required this.staffLimited,
    required this.onRange,
    required this.onPickFrom,
    required this.onPickTo,
    required this.customFromLabel,
    required this.customToLabel,
    required this.onClearStaff,
    required this.onApply,
  });

  final _Range range;
  final String rangeLabel;
  final TextEditingController entityCtrl;
  final String? action;
  final List<String> actions;
  final ValueChanged<String?> onAction;
  final bool staffLimited;
  final ValueChanged<_Range> onRange;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final String customFromLabel;
  final String customToLabel;
  final VoidCallback? onClearStaff;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const HeltySolidIcon(icon: Icons.tune, color: _kPurple),
            const SizedBox(width: 8),
            Text(
              'Filters',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Close',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        Text(
          rangeLabel,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in _Range.values)
              ChoiceChip(
                label: Text(_rangeName(item)),
                selected: range == item,
                onSelected: (_) => onRange(item),
              ),
          ],
        ),
        if (range == _Range.custom) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onPickFrom,
                  child: Text(customFromLabel),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onPickTo,
                  child: Text(customToLabel),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey('menu-action-${action ?? 'all'}'),
          initialValue: action ?? '',
          isExpanded: true,
          decoration: const InputDecoration(
            isDense: true,
            labelText: 'Action',
          ),
          items: [
            const DropdownMenuItem(value: '', child: Text('All actions')),
            for (final item in actions)
              DropdownMenuItem(value: item, child: Text(item)),
          ],
          onChanged: onAction,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: entityCtrl,
          decoration: const InputDecoration(
            isDense: true,
            labelText: 'Record type',
            hintText: 'Patient, Invoice',
          ),
          onSubmitted: (_) => onApply(),
        ),
        if (staffLimited && onClearStaff != null) ...[
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerLeft,
            child: HeltyStatusChip(
              label: 'One staff member',
              color: _kIndigo,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onClearStaff,
              child: const Text('Clear staff filter'),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(onPressed: onApply, child: const Text('Apply')),
        ),
      ],
    );
  }

  static String _rangeName(_Range range) {
    switch (range) {
      case _Range.day:
        return '24 hours';
      case _Range.week:
        return '7 days';
      case _Range.month:
        return '30 days';
      case _Range.custom:
        return 'Custom';
    }
  }
}

class _LogPane extends StatelessWidget {
  const _LogPane({
    required this.compact,
    required this.loading,
    required this.loadingMore,
    required this.error,
    required this.items,
    required this.hasMore,
    required this.onView,
    required this.onLoadMore,
    required this.onRetry,
  });

  final bool compact;
  final bool loading;
  final bool loadingMore;
  final String? error;
  final List<AdminAuditEntry> items;
  final bool hasMore;
  final ValueChanged<AdminAuditEntry> onView;
  final VoidCallback onLoadMore;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final body = loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? EmptyStateWidget(
            icon: Icons.error_outline,
            title: 'Could not load the audit log',
            message: error!,
            buttonText: 'Retry',
            onPressed: onRetry,
          )
        : items.isEmpty
        ? const EmptyStateWidget(
            icon: Icons.fact_check_outlined,
            title: 'No activity in this range',
            message: 'Try a wider date range or clear a filter.',
          )
        : compact
        ? ListView.separated(
            padding: const EdgeInsets.fromLTRB(2, 2, 2, 8),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _AuditCard(
              entry: items[index],
              onView: () => onView(items[index]),
            ),
          )
        : LayoutBuilder(
            builder: (context, constraints) {
              final tableWidth = math.max(constraints.maxWidth, 720.0);
              return Scrollbar(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    height: constraints.maxHeight,
                    child: Column(
                      children: [
                        _tableHead(context),
                        Expanded(
                          child: ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final entry = items[index];
                              final zebra = index.isOdd
                                  ? cs.onSurface.withValues(alpha: 0.035)
                                  : Colors.transparent;
                              return Material(
                                color: zebra,
                                child: InkWell(
                                  onTap: () => onView(entry),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    child: _AuditCells(
                                      entry: entry,
                                      onView: () => onView(entry),
                                    ),
                                  ),
                                ),
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

    return HeltySurfaceCard(
      child: Column(
        children: [
          Expanded(child: body),
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    loading
                        ? 'Loading activity'
                        : items.isEmpty
                        ? 'No rows to display'
                        : '${items.length} rows on this page',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                if (loadingMore)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  TextButton(
                    onPressed: hasMore ? onLoadMore : null,
                    child: const Text('Load more'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHead(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: 0.4,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Container(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('TIME', style: style)),
          const SizedBox(width: _kColGap),
          Expanded(flex: 4, child: Text('STAFF', style: style)),
          const SizedBox(width: _kColGap),
          Expanded(flex: 2, child: Text('ROLE', style: style)),
          const SizedBox(width: _kColGap),
          Expanded(flex: 2, child: Text('ACTION', style: style)),
          const SizedBox(width: _kColGap),
          Expanded(flex: 5, child: Text('WHAT CHANGED', style: style)),
          const SizedBox(width: _kColGap),
          const SizedBox(width: 72),
        ],
      ),
    );
  }
}

class _AuditCells extends StatelessWidget {
  const _AuditCells({required this.entry, required this.onView});

  final AdminAuditEntry entry;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall;
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: HeltyEllipsisText(
            text: DateFormatter.dateTimeWithSeconds(entry.createdAt),
            style: style,
          ),
        ),
        const SizedBox(width: _kColGap),
        Expanded(
          flex: 4,
          child: HeltyEllipsisText(
            text: entry.staff?.displayName ?? '—',
            style: style?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: _kColGap),
        Expanded(
          flex: 2,
          child: HeltyEllipsisText(
            text: entry.staffRole ?? entry.staff?.staffRole ?? '—',
            style: style,
          ),
        ),
        const SizedBox(width: _kColGap),
        Expanded(flex: 2, child: _ActionChip(action: entry.action)),
        const SizedBox(width: _kColGap),
        Expanded(
          flex: 5,
          child: HeltyEllipsisText(
            text: entry.summary ?? '${entry.entity} ${entry.entityId}',
            style: style,
          ),
        ),
        const SizedBox(width: _kColGap),
        SizedBox(
          width: 72,
          child: Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: onView,
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: const StadiumBorder(),
              ),
              child: const Text('View'),
            ),
          ),
        ),
      ],
    );
  }
}

class _AuditCard extends StatelessWidget {
  const _AuditCard({required this.entry, required this.onView});

  final AdminAuditEntry entry;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return HeltySurfaceCard(
      padding: const EdgeInsets.all(10),
      onTap: onView,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ActionChip(action: entry.action),
              const SizedBox(width: 8),
              Expanded(
                child: HeltyEllipsisText(
                  text: DateFormatter.dateTimeWithSeconds(entry.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: onView,
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: const StadiumBorder(),
                ),
                child: const Text('View'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          HeltyEllipsisText(
            text: entry.staff?.displayName ?? '—',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          HeltyEllipsisText(
            text: entry.summary ?? '${entry.entity} ${entry.entityId}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.action});

  final String action;

  @override
  Widget build(BuildContext context) {
    return HeltyStatusChip(label: action, color: _actionColor(action));
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.rangeLabel,
    required this.action,
    required this.entity,
    required this.staffLimited,
    required this.onClearStaff,
  });

  final String rangeLabel;
  final String action;
  final String entity;
  final bool staffLimited;
  final VoidCallback? onClearStaff;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HeltySurfaceCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const HeltySolidIcon(
                    icon: Icons.tune,
                    color: _kPurple,
                    size: 28,
                    iconSize: 14,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Current view',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _railLine(context, 'Range', rangeLabel),
              _railLine(context, 'Action', action),
              _railLine(context, 'Record type', entity),
              _railLine(
                context,
                'Staff',
                staffLimited ? 'One staff member' : 'Everyone',
              ),
              if (onClearStaff != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: onClearStaff,
                    child: const Text('Clear staff filter'),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: HeltySurfaceCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const HeltySolidIcon(
                      icon: Icons.info_outline,
                      color: _kBlue,
                      size: 28,
                      iconSize: 14,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'How to read a row',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'View opens the staff member, role, department, request, and the values before and after the change. Passwords and tokens are removed.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Counts above are for the rows on this page. The log does not include a hospital-wide total.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _railLine(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          HeltyEllipsisText(
            text: value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailDialog extends StatelessWidget {
  const _DetailDialog({required this.entry});

  final AdminAuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final staff = entry.staff?.displayName ?? 'Unknown staff';
    final role = entry.staffRole ?? entry.staff?.staffRole ?? '—';
    final department = entry.departmentName ?? '—';
    final account = entry.accountType ?? entry.staff?.accountType ?? '—';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              HeltySolidIcon(
                icon: Icons.fact_check_outlined,
                color: _actionColor(entry.action),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: HeltyEllipsisText(
                  text: '${entry.action} ${entry.entity}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(right: 8, bottom: 8),
              child: SelectableText(
                [
                  'When: ${DateFormatter.dateTimeWithSeconds(entry.createdAt)}',
                  'Staff: $staff',
                  'Role: $role',
                  'Department: $department',
                  'Account: $account',
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
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _actionColor(String action) {
  switch (action) {
    case 'CREATE':
      return _kGreen;
    case 'UPDATE':
      return _kBlue;
    case 'DELETE':
      return _kPink;
    case 'UPSERT':
      return _kPurple;
    case 'LOGIN':
      return _kTeal;
    case 'LOGIN_FAILED':
      return _kAmber;
    default:
      return _kIndigo;
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
