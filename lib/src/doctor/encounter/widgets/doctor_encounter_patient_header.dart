import 'package:flutter/material.dart';
import 'package:helty/src/helper/theme.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_layout_constants.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_metrics.dart';
import 'package:helty/src/widgets/helty_surface.dart';

import '../../../core/widgets/patient_avatar.dart';

/// OPD encounter patient summary. Collapsed by default to name + hospital id.
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
    return HeltySurfaceCard(
      padding: const EdgeInsets.all(12),
      child: _expanded ? _buildExpanded() : _buildCollapsed(),
    );
  }

  Widget _buildCollapsed() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: _toggleExpanded,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Row(
        children: [
          PatientAvatar(
            avatarUrl: widget.avatarUrl,
            firstName: widget.firstName,
            surname: widget.surname,
            displayName: widget.patientName,
            size: 40,
            backgroundColor: InpatientMetrics.iconPurple,
            foregroundColor: Colors.white,
            fontWeight: FontWeight.w800,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                HeltyEllipsisText(
                  text: widget.patientName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    HeltyStatusChip(
                      label: widget.hospitalNumber,
                      color: InpatientMetrics.iconBlue,
                    ),
                    if (widget.ageGender.isNotEmpty)
                      HeltyStatusChip(
                        label: widget.ageGender,
                        color: InpatientMetrics.iconTeal,
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Expand patient details',
            onPressed: _toggleExpanded,
            icon: const Icon(Icons.expand_more),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _identity(BuildContext context, {required double avatarSize}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PatientAvatar(
          avatarUrl: widget.avatarUrl,
          firstName: widget.firstName,
          surname: widget.surname,
          displayName: widget.patientName,
          size: avatarSize,
          backgroundColor: InpatientMetrics.iconPurple,
          foregroundColor: Colors.white,
          fontWeight: FontWeight.w800,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeltyEllipsisText(
                text: widget.patientName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  HeltyStatusChip(
                    label: widget.hospitalNumber,
                    color: InpatientMetrics.iconBlue,
                  ),
                  if (widget.ageGender.isNotEmpty)
                    HeltyStatusChip(
                      label: widget.ageGender,
                      color: InpatientMetrics.iconTeal,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpanded() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < kInpatientCompactBreakpoint;
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
            if (compact) ...[
              _identity(context, avatarSize: 48),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: _infoCells(context)),
              const SizedBox(height: 10),
              _allergiesChip(context, expand: true),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _identity(context, avatarSize: 56)),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 5,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _infoCells(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _allergiesChip(context, expand: false),
                ],
              ),
          ],
        );
      },
    );
  }

  List<Widget> _infoCells(BuildContext context) {
    final doctor = widget.doctorName?.trim();
    final created = widget.createdByName?.trim();
    final updated = widget.lastUpdatedByName?.trim();
    final insurance = widget.insurance?.trim();
    final chronic = widget.chronicConditions.join(', ');

    return [
      if (doctor != null && doctor.isNotEmpty)
        _infoCell(
          context,
          icon: Icons.medical_services_outlined,
          color: InpatientMetrics.iconPurple,
          label: widget.doctorLabel,
          value: doctor,
        ),
      if (created != null && created.isNotEmpty)
        _infoCell(
          context,
          icon: Icons.person_add_alt_1_outlined,
          color: InpatientMetrics.iconBlue,
          label: 'Created by',
          value: created,
        ),
      if (updated != null && updated.isNotEmpty)
        _infoCell(
          context,
          icon: Icons.edit_outlined,
          color: InpatientMetrics.iconIndigo,
          label: 'Last updated',
          value: updated,
        ),
      _infoCell(
        context,
        icon: Icons.local_hotel_outlined,
        color: InpatientMetrics.iconTeal,
        label: 'Past admissions',
        value: widget.pastAdmissionsCount > 0
            ? '${widget.pastAdmissionsCount}'
            : '—',
      ),
      if (insurance != null && insurance.isNotEmpty)
        _infoCell(
          context,
          icon: Icons.health_and_safety_outlined,
          color: InpatientMetrics.iconPink,
          label: 'Insurance',
          value: insurance,
        ),
      if (chronic.isNotEmpty)
        _infoCell(
          context,
          icon: Icons.monitor_heart_outlined,
          color: InpatientMetrics.waitAmber,
          label: 'Chronic conditions',
          value: chronic,
        ),
    ];
  }

  Widget _allergiesChip(BuildContext context, {required bool expand}) {
    final hasAllergies = widget.allergies.isNotEmpty;
    final label = hasAllergies
        ? 'Allergies: ${widget.allergies.join(', ')}'
        : 'No recorded allergies';
    final color = hasAllergies
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurfaceVariant;
    if (expand) {
      return HeltyEllipsisChip(label: label, color: color);
    }
    return HeltyStatusChip(label: label, color: color);
  }

  Widget _infoCell(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return SizedBox(
      width: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeltySolidIcon(
            icon: icon,
            color: color,
            size: 26,
            iconSize: 14,
            radius: 7,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeltyEllipsisText(
                  text: label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                HeltyEllipsisText(
                  text: value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
