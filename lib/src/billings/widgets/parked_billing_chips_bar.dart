import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/billings/parked_billing_session.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/providers/parked_billing_provider.dart';

class ParkedBillingChipsBar extends ConsumerWidget {
  const ParkedBillingChipsBar({
    super.key,
    required this.onResume,
    this.padding = const EdgeInsets.fromLTRB(8, 8, 8, 0),
  });

  final void Function(ParkedBillingSession session) onResume;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(parkedBillingProvider);
    if (sessions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pause_circle_outline, size: 18, color: Colors.orange.shade800),
              const SizedBox(width: 6),
              Text(
                'Waiting to pay',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade900,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${sessions.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final session = sessions[index];
                return _ParkedBillChip(
                  session: session,
                  onResume: () => onResume(session),
                  onDismiss: () => _confirmDismiss(context, ref, session),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDismiss(
    BuildContext context,
    WidgetRef ref,
    ParkedBillingSession session,
  ) async {
    final name = session.patient.firstName.trim().isEmpty
        ? 'this patient'
        : session.patient.firstName;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dismiss parked bill?'),
        content: Text(
          'Remove the parked bill for $name? Selected services will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(parkedBillingProvider.notifier).remove(session.id);
    }
  }
}

class _ParkedBillChip extends StatelessWidget {
  const _ParkedBillChip({
    required this.session,
    required this.onResume,
    required this.onDismiss,
  });

  final ParkedBillingSession session;
  final VoidCallback onResume;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final name = session.patient.firstName.trim().isEmpty
        ? 'Patient'
        : session.patient.firstName;
    final count = session.itemCount;
    final itemLabel = count == 1 ? '1 item' : '$count items';
    final amountLabel = session.flowConfig.hideServicePrices
        ? null
        : session.totalDue.toFinancial(isMoney: true);
    final ago = DateFormatter.relativeTimeAgo(session.parkedAt);

    final labelParts = <String>[
      name,
      itemLabel,
      if (amountLabel != null) amountLabel,
      ago,
    ];

    return Material(
      color: Colors.orange.shade50,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onResume,
        onLongPress: onDismiss,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.only(left: 12, right: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long, size: 16, color: Colors.orange.shade800),
              const SizedBox(width: 6),
              Text(
                labelParts.join(' · '),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade900,
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: Icon(Icons.close, size: 16, color: Colors.orange.shade700),
                tooltip: 'Dismiss parked bill',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
