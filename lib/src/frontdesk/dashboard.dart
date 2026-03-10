import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../app_router.gr.dart';

@RoutePage()
class FrontDeskDashboardScreen extends StatefulWidget {
  const FrontDeskDashboardScreen({super.key});

  @override
  State<FrontDeskDashboardScreen> createState() => _FrontDeskDashboardState();
}

class _FrontDeskDashboardState extends State<FrontDeskDashboardScreen> {
  // Calendar State
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Mock Data for Appointments (Used for the Calendar)
  final Map<DateTime, int> _appointmentCounts = {
    DateTime.now(): 12,
    DateTime.now().add(const Duration(days: 1)): 5,
    DateTime.now().add(const Duration(days: 2)): 8,
  };

  // Mock Data for Live Patient Queue
  final List<Map<String, dynamic>> _patients = [
    {
      'id': '#45821',
      'initials': 'SJ',
      'name': 'Mathew ThankGod',
      'time': '09:30 AM',
      'doctor': 'Dr. Udo',
      'status': 'With Doctor',
      'room': 'Room 304',
      'enlisted': true,
      'color': Colors.blue,
    },
    {
      'id': '#45822',
      'initials': 'MC',
      'name': 'Michael kalu',
      'time': '09:45 AM',
      'doctor': 'Dr. Ben Johnson',
      'status': 'Waiting',
      'room': 'Lobby Area B',
      'enlisted': false,
      'color': Colors.orange,
    },
    {
      'id': '#45823',
      'initials': 'ER',
      'name': 'Emma Chibueze',
      'time': '10:00 AM',
      'doctor': 'Dr. Victor Chris',
      'status': 'Checked In',
      'room': 'Room 305',
      'enlisted': true,
      'color': Colors.green,
    },
    {
      'id': '#45824',
      'initials': 'DK',
      'name': 'David Kimberly',
      'time': '10:15 AM',
      'doctor': 'Dr. James',
      'status': 'Scheduled',
      'room': '-',
      'enlisted': false,
      'color': Colors.grey,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  // Handle Right Click or Menu Tap
  void _showPatientActions(BuildContext context, Offset position, int index) {
    final patient = _patients[index];
    final bool isEnlisted = patient['enlisted'];

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          value: 'enlist_consult',
          child: Text(
            isEnlisted ? "DeEnlist" : "Enlist For Consultation",
            style: TextStyle(
              fontSize: 12, // Reduced font
              color: isEnlisted
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const PopupMenuItem(
          value: 'enlist_pharmacy',
          child: Text("Enlist for pharmacy", style: TextStyle(fontSize: 12)),
        ),
        const PopupMenuItem(
          value: 'bio_data',
          child: Text("Patient Bio Data", style: TextStyle(fontSize: 12)),
        ),
        const PopupMenuItem(
          value: 'ward_rounds',
          child: Text("Ward Rounds", style: TextStyle(fontSize: 12)),
        ),
        const PopupMenuItem(
          value: 'consults',
          child: Text("Consults", style: TextStyle(fontSize: 12)),
        ),
        const PopupMenuItem(
          value: 'transactions',
          child: Text("Transactions", style: TextStyle(fontSize: 12)),
        ),
      ],
    ).then((value) {
      if (!mounted) return;
      if (value == 'enlist_consult') {
        setState(() {
          _patients[index]['enlisted'] = !isEnlisted;
        });
      } else if (value == 'ward_rounds') {
        context.router.push(const InpatientsListRoute());
      }
      // Handle other actions here...
    });
  }

  // Show dialog when calendar day is double-clicked
  void _showDayAppointments(DateTime day) {
    int count = _getEventsForDay(day);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Appointments on ${DateFormat('MMM d, yyyy').format(day)}'),
        content: count > 0
            ? Text(
                'There are $count appointments scheduled for this date.',
                style: const TextStyle(fontSize: 14),
              )
            : const Text(
                'No appointments scheduled for this date.',
                style: TextStyle(fontSize: 14),
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

  int _getEventsForDay(DateTime day) {
    // Normalize dates to ignore time for matching
    final normalizedDay = DateTime(day.year, day.month, day.day);
    for (var key in _appointmentCounts.keys) {
      if (DateTime(key.year, key.month, key.day) == normalizedDay) {
        return _appointmentCounts[key]!;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column
            Expanded(
              flex: 7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome back, Sarah. Here is the overview for today.",
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 13, // Reduced font
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stat Cards Row
                  Row(
                    children: [
                      _buildStatCard(
                        context,
                        "Today's Appointments",
                        "142",
                        "+5%",
                        Icons.calendar_today,
                        Colors.blue,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        context,
                        "Checked-In",
                        "89",
                        "+12%",
                        Icons.check_circle_outline,
                        Colors.green,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        context,
                        "Waiting Room",
                        "12",
                        "-3%",
                        Icons.hourglass_empty,
                        Colors.orange,
                        isNegative: true,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        context,
                        "Discharged",
                        "45",
                        "+8%",
                        Icons.logout,
                        Colors.purple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Live Patient Queue Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Live Patient Queue",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.filter_list, size: 16),
                            label: const Text(
                              "Filter",
                              style: TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              minimumSize: Size.zero,
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text(
                              "Refresh",
                              style: TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              minimumSize: Size.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Patient Table
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Table Header
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  "Patient Name",
                                  style: _headerStyle(colorScheme),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "Time",
                                  style: _headerStyle(colorScheme),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "Doctor",
                                  style: _headerStyle(colorScheme),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "Status",
                                  style: _headerStyle(colorScheme),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "Assigned Room",
                                  style: _headerStyle(colorScheme),
                                ),
                              ),
                              const SizedBox(width: 48), // Action space
                            ],
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),

                        // Table Rows
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _patients.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: colorScheme.outline.withValues(alpha: 0.1),
                          ),
                          itemBuilder: (context, index) {
                            final patient = _patients[index];
                            return GestureDetector(
                              // Right click (desktop)
                              onSecondaryTapDown: (details) =>
                                  _showPatientActions(
                                    context,
                                    details.globalPosition,
                                    index,
                                  ),
                              // Long press (mobile alternative)
                              onLongPressStart: (details) =>
                                  _showPatientActions(
                                    context,
                                    details.globalPosition,
                                    index,
                                  ),
                              child: InkWell(
                                onTap: () {}, // Handled just for ripple effect
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      // Name & Initials
                                      Expanded(
                                        flex: 3,
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: patient['color']
                                                  .withOpacity(0.1),
                                              child: Text(
                                                patient['initials'],
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: patient['color'],
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  patient['name'],
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color:
                                                        colorScheme.onSurface,
                                                  ),
                                                ),
                                                Text(
                                                  "ID: ${patient['id']}",
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: colorScheme.onSurface
                                                        .withValues(alpha: 0.5),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Time
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          patient['time'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colorScheme.onSurface
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ),
                                      // Doctor
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          patient['doctor'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colorScheme.onSurface
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ),
                                      // Status Badge
                                      Expanded(
                                        flex: 2,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: patient['color']
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              patient['status'],
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: patient['color'],
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Room
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          patient['room'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colorScheme.onSurface
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ),
                                      // Action Icon / Quick check-in link
                                      SizedBox(
                                        width: 48,
                                        child: patient['status'] == 'Scheduled'
                                            ? InkWell(
                                                onTap: () {},
                                                child: Text(
                                                  "Check\nIn",
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: colorScheme.primary,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              )
                                            : IconButton(
                                                icon: const Icon(
                                                  Icons.more_vert,
                                                  size: 18,
                                                ),
                                                onPressed: () {
                                                  // Calculate position for the popup menu based on context
                                                  final RenderBox renderBox =
                                                      context.findRenderObject()
                                                          as RenderBox;
                                                  final position = renderBox
                                                      .localToGlobal(
                                                        Offset.zero,
                                                      );
                                                  _showPatientActions(
                                                    context,
                                                    position,
                                                    index,
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
                        ),

                        // Pagination / Footer
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Showing 4 of 28 patients",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () {},
                                    child: const Text(
                                      "Previous",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {},
                                    child: const Text(
                                      "Next",
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),

            // Right Column
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  // Quick Actions Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Quick Actions",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.router.push(PatientFormRoute());
                          },
                          icon: const Icon(
                            Icons.person_add,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "Register New Patient",
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            context.router.push(NewAppointmentRoute());
                          },
                          icon: Icon(
                            Icons.calendar_month,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          label: Text(
                            "Book Appointment",
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: Icon(
                            Icons.login,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          label: Text(
                            "Check-In Patient",
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Calendar Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // We use a Builder to provide custom double-tap gesture wraps over the calendar
                        TableCalendar(
                          firstDay: DateTime.utc(2020, 10, 16),
                          lastDay: DateTime.utc(2030, 3, 14),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) =>
                              isSameDay(_selectedDay, day),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          calendarFormat: CalendarFormat.month,
                          headerStyle: HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: false,
                            titleTextStyle: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            leftChevronIcon: const Icon(
                              Icons.chevron_left,
                              size: 20,
                            ),
                            rightChevronIcon: const Icon(
                              Icons.chevron_right,
                              size: 20,
                            ),
                          ),
                          daysOfWeekStyle: DaysOfWeekStyle(
                            weekdayStyle: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            weekendStyle: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          calendarBuilders: CalendarBuilders(
                            // Adding custom builder to intercept double taps while preserving standard UI
                            defaultBuilder: (context, day, focusedDay) {
                              return GestureDetector(
                                onDoubleTap: () => _showDayAppointments(day),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              );
                            },
                            selectedBuilder: (context, day, focusedDay) {
                              return GestureDetector(
                                onDoubleTap: () => _showDayAppointments(day),
                                child: Container(
                                  margin: const EdgeInsets.all(6.0),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${day.day}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            },
                            todayBuilder: (context, day, focusedDay) {
                              return GestureDetector(
                                onDoubleTap: () => _showDayAppointments(day),
                                child: Container(
                                  margin: const EdgeInsets.all(6.0),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                            markerBuilder: (context, day, events) {
                              int count = _getEventsForDay(day);
                              if (count > 0) {
                                return Positioned(
                                  bottom: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: colorScheme.secondary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '$count',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Doctors on duty",
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                            Text(
                              "12",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recent Activity Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Recent Activity",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              "View All",
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildActivityItem(
                          context,
                          "Check-in Complete",
                          "Emma Rodriguez - Dr. Lee",
                          "2 mins ago",
                          Colors.green,
                        ),
                        _buildActivityItem(
                          context,
                          "New Appointment",
                          "John Doe - Cardiology",
                          "15 mins ago",
                          Colors.blue,
                        ),
                        _buildActivityItem(
                          context,
                          "Wait Time Alert",
                          "Pediatrics Queue > 20m",
                          "1 hour ago",
                          Colors.orange,
                        ),
                        _buildActivityItem(
                          context,
                          "Shift Change",
                          "Nurse Station A",
                          "2 hours ago",
                          Colors.grey,
                          isLast: true,
                        ),
                      ],
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

  // Helper Widget for Stat Cards
  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    String change,
    IconData icon,
    Color iconColor, {
    bool isNegative = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                Text(
                  change,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isNegative ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget for Activity Timeline
  Widget _buildActivityItem(
    BuildContext context,
    String title,
    String subtitle,
    String time,
    Color dotColor, {
    bool isLast = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              if (!isLast) const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  TextStyle _headerStyle(ColorScheme colorScheme) {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface.withValues(alpha: 0.5),
    );
  }
}
