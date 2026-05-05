import 'package:auto_route/auto_route.dart';
import 'package:country_picker/country_picker.dart' as cp;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:states_and_capitals/states_and_capitals.dart' as sac;

import '../models/hmo_models.dart';
import '../models/ward_models.dart';
import '../services/hmo_service.dart';
import '../services/ward_service.dart';
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
  static const String _nigeriaName = 'Nigeria';
  static const List<String> _titleOptions = <String>[
    'Mr',
    'Miss',
    'Mrs',
    'Master',
    'Dr',
    'Prof',
    'Rev',
  ];
  static const List<String> _genderOptions = <String>[
    'Male',
    'Female',
    'Other',
  ];
  static const List<String> _maritalStatusOptions = <String>[
    'Single',
    'Married',
    'Divorced',
    'Widowed',
    'Separated',
  ];

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
  String? _selectedHmoId;
  List<HmoListItem> _hmoPlans = [];
  bool _loadingHmos = true;
  final WardService _wardService = WardService();
  List<Ward> _wards = [];
  bool _loadingWards = true;
  String? _selectedWardId;
  late TextEditingController _fingerprintController;

  late final List<cp.Country> _countries;
  late final List<sac.State> _nigerianStates;
  List<sac.LGA> _availableLgas = const [];
  sac.State? _selectedNigerianState;
  String? _selectedLgaName;

  /// Text field values as they were after [initState] (for merge-on-save when editing).
  late Map<String, String> _fieldSnapshot;

  /// Ward/HMO picks after async lists finish loading — compared on save to [Patient.wardId] / [Patient.hmoId].
  String? _wardIdBaseline;
  String? _hmoIdBaseline;
  bool _selectionBaselinesReady = false;

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
    _selectedHmoId = p?.hmoId;
    _selectedWardId = p?.wardId;
    _fingerprintController = TextEditingController(
      text: p?.fingerprintData ?? '',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHmoPlans());
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWards());

    _countries = List.of(cp.CountryService().getAll())
      ..sort((a, b) {
        final aIsNigeria = _equalsIgnoreCase(a.name, _nigeriaName);
        final bIsNigeria = _equalsIgnoreCase(b.name, _nigeriaName);
        if (aIsNigeria && !bIsNigeria) return -1;
        if (!aIsNigeria && bIsNigeria) return 1;
        return a.name.compareTo(b.name);
      });

    final nigeriaCountry = sac.StatesAndCapitals.getCountries().firstWhere(
      (country) => _equalsIgnoreCase(country.name, _nigeriaName),
    );
    _nigerianStates = sac.StatesAndCapitals.getStatesInCountry(
      countryId: nigeriaCountry.countryId,
    )..sort((a, b) => a.name.compareTo(b.name));

    _syncLocationSelectionsFromControllers();
    _fieldSnapshot = _snapshotControllers();
  }

  Map<String, String> _snapshotControllers() {
    return {
      'cardNo': _cardNoController.text,
      'title': _titleController.text,
      'surname': _surnameController.text,
      'firstName': _firstNameController.text,
      'otherName': _otherNameController.text,
      'dob': _dobController.text,
      'gender': _genderController.text,
      'maritalStatus': _maritalStatusController.text,
      'nationality': _nationalityController.text,
      'stateOfOrigin': _stateController.text,
      'lga': _lgaController.text,
      'town': _townController.text,
      'permanentAddress': _permanentAddressController.text,
      'religion': _religionController.text,
      'email': _emailController.text,
      'preferredLanguage': _preferredLanguageController.text,
      'phoneNumber': _phoneController.text,
      'addressOfResidence': _addressOfResidenceController.text,
      'profession': _professionController.text,
      'nextOfKinName': _nextOfKinNameController.text,
      'nextOfKinPhone': _nextOfKinPhoneController.text,
      'nextOfKinAddress': _nextOfKinAddressController.text,
      'nextOfKinRelationship': _nextOfKinRelationshipController.text,
      'hmo': _hmoController.text,
      'fingerprint': _fingerprintController.text,
    };
  }

  bool _fieldTextUnchanged(String key, String text) =>
      text.trim() == (_fieldSnapshot[key] ?? '').trim();

  String _mergeRequiredField(
    TextEditingController c,
    String key,
    String server,
  ) {
    if (_fieldTextUnchanged(key, c.text)) return server;
    return c.text.trim();
  }

  String? _mergeOptionalField(
    TextEditingController c,
    String key,
    String? server,
  ) {
    if (_fieldTextUnchanged(key, c.text)) return server;
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  DateTime _mergeDob(TextEditingController c, DateTime server) {
    if (_fieldTextUnchanged('dob', c.text)) return server;
    return DateTime.tryParse(c.text) ?? server;
  }

  void _tryCaptureSelectionBaselines() {
    if (_selectionBaselinesReady || _loadingWards || _loadingHmos) return;
    _wardIdBaseline = _selectedWardId;
    _hmoIdBaseline = _selectedHmoId;
    _selectionBaselinesReady = true;
  }

  Patient _buildPatientForSave() {
    final p = widget.patient;
    if (p == null) {
      return Patient(
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
        hmoId: _selectedHmoId,
        wardId: _selectedWardId,
        ward: () {
          for (final w in _wards) {
            if (w.id == _selectedWardId) return w.name;
          }
          return null;
        }(),
        fingerprintData: _fingerprintController.text.trim().isEmpty
            ? null
            : _fingerprintController.text.trim(),
        patientId: '',
      );
    }

    final mergedWardId =
        _selectionBaselinesReady && _selectedWardId == _wardIdBaseline
        ? p.wardId
        : _selectedWardId;
    final mergedHmoId =
        _selectionBaselinesReady && _selectedHmoId == _hmoIdBaseline
        ? p.hmoId
        : _selectedHmoId;

    String? resolvedWardName = p.ward;
    if (mergedWardId != null) {
      for (final w in _wards) {
        if (w.id == mergedWardId) {
          resolvedWardName = w.name;
          break;
        }
      }
    }

    return Patient(
      id: p.id,
      patientId: p.patientId,
      cardNo: _mergeRequiredField(_cardNoController, 'cardNo', p.cardNo),
      title: _mergeRequiredField(_titleController, 'title', p.title),
      surname: _mergeRequiredField(_surnameController, 'surname', p.surname),
      firstName: _mergeRequiredField(
        _firstNameController,
        'firstName',
        p.firstName,
      ),
      otherName: _mergeOptionalField(
        _otherNameController,
        'otherName',
        p.otherName,
      ),
      dob: _mergeDob(_dobController, p.dob),
      gender: _mergeRequiredField(_genderController, 'gender', p.gender),
      maritalStatus: _mergeRequiredField(
        _maritalStatusController,
        'maritalStatus',
        p.maritalStatus,
      ),
      nationality: _mergeRequiredField(
        _nationalityController,
        'nationality',
        p.nationality,
      ),
      stateOfOrigin: _mergeRequiredField(
        _stateController,
        'stateOfOrigin',
        p.stateOfOrigin,
      ),
      lga: _mergeRequiredField(_lgaController, 'lga', p.lga),
      town: _mergeRequiredField(_townController, 'town', p.town),
      permanentAddress: _mergeRequiredField(
        _permanentAddressController,
        'permanentAddress',
        p.permanentAddress,
      ),
      religion: _mergeOptionalField(
        _religionController,
        'religion',
        p.religion,
      ),
      email: _mergeOptionalField(_emailController, 'email', p.email),
      preferredLanguage: _mergeOptionalField(
        _preferredLanguageController,
        'preferredLanguage',
        p.preferredLanguage,
      ),
      phoneNumber: _mergeOptionalField(
        _phoneController,
        'phoneNumber',
        p.phoneNumber,
      ),
      addressOfResidence: _mergeOptionalField(
        _addressOfResidenceController,
        'addressOfResidence',
        p.addressOfResidence,
      ),
      profession: _mergeOptionalField(
        _professionController,
        'profession',
        p.profession,
      ),
      nextOfKinName: _mergeOptionalField(
        _nextOfKinNameController,
        'nextOfKinName',
        p.nextOfKinName,
      ),
      nextOfKinPhone: _mergeOptionalField(
        _nextOfKinPhoneController,
        'nextOfKinPhone',
        p.nextOfKinPhone,
      ),
      nextOfKinAddress: _mergeOptionalField(
        _nextOfKinAddressController,
        'nextOfKinAddress',
        p.nextOfKinAddress,
      ),
      nextOfKinRelationship: _mergeOptionalField(
        _nextOfKinRelationshipController,
        'nextOfKinRelationship',
        p.nextOfKinRelationship,
      ),
      hmo: _mergeOptionalField(_hmoController, 'hmo', p.hmo),
      hmoId: mergedHmoId,
      hmoProvider: p.hmoProvider,
      fingerprintData: _mergeOptionalField(
        _fingerprintController,
        'fingerprint',
        p.fingerprintData,
      ),
      createdAt: p.createdAt,
      createdBy: p.createdBy,
      updatedAt: p.updatedAt,
      updatedBy: p.updatedBy,
      status: p.status,
      lockNames: p.lockNames,
      fromUnregisteredFlow: p.fromUnregisteredFlow,
      unregisteredTransactionId: p.unregisteredTransactionId,
      ward: resolvedWardName ?? p.ward,
      wardId: mergedWardId,
      bedNumber: p.bedNumber,
      bedId: p.bedId,
      admissionDate: p.admissionDate,
      allergies: p.allergies,
      prescriptionHistory: p.prescriptionHistory,
    );
  }

  Future<void> _loadHmoPlans() async {
    try {
      final r = await HmoService().list(take: 200);
      if (!mounted) return;
      setState(() {
        _hmoPlans = r.items;
        _loadingHmos = false;
        final pat = widget.patient;
        if (pat != null &&
            (_selectedHmoId == null || _selectedHmoId!.isEmpty) &&
            pat.hmoId != null &&
            pat.hmoId!.isNotEmpty) {
          final match = _hmoPlans.where((h) => h.id == pat.hmoId).toList();
          if (match.isNotEmpty) _selectedHmoId = pat.hmoId;
        }
      });
      _tryCaptureSelectionBaselines();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingHmos = false);
      _tryCaptureSelectionBaselines();
    }
  }

  Future<void> _loadWards() async {
    try {
      final wards = await _wardService.fetchWards();
      if (!mounted) return;
      final sorted = [...wards]..sort((a, b) => a.name.compareTo(b.name));
      final defaultOpd = sorted.where(
        (w) => w.name.trim().toUpperCase() == 'OPD',
      );
      final opdId = defaultOpd.isNotEmpty ? defaultOpd.first.id : null;
      final pat = widget.patient;

      setState(() {
        _wards = sorted;
        if (pat == null) {
          _selectedWardId = _selectedWardId ?? opdId;
        } else {
          if (_selectedWardId == null &&
              pat.ward != null &&
              pat.ward!.trim().isNotEmpty) {
            final byName = sorted.where(
              (w) => _equalsIgnoreCase(w.name, pat.ward!.trim()),
            );
            if (byName.isNotEmpty) _selectedWardId = byName.first.id;
          }
          _selectedWardId = _selectedWardId ?? pat.wardId ?? opdId;
        }
        _loadingWards = false;
      });
      _tryCaptureSelectionBaselines();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingWards = false);
      _tryCaptureSelectionBaselines();
    }
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
      final payload = _buildPatientForSave();
      final service = ref.read(patientServiceProvider);
      final routeKey = widget.patient?.id ?? widget.patient?.patientId;
      try {
        if (widget.patient == null) {
          final savedPatient = await service.createPatient(payload);
          await _showSuccessModal(
            isUpdate: false,
            patientId: savedPatient.patientId,
          );
        } else {
          final updatedPatient = await service.updatePatient(payload, routeKey);
          await _showSuccessModal(
            isUpdate: true,
            patientId: updatedPatient.patientId,
          );
        }
        if (!mounted) return;
        Navigator.of(context).pop();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _showSuccessModal({
    required bool isUpdate,
    required String patientId,
  }) async {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final id = patientId.trim();
    final showId = id.isNotEmpty;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: colors.scrim.withValues(alpha: 0.45),
      builder: (dialogContext) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          alignment: Alignment.center,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Material(
              color: colors.surface,
              elevation: 6,
              shadowColor: colors.shadow.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: colors.primaryContainer.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: colors.primary,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isUpdate
                          ? 'Updated successfully'
                          : 'Created successfully',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (showId) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest.withValues(
                            alpha: 0.65,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: colors.outlineVariant.withValues(
                              alpha: 0.45,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Patient ID',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              id,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (isUpdate) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Changes have been saved.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.35,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
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
                    if (isEditing &&
                        (widget.patient?.patientId ?? '')
                            .trim()
                            .isNotEmpty) ...[
                      _buildPatientIdBanner(
                        context,
                        widget.patient!.patientId.trim(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    ModernFormCard(
                      title: 'Patient Information',
                      leadingIcon: Icons.person_outline,
                      headerAction: IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () {},
                      ),
                      children: [
                        _buildTextField(_cardNoController, 'Card Number'),
                        _buildDropdownField(
                          _titleController,
                          'Title',
                          options: _titleOptions,
                        ),
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
                        _buildDropdownField(
                          _genderController,
                          'Gender',
                          required: true,
                          options: _genderOptions,
                        ),
                        _buildDropdownField(
                          _maritalStatusController,
                          'Marital Status',
                          options: _maritalStatusOptions,
                        ),
                        _buildNationalityDropdown(),
                        if (_isNigeriaSelected) ...[
                          _buildNigerianStateDropdown(),
                          _buildNigerianLgaDropdown(),
                        ] else ...[
                          _buildTextField(
                            _stateController,
                            'State of Origin',
                            required: true,
                          ),
                          _buildTextField(_lgaController, 'LGA'),
                        ],
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
                        if (_loadingWards)
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: LinearProgressIndicator(),
                          )
                        else
                          DropdownButtonFormField<String>(
                            key: ValueKey(
                              '${_wards.length}_${_selectedWardId ?? 'none'}',
                            ),
                            initialValue: _selectedWardId,
                            decoration: const InputDecoration(
                              labelText: 'Ward *',
                              border: OutlineInputBorder(),
                              helperText: 'Required. Defaults to OPD',
                            ),
                            isExpanded: true,
                            items: [
                              if (_selectedWardId != null &&
                                  _selectedWardId!.isNotEmpty &&
                                  !_wards.any((w) => w.id == _selectedWardId))
                                DropdownMenuItem<String>(
                                  value: _selectedWardId,
                                  child: Text(
                                    widget.patient?.ward ??
                                        'Current ward (reload lists if needed)',
                                  ),
                                ),
                              ..._wards.map(
                                (w) => DropdownMenuItem<String>(
                                  value: w.id,
                                  child: Text(w.name),
                                ),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => _selectedWardId = v),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        const SizedBox(height: 8),
                        if (_loadingHmos)
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: LinearProgressIndicator(),
                          )
                        else
                          DropdownButtonFormField<String?>(
                            key: ValueKey(
                              '${_hmoPlans.length}_${_selectedHmoId ?? 'none'}',
                            ),
                            initialValue: _selectedHmoId,
                            decoration: const InputDecoration(
                              labelText: 'HMO plan',
                              border: OutlineInputBorder(),
                              helperText: 'Link patient to a configured plan',
                            ),
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('None'),
                              ),
                              if (_selectedHmoId != null &&
                                  _selectedHmoId!.isNotEmpty &&
                                  !_hmoPlans.any((h) => h.id == _selectedHmoId))
                                DropdownMenuItem<String?>(
                                  value: _selectedHmoId,
                                  child: Text(
                                    widget.patient?.hmoProvider?.name ??
                                        widget.patient?.hmo ??
                                        'Current HMO plan',
                                  ),
                                ),
                              ..._hmoPlans.map(
                                (h) => DropdownMenuItem<String?>(
                                  value: h.id,
                                  child: Text(
                                    h.code != null && h.code!.isNotEmpty
                                        ? '${h.name} (${h.code})'
                                        : h.name,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => _selectedHmoId = v),
                          ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          _hmoController,
                          'HMO membership code',
                          required: false,
                        ),
                        _buildFingerprintSection(),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 260),
                        child: ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16.0,
                              horizontal: 16.0,
                            ),
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

  Widget _buildPatientIdBanner(BuildContext context, String patientId) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.secondaryContainer.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.badge_outlined, color: colors.onSecondaryContainer),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Patient ID',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    patientId,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.25,
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

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  String? _matchOptionCaseInsensitive(String value, List<String> options) {
    final t = value.trim().toLowerCase();
    if (t.isEmpty) return null;
    for (final o in options) {
      if (o.toLowerCase() == t) return o;
    }
    return null;
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

  Widget _buildDropdownField(
    TextEditingController controller,
    String label, {
    required List<String> options,
    bool required = false,
  }) {
    final currentValue = controller.text.trim();
    final canonical = _matchOptionCaseInsensitive(currentValue, options);
    final valueForDropdown =
        canonical ??
        (options.contains(currentValue) ? currentValue : null) ??
        (currentValue.isNotEmpty ? currentValue : null);

    final items = <DropdownMenuItem<String>>[
      ...options.map(
        (option) =>
            DropdownMenuItem<String>(value: option, child: Text(option)),
      ),
    ];
    if (valueForDropdown != null &&
        valueForDropdown.isNotEmpty &&
        !items.any(
          (e) => e.value!.toLowerCase() == valueForDropdown.toLowerCase(),
        )) {
      items.insert(
        0,
        DropdownMenuItem<String>(
          value: valueForDropdown,
          child: Text(valueForDropdown),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: valueForDropdown,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      isExpanded: true,
      items: items,
      onChanged: (value) {
        controller.text = value ?? '';
      },
      validator: required
          ? (value) =>
                (value == null || value.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }

  bool get _isNigeriaSelected =>
      _equalsIgnoreCase(_nationalityController.text.trim(), _nigeriaName);

  bool _equalsIgnoreCase(String a, String b) =>
      a.toLowerCase() == b.toLowerCase();

  void _syncLocationSelectionsFromControllers() {
    if (!_isNigeriaSelected) {
      _selectedNigerianState = null;
      _availableLgas = const [];
      _selectedLgaName = null;
      return;
    }

    _selectedNigerianState = _findNigerianStateByName(_stateController.text);
    _refreshLgasForSelectedState(keepCurrentLga: true);
  }

  sac.State? _findNigerianStateByName(String stateName) {
    final normalized = stateName.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    for (final state in _nigerianStates) {
      if (state.name.toLowerCase() == normalized) return state;
    }
    return null;
  }

  void _refreshLgasForSelectedState({required bool keepCurrentLga}) {
    final selectedState = _selectedNigerianState;
    if (selectedState == null) {
      _availableLgas = const [];
      _selectedLgaName = null;
      _lgaController.clear();
      return;
    }

    final nigeriaCountryId = sac.StatesAndCapitals.getCountries()
        .firstWhere((country) => _equalsIgnoreCase(country.name, _nigeriaName))
        .countryId;
    _availableLgas = sac.StatesAndCapitals.getLocalGovernmentsInCountryAndState(
      countryId: nigeriaCountryId,
      stateId: selectedState.stateId,
    )..sort((a, b) => a.name.compareTo(b.name));

    if (keepCurrentLga) {
      final normalizedLga = _lgaController.text.trim().toLowerCase();
      final match = _availableLgas.where(
        (lga) => lga.name.toLowerCase() == normalizedLga,
      );
      _selectedLgaName = match.isNotEmpty ? match.first.name : null;
      return;
    }

    _selectedLgaName = null;
    _lgaController.clear();
  }

  Widget _buildNationalityDropdown() {
    final selectedNationality = _countries.where(
      (country) =>
          country.name.toLowerCase() ==
          _nationalityController.text.trim().toLowerCase(),
    );

    return DropdownButtonFormField<String>(
      initialValue: selectedNationality.isNotEmpty
          ? selectedNationality.first.name
          : null,
      decoration: const InputDecoration(
        labelText: 'Nationality',
        border: OutlineInputBorder(),
      ),
      validator: (value) =>
          (value == null || value.trim().isEmpty) ? 'Required' : null,
      isExpanded: true,
      items: _countries
          .map(
            (country) => DropdownMenuItem<String>(
              value: country.name,
              child: Text(country.name),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _nationalityController.text = value;
          if (_equalsIgnoreCase(value, _nigeriaName)) {
            _selectedNigerianState = _findNigerianStateByName(
              _stateController.text,
            );
            _refreshLgasForSelectedState(keepCurrentLga: true);
          } else {
            _selectedNigerianState = null;
            _selectedLgaName = null;
            _availableLgas = const [];
            _stateController.clear();
            _lgaController.clear();
          }
        });
      },
    );
  }

  Widget _buildNigerianStateDropdown() {
    return DropdownButtonFormField<sac.State>(
      initialValue: _selectedNigerianState,
      decoration: const InputDecoration(
        labelText: 'State of Origin',
        border: OutlineInputBorder(),
      ),
      validator: (value) => value == null ? 'Required' : null,
      isExpanded: true,
      items: _nigerianStates
          .map(
            (state) => DropdownMenuItem<sac.State>(
              value: state,
              child: Text(state.name),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedNigerianState = value;
          _stateController.text = value?.name ?? '';
          _refreshLgasForSelectedState(keepCurrentLga: false);
        });
      },
    );
  }

  Widget _buildNigerianLgaDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedLgaName,
      decoration: const InputDecoration(
        labelText: 'LGA',
        border: OutlineInputBorder(),
      ),
      isExpanded: true,
      items: _availableLgas
          .map(
            (lga) => DropdownMenuItem<String>(
              value: lga.name,
              child: Text(lga.name),
            ),
          )
          .toList(),
      onChanged: _availableLgas.isEmpty
          ? null
          : (value) {
              setState(() {
                _selectedLgaName = value;
                _lgaController.text = value ?? '';
              });
            },
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
                      label: Text(
                        hasFingerprint ? 'Rescan' : 'Scan fingerprint',
                      ),
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
