import 'package:flutter/material.dart';

/// Free-text doctor name used on a printed lab or radiology result.
///
/// The value is not tied to a staff record. It saves when the field loses
/// focus or the user submits it.
class ReportDoctorNameField extends StatefulWidget {
  const ReportDoctorNameField({
    super.key,
    required this.value,
    required this.onSave,
    this.onChanged,
  });

  final String value;
  final Future<void> Function(String value) onSave;
  final ValueChanged<String>? onChanged;

  @override
  State<ReportDoctorNameField> createState() => _ReportDoctorNameFieldState();
}

class _ReportDoctorNameFieldState extends State<ReportDoctorNameField> {
  late final TextEditingController _controller;
  late final FocusNode _focus;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focus = FocusNode()..addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant ReportDoctorNameField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focus.hasFocus &&
        oldWidget.value != widget.value &&
        _controller.text.trim() != widget.value.trim()) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focus.hasFocus) _commit();
  }

  Future<void> _commit() async {
    final next = _controller.text.trim();
    if (next == widget.value.trim() || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(next);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focus,
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: 'Doctor',
        hintText: 'Type any name for the printed result',
        helperText: 'Free text. This name is what appears on the printout.',
        isDense: true,
        suffixIcon: _saving
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : const Icon(Icons.edit_outlined),
      ),
      onSubmitted: (_) => _commit(),
      onChanged: widget.onChanged,
    );
  }
}
