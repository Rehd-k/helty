import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/app/org_config.dart';
import 'package:helty/src/lab/models/lab_models.dart';
import 'package:helty/src/lab/services/lab_api_service.dart';
import 'package:helty/src/printing/pdf/lab_order_pdf.dart';
import 'package:pdf/pdf.dart';

class SendLabResultsChoice {
  const SendLabResultsChoice({
    required this.sendEmail,
    required this.sendSms,
  });

  final bool sendEmail;
  final bool sendSms;
}

/// Asks which stored contacts should receive the laboratory results.
/// Send stays disabled until at least one available contact is checked.
Future<SendLabResultsChoice?> showSendLabResultsToPatientDialog(
  BuildContext context, {
  required LabOrderPatient patient,
}) {
  return showDialog<SendLabResultsChoice>(
    context: context,
    builder: (context) => _SendLabResultsDialog(patient: patient),
  );
}

/// Builds the same PDF used for printing and emails and/or texts it.
Future<void> sendLabResultsToPatient({
  required LabApiService api,
  required LabOrderPatient patient,
  required List<({LabOrder order, LabOrderItem item})> entries,
  required bool sendEmail,
  required bool sendSms,
}) async {
  if (patient.id.isEmpty) {
    throw StateError('Patient information is missing.');
  }
  if (!sendEmail && !sendSms) {
    throw StateError('Select email, phone, or both.');
  }

  final printable = entries
      .where((entry) => labOrderItemHasPrintableResults(entry.item))
      .toList();
  if (printable.isEmpty) {
    throw StateError('No printable results to send.');
  }

  String? pdfBase64;
  if (sendEmail) {
    final bytes = await buildLabPatientItemsPdf(
      patient: patient,
      entries: printable,
      format: PdfPageFormat.a4,
    );
    if (bytes.isEmpty) {
      throw StateError('No printable results to email.');
    }
    pdfBase64 = base64Encode(bytes);
  }

  String? smsText;
  if (sendSms) {
    final name = patient.capitalizedDisplayName.trim().isNotEmpty
        ? patient.capitalizedDisplayName.trim()
        : patient.displayName.trim();
    smsText = buildLabResultsSmsText(
      orgName: OrgConfig.instance.name,
      patientName: name,
      entries: printable,
    );
  }

  try {
    await api.sendResultsToPatient(
      patientId: patient.id,
      sendEmail: sendEmail,
      sendSms: sendSms,
      pdfBase64: pdfBase64,
      smsText: smsText,
    );
  } on DioException catch (e) {
    throw StateError(labSendErrorText(e));
  }
}

String labSendErrorText(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      final message = data['message'];
      if (message is List) {
        return message.map((part) => part.toString()).join(' ');
      }
      return message.toString();
    }
    final fallback = error.message?.trim();
    if (fallback != null && fallback.isNotEmpty) return fallback;
  }
  if (error is StateError) return error.message;
  return error.toString();
}

/// Plain-text results. The first line is the organization name from env.
String buildLabResultsSmsText({
  required String orgName,
  required String patientName,
  required List<({LabOrder order, LabOrderItem item})> entries,
}) {
  final buffer = StringBuffer()
    ..writeln(orgName.trim().isEmpty ? 'Laboratory results' : orgName.trim())
    ..writeln('Laboratory results');
  if (patientName.trim().isNotEmpty) {
    buffer.writeln(patientName.trim());
  }
  buffer.writeln();

  for (final entry in entries) {
    if (!labOrderItemHasPrintableResults(entry.item)) continue;
    final testName = entry.item.testVersion?.test?.name.trim();
    buffer.writeln(
      testName == null || testName.isEmpty ? 'Test' : testName,
    );

    final lines = entry.item.results
        .where((result) => !result.hiddenFromReport && result.value.trim().isNotEmpty)
        .toList()
      ..sort(
        (a, b) => (a.field?.position ?? 0).compareTo(b.field?.position ?? 0),
      );
    for (final result in lines) {
      final label = result.field?.label.trim();
      final unit = result.field?.unit?.trim();
      final reference = result.field?.referenceRange?.trim();
      final value = result.value.trim();
      final valueWithUnit = unit == null || unit.isEmpty ? value : '$value $unit';
      final name = label == null || label.isEmpty ? 'Result' : label;
      buffer.write('  $name: $valueWithUnit');
      if (reference != null && reference.isNotEmpty) {
        buffer.write(' (ref $reference)');
      }
      buffer.writeln();
    }

    if (entry.item.astRequested && entry.item.astResults.isNotEmpty) {
      final ast = List<LabAstResult>.from(entry.item.astResults)
        ..sort((a, b) {
          final byPosition =
              a.antibiotic.position.compareTo(b.antibiotic.position);
          return byPosition != 0
              ? byPosition
              : a.antibiotic.name.compareTo(b.antibiotic.name);
        });
      buffer.writeln('  Antibiotic susceptibility');
      for (final row in ast) {
        buffer.writeln('  ${row.antibiotic.name}: ${row.resultOption.label}');
      }
    }
    buffer.writeln();
  }

  return buffer.toString().trim();
}

class _SendLabResultsDialog extends StatefulWidget {
  const _SendLabResultsDialog({required this.patient});

  final LabOrderPatient patient;

  @override
  State<_SendLabResultsDialog> createState() => _SendLabResultsDialogState();
}

class _SendLabResultsDialogState extends State<_SendLabResultsDialog> {
  bool _email = false;
  bool _phone = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = widget.patient.email?.trim() ?? '';
    final phone = widget.patient.phoneNumber?.trim() ?? '';
    final hasEmail = email.isNotEmpty;
    final hasPhone = phone.isNotEmpty;
    final canSend = (_email && hasEmail) || (_phone && hasPhone);
    final name = widget.patient.capitalizedDisplayName.trim().isNotEmpty
        ? widget.patient.capitalizedDisplayName.trim()
        : widget.patient.displayName.trim();

    return AlertDialog(
      title: const Text('Send to patient'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (name.isNotEmpty)
              Text(
                name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              'Choose at least one contact on file.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: hasEmail && _email,
              onChanged: hasEmail
                  ? (value) => setState(() => _email = value ?? false)
                  : null,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Email'),
              subtitle: Text(hasEmail ? email : 'No email on file'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: hasPhone && _phone,
              onChanged: hasPhone
                  ? (value) => setState(() => _phone = value ?? false)
                  : null,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Phone'),
              subtitle: Text(hasPhone ? phone : 'No phone number on file'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: canSend
              ? () => Navigator.pop(
                    context,
                    SendLabResultsChoice(
                      sendEmail: _email && hasEmail,
                      sendSms: _phone && hasPhone,
                    ),
                  )
              : null,
          child: const Text('Send'),
        ),
      ],
    );
  }
}
