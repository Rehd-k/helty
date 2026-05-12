import 'package:flutter/material.dart';

import 'widgets/bespoke_section_forms.dart';
import 'widgets/catalog_fallback_section_form.dart';

/// Resolves [sectionKey] to a bespoke template or catalog-driven fallback.
Widget buildSectionForm({
  required String sectionKey,
  required Map<String, dynamic> data,
  required void Function(Map<String, dynamic>) onChanged,
  required bool readOnly,
  Map<String, dynamic>? exampleData,
}) {
  final bespoke = buildBespokeSectionForm(
    sectionKey: sectionKey,
    data: data,
    onChanged: onChanged,
    readOnly: readOnly,
  );
  if (bespoke != null) return bespoke;
  return CatalogFallbackSectionForm(
    data: data,
    onChanged: onChanged,
    exampleData: exampleData,
    readOnly: readOnly,
  );
}
