import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/app_router.gr.dart';

@RoutePage()
class InpatientsListScreen extends StatelessWidget {
  const InpatientsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // For now this is a UI-focused census view with mock data.
    // You can replace `_rows` with real inpatient/admission data later.
    final rows = [
      const _InpatientRow(
        patientId: 'P-0001',
        name: 'Mr John Doe',
        ageGender: '54 yrs • Male',
        ward: 'Male Medical',
        bed: 'MM-12',
        diagnosis: 'Severe pneumonia',
        daysAdmitted: 3,
      ),
      const _InpatientRow(
        patientId: 'P-0002',
        name: 'Mrs Jane Smith',
        ageGender: '62 yrs • Female',
        ward: 'Female Surgical',
        bed: 'FS-07',
        diagnosis: 'Post-op hysterectomy',
        daysAdmitted: 1,
      ),
      const _InpatientRow(
        patientId: 'P-0003',
        name: 'Master David Okoro',
        ageGender: '8 yrs • Male',
        ward: 'Paediatrics',
        bed: 'P-03',
        diagnosis: 'Severe malaria',
        daysAdmitted: 2,
      ),
    ];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inpatients (Ward Census)',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select a patient in a ward to open the full inpatient view.',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.bed, size: 18, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          '${rows.length} Inpatients',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Filters row (stub for future ward/doctor filters)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Ward dropdown (placeholder)
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Ward'),
                        items: const [
                          DropdownMenuItem(
                            value: 'All',
                            child: Text('All wards'),
                          ),
                        ],
                        initialValue: 'All',
                        onChanged: (_) {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Simple search box
                    Expanded(
                      flex: 2,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by name, hospital number or bed',
                          prefixIcon: Icon(
                            Icons.search,
                            size: 18,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Table
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.onSurface.withValues(alpha: 0.02),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: const [
                            _HeaderCell('PATIENT'),
                            _HeaderCell('WARD'),
                            _HeaderCell('BED'),
                            _HeaderCell('DIAGNOSIS'),
                            _HeaderCell('DAYS ADMITTED'),
                            _HeaderCell('ACTIONS', alignRight: true),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: colorScheme.outline.withValues(alpha: 0.12),
                      ),
                      Expanded(
                        child: ListView.separated(
                          itemCount: rows.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: colorScheme.outline.withValues(alpha: 0.06),
                          ),
                          itemBuilder: (context, index) {
                            final row = rows[index];
                            return InkWell(
                              onTap: () => _openInpatientView(
                                context: context,
                                row: row,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor: colorScheme.primary
                                                .withValues(alpha: 0.12),
                                            child: Text(
                                              row.initials,
                                              style: TextStyle(
                                                color: colorScheme.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                row.name,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: colorScheme.onSurface,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                row.ageGender,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: colorScheme.onSurface
                                                      .withValues(alpha: 0.7),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        row.ward,
                                        style: TextStyle(
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        row.bed,
                                        style: TextStyle(
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        row.diagnosis,
                                        style: TextStyle(
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.8),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '${row.daysAdmitted} days',
                                        style: TextStyle(
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.9),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: OutlinedButton.icon(
                                          onPressed: () => _openInpatientView(
                                            context: context,
                                            row: row,
                                          ),
                                          icon: const Icon(
                                            Icons.open_in_new,
                                            size: 16,
                                          ),
                                          label: const Text('Open view'),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openInpatientView({
    required BuildContext context,
    required _InpatientRow row,
  }) {
    context.router.push(
      InpatientPatientViewRoute(
        patientId: row.patientId,
        ward: row.ward,
        bedNumber: row.bed,
        diagnosis: row.diagnosis,
      ),
    );
  }
}

class _InpatientRow {
  final String patientId;
  final String name;
  final String ageGender;
  final String ward;
  final String bed;
  final String diagnosis;
  final int daysAdmitted;

  const _InpatientRow({
    required this.patientId,
    required this.name,
    required this.ageGender,
    required this.ward,
    required this.bed,
    required this.diagnosis,
    required this.daysAdmitted,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final bool alignRight;

  const _HeaderCell(this.label, {this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final text = Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.4,
        color: colorScheme.onSurface.withValues(alpha: 0.6),
      ),
    );

    return Expanded(
      child: alignRight
          ? Align(alignment: Alignment.centerRight, child: text)
          : text,
    );
  }
}
