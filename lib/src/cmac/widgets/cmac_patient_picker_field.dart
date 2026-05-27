import 'dart:async';

import 'package:flutter/material.dart';
import 'package:helty/src/paitients/patient_model.dart';
import 'package:helty/src/paitients/patient_service.dart';

class CmacPatientPickerField extends StatefulWidget {
  const CmacPatientPickerField({
    super.key,
    required this.onSelected,
    this.initialPatientId,
  });

  final void Function(String patientId, String label) onSelected;
  final String? initialPatientId;

  @override
  State<CmacPatientPickerField> createState() => _CmacPatientPickerFieldState();
}

class _CmacPatientPickerFieldState extends State<CmacPatientPickerField> {
  final _controller = TextEditingController();
  final _service = PatientService();
  Timer? _debounce;
  List<Patient> _hits = [];
  bool _loading = false;
  String? _selectedLabel;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.trim().length < 2) {
      setState(() => _hits = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _loading = true);
      try {
        final list = await _service.fetchPatients(
          query: q.trim(),
          take: 15,
          skip: 0,
          isAscending: true,
        );
        if (!mounted) return;
        setState(() {
          _hits = list;
          _loading = false;
        });
      } catch (_) {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: 'Search patient',
            hintText: 'Name or ID (min 2 chars)',
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          onChanged: _onChanged,
        ),
        if (_selectedLabel != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Chip(
              label: Text('Selected: $_selectedLabel'),
              onDeleted: () {
                setState(() {
                  _selectedLabel = null;
                  _controller.clear();
                });
                widget.onSelected('', '');
              },
            ),
          ),
        if (_hits.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: Card(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _hits.length,
                itemBuilder: (_, i) {
                  final p = _hits[i];
                  final label = '${p.firstName} ${p.surname}'.trim();
                  return ListTile(
                    dense: true,
                    title: Text(label),
                    subtitle: Text(p.id ?? ''),
                    onTap: () {
                      final id = p.id ?? '';
                      setState(() {
                        _selectedLabel = label;
                        _hits = [];
                        _controller.text = label;
                      });
                      widget.onSelected(id, label);
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
