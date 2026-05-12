import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../models/invoice.dart';
import '../../providers/auth_provider.dart';
import '../../services/invoice_service.dart';

bool patientIdLooksLikeUuid(String s) {
  final trimmed = s.trim();
  return RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  ).hasMatch(trimmed);
}

Invoice? pickOpenInvoice(List<Invoice> invoices) {
  if (invoices.isEmpty) return null;
  final openInvoices = invoices.where((invoice) {
    final status = invoice.status.toUpperCase();
    return status != 'PAID' &&
        status != 'FULLY_PAID' &&
        status != 'CANCELLED' &&
        status != 'VOID';
  }).toList();
  if (openInvoices.isEmpty) return null;
  openInvoices.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return openInvoices.first;
}

/// Resolves an open billing invoice for [patientId] or creates one (requires staff JWT).
Future<String> resolveOrCreateOpenInvoiceId(
  WidgetRef ref,
  String patientId,
) async {
  if (!patientIdLooksLikeUuid(patientId)) {
    throw const ValidationException(
      'Patient must have a server UUID to add invoice lines.',
    );
  }
  final staffId = (ref.read(authProvider).staff?.id ?? '').trim();
  if (staffId.isEmpty) {
    throw const ValidationException('Sign in required to add invoice lines.');
  }
  final svc = InvoiceService();
  final invoices = await svc.getPatientInvoices(patientId);
  final open = pickOpenInvoice(invoices);
  if (open != null) return open.id;
  final created = await svc.createBillingInvoice(
    patientId: patientId,
    staffId: staffId,
  );
  return created.id;
}
