import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- MOCK DATA MODELS ---
class Patient {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;

  const Patient({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
  });

  String get fullName => '$firstName $lastName';
}

class Doctor {
  final String id;
  final String name;
  final String specialty;

  const Doctor({required this.id, required this.name, required this.specialty});
}

@RoutePage()
class NewAppointmentScreen extends StatefulWidget {
  const NewAppointmentScreen({super.key});

  @override
  State<NewAppointmentScreen> createState() => _NewAppointmentPageState();
}

class _NewAppointmentPageState extends State<NewAppointmentScreen> {
  // Mock Database
  final List<Patient> _mockPatients = [
    const Patient(
      id: 'P01',
      firstName: 'Sarah',
      lastName: 'Jenkins',
      phone: '555-0101',
    ),
    const Patient(
      id: 'P02',
      firstName: 'Michael',
      lastName: 'Scott',
      phone: '555-0102',
    ),
    const Patient(
      id: 'P03',
      firstName: 'Jim',
      lastName: 'Halpert',
      phone: '555-0103',
    ),
    const Patient(
      id: 'P04',
      firstName: 'Pam',
      lastName: 'Beesly',
      phone: '555-0104',
    ),
  ];

  final List<Doctor> _mockDoctors = [
    const Doctor(
      id: 'D01',
      name: 'Dr. Gregory House',
      specialty: 'Diagnostician',
    ),
    const Doctor(
      id: 'D02',
      name: 'Dr. Meredith Grey',
      specialty: 'General Surgery',
    ),
    const Doctor(
      id: 'D03',
      name: 'Dr. Stephen Strange',
      specialty: 'Neurosurgery',
    ),
  ];

  // Form State
  Patient? _selectedPatient;
  Doctor? _selectedDoctor;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _remindSms = true;
  bool _remindEmail = false;
  final TextEditingController _notesController = TextEditingController();

  // UI State
  bool _isConfirmed = false;

