import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:helty/src/lab/models/lab_models.dart';
import 'package:helty/src/lab/services/lab_api_service.dart';
import 'package:helty/src/lab/ui/config/lab_config_shared.dart';

Future<LabCategory?> showLabCategoryForm({
  required BuildContext context,
  required LabApiService api,
  LabCategory? existing,
}) {
  return showDialog<LabCategory>(
    context: context,
    builder: (ctx) => _CategoryFormDialog(api: api, existing: existing),
  );
}

Future<LabTest?> showLabTestForm({
  required BuildContext context,
  required LabApiService api,
  required List<LabCategory> categories,
  LabTest? existing,
  String? initialCategoryId,
}) {
  return showDialog<LabTest>(
    context: context,
    builder: (ctx) => _TestFormDialog(
      api: api,
      categories: categories,
      existing: existing,
      initialCategoryId: initialCategoryId,
    ),
  );
}

Future<bool> showLabFieldForm({
  required BuildContext context,
  required LabApiService api,
  required String versionId,
  required int nextPosition,
  LabTestField? existing,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => _FieldFormDialog(
      api: api,
      versionId: versionId,
      nextPosition: nextPosition,
      existing: existing,
    ),
  ).then((value) => value ?? false);
}

Future<LabAntibiotic?> showLabAntibioticForm({
  required BuildContext context,
  required LabApiService api,
  LabAntibiotic? existing,
  int nextPosition = 0,
}) {
  return showDialog<LabAntibiotic>(
    context: context,
    builder: (ctx) => _AntibioticFormDialog(
      api: api,
      existing: existing,
      nextPosition: nextPosition,
    ),
  );
}

Future<LabAstResultOption?> showLabAstOptionForm({
  required BuildContext context,
  required LabApiService api,
  LabAstResultOption? existing,
  int nextPosition = 0,
}) {
  return showDialog<LabAstResultOption>(
    context: context,
    builder: (ctx) => _AstOptionFormDialog(
      api: api,
      existing: existing,
      nextPosition: nextPosition,
    ),
  );
}

/// How a new test version should be created.
enum LabVersionCreateChoice { copyFields, empty }

Future<LabVersionCreateChoice?> showLabVersionCreateChoice({
  required BuildContext context,
  required String testName,
  required int fromVersion,
  required int fieldCount,
}) {
  return showDialog<LabVersionCreateChoice>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('New version'),
      content: Text(
        'Create a new active version of $testName. '
        'Copy $fieldCount result field${fieldCount == 1 ? '' : 's'} from v$fromVersion, '
        'or start with an empty version. The current version stays as it is.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, LabVersionCreateChoice.empty),
          child: const Text('Empty version'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(ctx, LabVersionCreateChoice.copyFields),
          child: const Text('Copy fields'),
        ),
      ],
    ),
  );
}

Future<bool> confirmLabConfigDelete({
  required BuildContext context,
  required String title,
  required String message,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  ).then((value) => value ?? false);
}

class _FormShell extends StatelessWidget {
  const _FormShell({
    required this.title,
    required this.body,
    required this.submitLabel,
    required this.saving,
    required this.onSubmit,
  });

  final String title;
  final Widget body;
  final String submitLabel;
  final bool saving;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: (width - 32).clamp(280, 560),
        child: SingleChildScrollView(child: body),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: saving ? null : onSubmit,
          child: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(submitLabel),
        ),
      ],
    );
  }
}

void _showFormError(BuildContext context, Object error) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(labConfigErrorMessage(error))));
}

class _CategoryFormDialog extends StatefulWidget {
  const _CategoryFormDialog({required this.api, this.existing});

