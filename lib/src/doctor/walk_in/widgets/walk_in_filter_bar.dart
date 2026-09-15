import 'package:flutter/material.dart';

import '../../../helper/theme.dart';
import '../../../models/consulting_room_model.dart';
import '../../../services/department_service.dart';
import '../../../widgets/date.filter.dart';
import '../walk_in_queue_metrics.dart';

/// Compact one-line search + consulting room, department, status.
/// Date range (and extra filters on small screens) live in the filter menu.
class WalkInFilterBar extends StatelessWidget {
  const WalkInFilterBar({
    super.key,
    required this.searchController,
    required this.consultingRooms,
    required this.selectedRoom,
    required this.onRoomChanged,
    required this.loadingRooms,
    required this.departments,
    required this.selectedDepartmentId,
    required this.onDepartmentChanged,
    required this.statusValue,
    required this.onStatusChanged,
    required this.onDateFilterChanged,
    required this.onDateRefresh,
    required this.compact,
    this.fromDate,
    this.toDate,
    this.onOpenFilterMenu,
  });

  final TextEditingController searchController;
  final List<ConsultingRoomModel> consultingRooms;
  final ConsultingRoomModel? selectedRoom;
  final ValueChanged<ConsultingRoomModel?> onRoomChanged;
  final bool loadingRooms;
  final List<Department> departments;
  final String? selectedDepartmentId;
  final ValueChanged<String?> onDepartmentChanged;
  final String statusValue;
  final ValueChanged<String> onStatusChanged;
  final void Function(
    String query,
    String category,
    DateTime? from,
    DateTime? to,
  )
  onDateFilterChanged;
  final VoidCallback onDateRefresh;
  final bool compact;
  final DateTime? fromDate;
  final DateTime? toDate;
  final VoidCallback? onOpenFilterMenu;

  InputDecoration _decoration(
    BuildContext context, {
    required String label,
    required Color iconColor,
    IconData? icon,
    String? hint,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      prefixIcon: icon == null
          ? null
          : Padding(
              padding: const EdgeInsets.all(6),
              child: WalkInSolidIcon(
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

  Widget _searchField(BuildContext context) {
    return TextField(
      controller: searchController,
      decoration: _decoration(
        context,
        label: 'Search',
        hint: 'Name, ID, phone, or reason…',
        icon: Icons.search,
        iconColor: WalkInQueueMetrics.iconIndigo,
      ),
      style: const TextStyle(fontSize: 12),
    );
  }

  Widget _roomDropdown(BuildContext context) {
    return DropdownButtonFormField<ConsultingRoomModel?>(
      key: ValueKey('room-${selectedRoom?.id ?? 'all'}'),
      initialValue: selectedRoom,
      isExpanded: true,
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: _decoration(
        context,
        label: 'Consulting Room',
        icon: Icons.meeting_room_outlined,
        iconColor: WalkInQueueMetrics.iconBlue,
      ),
      items: [
        const DropdownMenuItem<ConsultingRoomModel?>(
          value: null,
          child: Text('All rooms', overflow: TextOverflow.ellipsis),
        ),
        ...consultingRooms.map(
          (room) => DropdownMenuItem<ConsultingRoomModel?>(
            value: room,
            child: Text(room.name, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: loadingRooms ? null : onRoomChanged,
    );
  }

  Widget _departmentDropdown(BuildContext context) {
    return DropdownButtonFormField<String?>(
      key: ValueKey('dept-${selectedDepartmentId ?? 'all'}'),
      initialValue: selectedDepartmentId,
      isExpanded: true,
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: _decoration(
        context,
        label: 'Department',
        icon: Icons.apartment_outlined,
        iconColor: WalkInQueueMetrics.iconPink,
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('All Departments', overflow: TextOverflow.ellipsis),
        ),
        ...departments.map(
          (d) => DropdownMenuItem<String?>(
            value: d.id,
            child: Text(d.name, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: onDepartmentChanged,
    );
  }

  Widget _statusDropdown(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey('status-$statusValue'),
      initialValue: statusValue,
      isExpanded: true,
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: _decoration(
        context,
        label: 'Status',
        icon: Icons.flag_outlined,
        iconColor: WalkInQueueMetrics.waitAmber,
      ),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('All Statuses')),
        DropdownMenuItem(value: 'waiting', child: Text('Waiting')),
        DropdownMenuItem(
          value: 'inConsultation',
          child: Text('In Consultation'),
        ),
      ],
      onChanged: (v) {
        if (v != null) onStatusChanged(v);
      },
    );
  }

  Widget _dateFilter() {
    return FromToDateFilter(
      doRefresh: onDateRefresh,
      dateFilter: true,
      notifyOnInit: false,
      initialFrom: fromDate,
      initialTo: toDate,
      onFilterChanged: onDateFilterChanged,
    );
  }

  Widget filterMenuBody(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (compact) ...[
          _roomDropdown(context),
          const SizedBox(height: 10),
          _departmentDropdown(context),
          const SizedBox(height: 10),
          _statusDropdown(context),
          const SizedBox(height: 12),
        ],
        Text(
          'Date range',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        _dateFilter(),
      ],
    );
  }

  Widget _filterIconButton({VoidCallback? onPressed}) {
    return IconButton(
      tooltip: 'Filters',
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: const WalkInSolidIcon(
        icon: Icons.tune,
        color: WalkInQueueMetrics.iconPurple,
        size: 32,
        iconSize: 16,
        radius: 8,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filterButton = _filterIconButton(
      onPressed: onOpenFilterMenu ?? () => showWalkInFilterMenu(context, this),
    );

    if (compact) {
      return Row(
        children: [
          Expanded(child: _searchField(context)),
          const SizedBox(width: 8),
          filterButton,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 3, child: _searchField(context)),
        const SizedBox(width: 8),
        Expanded(flex: 2, child: _roomDropdown(context)),
        const SizedBox(width: 8),
        Expanded(flex: 2, child: _departmentDropdown(context)),
        const SizedBox(width: 8),
        Expanded(flex: 2, child: _statusDropdown(context)),
        const SizedBox(width: 8),
        filterButton,
      ],
    );
  }
}

Future<void> showWalkInFilterMenu(
  BuildContext context,
  WalkInFilterBar filterBar,
) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.18),
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return Dialog(
        alignment: Alignment.topRight,
        insetPadding: const EdgeInsets.fromLTRB(16, 88, 16, 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const WalkInSolidIcon(
                      icon: Icons.tune,
                      color: WalkInQueueMetrics.iconPurple,
                    ),
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
                      onPressed: () => Navigator.of(ctx).maybePop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: filterBar.filterMenuBody(ctx),
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
