import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'clinical_form_shared.dart';

/// Builds fields from catalog [exampleData] when no bespoke form exists.
class CatalogFallbackSectionForm extends StatefulWidget {
  const CatalogFallbackSectionForm({
    super.key,
    required this.data,
    required this.onChanged,
    required this.exampleData,
    this.readOnly = false,
  });

  final Map<String, dynamic> data;
  final void Function(Map<String, dynamic>) onChanged;
  final Map<String, dynamic>? exampleData;
  final bool readOnly;

  @override
  State<CatalogFallbackSectionForm> createState() =>
      _CatalogFallbackSectionFormState();
}

class _CatalogFallbackSectionFormState
    extends State<CatalogFallbackSectionForm> {
  late Map<String, dynamic> _draft;

  @override
  void initState() {
    super.initState();
    _draft = Map<String, dynamic>.from(widget.data);
    _mergeExampleKeys();
  }

  @override
  void didUpdateWidget(CatalogFallbackSectionForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _draft = Map<String, dynamic>.from(widget.data);
      _mergeExampleKeys();
    }
  }

  void _mergeExampleKeys() {
    final ex = widget.exampleData;
    if (ex == null) return;
    for (final e in ex.entries) {
      _draft.putIfAbsent(e.key, () => e.value);
    }
  }

  void _patch(String key, dynamic value) {
    setState(() {
      _draft[key] = value;
    });
    widget.onChanged(Map<String, dynamic>.from(_draft));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keys = _draft.keys.toList()..sort();
    if (keys.isEmpty) {
      return ClinicalSectionCard(
        title: 'Section data',
        subtitle:
            'No example shape from catalog. Add fields manually in raw JSON below.',
        child: _rawJsonEditor(theme),
      );
    }

    return ClinicalSectionCard(
      title: 'Section fields',
      subtitle: 'Generated from catalog example. Prefer structured forms when available.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final k in keys) _fieldForKey(k, theme),
          const Gap(16),
          Text(
            'Raw JSON',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(8),
          _rawJsonEditor(theme),
        ],
      ),
    );
  }

  Widget _fieldForKey(String k, ThemeData theme) {
    final v = _draft[k];
    if (widget.readOnly) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ClinicalLabeledField(
          label: k,
          child: Text(
            v?.toString() ?? '—',
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }
    if (v is bool) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(k),
          value: v,
          onChanged: (b) => _patch(k, b),
        ),
      );
    }
    if (v is num) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ClinicalLabeledField(
          label: k,
          child: TextFormField(
            initialValue: v.toString(),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
            ),
            onChanged: (s) {
              final n = num.tryParse(s);
              if (n != null) _patch(k, n);
            },
          ),
        ),
      );
    }
    if (v is Map || v is List) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ClinicalLabeledField(
          label: k,
          child: TextFormField(
            initialValue: v is Map
                ? jsonEncode(v)
                : jsonEncode(v),
            maxLines: 4,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
            ),
            onChanged: (s) {
              try {
                final decoded = jsonDecode(s);
                _patch(k, decoded);
              } catch (_) {
                // keep partial typing
              }
            },
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClinicalLabeledField(
        label: k,
        child: TextFormField(
          initialValue: v?.toString() ?? '',
          maxLines: v?.toString().contains('\n') == true ? 4 : 1,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
          ),
          onChanged: (s) => _patch(k, s),
        ),
      ),
    );
  }

  Widget _rawJsonEditor(ThemeData theme) {
    return TextFormField(
      initialValue: prettyJson(_draft),
      readOnly: widget.readOnly,
      maxLines: 8,
      style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        alignLabelWithHint: true,
      ),
      onChanged: widget.readOnly
          ? null
          : (s) {
              try {
                final m = jsonDecode(s);
                if (m is Map<String, dynamic>) {
                  setState(() => _draft = Map<String, dynamic>.from(m));
                  widget.onChanged(Map<String, dynamic>.from(m));
                }
              } catch (_) {}
            },
    );
  }
}