  final LabApiService api;
  final LabCategory? existing;

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _description = TextEditingController(
      text: widget.existing?.description ?? '',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final description = _description.text.trim();
    setState(() => _saving = true);
    try {
      final saved = widget.existing == null
          ? await widget.api.createCategory(
              name: name,
              description: description.isEmpty ? null : description,
            )
          : await widget.api.updateCategory(
              widget.existing!.id,
              name: name,
              description: description,
            );
      if (mounted) Navigator.pop(context, saved);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        _showFormError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FormShell(
      title: widget.existing == null ? 'New category' : 'Edit category',
      submitLabel: widget.existing == null ? 'Create' : 'Save',
      saving: _saving,
      onSubmit: _submit,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: labConfigFieldDecoration(
              context,
              label: 'Name',
              hint: 'e.g. Hematology',
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            decoration: labConfigFieldDecoration(
              context,
              label: 'Description (optional)',
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _TestFormDialog extends StatefulWidget {
  const _TestFormDialog({
    required this.api,
    required this.categories,
    this.existing,
    this.initialCategoryId,
  });

  final LabApiService api;
  final List<LabCategory> categories;
  final LabTest? existing;
  final String? initialCategoryId;

  @override
  State<_TestFormDialog> createState() => _TestFormDialogState();
}

class _TestFormDialogState extends State<_TestFormDialog> {
  late final TextEditingController _name;
  late final TextEditingController _sample;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late String? _categoryId;
  late bool _isActive;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _sample = TextEditingController(text: existing?.sampleType ?? '');
    _description = TextEditingController(text: existing?.description ?? '');
    _price = TextEditingController(
      text: existing?.price == null ? '' : _priceText(existing!.price!),
    );
    _isActive = existing?.isActive ?? true;
    final preferred = existing?.category?.id ?? widget.initialCategoryId;
    _categoryId = widget.categories.any((c) => c.id == preferred)
        ? preferred
        : (widget.categories.isEmpty ? null : widget.categories.first.id);
  }

  String _priceText(double price) {
    if (price == price.roundToDouble()) return price.toStringAsFixed(0);
    return price.toString();
  }

  @override
  void dispose() {
    _name.dispose();
    _sample.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final sample = _sample.text.trim();
    final categoryId = _categoryId;
    if (name.isEmpty || sample.isEmpty || categoryId == null) return;
    final priceRaw = _price.text.trim().replaceAll(',', '');
    double? price;
    if (priceRaw.isNotEmpty) {
      price = double.tryParse(priceRaw);
      if (price == null) {
        _showFormError(context, 'Enter a valid price, or leave it blank.');
        return;
      }
    }
    final description = _description.text.trim();
    final existing = widget.existing;
    setState(() => _saving = true);
    try {
      final saved = existing == null
          ? await widget.api.createTest(
              categoryId: categoryId,
              name: name,
              sampleType: sample,
              description: description.isEmpty ? null : description,
              price: price,
              isActive: _isActive,
            )
          : await widget.api.updateTest(
              existing.id,
              categoryId: categoryId,
              name: name,
              sampleType: sample,
              description: description,
              price: price,
              isActive: _isActive,
            );
      if (mounted) Navigator.pop(context, saved);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        _showFormError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = [...widget.categories]
      ..sort((a, b) => compareLabText(a.name, b.name));
    return _FormShell(
      title: widget.existing == null ? 'New test' : 'Edit test',
      submitLabel: widget.existing == null ? 'Create' : 'Save',
      saving: _saving,
      onSubmit: _submit,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            key: ValueKey(_categoryId),
            initialValue: _categoryId,
            isExpanded: true,
            decoration: labConfigFieldDecoration(context, label: 'Category'),
            items: [
              for (final category in categories)
                DropdownMenuItem(
                  value: category.id,
                  child: Text(category.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: _saving
                ? null
                : (value) => setState(() => _categoryId = value),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            autofocus: widget.existing == null,
            decoration: labConfigFieldDecoration(
              context,
              label: 'Test name',
              hint: 'e.g. CBC',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sample,
            decoration: labConfigFieldDecoration(
              context,
              label: 'Sample type',
              hint: 'e.g. Blood',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            decoration: labConfigFieldDecoration(
              context,
              label: 'Description (optional)',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _price,
            decoration: labConfigFieldDecoration(
              context,
              label: 'Price (optional)',
              hint: widget.existing?.price?.toFinancial(isMoney: true),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Active'),
            subtitle: const Text(
              'Inactive tests stay in the catalog but can be hidden',
            ),
            value: _isActive,
            onChanged: _saving
                ? null
                : (value) => setState(() => _isActive = value),
          ),
        ],
      ),
    );
  }
}

class _FieldFormDialog extends StatefulWidget {
  const _FieldFormDialog({
    required this.api,
    required this.versionId,
    required this.nextPosition,
    this.existing,
  });

  final LabApiService api;
  final String versionId;
  final int nextPosition;
  final LabTestField? existing;

  @override
  State<_FieldFormDialog> createState() => _FieldFormDialogState();
}

class _FieldFormDialogState extends State<_FieldFormDialog> {
  late final TextEditingController _label;
  late final TextEditingController _unit;
  late final TextEditingController _range;
  late final TextEditingController _options;
  late final TextEditingController _position;
  late LabFieldType _type;
  late bool _required;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _label = TextEditingController(text: existing?.label ?? '');
    _unit = TextEditingController(text: existing?.unit ?? '');
    _range = TextEditingController(text: existing?.referenceRange ?? '');
    _options = TextEditingController(
      text: _optionsForEditor(existing?.optionsJson),
    );
    _position = TextEditingController(
      text: '${existing?.position ?? widget.nextPosition}',
    );
    _type = existing?.fieldType ?? LabFieldType.text;
    _required = existing?.required ?? false;
  }

  String _optionsForEditor(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List && decoded.every((item) => item is String)) {
        return decoded.join(', ');
      }
    } catch (_) {}
    return raw;
  }

  @override
  void dispose() {
    _label.dispose();
    _unit.dispose();
    _range.dispose();
    _options.dispose();
    _position.dispose();
    super.dispose();
  }

  bool get _needsOptions =>
      _type == LabFieldType.dropdown || _type == LabFieldType.multiselect;

  String? _normalizeOptions(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    if (text.startsWith('[')) {
      final decoded = jsonDecode(text);
      if (decoded is! List) {
        throw const FormatException('Options must be a JSON list');
      }
      return jsonEncode(decoded);
    }
    final parts = text
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return null;
    return jsonEncode(parts);
  }

  Future<void> _submit() async {
    final label = _label.text.trim();
    if (label.isEmpty) return;
    String? optionsJson;
    if (_needsOptions) {
      try {
        optionsJson = _normalizeOptions(_options.text);
      } catch (error) {
        _showFormError(
          context,
          'Options must be comma-separated values or a JSON list.',
        );
        return;
      }
    }
    final position = int.tryParse(_position.text.trim()) ?? widget.nextPosition;
    final unit = _unit.text.trim();
    final range = _range.text.trim();
    final existing = widget.existing;
    setState(() => _saving = true);
    try {
      if (existing == null) {
        await widget.api.createTestField(
          testVersionId: widget.versionId,
          label: label,
          fieldType: _type.name.toUpperCase(),
          unit: unit.isEmpty ? null : unit,
          referenceRange: range.isEmpty ? null : range,
          required: _required,
          position: position,
          optionsJson: optionsJson,
        );
      } else {
        await widget.api.updateTestField(
          existing.id,
          label: label,
          fieldType: _type.name.toUpperCase(),
          unit: unit,
          referenceRange: range,
          required: _required,
          position: position,
          optionsJson: _needsOptions ? (optionsJson ?? '') : null,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        _showFormError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FormShell(
      title: widget.existing == null ? 'Add result field' : 'Edit result field',
      submitLabel: widget.existing == null ? 'Create' : 'Save',
      saving: _saving,
      onSubmit: _submit,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _label,
            autofocus: true,
            decoration: labConfigFieldDecoration(
              context,
              label: 'Label',
              hint: 'e.g. Haemoglobin',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<LabFieldType>(
            key: ValueKey(_type),
            initialValue: _type,
            isExpanded: true,
            decoration: labConfigFieldDecoration(context, label: 'Field type'),
            items: [
              for (final type in LabFieldType.values)
                DropdownMenuItem(
                  value: type,
                  child: Text(labFieldTypeLabel(type)),
                ),
            ],
            onChanged: _saving
                ? null
                : (value) {
                    if (value != null) setState(() => _type = value);
                  },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _unit,
            decoration: labConfigFieldDecoration(
              context,
              label: 'Unit (optional)',
              hint: 'e.g. g/dL',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _range,
            decoration: labConfigFieldDecoration(
              context,
              label: 'Reference range (optional)',
              hint: 'e.g. 12-16, <1.2, >=5',
            ),
          ),
          if (_needsOptions) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _options,
              decoration: labConfigFieldDecoration(
                context,
                label: 'Options',
                hint: 'A, B, C  or  ["A","B"]',
              ),
              maxLines: 2,
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _position,
            decoration: labConfigFieldDecoration(context, label: 'Position'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Required'),
            value: _required,
            onChanged: _saving
                ? null
                : (value) => setState(() => _required = value ?? false),
          ),
        ],
      ),
    );
  }
}

class _AntibioticFormDialog extends StatefulWidget {
  const _AntibioticFormDialog({
    required this.api,
    required this.nextPosition,
    this.existing,
  });

  final LabApiService api;
  final LabAntibiotic? existing;
  final int nextPosition;

  @override
  State<_AntibioticFormDialog> createState() => _AntibioticFormDialogState();
}

class _AntibioticFormDialogState extends State<_AntibioticFormDialog> {
  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _position;
  late bool _isActive;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _code = TextEditingController(text: existing?.code ?? '');
    _position = TextEditingController(
      text: '${existing?.position ?? widget.nextPosition}',
    );
    _isActive = existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _position.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final code = _code.text.trim();
    final position = int.tryParse(_position.text.trim()) ?? widget.nextPosition;
    final existing = widget.existing;
    setState(() => _saving = true);
    try {
      final saved = existing == null
          ? await widget.api.createAntibiotic(
              name: name,
              code: code.isEmpty ? null : code,
              isActive: _isActive,
              position: position,
            )
          : await widget.api.updateAntibiotic(
              existing.id,
              name: name,
              code: code,
              isActive: _isActive,
              position: position,
            );
      if (mounted) Navigator.pop(context, saved);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        _showFormError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FormShell(
      title: widget.existing == null ? 'New antibiotic' : 'Edit antibiotic',
      submitLabel: widget.existing == null ? 'Create' : 'Save',
      saving: _saving,
      onSubmit: _submit,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: labConfigFieldDecoration(
              context,
              label: 'Name',
              hint: 'e.g. Amoxicillin',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _code,
            decoration: labConfigFieldDecoration(
              context,
              label: 'Code (optional)',
              hint: 'e.g. AMX',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _position,
            decoration: labConfigFieldDecoration(context, label: 'Position'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Active'),
            subtitle: const Text(
              'Deactivate instead of delete when it is already on reports',
            ),
            value: _isActive,
            onChanged: _saving
                ? null
                : (value) => setState(() => _isActive = value),
          ),
        ],
      ),
    );
  }
}

class _AstOptionFormDialog extends StatefulWidget {
  const _AstOptionFormDialog({
    required this.api,
    required this.nextPosition,
    this.existing,
  });

  final LabApiService api;
  final LabAstResultOption? existing;
  final int nextPosition;

  @override
  State<_AstOptionFormDialog> createState() => _AstOptionFormDialogState();
}

class _AstOptionFormDialogState extends State<_AstOptionFormDialog> {
  late final TextEditingController _label;
  late final TextEditingController _code;
  late final TextEditingController _position;
  late bool _isActive;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _label = TextEditingController(text: existing?.label ?? '');
    _code = TextEditingController(text: existing?.code ?? '');
    _position = TextEditingController(
      text: '${existing?.position ?? widget.nextPosition}',
    );
    _isActive = existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _label.dispose();
    _code.dispose();
    _position.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final label = _label.text.trim();
    if (label.isEmpty) return;
    final code = _code.text.trim();
    final position = int.tryParse(_position.text.trim()) ?? widget.nextPosition;
    final existing = widget.existing;
    setState(() => _saving = true);
    try {
      final saved = existing == null
          ? await widget.api.createAstResultOption(
              label: label,
              code: code.isEmpty ? null : code,
              isActive: _isActive,
              position: position,
            )
          : await widget.api.updateAstResultOption(
              existing.id,
              label: label,
              code: code,
              isActive: _isActive,
              position: position,
            );
      if (mounted) Navigator.pop(context, saved);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        _showFormError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FormShell(
      title: widget.existing == null
          ? 'New AST result option'
          : 'Edit AST result option',
      submitLabel: widget.existing == null ? 'Create' : 'Save',
      saving: _saving,
      onSubmit: _submit,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _label,
            autofocus: true,
            decoration: labConfigFieldDecoration(
              context,
              label: 'Label',
              hint: 'e.g. Sensitive',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _code,
            decoration: labConfigFieldDecoration(
              context,
              label: 'Code (optional)',
              hint: 'e.g. S',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _position,
            decoration: labConfigFieldDecoration(context, label: 'Position'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Active'),
            subtitle: const Text(
              'Deactivate instead of delete when it is already on reports',
            ),
            value: _isActive,
            onChanged: _saving
                ? null
                : (value) => setState(() => _isActive = value),
          ),
        ],
      ),
    );
  }
}
