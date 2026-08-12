import 'package:flutter/material.dart';
import 'package:helty/src/helper/theme.dart';

import '../../../core/layout/app_breakpoints.dart';
import '../../../core/widgets/patient_avatar.dart';

/// OPD encounter patient summary: name, age, gender, allergies, chronic conditions,
/// past admissions count, insurance. Collapsed by default to name + hospital id.
class DoctorEncounterPatientHeader extends StatefulWidget {
  final String patientName;
  final String ageGender;
  final String hospitalNumber;
  final List<String> allergies;
  final List<String> chronicConditions;
  final int pastAdmissionsCount;
  final String? insurance;
  final String? doctorName;
  final String doctorLabel;
  final String? createdByName;
  final String? lastUpdatedByName;
  final String? avatarUrl;
  final String? firstName;
  final String? surname;

  const DoctorEncounterPatientHeader({
    super.key,
    required this.patientName,
    required this.ageGender,
    required this.hospitalNumber,
    this.allergies = const [],
    this.chronicConditions = const [],
    this.pastAdmissionsCount = 0,
    this.insurance,
    this.doctorName,
    this.doctorLabel = 'Doctor',
    this.createdByName,
    this.lastUpdatedByName,
    this.avatarUrl,
    this.firstName,
    this.surname,
  });

  @override
  State<DoctorEncounterPatientHeader> createState() =>
      _DoctorEncounterPatientHeaderState();
}

class _DoctorEncounterPatientHeaderState
    extends State<DoctorEncounterPatientHeader> {
  bool _expanded = false;

  void _toggleExpanded() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        child: _expanded ? _buildExpanded() : _buildCollapsed(),
      ),
    );
  }

  Widget _buildCollapsed() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: _toggleExpanded,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          PatientAvatar(
            avatarUrl: widget.avatarUrl,
            firstName: widget.firstName,
            surname: widget.surname,
            size: 40,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
            foregroundColor: colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.patientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                _metaChip(
                  context,
                  icon: Icons.badge_outlined,
                  label: widget.hospitalNumber,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Expand patient details',
            onPressed: _toggleExpanded,
            icon: const Icon(Icons.expand_more),
          ),
        ],
      ),
    );
  }

  Widget _buildExpanded() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bp = AppBreakpoints.of(context);
    final stackAllergies = !bp.isDesktop;

    final identity = Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PatientAvatar(
            avatarUrl: widget.avatarUrl,
            firstName: widget.firstName,
            surname: widget.surname,
            size: 52,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
            foregroundColor: colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.patientName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _metaChip(
                      context,
                      icon: Icons.badge_outlined,
                      label: widget.hospitalNumber,
                    ),
                    _metaChip(
                      context,
                      icon: Icons.person_outline,
                      label: widget.ageGender,
                    ),
                    if (widget.doctorName != null &&
                        widget.doctorName!.trim().isNotEmpty)
                      _metaChip(
                        context,
                        icon: Icons.medical_services_outlined,
                        label:
                            '${widget.doctorLabel}: ${widget.doctorName!.trim()}',
                      ),
                    if (widget.createdByName != null &&
                        widget.createdByName!.trim().isNotEmpty)
                      _metaChip(
                        context,
                        icon: Icons.person_add_alt_1_outlined,
                        label: 'Created by: ${widget.createdByName!.trim()}',
                      ),
                    if (widget.lastUpdatedByName != null &&
                        widget.lastUpdatedByName!.trim().isNotEmpty)
                      _metaChip(
                        context,
                        icon: Icons.edit_outlined,
                        label:
                            'Last updated by: ${widget.lastUpdatedByName!.trim()}',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final infoFields = Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: _infoRow(
              context,
              label: 'Past admissions',
              value: '${widget.pastAdmissionsCount}',
            ),
          ),
          if (widget.insurance != null && widget.insurance!.isNotEmpty) ...[
            const SizedBox(width: 16),
            Flexible(
              child: _infoRow(
                context,
                label: 'Insurance',
                value: widget.insurance!,
              ),
            ),
          ],
          if (widget.chronicConditions.isNotEmpty) ...[
            const SizedBox(width: 16),
            Flexible(
              child: _infoRow(
                context,
                label: 'Chronic conditions',
                value: widget.chronicConditions.join(', '),
              ),
            ),
          ],
        ],
      ),
    );

    final allergiesChip = _allergiesChip(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            tooltip: 'Collapse patient details',
            onPressed: _toggleExpanded,
            icon: const Icon(Icons.expand_less),
            visualDensity: VisualDensity.compact,
          ),
        ),
        if (stackAllergies)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  identity,
                  const SizedBox(width: 16),
                  infoFields,
                ],
              ),
              const SizedBox(height: 12),
              allergiesChip,
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              identity,
              const SizedBox(width: 28),
              infoFields,
              const SizedBox(width: 24),
              allergiesChip,
            ],
          ),
      ],
    );
  }

  Widget _allergiesChip(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.allergies.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
              'Allergies: ${widget.allergies.join(', ')}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
    );
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
    );
  }
}
