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

  Future<void> _save() async {
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
          await service.createPatient(newPatient);
        } else {
          await service.updatePatient(newPatient);
        }
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.patient != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Patient' : 'Register Patient'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ModernFormCard(
                title: 'Patient Information', // Patient Information
                leadingIcon: Icons.person_outline,
                headerAction: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {},
                ),

                children: [
                  _buildTextField(_cardNoController, 'Card Number'),
                  _buildTextField(_titleController, 'Title'),
                  _buildTextField(
                    _surnameController,
                    'Surname *',
                    required: true,
                  ),
                  _buildTextField(
                    _firstNameController,
                    'First Name *',
                    required: true,
                  ),
                  _buildTextField(_otherNameController, 'Other Name'),
                ],
              ),
              const SizedBox(height: 12),

              ModernFormCard(
                title: 'Demographics',
                children: [
                  _buildDateField(
                    _dobController,
                    'Date of Birth',
                    required: true,
                  ),
                  _buildTextField(_genderController, 'Gender', required: true),
                  _buildTextField(_maritalStatusController, 'Marital Status'),
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

              // other
              const SizedBox(height: 32),
              _sectionHeader('Other Info'),
              ModernFormCard(
                title: 'Other Info',
                children: [
                  _buildTextField(_hmoController, 'HMO'),
                  _buildTextField(_fingerprintController, 'Fingerprint Data'),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity / 2,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(isEditing ? 'Update Patient' : 'Create Patient'),
                ),
              ),
            ],
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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
}
