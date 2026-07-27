import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:helty/src/helper/theme.dart';
import '../../../core/widgets/patient_avatar.dart';
import 'inpatient_layout_constants.dart';

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
    return scheme.primary;
  }

  /// Width for each info cell on wide layouts; keeps cells readable on tablets.
  static double _expandedInfoItemWidth(double cardWidth) {
    const reserved = 520.0;
    return math.min(220, math.max(140, (cardWidth - reserved) / 3));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final compact = maxW < kInpatientCompactBreakpoint;
        final innerW = (maxW - 40).clamp(0.0, double.infinity);

        final rawInfoW = compact
            ? (innerW >= 360 ? (innerW - 8) / 2 : innerW)
            : _expandedInfoItemWidth(maxW);
        final double infoItemW = math.max(72.0, rawInfoW);

        final infoChildren = <Widget>[
          _infoRow(context, label: 'Ward', value: ward, width: infoItemW),
          _infoRow(context, label: 'Bed', value: bedNumber, width: infoItemW),
          _infoRow(
            context,
            label: 'Attending Doctor',
            value: attendingDoctor,
            width: infoItemW,
          ),
          _infoRow(
            context,
            label: 'Reason',
            value: diagnosis,
            width: infoItemW,
          ),
          _infoRow(
            context,
            label: 'Admission Date',
            value: admissionDate,
            width: infoItemW,
          ),
          if (lengthOfStay != null && lengthOfStay!.trim().isNotEmpty)
            _infoRow(
              context,
              label: 'Length of stay',
              value: lengthOfStay!,
              width: infoItemW,
            ),
        ];

        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            child: compact
              ? _buildCompactLayout(
                  context,
                  colorScheme,
                  theme,
                  infoChildren,
                  innerW,
                )
              : _buildExpandedLayout(
                  context,
                  colorScheme,
                  theme,
                  infoChildren,
                  maxW,
                ),
          ),
        );
      },
    );
  }

  Widget _buildCompactLayout(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeData theme,
    List<Widget> infoChildren,
    double innerW,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PatientAvatar(
              avatarUrl: avatarUrl,
              firstName: firstName,
              surname: surname,
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
                    patientName,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
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
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: _compactInnerSpacing(innerW),
          runSpacing: 8,
          children: infoChildren,
        ),
        const SizedBox(height: 16),
        _safetyColumn(
          context,
          colorScheme,
          theme,
          alignEnd: false,
          fullWidthAllergies: true,
        ),
      ],
    );
  }

  double _compactInnerSpacing(double innerW) {
    return innerW >= 360 ? 8 : 0;
  }

  Widget _buildExpandedLayout(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeData theme,
    List<Widget> infoChildren,
    double cardWidth,
  ) {
    final double identityMaxWidth = math.min(
      280.0,
      math.max(160.0, cardWidth * 0.28),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: identityMaxWidth,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PatientAvatar(
                avatarUrl: avatarUrl,
                firstName: firstName,
                surname: surname,
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
                      patientName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
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
          ),
        ),
        const SizedBox(width: 28),
        Expanded(
          child: Wrap(spacing: 24, runSpacing: 8, children: infoChildren),
        ),
        const SizedBox(width: 24),
        _safetyColumn(
          context,
          colorScheme,
          theme,
          alignEnd: true,
          fullWidthAllergies: false,
        ),
      ],
    );
  }

  Widget _safetyColumn(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeData theme, {
    required bool alignEnd,
    required bool fullWidthAllergies,
  }) {
    final allergyWidget = allergies.isNotEmpty
        ? Container(
            width: fullWidthAllergies ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: fullWidthAllergies
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: colorScheme.error,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 6),
                if (fullWidthAllergies)
                  Expanded(
                    child: Text(
                      'Allergies: ${allergies.join(', ')}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                      softWrap: true,
                    ),
                  )
                else
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
        : Container(
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

    final column = Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.stretch,
      children: [
        if (fullWidthAllergies)
          allergyWidget
        else
          Align(alignment: Alignment.centerRight, child: allergyWidget),
        const SizedBox(height: 10),
        Align(
          alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
        ),
        const SizedBox(height: 10),
        if (riskFlags.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
            children: riskFlags
                .map(
                  (f) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondary.withValues(alpha: 0.12),
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
    );

    return column;
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
    required double width,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
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
