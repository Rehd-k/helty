import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:helty/src/helper/theme.dart';
import 'package:helty/src/lab/models/lab_models.dart';
import 'package:helty/src/lab/ui/widgets/lab_clinical_ui.dart';
import 'package:helty/src/widgets/helty_surface.dart';

enum LabConfigSection { catalog, antibiotics, ast }

extension LabConfigSectionX on LabConfigSection {
  String get label => switch (this) {
    LabConfigSection.catalog => 'Catalog',
    LabConfigSection.antibiotics => 'Antibiotics',
    LabConfigSection.ast => 'AST options',
  };

  String get searchHint => switch (this) {
    LabConfigSection.catalog => 'Search categories, tests, or sample types',
    LabConfigSection.antibiotics => 'Search antibiotics or codes',
    LabConfigSection.ast => 'Search labels or codes',
  };
}

/// One category (or the uncategorized bucket) and the tests currently shown under it.
class LabConfigGroup {
  const LabConfigGroup({
    required this.id,
    required this.name,
    required this.tests,
    required this.totalTests,
    this.description,
    this.category,
  });

  final String id;
  final String name;
  final String? description;
  final LabCategory? category;
  final List<LabTest> tests;
  final int totalTests;

  bool get canEdit => category != null;
}

String labConfigErrorMessage(Object error) {
  if (error is DioException) {
    final code = error.response?.statusCode;
    final data = error.response?.data;
    String? message;
    if (data is Map && data['message'] != null) {
      final raw = data['message'];
      message = raw is List ? raw.join(', ') : raw.toString();
    } else if (data is String && data.trim().isNotEmpty) {
      message = data.trim();
    }
    if (code == 409) {
      return message ??
          'This item is already used on reports. Deactivate it instead of deleting it.';
    }
    return message ?? error.message ?? 'Request failed';
  }
  return error.toString();
}

InputDecoration labConfigFieldDecoration(
  BuildContext context, {
  required String label,
  String? hint,
  IconData? icon,
  Color iconColor = LabClinicalUi.iconIndigo,
  Widget? suffixIcon,
}) {
  final cs = Theme.of(context).colorScheme;
  return InputDecoration(
    labelText: label,
    hintText: hint,
    isDense: true,
    suffixIcon: suffixIcon,
    prefixIcon: icon == null
        ? null
        : Padding(
            padding: const EdgeInsets.all(6),
            child: HeltySolidIcon(
              icon: icon,
              color: iconColor,
              size: 22,
              iconSize: 13,
              radius: 6,
            ),
          ),
    prefixIconConstraints: const BoxConstraints(minWidth: 34, minHeight: 34),
    filled: true,
    fillColor: cs.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35)),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    labelStyle: const TextStyle(fontSize: 11),
  );
}

class LabConfigIconButton extends StatelessWidget {
  const LabConfigIconButton({
    super.key,
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: HeltySolidIcon(
        icon: icon,
        color: color,
        size: 32,
        iconSize: 16,
        radius: 8,
      ),
    );
  }
}

String labFieldTypeLabel(LabFieldType type) => switch (type) {
  LabFieldType.text => 'Text',
  LabFieldType.number => 'Number',
  LabFieldType.dropdown => 'Dropdown',
  LabFieldType.checkbox => 'Checkbox',
  LabFieldType.multiselect => 'Multi-select',
  LabFieldType.date => 'Date',
};

IconData labFieldTypeIcon(LabFieldType type) => switch (type) {
  LabFieldType.text => Icons.text_fields_rounded,
  LabFieldType.number => Icons.numbers_rounded,
  LabFieldType.dropdown => Icons.arrow_drop_down_circle_outlined,
  LabFieldType.checkbox => Icons.check_box_outlined,
  LabFieldType.multiselect => Icons.checklist_rounded,
  LabFieldType.date => Icons.calendar_today_outlined,
};

Color labFieldTypeColor(LabFieldType type) => switch (type) {
  LabFieldType.text => LabClinicalUi.iconBlue,
  LabFieldType.number => LabClinicalUi.iconTeal,
  LabFieldType.dropdown => LabClinicalUi.iconPurple,
  LabFieldType.checkbox => LabClinicalUi.iconGreen,
  LabFieldType.multiselect => LabClinicalUi.iconIndigo,
  LabFieldType.date => LabClinicalUi.iconAmber,
};

int compareLabText(String a, String b) =>
    a.toLowerCase().compareTo(b.toLowerCase());
