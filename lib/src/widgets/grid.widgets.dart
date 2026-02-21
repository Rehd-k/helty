import 'package:flutter/material.dart';
import 'package:helty/src/core/extensions/number.extention.dart';

import '../billings/pending.bills.dart';

Widget buildModernGrid(
  PatientRecord? patient,

  /// function that will be called when the user taps the delete
  /// icon next to an item. The index of the item is supplied.
  void Function(int) removeService,
  BuildContext context,
) {
  return Column(
    children: [
      // --- HEADER ---
      Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor, // Dark professional background
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: const Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                'Description/Service',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                'QTY',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Unit Price',
                textAlign: TextAlign.right,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Total',
                textAlign: TextAlign.right,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),

      // --- BODY ---
      Expanded(
        child: ListView.separated(
          itemCount: patient!.details.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = patient.details[index];
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              color: index % 2 == 0
                  ? Colors.white
                  : Colors.grey.shade50, // Zebra striping
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      item.service,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text('${item.qty}', textAlign: TextAlign.center),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.price.toFinancial(isMoney: true),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      (item.qty * item.price).toFinancial(isMoney: true),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ],
  );
}
