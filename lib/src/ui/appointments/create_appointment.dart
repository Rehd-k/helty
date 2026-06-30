import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../helper/date.formatter.dart';
import '../../models/staff_model.dart';
import '../../paitients/patient_model.dart';
import '../../services/appointment_service.dart';
import '../../paitients/patient_service.dart';
import '../../services/staff_service.dart';

@RoutePage()
class NewAppointmentScreen extends StatefulWidget {
  const NewAppointmentScreen({super.key});

  @override
  State<NewAppointmentScreen> createState() => _NewAppointmentPageState();
}

class _NewAppointmentPageState extends State<NewAppointmentScreen> {
  final PatientService _patientService = PatientService();
  final StaffService _staffService = StaffService();
  final AppointmentService _appointmentService = AppointmentService();

  final TextEditingController _patientQueryController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  Timer? _patientDebounce;
  List<Patient> _patientHits = [];
  bool _patientLoading = false;

  List<Staff> _doctors = [];
  bool _loadingDoctors = true;

  Patient? _selectedPatient;
  Staff? _selectedDoctor;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _submitting = false;
  bool _confirmed = false;
  String? _createdAppointmentId;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
    _patientQueryController.addListener(_onPatientQueryChanged);
  }

  @override
  void dispose() {
    _patientDebounce?.cancel();
    _patientQueryController.removeListener(_onPatientQueryChanged);
    _patientQueryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onPatientQueryChanged() {
    _patientDebounce?.cancel();
    final q = _patientQueryController.text.trim();
    if (q.length < 2) {
      setState(() => _patientHits = []);
      return;
    }
    _patientDebounce = Timer(
      const Duration(milliseconds: 400),
      _runPatientSearch,
    );
  }

  Future<void> _runPatientSearch() async {
    final q = _patientQueryController.text.trim();
    if (q.length < 2) return;
    setState(() => _patientLoading = true);
    try {
      final list = await _patientService.fetchPatients(
        query: q,
        take: 20,
        skip: 0,
        isAscending: true,
        sortBy: 'surname',
        listStatusFilter: PatientListStatusFilter.none,
      );
      if (!mounted) return;
      setState(() {
        _patientHits = list;
        _patientLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _patientLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Patient search failed: $e')));
    }
  }

  Future<void> _loadDoctors() async {
    setState(() => _loadingDoctors = true);
    try {
      final list = await _staffService.fetchStaff(
        page: 1,
        limit: 250,
        isActive: true,
      );
      if (!mounted) return;
      setState(() {
        _doctors = list;
        _loadingDoctors = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingDoctors = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not load staff list: $e')));
    }
  }

  String _patientLabel(Patient p) => p.displayName;

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  DateTime? _combinedDateTime() {
    final d = _selectedDate;
    final t = _selectedTime;
    if (d == null || t == null) return null;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  Future<void> _submit() async {
    final dt = _combinedDateTime();
    if (_selectedPatient?.id == null || _selectedDoctor == null || dt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select patient, doctor, date, and time.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final created = await _appointmentService.createAppointment(
        patientId: _selectedPatient!.id!,
        staffId: _selectedDoctor!.id,
        appointmentDate: dt.toUtc(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _confirmed = true;
        _createdAppointmentId = created.id;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create appointment: $e')),
      );
    }
  }

  void _resetForm() {
    setState(() {
      _selectedPatient = null;
      _selectedDoctor = null;
      _selectedDate = null;
      _selectedTime = null;
      _notesController.clear();
      _patientQueryController.clear();
      _patientHits = [];
      _confirmed = false;
      _createdAppointmentId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: _confirmed
                      ? _buildSuccessCard(colorScheme, textTheme)
                      : _buildFormCard(colorScheme, textTheme),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 720;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.event_available_rounded,
                      color: colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Schedule a visit',
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Search a registered patient, pick a clinician, and choose a slot.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _patientBlock(colorScheme)),
                      const SizedBox(width: 20),
                      Expanded(child: _doctorBlock(colorScheme)),
                    ],
                  )
                else ...[
                  _patientBlock(colorScheme),
                  const SizedBox(height: 20),
                  _doctorBlock(colorScheme),
                ],
                const SizedBox(height: 20),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _dateTimeBlock(colorScheme)),
                      const SizedBox(width: 20),
                      Expanded(child: _notesBlock(colorScheme)),
                    ],
                  )
                else ...[
                  _dateTimeBlock(colorScheme),
                  const SizedBox(height: 16),
                  _notesBlock(colorScheme),
                ],
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _submitting ? null : _resetForm,
                      child: const Text('Clear'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(
                        _submitting ? 'Booking…' : 'Book appointment',
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _patientBlock(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Patient', Icons.person_outline_rounded, colorScheme),
        const SizedBox(height: 10),
        if (_selectedPatient != null)
          _patientChip(colorScheme)
        else ...[
          TextField(
            controller: _patientQueryController,
            decoration: InputDecoration(
              hintText: 'Type at least 2 letters to search…',
              prefixIcon: const Icon(Icons.search_rounded, size: 22),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.45,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_patientLoading)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (_patientHits.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Material(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _patientHits.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                    itemBuilder: (context, i) {
                      final p = _patientHits[i];
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primaryContainer,
                          child: Text(
                            p.firstName.isNotEmpty
                                ? p.firstName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        title: Text(
                          _patientLabel(p),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'ID: ${p.patientId.isEmpty ? (p.id ?? '—') : p.patientId}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedPatient = p;
                            _patientHits = [];
                            _patientQueryController.clear();
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _patientChip(ColorScheme colorScheme) {
    final p = _selectedPatient!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colorScheme.primary,
            child: Text(
              p.firstName.isNotEmpty ? p.firstName[0].toUpperCase() : '?',
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _patientLabel(p),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Patient ID: ${p.patientId.isEmpty ? '—' : p.patientId}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Change patient',
            onPressed: () => setState(() => _selectedPatient = null),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _doctorBlock(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(
          'Clinician',
          Icons.medical_services_outlined,
          colorScheme,
        ),
        const SizedBox(height: 10),
        if (_loadingDoctors)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
        else
          InputDecorator(
            decoration: InputDecoration(
              hintText: 'Select doctor / consultant',
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.45,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Staff>(
                isExpanded: true,
                hint: const Text('Select doctor / consultant'),
                value: _selectedDoctor,
                items: _doctors
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(
                          '${s.firstName} ${s.lastName} · ${s.staffRole}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedDoctor = v),
              ),
            ),
          ),
      ],
    );
  }

  Widget _dateTimeBlock(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Date & time', Icons.schedule_rounded, colorScheme),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _dtButton(
                colorScheme,
                icon: Icons.calendar_month_rounded,
                label: _selectedDate == null
                    ? 'Date'
                    : DateFormat('EEE, MMM d').format(_selectedDate!),
                filled: _selectedDate != null,
                onTap: _pickDate,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _dtButton(
                colorScheme,
                icon: Icons.schedule_rounded,
                label: _selectedTime == null
                    ? 'Time'
                    : _selectedTime!.format(context),
                filled: _selectedTime != null,
                onTap: _pickTime,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _notesBlock(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Notes', Icons.notes_rounded, colorScheme),
        const SizedBox(height: 10),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Reason for visit, instructions…',
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.45,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _dtButton(
    ColorScheme colorScheme, {
    required IconData icon,
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return FilledButton.tonal(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: filled
            ? colorScheme.primaryContainer.withValues(alpha: 0.55)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        foregroundColor: colorScheme.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: filled
                ? colorScheme.primary.withValues(alpha: 0.45)
                : colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: filled ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String title, IconData icon, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: colorScheme.onSurface,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessCard(ColorScheme colorScheme, TextTheme textTheme) {
    final dt = _combinedDateTime();
    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 28),
        child: Column(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 56,
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Appointment booked',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The visit has been saved to the server.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (_createdAppointmentId != null) ...[
              const SizedBox(height: 8),
              SelectableText(
                'Ref: $_createdAppointmentId',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _summaryLine(
                    Icons.person_rounded,
                    'Patient',
                    _selectedPatient != null
                        ? _patientLabel(_selectedPatient!)
                        : '—',
                  ),
                  const Divider(height: 24),
                  _summaryLine(
                    Icons.medical_information_outlined,
                    'Clinician',
                    _selectedDoctor != null
                        ? '${_selectedDoctor!.firstName} ${_selectedDoctor!.lastName}'
                        : '—',
                  ),
                  const Divider(height: 24),
                  _summaryLine(
                    Icons.event_rounded,
                    'When',
                    dt != null
                        ? '${DateFormatter.fullDate(dt)} · ${DateFormat.jm().format(dt)}'
                        : '—',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.tonalIcon(
              onPressed: _resetForm,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Schedule another'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryLine(IconData icon, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: scheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
