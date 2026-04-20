import 'package:flutter/material.dart';

class PatientHeaderCard extends StatelessWidget {
  final String patientName;
  final String ageGender;
  final String hospitalNumber;
  final String ward;
  final String bedNumber;
  final String attendingDoctor;
  final String diagnosis;
  final String admissionDate;
  /// Calendar days since admission (e.g. "4 days"), or null to hide the row.
  final String? lengthOfStay;
  final List<String> allergies;
  final String codeStatus; // e.g. Full Code / DNR
  final List<String> riskFlags; // e.g. Fall Risk, Isolation

  const PatientHeaderCard({
    super.key,
    required this.patientName,
    required this.ageGender,
    required this.hospitalNumber,
    required this.ward,
    required this.bedNumber,
    required this.attendingDoctor,
    required this.diagnosis,
    required this.admissionDate,
    this.lengthOfStay,
    required this.allergies,
    required this.codeStatus,
    required this.riskFlags,
  });

  Color _codeStatusColor(ColorScheme scheme) {
    final lower = codeStatus.toLowerCase();
    if (lower.contains('dnr') || lower.contains('no resus')) {
      return scheme.error;
    }
    return scheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: avatar + core identity
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                child: Text(
                  _initials(patientName),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patientName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _metaChip(
                        context,
                        icon: Icons.badge_outlined,
                        label: hospitalNumber,
                      ),
                      const SizedBox(width: 8),
                      _metaChip(
                        context,
                        icon: Icons.person_outline,
                        label: ageGender,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 28),

          // Middle: admission / location details
          Expanded(
            child: Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                _infoRow(context, label: 'Ward', value: ward),
                _infoRow(context, label: 'Bed', value: bedNumber),
                _infoRow(
                  context,
                  label: 'Attending Doctor',
                  value: attendingDoctor,
                ),
                _infoRow(context, label: 'Diagnosis', value: diagnosis),
                _infoRow(
                  context,
                  label: 'Admission Date',
                  value: admissionDate,
                ),
                if (lengthOfStay != null && lengthOfStay!.trim().isNotEmpty)
                  _infoRow(
                    context,
                    label: 'Length of stay',
                    value: lengthOfStay!,
                  ),
              ],
            ),
          ),

          const SizedBox(width: 24),

          // Right: safety flags
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Allergies
              if (allergies.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: colorScheme.error,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Allergies: ${allergies.join(', ')}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceBright,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: colorScheme.onSurfaceVariant,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'No recorded allergies',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),

              // Code status
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _codeStatusColor(colorScheme).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.monitor_heart_outlined,
                      color: _codeStatusColor(colorScheme),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      codeStatus,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: _codeStatusColor(colorScheme),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Risk flags
              if (riskFlags.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.end,
                  children: riskFlags
                      .map(
                        (f) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondary.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            f,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  Widget _metaChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
