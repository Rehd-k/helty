import 'package:flutter/material.dart';

/// Prompt for a refund request reason (required, non-empty).
Future<String?> showInvoiceItemRefundReasonDialog(BuildContext context) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Request refund'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: 'Why is this line being refunded?',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final reason = controller.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(ctx, reason);
            },
            child: const Text('Submit request'),
          ),
        ],
      );
    },
  );
}

/// Confirm cancellation of a pending refund request.
Future<bool> showCancelInvoiceItemRefundDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Cancel refund request'),
      content: const Text(
        'Withdraw this pending refund request? The line will remain on the invoice.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Keep pending'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Cancel request'),
        ),
      ],
    ),
  );
  return result == true;
}

/// Optional note when account head approves a refund.
Future<String?> showRefundApproveNoteDialog(BuildContext context) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Approve refund'),
      content: TextField(
        controller: controller,
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'Note (optional)',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: const Text('Approve'),
        ),
      ],
    ),
  );
}

/// Required reason when account head rejects a refund.
Future<String?> showRefundRejectReasonDialog(BuildContext context) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Reject refund'),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Reason',
          hintText: 'Why is this refund being rejected?',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final reason = controller.text.trim();
            if (reason.isEmpty) return;
            Navigator.pop(ctx, reason);
          },
          child: const Text('Reject'),
        ),
      ],
    ),
  );
}
