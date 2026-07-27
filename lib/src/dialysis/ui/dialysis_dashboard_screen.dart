import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/core/widgets/patient_avatar.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/dialysis/models/dialysis_models.dart';
import 'package:helty/src/dialysis/providers/dialysis_providers.dart';
import 'package:helty/src/helper/date.formatter.dart';

@RoutePage()
class DialysisDashboardScreen extends ConsumerStatefulWidget {
  const DialysisDashboardScreen({super.key});

  @override
  ConsumerState<DialysisDashboardScreen> createState() =>
      _DialysisDashboardScreenState();
}

class _DialysisDashboardScreenState extends ConsumerState<DialysisDashboardScreen> {
  DialysisSessionStatus? _filterStatus;
  static const _skip = 0;
  static const _take = 20;
  bool _loadingSummary = true;
  String? _summaryError;
  Map<DialysisSessionStatus, int> _statusCounts = {};
  int _totalSessionsInRange = 0;

  late DateTimeRange _sessionsDateRange;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _sessionsDateRange = DateTimeRange(
      start: DateTime(n.year, n.month, n.day),
      end: DateTime(n.year, n.month, n.day, 23, 59, 59, 999),
    );
    _loadSummary();
  }

  (DateTime, DateTime) _queryBounds() {
    final r = _sessionsDateRange;
    return (
      DateTime(r.start.year, r.start.month, r.start.day),
      DateTime(r.end.year, r.end.month, r.end.day, 23, 59, 59, 999),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _sessionsDateRange,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _sessionsDateRange = DateTimeRange(
        start: DateTime(picked.start.year, picked.start.month, picked.start.day),
        end: DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
          999,
        ),
      );
    });
    await _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _loadingSummary = true;
      _summaryError = null;
    });
    try {
      final api = ref.read(dialysisApiServiceProvider);
      final (from, to) = _queryBounds();
      final response = await api.getSessions(
        fromDate: from,
        toDate: to,
        skip: 0,
        take: 100,
      );
      final counts = {
        for (final s in DialysisSessionStatus.values) s: 0,
      };
      for (final session in response.sessions) {
        counts[session.status] = (counts[session.status] ?? 0) + 1;
      }
      if (!mounted) return;
      setState(() {
        _statusCounts = counts;
        _totalSessionsInRange = response.sessions.length;
        _loadingSummary = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _summaryError = e.toString();
        _loadingSummary = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: true,
            pinned: true,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Dialysis',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.secondaryContainer.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 24, bottom: 16),
                      child: Icon(
                        Icons.bloodtype_rounded,
                        size: 64,
                        color: theme.colorScheme.primary.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ResponsiveBody(
              builder: (context, bp) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryRow(theme),
                  SizedBox(height: bp.isMobile ? 16 : 24),
                  _buildSessionsSection(context, theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(ThemeData theme) {
    if (_loadingSummary) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_summaryError != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.error),
              const SizedBox(width: 12),
              Expanded(child: Text(_summaryError!)),
              TextButton(onPressed: _loadSummary, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final cards = [
      _SummaryCard(
        label: 'Sessions in range',
        value: _totalSessionsInRange.toString(),
        icon: Icons.event_note_rounded,
        accent: theme.colorScheme.primary,
      ),
      _SummaryCard(
        label: 'Pending',
        value: (_statusCounts[DialysisSessionStatus.pending] ?? 0).toString(),
        icon: Icons.schedule_rounded,
        accent: theme.colorScheme.tertiary,
      ),
      _SummaryCard(
        label: 'In progress',
        value:
            (_statusCounts[DialysisSessionStatus.inProgress] ?? 0).toString(),
        icon: Icons.play_circle_outline_rounded,
        accent: theme.colorScheme.secondary,
      ),
      _SummaryCard(
        label: 'Completed',
        value: (_statusCounts[DialysisSessionStatus.completed] ?? 0).toString(),
        icon: Icons.check_circle_rounded,
        accent: theme.colorScheme.primaryContainer,
      ),
    ];

    return ResponsiveWrapGrid(
      mobileColumns: 1,
      tabletColumns: 2,
      desktopColumns: 4,
      children: cards,
    );
  }

  Widget _buildSessionsSection(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: _loadingSummary ? null : _pickDateRange,
          icon: const Icon(Icons.date_range_outlined, size: 20),
          label: Text(
            'Date range: ${DateFormatter.shortDate(_sessionsDateRange.start)} – ${DateFormatter.shortDate(_sessionsDateRange.end)}',
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sessions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                _StatusChip(
                  label: 'All',
                  selected: _filterStatus == null,
                  onTap: () => setState(() => _filterStatus = null),
                ),
                ...DialysisSessionStatus.values.map(
                  (s) => _StatusChip(
                    label: s.displayLabel,
                    selected: _filterStatus == s,
                    onTap: () => setState(() => _filterStatus = s),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SessionsList(
          dateRange: _sessionsDateRange,
          status: _filterStatus,
          skip: _skip,
          take: _take,
          onSessionTap: (session) => context.router.push(
            DialysisSessionDetailRoute(sessionId: session.id),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.bodySmall),
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: theme.colorScheme.primaryContainer,
    );
  }
}

class _SessionsList extends ConsumerWidget {
  const _SessionsList({
    required this.dateRange,
    required this.status,
    required this.skip,
    required this.take,
    required this.onSessionTap,
  });

  final DateTimeRange dateRange;
  final DialysisSessionStatus? status;
  final int skip;
  final int take;
  final void Function(DialysisSession session) onSessionTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final from = DateTime(
      dateRange.start.year,
      dateRange.start.month,
      dateRange.start.day,
    );
    final to = DateTime(
      dateRange.end.year,
      dateRange.end.month,
      dateRange.end.day,
      23,
      59,
      59,
      999,
    );

    return FutureBuilder<DialysisSessionsResponse>(
      future: ref.read(dialysisApiServiceProvider).getSessions(
            fromDate: from,
            toDate: to,
            status: status,
            skip: skip,
            take: take,
          ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text(
            snapshot.error.toString(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          );
        }
        final sessions = snapshot.data?.sessions ?? [];
        if (sessions.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'No dialysis sessions in this range.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sessions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final s = sessions[index];
            final patientName = s.patient?.displayName ?? s.patientId;
            final serviceName = s.service?.name ?? 'Dialysis session';
            return Card(
              child: ListTile(
                leading: PatientAvatar(
                  avatarUrl: s.patient?.avatarUrl,
                  firstName: s.patient?.firstName,
                  surname: s.patient?.surname,
                  displayName: patientName,
                  size: 40,
                ),
                title: Text(patientName),
                subtitle: Text('$serviceName · ${s.status.displayLabel}'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => onSessionTap(s),
              ),
            );
          },
        );
      },
    );
  }
}
