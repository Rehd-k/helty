import 'dart:developer';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'patient_model.dart';
import 'patient_providers.dart';
import '../widgets/responsive_grid.dart';

@RoutePage()
class PatientFormScreen extends ConsumerStatefulWidget {
  final Patient? patient;
  const PatientFormScreen({super.key, this.patient});

  @override
  ConsumerState<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends ConsumerState<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // controllers for all fields

  late TextEditingController _cardNoController;
  late TextEditingController _titleController;
  late TextEditingController _surnameController;
  late TextEditingController _firstNameController;
  late TextEditingController _otherNameController;
  late TextEditingController _dobController;
  late TextEditingController _genderController;
  late TextEditingController _maritalStatusController;
  late TextEditingController _nationalityController;
  late TextEditingController _stateController;
  late TextEditingController _lgaController;
  late TextEditingController _townController;
  late TextEditingController _permanentAddressController;
  late TextEditingController _religionController;
  late TextEditingController _emailController;
  late TextEditingController _preferredLanguageController;
  late TextEditingController _phoneController;
  late TextEditingController _addressOfResidenceController;
  late TextEditingController _professionController;
  late TextEditingController _nextOfKinNameController;
  late TextEditingController _nextOfKinPhoneController;
  late TextEditingController _nextOfKinAddressController;
  late TextEditingController _nextOfKinRelationshipController;
  late TextEditingController _hmoController;
  late TextEditingController _fingerprintController;

  @override
  void initState() {
    super.initState();
    final p = widget.patient;
    _cardNoController = TextEditingController(text: p?.cardNo ?? '');
    _titleController = TextEditingController(text: p?.title ?? '');
    _surnameController = TextEditingController(text: p?.surname);
    _firstNameController = TextEditingController(text: p?.firstName);
    _otherNameController = TextEditingController(text: p?.otherName ?? '');
    _dobController = TextEditingController(
      text: p?.dob.toIso8601String().split('T').first ?? '',
    );
    _genderController = TextEditingController(text: p?.gender);
    _maritalStatusController = TextEditingController(text: p?.maritalStatus);
    _nationalityController = TextEditingController(text: p?.nationality);
    _stateController = TextEditingController(text: p?.stateOfOrigin);
    _lgaController = TextEditingController(text: p?.lga);
    _townController = TextEditingController(text: p?.town);
    _permanentAddressController = TextEditingController(
      text: p?.permanentAddress,
    );
    _religionController = TextEditingController(text: p?.religion ?? '');
    _emailController = TextEditingController(text: p?.email ?? '');
    _preferredLanguageController = TextEditingController(
      text: p?.preferredLanguage ?? '',
    );
    _phoneController = TextEditingController(text: p?.phoneNumber ?? '');
    _addressOfResidenceController = TextEditingController(
      text: p?.addressOfResidence ?? '',
    );
    _professionController = TextEditingController(text: p?.profession ?? '');
    _nextOfKinNameController = TextEditingController(
      text: p?.nextOfKinName ?? '',
    );
    _nextOfKinPhoneController = TextEditingController(
      text: p?.nextOfKinPhone ?? '',
    );
    _nextOfKinAddressController = TextEditingController(
      text: p?.nextOfKinAddress ?? '',
    );
    _nextOfKinRelationshipController = TextEditingController(
      text: p?.nextOfKinRelationship ?? '',
    );
    _hmoController = TextEditingController(text: p?.hmo ?? '');
    _fingerprintController = TextEditingController(
      text: p?.fingerprintData ?? '',
    );
  }

