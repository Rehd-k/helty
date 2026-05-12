import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// Rounded card wrapper for specialty sub-forms.
class ClinicalSectionCard extends StatelessWidget {
  const ClinicalSectionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle != null) ...[
              const Gap(4),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
            const Gap(16),
            child,
          ],
        ),
      ),
    );
  }
}

class ClinicalLabeledField extends StatelessWidget {
  const ClinicalLabeledField({
    super.key,
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const Gap(6),
        child,
      ],
    );
  }
}

/// Edit list of attachment URLs in [data] under [listKey] (default `attachmentUrls`).
class AttachmentUrlsEditor extends StatelessWidget {
  const AttachmentUrlsEditor({
    super.key,
    required this.data,
    required this.onChanged,
    this.readOnly = false,
    this.listKey = 'attachmentUrls',
  });

  final Map<String, dynamic> data;
  final void Function(Map<String, dynamic>) onChanged;
  final bool readOnly;
  final String listKey;

  @override
  Widget build(BuildContext context) {
    final raw = data[listKey];
    final list = <String>[
      if (raw is List) ...raw.map((e) => e.toString()),
    ];

    void updateList(List<String> next) {
      final m = Map<String, dynamic>.from(data);
      m[listKey] = next;
      onChanged(m);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...list.asMap().entries.map((e) {
          final i = e.key;
          final url = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: url,
                    readOnly: readOnly,
                    decoration: InputDecoration(
                      labelText: 'URL ${i + 1}',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    onChanged: readOnly
                        ? null
                        : (v) {
                            final n = List<String>.from(list);
                            n[i] = v;
                            updateList(n);
                          },
                  ),
                ),
                if (!readOnly) ...[
                  const Gap(8),
                  IconButton(
                    onPressed: () {
                      final n = List<String>.from(list)..removeAt(i);
                      updateList(n);
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                ],
              ],
            ),
          );
        }),
        if (!readOnly)
          TextButton.icon(
            onPressed: () => updateList([...list, '']),
            icon: const Icon(Icons.add_link, size: 20),
            label: const Text('Add URL'),
          ),
      ],
    );
  }
}

/// NIHSS-style int item row.
class ScoreDropdownTile extends StatefulWidget {
  const ScoreDropdownTile({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.readOnly = false,
  });

  final String label;
  final int? value;
  final List<int> items;
  final ValueChanged<int?> onChanged;
  final bool readOnly;

  @override
  State<ScoreDropdownTile> createState() => _ScoreDropdownTileState();
}

class _ScoreDropdownTileState extends State<ScoreDropdownTile> {
  int? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.value;
  }

  @override
  void didUpdateWidget(ScoreDropdownTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _selected = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              widget.label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<int>(
              initialValue: _selected,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: widget.items
                  .map(
                    (i) => DropdownMenuItem(value: i, child: Text('$i')),
                  )
                  .toList(),
              onChanged: widget.readOnly
                  ? null
                  : (v) {
                      setState(() => _selected = v);
                      widget.onChanged(v);
                    },
            ),
          ),
        ],
      ),
    );
  }
}

String prettyJson(Map<String, dynamic> m) {
  try {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(m);
  } catch (_) {
    return m.toString();
  }
}
