import 'package:flutter/material.dart';

import '../../models/bank_model.dart';
import '../../models/invoice.dart';
import '../../services/bank_service.dart';
import 'receipt_escpos_service.dart';
import 'receipt_printer_picker_sheet.dart';

final Set<String> _inFlightInvoiceIds = <String>{};

/// Loads every registered bank, then opens the thermal printer picker.
///
/// A failed bank request does not print a slip with no accounts.
Future<void> printUnpaidInvoice(BuildContext context, Invoice invoice) async {
  if (!_inFlightInvoiceIds.add(invoice.id)) return;

  final navigator = Navigator.of(context, rootNavigator: true);
  final route = DialogRoute<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return const PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 16),
                  Text('Loading bank accounts'),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
  try {
    navigator.push(route);

    final List<BankModel> banks;
    try {
      banks = await BankService().fetchAllBanks();
    } catch (_) {
      _dismissLoading(navigator, route);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to load bank accounts. The invoice was not printed.',
            ),
          ),
        );
      }
      return;
    }

    _dismissLoading(navigator, route);
    if (!context.mounted) return;

    await showReceiptPrinterPickerSheet(
      context,
      data: ReceiptEscposService.fromUnpaidInvoice(
        invoice: invoice,
        banks: banks,
      ),
    );
  } finally {
    _inFlightInvoiceIds.remove(invoice.id);
  }
}

void _dismissLoading(NavigatorState navigator, Route<void> route) {
  if (navigator.mounted && route.isActive) {
    navigator.removeRoute(route);
  }
}
