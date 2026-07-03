import 'package:flutter/material.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/pharmacy/models/pharmacy_refill_models.dart';
import 'package:helty/src/pharmacy/services/pharmacy_refill_service.dart';

/// Approve or reject a pending refill request. Returns the updated request on
/// success, or `null` when the dialog is dismissed.
Future<PrescriptionRefillRequest?> showPharmacyRefillReviewDialog(
  BuildContext context, {
  required PrescriptionRefillRequest request,
  required PharmacyRefillService service,
  required String reviewedByStaffId,
  required bool approve,
}) {
  return showDialog<PrescriptionRefillRequest>(
    context: context,
    builder: (_) => _PharmacyRefillReviewDialog(
      request: request,
      service: service,
      reviewedByStaffId: reviewedByStaffId,
      approve: approve,
    ),
  );
}

class _PharmacyRefillReviewDialog extends StatefulWidget {
  const _PharmacyRefillReviewDialog({
    required this.request,
    required this.service,
    required this.reviewedByStaffId,
    required this.approve,
  });

  final PrescriptionRefillRequest request;
  final PharmacyRefillService service;
  final String reviewedByStaffId;
  final bool approve;

  @override
  State<_PharmacyRefillReviewDialog> createState() =>
      _PharmacyRefillReviewDialogState();
}

class _PharmacyRefillReviewDialogState
    extends State<_PharmacyRefillReviewDialog> {
  final _notesCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  String? _error;

  bool get _isApprove => widget.approve;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final updated = await widget.service.review(
        id: widget.request.id,
        status: _isApprove
            ? RefillRequestStatus.approved
            : RefillRequestStatus.rejected,
        reviewedByStaffId: widget.reviewedByStaffId,
        pharmacyNotes: _notesCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prescription = widget.request.prescription;
    final drugName = prescription?.drug ??
        prescription?.firstItem?.drug?.displayName ??
        'Prescription';

    return AlertDialog(
      title: Text(_isApprove ? 'Approve refill' : 'Reject refill'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(drugName, style: theme.textTheme.titleMedium),
              if (widget.request.patient != null)
                Text(
                  widget.request.patient!.displayName,
                  style: theme.textTheme.bodySmall,
                ),
              const SizedBox(height: 12),
              if (_isApprove) ..._buildApprovalHints(theme),
              TextFormField(
                controller: _notesCtrl,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: _isApprove
                      ? 'Pharmacy notes (optional)'
                      : 'Reason for rejection',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (_isApprove) return null;
                  if (value == null || value.trim().isEmpty) {
                    return 'A rejection reason is required';
                  }
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          style: _isApprove
              ? null
              : FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                ),
          child: _submitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isApprove ? 'Approve' : 'Reject'),
        ),
      ],
    );
  }

  List<Widget> _buildApprovalHints(ThemeData theme) {
    final hints = <String>[];
    final prescription = widget.request.prescription;
    if (prescription?.isExpired == true) {
      final end = prescription?.endDate;
      hints.add(
        'Prescription expired${end != null ? ' on ${DateFormatter.medicalDate(end)}' : ''}.',
      );
    }
    final refills = prescription?.refillsAllowed;
    if (refills != null && refills <= 0) {
      hints.add('No refills remaining on this prescription.');
    }
    if (hints.isEmpty) return const [];
    return [
      Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final hint in hints)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(hint, style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
          ],
        ),
      ),
    ];
  }
}
