// --- MODERN FORM DIALOG ---
import 'package:flutter/material.dart';

import '../models/ward_models.dart';
import '../services/ward_service.dart';
import '../widgets/text_field.dart';

Future<void> showNewPatientInvoiceForm(
  BuildContext context,
  TextEditingController firstName,
  TextEditingController surname,
  TextEditingController age,
  TextEditingController gender,
  TextEditingController wardId,
  Function createNewPatient,
) {
  final colorScheme = Theme.of(context).colorScheme;
  final wardService = WardService();
  final wardsFuture = wardService.fetchWards();

  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: colorScheme.surface,
        titlePadding: const EdgeInsets.all(24),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        actionsPadding: const EdgeInsets.all(24),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "New Patient Record",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => Navigator.pop(context),
              splashRadius: 20,
            ),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Please fill out the patient's basic bio-data.",
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),

                // First Name & Surname Row
                Row(
                  children: [
                    Expanded(
                      child: BuildModernTextField(
                        colorScheme: colorScheme,
                        label: "First Name",
                        hint: "First Name",
                        isNumber: false,
                        controller: firstName,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: BuildModernTextField(
                        colorScheme: colorScheme,
                        label: "Surname",
                        hint: "Surname",
                        isNumber: false,
                        controller: surname,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Age & Sex Row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: BuildModernTextField(
                        colorScheme: colorScheme,
                        label: "Age",
                        hint: "Age",
                        isNumber: true,
                        controller: age,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        initialValue: gender.text.trim().isNotEmpty
                            ? gender.text.trim()
                            : null,
                        decoration: InputDecoration(
                          labelText: "Sex",
                          labelStyle: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          filled: true,
                          fillColor: colorScheme.onSurface.withValues(
                            alpha: 0.02,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: colorScheme.outline.withValues(alpha: 0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: colorScheme.outline.withValues(alpha: 0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: colorScheme.primary),
                          ),
                        ),
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                        items: ['Male', 'Female']
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                        onChanged: (val) {
                          gender.text = val!;
                        },
                      ),
                    ),
                  ],
                ),
                FutureBuilder<List<Ward>>(
                  future: wardsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final wards = snapshot.data ?? const <Ward>[];
                      Ward? opd;
                      for (final w in wards) {
                        if (w.name.trim().toUpperCase() == 'OPD') {
                          opd = w;
                          break;
                        }
                      }
                      wardId.text = opd?.id ?? (wards.isNotEmpty ? wards.first.id : '');
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              firstName.clear();
              surname.clear();
              age.clear();
              gender.clear();
              wardId.clear();
              Navigator.pop(context);
            },
            child: Text(
              "Cancel",
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              createNewPatient();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.check, size: 16, color: Colors.white),
            label: const Text(
              "Render Service",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      );
    },
  );
}
