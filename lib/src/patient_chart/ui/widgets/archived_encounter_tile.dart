import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:helty/src/widgets/empty.widget.dart';

import '../../models/archived_encounter_models.dart';
import '../../permissions/patient_chart_permissions.dart';
import '../../services/patient_chart_service.dart';
import '../../../models/staff_model.dart';
import 'archived_document_viewer.dart';

class ArchivedEncountersList extends StatelessWidget {
  const ArchivedEncountersList({
    super.key,
    required this.groups,
    required this.service,
    required this.staff,
    required this.onChanged,
  });

  final List<PatientArchivedEncounter> groups;
  final PatientChartService service;
  final Staff? staff;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.upload_file_outlined,
        title: 'No archived encounter scans',
        message: 'Uploaded paper encounter scans will be listed here.',
      );
    }

    final canDelete = canDeleteArchivedEncounters(staff);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: ExpansionTile(
            title: Text(
              group.title?.trim().isNotEmpty == true
                  ? group.title!
                  : 'Visit ${DateFormat.yMMMd().format(group.encounterOccurredAt)}',
            ),
            subtitle: Text(
              [
                'Visit: ${DateFormat.yMMMd().add_jm().format(group.encounterOccurredAt)}',
                if (group.createdAt != null)
                  'Uploaded: ${DateFormat.yMMMd().format(group.createdAt!)}',
                if (group.uploadedBy != null)
                  'By: ${group.uploadedBy!.displayName}',
              ].join(' · '),
            ),
            children: [
              if (group.notes != null && group.notes!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(group.notes!),
                  ),
                ),
              ...group.documents.map(
                (doc) => ListTile(
                  leading: Icon(
                    doc.isPdf
                        ? Icons.picture_as_pdf_outlined
                        : Icons.image_outlined,
                  ),
                  title: Text(doc.fileName, overflow: TextOverflow.ellipsis),
                  subtitle: doc.uploadedAt != null
                      ? Text(
                          DateFormat.yMMMd().add_jm().format(doc.uploadedAt!),
                        )
                      : null,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ArchivedDocumentViewer(
                          document: doc,
                          service: service,
                        ),
                      ),
                    );
                  },
                  trailing: canDelete
                      ? IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmDelete(context, doc),
                        )
                      : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ArchivedEncounterDocument doc,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text('Remove "${doc.fileName}" from archived records?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await service.deleteArchivedDocument(doc.id);
      onChanged();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document deleted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }
}
