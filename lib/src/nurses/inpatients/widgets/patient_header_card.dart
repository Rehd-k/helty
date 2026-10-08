import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:helty/src/core/widgets/patient_avatar.dart';
import 'package:helty/src/helper/theme.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_layout_constants.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_metrics.dart';
import 'package:helty/src/widgets/helty_surface.dart';

class PatientHeaderCard extends StatelessWidget {
  final String patientName;
  final String ageGender;
  final String hospitalNumber;
  final String ward;
  final String bedNumber;
  final String attendingDoctor;
  final String diagnosis;
  final String admissionDate;
  final String? createdBy;

  /// Calendar days since admission (e.g. "4 days"), or null to hide the row.
  final String? lengthOfStay;
  final List<String> allergies;
  final String codeStatus;
  final List<String> riskFlags;
  final String? avatarUrl;
  final String? firstName;
  final String? surname;

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
    this.createdBy,
    this.lengthOfStay,
    required this.allergies,
    required this.codeStatus,
    required this.riskFlags,
    this.avatarUrl,
    this.firstName,
    this.surname,
  });

  Color _codeStatusColor(ColorScheme scheme) {
    final lower = codeStatus.toLowerCase();
    if (lower.contains('dnr') || lower.contains('no resus')) {
      return scheme.error;
    }
    return InpatientMetrics.iconPurple;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < kInpatientCompactBreakpoint;
        return HeltySurfaceCard(
          padding: EdgeInsets.all(compact ? 10 : 12),
          child: compact
              ? _MobilePatientHeader(
                  collapsed: _collapsed(context),
                  expanded: _compact(context),
                )
              : _wide(context),
        );
      },
    );
  }

  Widget _identity(BuildContext context, {required double avatarSize}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PatientAvatar(
          avatarUrl: avatarUrl,
          firstName: firstName,
          surname: surname,
          displayName: patientName,
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
                text: patientName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _metaChip(
                    context,
                    icon: Icons.badge_outlined,
                    label: hospitalNumber,
                  ),
                  _metaChip(
                    context,
                    icon: Icons.person_outline,
                    label: ageGender,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _collapsed(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final place = [
      if (ward.trim().isNotEmpty && ward != '—') ward,
      if (bedNumber.trim().isNotEmpty && bedNumber != '—') 'Bed $bedNumber',
    ].join(' · ');
    final allergy = allergies.isEmpty ? null : allergies.join(', ');

    return Row(
      children: [
        PatientAvatar(
          avatarUrl: avatarUrl,
          firstName: firstName,
          surname: surname,
          displayName: patientName,
          size: 40,
          backgroundColor: InpatientMetrics.iconPurple,
          foregroundColor: Colors.white,
          fontWeight: FontWeight.w800,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeltyEllipsisText(
                text: patientName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              if (place.isNotEmpty)
                HeltyEllipsisText(
                  text: place,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              if (allergy != null)
                HeltyEllipsisText(
                  text: 'Allergies: $allergy',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
        Icon(Icons.expand_more, color: cs.onSurfaceVariant),
      ],
    );
  }

  Widget _wide(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _identity(context, avatarSize: 64)),
        const SizedBox(width: 12),
        Expanded(flex: 6, child: _infoWrap(context, twoColumn: false)),
        const SizedBox(width: 8),
        Expanded(flex: 3, child: _safetyColumn(context, alignEnd: true)),
      ],
    );
  }

  Widget _compact(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _identity(context, avatarSize: 52),
        const SizedBox(height: 10),
        _infoWrap(context, twoColumn: true),
        const SizedBox(height: 10),
        _safetyColumn(context, alignEnd: false),
      ],
    );
  }

  Widget _infoWrap(BuildContext context, {required bool twoColumn}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 180.0;
        final cellWidth = twoColumn && available > 8
            ? (available - 8) / 2
            : math.min(180.0, math.max(available, 0)).toDouble();
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _infoCells(context, cellWidth),
        );
      },
    );
  }

  List<Widget> _infoCells(BuildContext context, double cellWidth) {
    return [
      _infoCell(
        context,
        width: cellWidth,
        icon: Icons.apartment_outlined,
        color: InpatientMetrics.iconIndigo,
        label: 'Ward',
        value: ward,
      ),
      _infoCell(
        context,
        width: cellWidth,
        icon: Icons.bed_outlined,
        color: InpatientMetrics.iconTeal,
        label: 'Bed',
        value: bedNumber,
      ),
      _infoCell(
        context,
        width: cellWidth,
        icon: Icons.medical_information_outlined,
        color: InpatientMetrics.iconPurple,
        label: 'Attending Doctor',
        value: attendingDoctor,
      ),
      _infoCell(
        context,
        width: cellWidth,
        icon: Icons.monitor_heart_outlined,
        color: InpatientMetrics.waitAmber,
        label: 'Reason',
        value: diagnosis,
      ),
      _infoCell(
        context,
        width: cellWidth,
        icon: Icons.event_outlined,
        color: InpatientMetrics.iconPink,
        label: 'Admission Date',
        value: admissionDate,
      ),
      if (lengthOfStay != null && lengthOfStay!.trim().isNotEmpty)
        _infoCell(
          context,
          width: cellWidth,
          icon: Icons.schedule_outlined,
          color: InpatientMetrics.waitGreen,
          label: 'Length of stay',
          value: lengthOfStay!,
        ),
      if (createdBy != null && createdBy!.trim().isNotEmpty)
        _infoCell(
          context,
          width: cellWidth,
          icon: Icons.badge_outlined,
          color: InpatientMetrics.iconBlue,
          label: 'Created by',
          value: createdBy!,
        ),
    ];
  }

  Widget _infoCell(
    BuildContext context, {
    required double width,
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return SizedBox(
      width: width,
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

  Widget _safetyColumn(BuildContext context, {required bool alignEnd}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasAllergies = allergies.isNotEmpty;
    final allergyLabel = hasAllergies
        ? allergies.join(', ')
        : 'No recorded allergies';

    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.stretch,
      children: [
        HeltyEllipsisChip(
          label: allergyLabel,
          color: hasAllergies ? cs.error : cs.onSurfaceVariant,
        ),
        const SizedBox(height: 8),
        HeltyStatusChip(label: codeStatus, color: _codeStatusColor(cs)),
        if (riskFlags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
            children: [
              for (final f in riskFlags)
                HeltyStatusChip(label: f, color: cs.secondary),
            ],
          ),
        ],
      ],
    );
  }

  Widget _metaChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          HeltyEllipsisText(
            text: label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobilePatientHeader extends StatefulWidget {
  const _MobilePatientHeader({
    required this.collapsed,
    required this.expanded,
  });

  final Widget collapsed;
  final Widget expanded;

  @override
  State<_MobilePatientHeader> createState() => _MobilePatientHeaderState();
}

class _MobilePatientHeaderState extends State<_MobilePatientHeader> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    if (!_open) {
      return InkWell(
        onTap: () => setState(() => _open = true),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: widget.collapsed,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            tooltip: 'Hide patient details',
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => _open = false),
            icon: const Icon(Icons.expand_less),
          ),
        ),
        widget.expanded,
      ],
    );
  }
}
