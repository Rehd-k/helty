import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/core/widgets/patient_avatar.dart';
import 'package:helty/src/theatre/models/theatre_models.dart';
import 'package:helty/src/theatre/providers/theatre_providers.dart';
import 'package:helty/src/theatre/widgets/theatre_status_chip.dart';

@RoutePage()
class TheatreDashboardScreen extends ConsumerStatefulWidget {
  const TheatreDashboardScreen({super.key});

  @override
  ConsumerState<TheatreDashboardScreen> createState() =>
      _TheatreDashboardScreenState();
}

class _TheatreDashboardScreenState extends ConsumerState<TheatreDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  SurgeryRequestStatus? _queueStatusFilter = SurgeryRequestStatus.requested;
  late DateTimeRange _dateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final now = DateTime.now();
    _dateRange = DateTimeRange(
      start: DateTime(now.year, now.month, now.day),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  (DateTime, DateTime) _queryBounds() {
    final r = _dateRange;
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
      initialDateRange: _dateRange,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _dateRange = DateTimeRange(
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
  }

  void _openRequest(SurgeryRequest request) {
    if (request.status == SurgeryRequestStatus.requested) {
      context.router.push(
        TheatreScheduleFormRoute(surgeryRequestId: request.id),
      );
    } else {
      context.router.push(
        TheatreCaseDetailRoute(surgeryRequestId: request.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (from, to) = _queryBounds();

    final queueParams = SurgeryRequestsParams(
      status: _queueStatusFilter,
      from: from,
      to: to,
      take: 100,
    );
    final scheduleParams = TheatreSchedulesParams(from: from, to: to, take: 100);

    final queueAsync = ref.watch(surgeryRequestsProvider(queueParams));
    final scheduleAsync = ref.watch(theatreSchedulesProvider(scheduleParams));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theatre'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Queue'),
            Tab(text: 'Schedule board'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range_outlined),
            tooltip: 'Date range',
            onPressed: _pickDateRange,
          ),
        ],
      ),
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) => TabBarView(
          controller: _tabController,
          children: [
            _buildQueueTab(context, queueAsync, queueParams),
            _buildScheduleTab(context, scheduleAsync, scheduleParams),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueTab(
    BuildContext context,
    AsyncValue<SurgeryRequestsResponse> queueAsync,
    SurgeryRequestsParams queueParams,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              FilterChip(
                label: const Text('Requested'),
                selected:
                    _queueStatusFilter == SurgeryRequestStatus.requested,
                onSelected: (_) => setState(
                  () => _queueStatusFilter = SurgeryRequestStatus.requested,
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Scheduled'),
                selected:
                    _queueStatusFilter == SurgeryRequestStatus.scheduled,
                onSelected: (_) => setState(
                  () => _queueStatusFilter = SurgeryRequestStatus.scheduled,
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('In progress'),
                selected:
                    _queueStatusFilter == SurgeryRequestStatus.inProgress,
                onSelected: (_) => setState(
                  () => _queueStatusFilter = SurgeryRequestStatus.inProgress,
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Completed'),
                selected:
                    _queueStatusFilter == SurgeryRequestStatus.completed,
                onSelected: (_) => setState(
                  () => _queueStatusFilter = SurgeryRequestStatus.completed,
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Billed'),
                selected: _queueStatusFilter == SurgeryRequestStatus.billed,
                onSelected: (_) => setState(
                  () => _queueStatusFilter = SurgeryRequestStatus.billed,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: queueAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (response) {
              if (response.requests.isEmpty) {
                return Center(
                  child: Text(
                    'No surgery requests',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(surgeryRequestsProvider(queueParams));
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: response.requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final request = response.requests[index];
                    return _RequestCard(
                      request: request,
                      onTap: () => _openRequest(request),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleTab(
    BuildContext context,
    AsyncValue<TheatreSchedulesResponse> scheduleAsync,
    TheatreSchedulesParams scheduleParams,
  ) {
    final theme = Theme.of(context);
    return scheduleAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (response) {
        if (response.schedules.isEmpty) {
          return Center(
            child: Text(
              'No schedules in range',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        final sorted = [...response.schedules]
          ..sort(
            (a, b) =>
                (a.scheduledAt ?? DateTime(1970)).compareTo(
                  b.scheduledAt ?? DateTime(1970),
                ),
          );
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(theatreSchedulesProvider(scheduleParams));
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final schedule = sorted[index];
              final request = schedule.surgeryRequest;
              final patientName =
                  request?.patient?.displayName ??
                  request?.patientId ??
                  'Patient';
              final procedure = request?.service?.name ?? 'Surgery';
              return Card(
                child: ListTile(
                  leading: PatientAvatar(
                    avatarUrl: request?.patient?.avatarUrl,
                    firstName: request?.patient?.firstName,
                    surname: request?.patient?.surname,
                    displayName: patientName,
                    size: 40,
                  ),
                  title: Text(procedure),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(patientName),
                      if (schedule.scheduledAt != null)
                        Text(
                          DateFormatter.dateTime(schedule.scheduledAt!),
                        ),
                      Text(
                        'Room: ${schedule.theatreRoom?.name ?? schedule.theatreRoomId}',
                      ),
                    ],
                  ),
                  trailing: request != null
                      ? TheatreStatusChip(status: request.status)
                      : null,
                  onTap: request != null
                      ? () => context.router.push(
                          TheatreCaseDetailRoute(
                            surgeryRequestId: request.id,
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.onTap,
  });

  final SurgeryRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: PatientAvatar(
          avatarUrl: request.patient?.avatarUrl,
          firstName: request.patient?.firstName,
          surname: request.patient?.surname,
          displayName: request.patient?.displayName ?? request.patientId,
          size: 40,
        ),
        title: Text(request.service?.name ?? 'Surgery request'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(request.patient?.displayName ?? request.patientId),
            if (request.priority != null)
              Text('Priority: ${request.priority!.displayLabel}'),
            if (request.preferredDate != null)
              Text(
                'Preferred: ${DateFormatter.dateTime(request.preferredDate!)}',
              ),
          ],
        ),
        trailing: TheatreStatusChip(status: request.status),
        onTap: onTap,
      ),
    );
  }
}
