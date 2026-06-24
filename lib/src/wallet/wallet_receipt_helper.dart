import 'package:flutter/material.dart';

import '../models/invoice_billing_models.dart';
import '../printing/escpos/receipt_printer_picker_sheet.dart';
import '../providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WalletReceiptHelper {
  static Map<String, dynamic> depositReceiptData({
    required BillingWalletTransaction transaction,
    required String patientName,
    required String chartNumber,
    required double balanceAfter,
    String? staffFirstName,
    String? staffLastName,
    bool isReprint = false,
  }) {
    final ref = transaction.reference?.trim();
    final description = ref != null && ref.isNotEmpty && ref != 'deposit'
        ? 'Wallet deposit ($ref)'
        : 'Wallet deposit';
    return {
      'receiptTitle': '*** WALLET DEPOSIT RECEIPT ***',
      'transaction': {
        'transactionID': transaction.id,
        'totalAmount': transaction.amount,
        'discountAmount': 0,
        'amountPaid': transaction.amount,
        'createdAt':
            transaction.createdAt?.toIso8601String() ??
            DateTime.now().toIso8601String(),
        'balanceAfter': balanceAfter,
        if (isReprint) 'reprinted': true,
      },
      'patient': {
        'firstName': patientName,
        'surname': '',
        'patientId': chartNumber,
      },
      'staff': {
        'firstName': staffFirstName ?? '',
        'lastName': staffLastName ?? '',
      },
      'itemSnapshots': [
        {
          'description': description,
          'quantity': 1,
          'total': transaction.amount.toStringAsFixed(2),
        },
        {
          'description': 'Balance after deposit',
          'quantity': 1,
          'total': balanceAfter.toStringAsFixed(2),
        },
      ],
    };
  }

  static Map<String, dynamic> paymentReceiptData({
    required BillingPaymentDetail payment,
    bool isReprint = false,
  }) {
    final items = payment.itemAllocations.isNotEmpty
        ? payment.itemAllocations
              .map(
                (a) => {
                  'description': a.description ?? 'Invoice item',
                  'quantity': 1,
                  'total': a.amount.toStringAsFixed(2),
                },
              )
              .toList()
        : [
            {
              'description': 'Wallet payment — ${payment.invoiceNumber ?? ''}',
              'quantity': 1,
              'total': payment.amount.toStringAsFixed(2),
            },
          ];
    final staffName = payment.receivedByName ?? payment.createdByName ?? '';
    final parts = staffName.split(' ');
    return {
      'receiptTitle': '*** WALLET PAYMENT RECEIPT ***',
      'transaction': {
        'transactionID': payment.id,
        'totalAmount': payment.amount,
        'discountAmount': 0,
        'amountPaid': payment.amount,
        'createdAt':
            payment.paidAt?.toIso8601String() ??
            DateTime.now().toIso8601String(),
        if (isReprint) 'reprinted': true,
      },
      'patient': {
        'firstName': payment.patientName ?? '',
        'surname': '',
        'patientId': payment.patientChartNumber ?? '',
      },
      'staff': {
        'firstName': parts.isNotEmpty ? parts.first : staffName,
        'lastName': parts.length > 1 ? parts.sublist(1).join(' ') : '',
      },
      'itemSnapshots': items,
      'invoiceNumber': payment.invoiceNumber,
      'paymentMethod': 'Patient wallet',
    };
  }

  static Map<String, dynamic> refundReceiptData({
    required BillingWalletTransaction transaction,
    required String patientName,
    required String chartNumber,
    String? invoiceNumber,
    bool isReprint = false,
  }) {
    return {
      'receiptTitle': '*** WALLET REFUND CREDIT ***',
      'transaction': {
        'transactionID': transaction.id,
        'totalAmount': transaction.amount,
        'discountAmount': 0,
        'amountPaid': transaction.amount,
        'createdAt':
            transaction.createdAt?.toIso8601String() ??
            DateTime.now().toIso8601String(),
        if (isReprint) 'reprinted': true,
      },
      'patient': {
        'firstName': patientName,
        'surname': '',
        'patientId': chartNumber,
      },
      'staff': {'firstName': '', 'lastName': ''},
      'itemSnapshots': [
        {
          'description': invoiceNumber != null && invoiceNumber.isNotEmpty
              ? 'Refund credit — Invoice $invoiceNumber'
              : 'Refund credit to wallet',
          'quantity': 1,
          'total': transaction.amount.toStringAsFixed(2),
        },
      ],
    };
  }

  static Future<void> printDeposit({
    required BuildContext context,
    required BillingWalletTransaction transaction,
    required String patientName,
    required String chartNumber,
    required double balanceAfter,
    String? staffFirstName,
    String? staffLastName,
    bool isReprint = false,
  }) {
    return showReceiptPrinterPickerSheet(
      context,
      data: depositReceiptData(
        transaction: transaction,
        patientName: patientName,
        chartNumber: chartNumber,
        balanceAfter: balanceAfter,
        staffFirstName: staffFirstName,
        staffLastName: staffLastName,
        isReprint: isReprint,
      ),
      isCopy: isReprint,
    );
  }

  static Future<void> printPayment({
    required BuildContext context,
    required BillingPaymentDetail payment,
    bool isReprint = false,
  }) {
    return showReceiptPrinterPickerSheet(
      context,
      data: paymentReceiptData(payment: payment, isReprint: isReprint),
      isCopy: isReprint,
    );
  }

  static Future<void> printRefund({
    required BuildContext context,
    required BillingWalletTransaction transaction,
    required String patientName,
    required String chartNumber,
    String? invoiceNumber,
    bool isReprint = false,
  }) {
    return showReceiptPrinterPickerSheet(
      context,
      data: refundReceiptData(
        transaction: transaction,
        patientName: patientName,
        chartNumber: chartNumber,
        invoiceNumber: invoiceNumber,
        isReprint: isReprint,
      ),
      isCopy: isReprint,
    );
  }

  static Future<void> printFromAuth({
    required BuildContext context,
    required WidgetRef ref,
    required BillingWalletTransaction transaction,
    required String patientName,
    required String chartNumber,
    required double balanceAfter,
    bool isReprint = false,
  }) {
    final staff = ref.read(authProvider).staff;
    return printDeposit(
      context: context,
      transaction: transaction,
      patientName: patientName,
      chartNumber: chartNumber,
      balanceAfter: balanceAfter,
      staffFirstName: staff?.firstName,
      staffLastName: staff?.lastName,
      isReprint: isReprint,
    );
  }
}
