import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:helty/src/helper/theme.dart';
import '../../../core/widgets/patient_avatar.dart';
import 'inpatient_layout_constants.dart';

class PatientHeaderCard extends StatefulWidget {
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
    this.createdBy,
    this.lengthOfStay,
    required this.allergies,
    required this.codeStatus,
    required this.riskFlags,
    this.avatarUrl,
    this.firstName,
    this.surname,
  });

  @override
  State<PatientHeaderCard> createState() => _PatientHeaderCardState();
}

class _PatientHeaderCardState extends State<PatientHeaderCard> {
  bool _expanded = false;

  Color _codeStatusColor(ColorScheme scheme) {
    final lower = widget.codeStatus.toLowerCase();
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

  void _toggleExpanded() => setState(() => _expanded = !_expanded);

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
          _infoRow(context, label: 'Ward', value: widget.ward, width: infoItemW),
          _infoRow(
            context,
            label: 'Bed',
            value: widget.bedNumber,
            width: infoItemW,
          ),
          _infoRow(
            context,
            label: 'Attending Doctor',
            value: widget.attendingDoctor,
            width: infoItemW,
          ),
          _infoRow(
            context,
            label: 'Reason',
            value: widget.diagnosis,
            width: infoItemW,
          ),
          _infoRow(
            context,
            label: 'Admission Date',
            value: widget.admissionDate,
            width: infoItemW,
          ),
          if (widget.createdBy != null && widget.createdBy!.trim().isNotEmpty)
            _infoRow(
              context,
              label: 'Created by',
              value: widget.createdBy!,
              width: infoItemW,
            ),
          if (widget.lengthOfStay != null &&
              widget.lengthOfStay!.trim().isNotEmpty)
            _infoRow(
              context,
              label: 'Length of stay',
              value: widget.lengthOfStay!,
              width: infoItemW,
            ),
        ];

        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            child: _expanded
                ? Column(
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
                      compact
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
                    ],
                  )
                : _buildCollapsedLayout(context, colorScheme, theme),
          ),
        );
      },
    );
  }

  Widget _buildCollapsedLayout(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
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
                        label: widget.hospitalNumber,
                      ),
                      _metaChip(
                        context,
                        icon: Icons.person_outline,
                        label: widget.ageGender,
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
                          label: widget.hospitalNumber,
                        ),
                        _metaChip(
                          context,
                          icon: Icons.person_outline,
                          label: widget.ageGender,
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
    final allergyWidget = widget.allergies.isNotEmpty
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
                      'Allergies: ${widget.allergies.join(', ')}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                      softWrap: true,
                    ),
                  )
                else
                  Text(
                    'Allergies: ${widget.allergies.join(', ')}',
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
                  widget.codeStatus,
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
        if (widget.riskFlags.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
            children: widget.riskFlags
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