  @override
  void dispose() {
    _cardNoController.dispose();
    _titleController.dispose();
    _surnameController.dispose();
    _firstNameController.dispose();
    _otherNameController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _maritalStatusController.dispose();
    _nationalityController.dispose();
    _stateController.dispose();
    _lgaController.dispose();
    _townController.dispose();
    _permanentAddressController.dispose();
    _religionController.dispose();
    _emailController.dispose();
    _preferredLanguageController.dispose();
    _phoneController.dispose();
    _addressOfResidenceController.dispose();
    _professionController.dispose();
    _nextOfKinNameController.dispose();
    _nextOfKinPhoneController.dispose();
    _nextOfKinAddressController.dispose();
    _nextOfKinRelationshipController.dispose();
    _hmoController.dispose();
    _fingerprintController.dispose();
    super.dispose();
  }

  Future<void> _save(String? patientId) async {
    if (_formKey.currentState?.validate() ?? false) {
      final newPatient = Patient(
        cardNo: _cardNoController.text.trim(),
        title: _titleController.text.trim(),
        surname: _surnameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        otherName: _otherNameController.text.trim().isEmpty
            ? null
            : _otherNameController.text.trim(),
        dob: DateTime.tryParse(_dobController.text) ?? DateTime.now(),
        gender: _genderController.text.trim(),
        maritalStatus: _maritalStatusController.text.trim(),
        nationality: _nationalityController.text.trim(),
        stateOfOrigin: _stateController.text.trim(),
        lga: _lgaController.text.trim(),
        town: _townController.text.trim(),
        permanentAddress: _permanentAddressController.text.trim(),
        religion: _religionController.text.trim().isEmpty
            ? null
            : _religionController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        preferredLanguage: _preferredLanguageController.text.trim().isEmpty
            ? null
            : _preferredLanguageController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        addressOfResidence: _addressOfResidenceController.text.trim().isEmpty
            ? null
            : _addressOfResidenceController.text.trim(),
        profession: _professionController.text.trim().isEmpty
            ? null
            : _professionController.text.trim(),
        nextOfKinName: _nextOfKinNameController.text.trim().isEmpty
            ? null
            : _nextOfKinNameController.text.trim(),
        nextOfKinPhone: _nextOfKinPhoneController.text.trim().isEmpty
            ? null
            : _nextOfKinPhoneController.text.trim(),
        nextOfKinAddress: _nextOfKinAddressController.text.trim().isEmpty
            ? null
            : _nextOfKinAddressController.text.trim(),
        nextOfKinRelationship:
            _nextOfKinRelationshipController.text.trim().isEmpty
            ? null
            : _nextOfKinRelationshipController.text.trim(),
        hmo: _hmoController.text.trim().isEmpty
            ? null
            : _hmoController.text.trim(),
        fingerprintData: _fingerprintController.text.trim().isEmpty
            ? null
            : _fingerprintController.text.trim(),
        patientId: '',
      );

      final service = ref.read(patientServiceProvider);
      try {
        if (widget.patient == null) {
          Patient savedPatient = await service.createPatient(newPatient);
          _showSuccessModal(savedPatient.patientId);
        } else {
          Patient updatedPatient = await service.updatePatient(
            newPatient,
            patientId,
          );
          _showSuccessModal(updatedPatient.patientId);
        }
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _showSuccessModal(String patientId) async {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.green,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Created successfully',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Patient Id - $patientId',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isEditing = widget.patient != null;
    final isFromUnregistered = widget.patient?.fromUnregisteredFlow ?? false;
    log(widget.patient?.toJson().toString() ?? 'No patient');
    return Scaffold(
      backgroundColor: colors.surfaceContainerHighest.withValues(alpha: 0.03),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colors.surface,
        title: Text(
          isEditing
              ? (isFromUnregistered ? 'Register Patient' : 'Edit Patient')
              : 'Register Patient',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ModernFormCard(
                      title: 'Patient Information',
                      leadingIcon: Icons.person_outline,
                      headerAction: IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () {},
                      ),
                      children: [
                        _buildTextField(_cardNoController, 'Card Number'),
                        _buildTextField(_titleController, 'Title'),
                        _buildTextField(
                          _surnameController,
                          'Surname *',
                          required: true,
                          readOnly: widget.patient?.lockNames ?? false,
                        ),
                        _buildTextField(
                          _firstNameController,
                          'First Name *',
                          required: true,
                          readOnly: widget.patient?.lockNames ?? false,
                        ),
                        _buildTextField(_otherNameController, 'Other Name'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ModernFormCard(
                      title: 'Demographics',
                      leadingIcon: Icons.badge_outlined,
                      children: [
                        _buildDateField(
                          _dobController,
                          'Date of Birth',
                          required: true,
                        ),
                        _buildTextField(
                          _genderController,
                          'Gender',
                          required: true,
                        ),
                        _buildTextField(
                          _maritalStatusController,
                          'Marital Status',
                        ),
                        _buildTextField(
                          _nationalityController,
                          'Nationality',
                          required: true,
                        ),
                        _buildTextField(
                          _stateController,
                          'State of Origin',
                          required: true,
                        ),
                        _buildTextField(_lgaController, 'LGA'),
                        _buildTextField(_townController, 'Town'),
                        _buildTextField(
                          _permanentAddressController,
                          'Permanent Address',
                        ),
                        _buildTextField(_religionController, 'Religion'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ModernFormCard(
                      title: 'Contact',
                      leadingIcon: Icons.call_outlined,
                      children: [
                        _buildTextField(
                          _emailController,
                          'Email',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        _buildTextField(
                          _phoneController,
                          'Phone',
                          keyboardType: TextInputType.phone,
                        ),
                        _buildTextField(
                          _preferredLanguageController,
                          'Preferred Language',
                        ),
                        _buildTextField(
                          _addressOfResidenceController,
                          'Address of Residence',
                        ),
                        _buildTextField(_professionController, 'Profession'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ModernFormCard(
                      title: 'Next of Kin',
                      leadingIcon: Icons.family_restroom_outlined,
                      children: [
                        _buildTextField(_nextOfKinNameController, 'Name'),
                        _buildTextField(_nextOfKinPhoneController, 'Phone'),
                        _buildTextField(_nextOfKinAddressController, 'Address'),
                        _buildTextField(
                          _nextOfKinRelationshipController,
                          'Relationship',
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _sectionHeader('Other Info'),
                    ModernFormCard(
                      title: 'Other Info',
                      leadingIcon: Icons.more_horiz,
                      children: [
                        _buildTextField(_hmoController, 'HMO'),
                        _buildFingerprintSection(),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 260),
                        child: ElevatedButton(
                          onPressed: () => _save(widget.patient?.id),
                          style: ElevatedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 16.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            isEditing ? 'Update Patient' : 'Create Patient',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: required
          ? (v) => v == null || v.trim().isEmpty ? 'Required' : null
          : null,
    );
  }

  Widget _buildDateField(
    TextEditingController controller,
    String label, {
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      validator: required
          ? (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (DateTime.tryParse(v) == null) return 'Invalid date';
              return null;
            }
          : null,
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.tryParse(controller.text) ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          controller.text = picked.toIso8601String().split('T').first;
        }
      },
    );
  }

  Widget _buildFingerprintSection() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasFingerprint = _fingerprintController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            colors.primary.withValues(alpha: 0.08),
            colors.primary.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: hasFingerprint
              ? colors.primary
              : colors.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.fingerprint_rounded,
              color: colors.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fingerprint',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasFingerprint
                      ? 'Fingerprint data captured. You can rescan or clear it.'
                      : 'No fingerprint has been captured yet. Place the finger on the scanner to capture.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (hasFingerprint)
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _fingerprintController.clear();
                          });
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Clear'),
                      ),
                    FilledButton.icon(
                      onPressed: () async {
                        setState(() {
                          _fingerprintController.text =
                              'Captured at ${DateTime.now().toIso8601String()}';
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Fingerprint captured (demo only). Integrate with scanner SDK here.',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.fingerprint_rounded),
                      label:
                          Text(hasFingerprint ? 'Rescan' : 'Scan fingerprint'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
