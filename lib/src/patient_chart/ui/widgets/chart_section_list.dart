import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/patient_chart_models.dart';

/// Generic list renderer for chart section JSON rows.
class ChartSectionList extends StatelessWidget {
  const ChartSectionList({
    super.key,
    required this.sectionKey,
    required this.items,
    this.onLoadMore,
    this.loadingMore = false,
    this.hasMore = false,
  });

  final String sectionKey;
  final List<Map<String, dynamic>> items;
  final VoidCallback? onLoadMore;
  final bool loadingMore;
  final bool hasMore;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No records in this section.'),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: items.length + (hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index >= items.length) {
          return Center(
            child: loadingMore
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  )
                : TextButton(
                    onPressed: onLoadMore,
                    child: const Text('Load more'),
                  ),
          );
        }
        final item = items[index];
        final key = item['_section']?.toString() ?? sectionKey;
        return _SectionTile(
          sectionKey: key,
          item: item,
        );
      },
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({required this.sectionKey, required this.item});

  final String sectionKey;
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = _titleForItem();
    final subtitle = _subtitleForItem();
    final trailing = _trailingForItem();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: ListTile(
        title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: subtitle != null
            ? Text(subtitle, maxLines: 4, overflow: TextOverflow.ellipsis)
            : null,
        trailing: trailing,
        isThreeLine: subtitle != null && subtitle.length > 60,
      ),
    );
  }

  String _titleForItem() {
    switch (sectionKey) {
      case PatientChartSectionKeys.encounters:
        return item['chiefComplaint']?.toString() ??
            item['type']?.toString() ??
            'Encounter';
      case PatientChartSectionKeys.admissions:
        return item['ward'] is Map
            ? (item['ward'] as Map)['name']?.toString() ?? 'Admission'
            : 'Admission';
      case PatientChartSectionKeys.vitals:
        return _formatDate(item['recordedAt'] ?? item['createdAt']) ??
            'Vitals';
      case PatientChartSectionKeys.allergies:
        return item['name']?.toString() ??
            item['substance']?.toString() ??
            'Allergy';
      case PatientChartSectionKeys.invoices:
        return 'Invoice ${item['invoiceNumber'] ?? item['id'] ?? ''}'.trim();
      case PatientChartSectionKeys.wallet:
        return 'Wallet';
      default:
        return item['title']?.toString() ??
            item['name']?.toString() ??
            item['drugName']?.toString() ??
            item['testName']?.toString() ??
            sectionKey;
    }
  }

  String? _subtitleForItem() {
    final parts = <String>[];
    final date = _formatDate(
      item['createdAt'] ??
          item['encounterDate'] ??
          item['admissionDate'] ??
          item['orderedAt'] ??
          item['occurredAt'],
    );
    if (date != null) parts.add(date);

    final doctor = item['doctor'];
    if (doctor is Map) {
      final name = [
        doctor['firstName'],
        doctor['lastName'],
      ].whereType<String>().join(' ').trim();
      if (name.isNotEmpty) parts.add('Dr. $name');
    }

    final status = item['status']?.toString();
    if (status != null && status.isNotEmpty) parts.add(status);

    final notes = item['notes']?.toString() ?? item['findings']?.toString();
    if (notes != null && notes.isNotEmpty) parts.add(notes);

    if (sectionKey == PatientChartSectionKeys.wallet) {
      final bal = item['balance'] ?? item['wallet']?['balance'];
      if (bal != null) parts.add('Balance: $bal');
      final txs = item['transactions'];
      if (txs is List) parts.add('${txs.length} transaction(s)');
    }

    return parts.isEmpty ? null : parts.join(' · ');
  }

  Widget? _trailingForItem() {
    final amount = item['total'] ?? item['amount'] ?? item['totalAmount'];
    if (amount != null) {
      return Text(
        amount is num ? amount.toStringAsFixed(2) : amount.toString(),
        style: const TextStyle(fontWeight: FontWeight.w600),
      );
    }
    return null;
  }

  String? _formatDate(dynamic v) {
    if (v == null) return null;
    final dt = DateTime.tryParse(v.toString());
    if (dt == null) return v.toString();
    return DateFormat.yMMMd().add_jm().format(dt.toLocal());
  }
}