  // --- ACTIONS ---

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  void _bookAppointment() {
    if (_selectedPatient == null ||
        _selectedDoctor == null ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please complete all required fields.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Transition to confirmation screen
    setState(() {
      _isConfirmed = true;
    });
  }

  void _resetForm() {
    setState(() {
      _selectedPatient = null;
      _selectedDoctor = null;
      _selectedDate = null;
      _selectedTime = null;
      _notesController.clear();
      _isConfirmed = false;
    });
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.5,
      ),
      appBar: AppBar(
        title: const Text('New Appointment'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          // Kept as a fallback for very small screens, but shouldn't be needed on desktop
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 750,
            ), // Widened to fit side-by-side elements nicely
            child: Card(
              elevation: 4,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              color: colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(
                  24.0,
                ), // Slightly reduced padding to save space
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _isConfirmed
                      ? _buildConfirmationView(colorScheme, textTheme)
                      : _buildFormView(colorScheme, textTheme),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      key: const ValueKey('form'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.edit_calendar,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Schedule Visit',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    'Fill out the details to book a new appointment.',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ROW 1: Patient and Doctor Side-by-Side
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Selection
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Patient Details', Icons.person_outline),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 50, // Fixed height to keep row aligned
                    child: _selectedPatient != null
                        ? _buildPatientPill(colorScheme)
                        : _buildPatientSearch(colorScheme),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Doctor Selection
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    'Assigned Doctor',
                    Icons.medical_services_outlined,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 50,
                    child: _buildDoctorDropdown(colorScheme),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ROW 2: Date & Time and Reminders Side-by-Side
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date & Time
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Date & Time', Icons.schedule),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateTimePickerBtn(
                          icon: Icons.calendar_today,
                          label: _selectedDate == null
                              ? 'Select Date'
                              : DateFormat(
                                  'MMM d, yyyy',
                                ).format(_selectedDate!),
                          onTap: _pickDate,
                          colorScheme: colorScheme,
                          hasValue: _selectedDate != null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDateTimePickerBtn(
                          icon: Icons.access_time,
                          label: _selectedTime == null
                              ? 'Select Time'
                              : _selectedTime!.format(context),
                          onTap: _pickTime,
                          colorScheme: colorScheme,
                          hasValue: _selectedTime != null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Reminders
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    'Reminders',
                    Icons.notifications_active_outlined,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      FilterChip(
                        label: const Text('SMS'),
                        selected: _remindSms,
                        onSelected: (val) => setState(() => _remindSms = val),
                        avatar: Icon(
                          Icons.sms_outlined,
                          size: 16,
                          color: _remindSms
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Email'),
                        selected: _remindEmail,
                        onSelected: (val) => setState(() => _remindEmail = val),
                        avatar: Icon(
                          Icons.email_outlined,
                          size: 16,
                          color: _remindEmail
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Notes
        _buildSectionHeader('Additional Notes', Icons.notes),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 2, // Reduced to save space
          decoration: InputDecoration(
            hintText: 'Reason for visit, specific symptoms, etc.',
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 24),
        const Divider(height: 1),
        const SizedBox(height: 16),

        // Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: _resetForm, child: const Text('Clear')),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _bookAppointment,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Book Appointment'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConfirmationView(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      key: const ValueKey('confirmation'),
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Appointment Confirmed!',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your appointment for ${_selectedPatient?.fullName ?? 'the patient'} has been successfully scheduled.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),

          // Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              children: [
                _summaryRow(
                  Icons.person,
                  'Patient',
                  _selectedPatient?.fullName ?? '',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),
                _summaryRow(
                  Icons.medical_services,
                  'Doctor',
                  _selectedDoctor?.name ?? '',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1),
                ),
                _summaryRow(
                  Icons.event,
                  'Date & Time',
                  '${DateFormat('MMM d, yyyy').format(_selectedDate ?? DateTime.now())} at ${_selectedTime?.format(context) ?? ''}',
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _resetForm,
            icon: const Icon(Icons.add),
            label: const Text('Book Another Appointment'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.grey)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  // --- SUB-WIDGETS ---

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildPatientPill(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: colorScheme.primary,
            child: Text(
              _selectedPatient!.firstName[0],
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _selectedPatient!.fullName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _selectedPatient = null),
            color: colorScheme.onSurfaceVariant,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Remove patient',
          ),
        ],
      ),
    );
  }

  Widget _buildPatientSearch(ColorScheme colorScheme) {
    return Autocomplete<Patient>(
      displayStringForOption: (option) => option.fullName,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<Patient>.empty();
        }
        return _mockPatients.where(
          (patient) => patient.fullName.toLowerCase().contains(
            textEditingValue.text.toLowerCase(),
          ),
        );
      },
      onSelected: (Patient selection) {
        setState(() => _selectedPatient = selection);
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: 'Search patient name...',
            prefixIcon: const Icon(Icons.search, size: 20),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person_outline, size: 18),
                    ),
                    title: Text(
                      option.fullName,
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      option.phone,
                      style: const TextStyle(fontSize: 12),
                    ),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDoctorDropdown(ColorScheme colorScheme) {
    return DropdownButtonFormField<Doctor>(
      decoration: InputDecoration(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant..withValues(alpha: 0.5),
          ),
        ),
      ),
      hint: const Text('Select a Doctor'),
      initialValue: _selectedDoctor,
      icon: const Icon(Icons.expand_more, size: 20),
      items: _mockDoctors.map((doc) {
        return DropdownMenuItem<Doctor>(
          value: doc,
          child: Text(
            '${doc.name} (${doc.specialty})',
            style: const TextStyle(fontSize: 14),
          ),
        );
      }).toList(),
      onChanged: (val) {
        setState(() => _selectedDoctor = val);
      },
    );
  }

  Widget _buildDateTimePickerBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required bool hasValue,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(
        icon,
        size: 16,
        color: hasValue ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: hasValue
              ? colorScheme.onSurface
              : colorScheme.onSurfaceVariant,
          fontWeight: hasValue ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.centerLeft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(
          color: hasValue
              ? colorScheme.primary
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        backgroundColor: hasValue
            ? colorScheme.primaryContainer.withValues(alpha: 0.1)
            : Colors.transparent,
      ),
    );
  }
}
