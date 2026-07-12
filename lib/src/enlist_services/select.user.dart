import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/services/api_service.dart';
import 'package:helty/src/widgets/empty.widget.dart';

import '../../app_router.gr.dart';
import '../billings/patient_invoice.dart';
import '../paitients/patient_model.dart';
import '../widgets/patients.tiles.dart';

class SelectUser extends StatefulWidget {
  final List<Patient> patients;
  final ValueChanged<String> onSearch;
  final ValueChanged<Patient> onPatientSelected;
  final ValueChanged<Map<String, dynamic>>? selectNoIdUser;
  final String serviceName;

  const SelectUser({
    super.key,
    required this.patients,
    required this.onSearch,
    required this.onPatientSelected,
    this.selectNoIdUser,
    required this.serviceName,
  });

  @override
  State<SelectUser> createState() => _SelectUserState();
}

class _SelectUserState extends State<SelectUser> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ApiService apiService = ApiService();

  final TextEditingController firstName = TextEditingController();
  final TextEditingController surname = TextEditingController();
  final TextEditingController age = TextEditingController();
  final TextEditingController gender = TextEditingController();
  final TextEditingController wardId = TextEditingController();

  bool _isSearching = false;

  bool get _allowQuickNewPatient =>
      widget.serviceName == 'OPD' ||
      widget.serviceName == 'Radiology' ||
      widget.serviceName == 'lab' ||
      widget.serviceName == 'ED';

  void createNewPatient() async {
    if (wardId.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a ward')),
      );
      return;
    }
    try {
      var newUser = await apiService.dio.post(
        '/patients',
        data: {
          'firstName': firstName.text,
          'surname': surname.text,
          'age': age.text,
          'gender': gender.text,
          'wardId': wardId.text.trim(),
        },
      );

      widget.onPatientSelected(
        Patient.fromJson(newUser.data as Map<String, dynamic>),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildContent() {
    if (!_isSearching && _searchCtrl.text.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.search_rounded,
        title: "Start Searching",
        message: "Find a patient to view pending bills and encounters.",
      );
    }
    if (widget.patients.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.person_off_outlined,
        title: "Oops, such empty",
        message: "We couldn't find any patient matching '${_searchCtrl.text}'.",
        buttonText: _allowQuickNewPatient
            ? "Register New Patient"
            : "Go Back",
        onPressed: () => _allowQuickNewPatient
            ? context.router.push(PatientFormRoute())
            : context.router.pop(),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: widget.patients.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return PatientTile(
          patient: widget.patients[index],
          onTap: () => widget.onPatientSelected(widget.patients[index]),
        );
      },
    );
  }

  Widget _buildNewPatientButton() {
    return ElevatedButton.icon(
      onPressed: () => showNewPatientInvoiceForm(
        context,
        firstName,
        surname,
        age,
        gender,
        wardId,
        createNewPatient,
      ),
      icon: const Icon(
        Icons.person_add_alt_1_rounded,
        size: 16,
      ),
      label: const Text(
        "New Patient",
        style: TextStyle(fontSize: 13),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  Widget _buildHeader(bool compact) {
    final titleRow = Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.person_search_rounded, size: 20),
        ),
        const SizedBox(width: 12),
        const Text(
          'Find Patient',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (!compact && _allowQuickNewPatient) ...[
          const Spacer(),
          _buildNewPatientButton(),
        ],
      ],
    );

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (compact && _allowQuickNewPatient) ...[
            titleRow,
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: _buildNewPatientButton(),
            ),
          ] else
            titleRow,
          const SizedBox(height: 16),
          TextField(
            controller: _searchCtrl,
            onChanged: (val) {
              setState(() {
                _isSearching = val.isNotEmpty;
              });
              widget.onSearch(val);
            },
            decoration: InputDecoration(
              hintText: "Name, ID, or Phone number...",
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              border: InputBorder.none,
              prefixIcon: const Icon(
                Icons.search,
                color: Colors.grey,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.fingerprint),
                onPressed: () {},
                tooltip: "Scan Fingerprint",
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard(bool compact, {required bool boundedHeight}) {
    final content = _buildContent();
    final card = Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(compact),
          const Divider(height: 1),
          if (boundedHeight)
            Expanded(child: content)
          else
            SizedBox(
              height: _fallbackListHeight(context),
              child: content,
            ),
        ],
      ),
    );

    if (boundedHeight) {
      return Expanded(child: card);
    }
    return card;
  }

  double _fallbackListHeight(BuildContext context) {
    final media = MediaQuery.of(context);
    const chrome = 220.0;
    final available = media.size.height - media.padding.vertical - chrome;
    return (available * 0.55).clamp(280, 600);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < AppBreakpoints.tabletMin;
        final boundedHeight = constraints.maxHeight.isFinite;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSearchCard(compact, boundedHeight: boundedHeight),
          ],
        );
      },
    );
  }
}
