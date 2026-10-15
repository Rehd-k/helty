import 'package:flutter/material.dart';

import 'package:helty/src/lab/ui/widgets/lab_clinical_ui.dart';
import 'package:helty/src/widgets/helty_surface.dart';

class LabConfigLookupRow {
  const LabConfigLookupRow({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.active,
  });

  final String id;
  final String title;
  final String subtitle;
  final bool active;
}

class LabConfigLookupList extends StatelessWidget {
  const LabConfigLookupList({
    super.key,
    required this.title,
    required this.icon,
    required this.accent,
    required this.rows,
    required this.footerLabel,
    required this.emptyLabel,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final List<LabConfigLookupRow> rows;
  final String footerLabel;
  final String emptyLabel;
  final ValueChanged<String> onEdit;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return HeltySurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: HeltyEllipsisText(
              text: title,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.7)),
          Expanded(
            child: rows.isEmpty
                ? Center(
                    child: Text(
                      emptyLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      return Material(
                        color: LabClinicalUi.zebraFill(cs, index),
                        child: InkWell(
                          onTap: () => onEdit(row.id),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                            child: Row(
                              children: [
                                HeltySolidIcon(
                                  icon: icon,
                                  color: row.active
                                      ? accent
                                      : LabClinicalUi.iconAmber,
                                  size: 28,
                                  iconSize: 15,
                                  radius: 7,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      HeltyEllipsisText(
                                        text: row.title,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      HeltyEllipsisText(
                                        text: row.subtitle,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: cs.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!row.active)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: HeltyStatusChip(
                                      label: 'Inactive',
                                      color: LabClinicalUi.iconAmber,
                                    ),
                                  ),
                                PopupMenuButton<String>(
                                  tooltip: 'Actions',
                                  onSelected: (action) {
                                    if (action == 'edit') onEdit(row.id);
                                    if (action == 'delete') onDelete(row.id);
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.7)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: HeltyEllipsisText(
              text: footerLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
