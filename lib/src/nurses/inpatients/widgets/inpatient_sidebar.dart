import 'package:flutter/material.dart';

import 'package:helty/src/admissions/widgets/admission_ward_location_section.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/helper/theme.dart';
import 'package:helty/src/models/admission_alert_model.dart';
import 'package:helty/src/models/admission_model.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_metrics.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_ui_tabs.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_view_scope.dart';
import 'package:helty/src/services/admission_alert_service.dart';
import 'package:helty/src/widgets/helty_surface.dart';

class InpatientSidebar extends StatefulWidget {
  const InpatientSidebar({
    super.key,
    required this.admission,
    this.fillHeight = false,
    this.onLocationUpdated,
  });

  final AdmissionModel? admission;
  final bool fillHeight;
  final VoidCallback? onLocationUpdated;

  @override
  State<InpatientSidebar> createState() => _InpatientSidebarState();
}

class _InpatientSidebarState extends State<InpatientSidebar> {
  final _alertService = AdmissionAlertService();
  List<AdmissionAlertModel> _alerts = [];
  bool _loadingAlerts = false;
  String? _lastAdmissionId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = InpatientViewScope.of(context)?.admissionId;
    if (id == null || id.isEmpty) {
      if (_lastAdmissionId != null) {
        setState(() {
          _alerts = [];
          _loadingAlerts = false;
          _lastAdmissionId = null;
        });
      }
      return;
    }
    if (id != _lastAdmissionId) {
      _lastAdmissionId = id;
      _loadAlerts(id);
    }
  }

  Future<void> _loadAlerts(String admissionId) async {
    setState(() => _loadingAlerts = true);
    try {
      final list = await _alertService.list(admissionId, unresolvedOnly: true);
      if (!mounted) return;
      setState(() {
        _alerts = list;
        _loadingAlerts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _alerts = [];
        _loadingAlerts = false;
      });
    }
  }

  void _go(int tab) {
    InpatientViewScope.of(context)?.onSelectTab?.call(tab);
  }

  @override
  Widget build(BuildContext context) {
    final scope = InpatientViewScope.of(context);
    final showWard =
        scope?.isNurse == true &&
        scope?.isAdmissionActive == true &&
        widget.admission != null;

    final quick = _QuickActionsCard(onSelect: _go);
    final alerts = _AlertsCard(
      alerts: _alerts,
      loading: _loadingAlerts,
      onViewAll: () => _go(InpatientUiTabs.alerts),
      expanded: widget.fillHeight,
    );

    final children = <Widget>[
      quick,
      const SizedBox(height: 12),
      if (widget.fillHeight) Expanded(flex: 3, child: alerts) else alerts,
      if (showWard) ...[
        const SizedBox(height: 12),
        if (widget.fillHeight)
          Expanded(
            flex: 2,
            child: _WardLocationCard(
              admission: widget.admission!,
              onLocationUpdated: widget.onLocationUpdated,
              expanded: true,
            ),
          )
        else
          _WardLocationCard(
            admission: widget.admission!,
            onLocationUpdated: widget.onLocationUpdated,
            expanded: false,
          ),
      ],
    ];

    if (!widget.fillHeight) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({required this.onSelect});

  final void Function(int tab) onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const actions = <({String label, IconData icon, Color color, int tab})>[
      (
        label: 'Vitals',
        icon: Icons.monitor_heart_outlined,
        color: InpatientMetrics.waitRed,
        tab: InpatientUiTabs.vitals,
      ),
      (
        label: 'Medications',
        icon: Icons.medication_outlined,
        color: InpatientMetrics.waitAmber,
        tab: InpatientUiTabs.medications,
      ),
      (
        label: 'Lab Results',
        icon: Icons.science_outlined,
        color: InpatientMetrics.iconTeal,
        tab: InpatientUiTabs.labResults,
      ),
      (
        label: 'Imaging',
        icon: Icons.photo_outlined,
        color: InpatientMetrics.iconBlue,
        tab: InpatientUiTabs.imaging,
      ),
      (
        label: 'Nursing Report',
        icon: Icons.note_alt_outlined,
        color: InpatientMetrics.iconPink,
        tab: InpatientUiTabs.nursingReport,
      ),
      (
        label: 'Procedures',
        icon: Icons.healing_outlined,
        color: InpatientMetrics.iconPurple,
        tab: InpatientUiTabs.procedures,
      ),
    ];

    return HeltySurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const HeltySolidIcon(
                icon: Icons.flash_on,
                color: InpatientMetrics.waitAmber,
                size: 26,
                iconSize: 14,
                radius: 7,
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            _ActionRow(
              label: actions[i].label,
              icon: actions[i].icon,
              color: actions[i].color,
              onTap: () => onSelect(actions[i].tab),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              HeltySolidIcon(
                icon: icon,
                color: color,
                size: 28,
                iconSize: 15,
                radius: 8,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: HeltyEllipsisText(
                  text: label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertsCard extends StatelessWidget {
  const _AlertsCard({
    required this.alerts,
    required this.loading,
    required this.onViewAll,
    required this.expanded,
  });

  final List<AdmissionAlertModel> alerts;
  final bool loading;
  final VoidCallback onViewAll;
  final bool expanded;

  Color _severityColor(String? severity) {
    final s = (severity ?? '').toUpperCase();
    if (s.contains('CRIT') || s.contains('HIGH')) {
      return InpatientMetrics.waitRed;
    }
    if (s.contains('MED')) return InpatientMetrics.waitAmber;
    return InpatientMetrics.iconBlue;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final count = alerts.length;

    final header = Row(
      children: [
        const HeltySolidIcon(
          icon: Icons.notifications_outlined,
          color: InpatientMetrics.waitRed,
          size: 26,
          iconSize: 14,
          radius: 7,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Alerts & Notifications',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: InpatientMetrics.waitRed,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );

    Widget listBody;
    if (loading) {
      listBody = const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    } else if (alerts.isEmpty) {
      listBody = Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No unresolved alerts.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      );
    } else {
      listBody = ListView.separated(
        shrinkWrap: !expanded,
        physics: expanded
            ? const AlwaysScrollableScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        itemCount: alerts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final a = alerts[i];
          final title = (a.title ?? a.message ?? 'Alert').trim();
          final when = a.dueAt ?? a.createdAt;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeltySolidIcon(
                icon: Icons.priority_high,
                color: _severityColor(a.severity),
                size: 26,
                iconSize: 14,
                radius: 7,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HeltyEllipsisText(
                      text: title,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if ((a.message ?? '').trim().isNotEmpty &&
                        a.message!.trim() != title)
                      HeltyEllipsisText(
                        text: a.message!.trim(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (when != null)
                Text(
                  DateFormatter.relativeTimeAgo(when),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
            ],
          );
        },
      );
    }

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: 10),
        if (expanded) Expanded(child: listBody) else listBody,
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onViewAll,
            child: const Text('View all'),
          ),
        ),
      ],
    );

    final card = HeltySurfaceCard(
      padding: const EdgeInsets.all(12),
      child: column,
    );
    return expanded ? SizedBox.expand(child: card) : card;
  }
}

class _WardLocationCard extends StatelessWidget {
  const _WardLocationCard({
    required this.admission,
    required this.onLocationUpdated,
    required this.expanded,
  });

  final AdmissionModel admission;
  final VoidCallback? onLocationUpdated;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const HeltySolidIcon(
              icon: Icons.holiday_village_outlined,
              color: InpatientMetrics.iconIndigo,
              size: 26,
              iconSize: 14,
              radius: 7,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ward location',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AdmissionWardLocationSection(
          admission: admission,
          compact: true,
          onLocationUpdated: onLocationUpdated,
        ),
      ],
    );

    final card = HeltySurfaceCard(
      padding: const EdgeInsets.all(12),
      child: expanded ? SingleChildScrollView(child: child) : child,
    );
    return expanded ? SizedBox.expand(child: card) : card;
  }
}
