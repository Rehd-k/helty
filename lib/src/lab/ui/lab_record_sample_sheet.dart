import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/lab/models/lab_models.dart';
import 'package:helty/src/lab/providers/lab_providers.dart';

class LabRecordSampleSheet extends ConsumerStatefulWidget {
  const LabRecordSampleSheet({
    super.key,
    required this.orderItem,
    required this.staffId,
    required this.onSaved,
  });

  final LabOrderItem orderItem;
  final String staffId;
  final VoidCallback onSaved;

  @override
  ConsumerState<LabRecordSampleSheet> createState() =>
      _LabRecordSampleSheetState();
}

class _LabRecordSampleSheetState extends ConsumerState<LabRecordSampleSheet> {
  late DateTime _collectionTime;
  late TextEditingController _barcodeController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _collectionTime = DateTime.now();
    _barcodeController = TextEditingController();
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  String get _sampleType =>
      widget.orderItem.testVersion?.test?.sampleType ?? 'Unknown';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Record sample',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.orderItem.testVersion?.test?.name ?? 'Test',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              _Field(
                label: 'Sample type',
                value: _sampleType,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Collection time'),
                subtitle: Text(
                  '${_collectionTime.year}-${_collectionTime.month.toString().padLeft(2, '0')}-${_collectionTime.day.toString().padLeft(2, '0')} '
                  '${_collectionTime.hour.toString().padLeft(2, '0')}:${_collectionTime.minute.toString().padLeft(2, '0')}',
                ),
                trailing: FilledButton.tonal(
                  onPressed: () async {
                    final time = await showDatePicker(
                      context: context,
                      initialDate: _collectionTime,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (!mounted || time == null) return;
                    final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_collectionTime),
                    );
                    if (!mounted || t == null) return;
                    setState(() {
                      _collectionTime = DateTime(
                        time.year,
                        time.month,
                        time.day,
                        t.hour,
                        t.minute,
                      );
                    });
                  },
                  child: const Text('Change'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _barcodeController,
                decoration: const InputDecoration(
                  labelText: 'Barcode (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save sample'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await ref.read(labApiServiceProvider).createSample(
            orderItemId: widget.orderItem.id,
            sampleType: _sampleType,
            collectedBy: widget.staffId,
            collectionTime: _collectionTime,
            barcode: _barcodeController.text.trim().isEmpty
                ? null
                : _barcodeController.text.trim(),
          );
      widget.onSaved();
    } catch (e) {
      final message = (e is DioException && e.error is ConflictException)
          ? 'Sample already recorded for this item.'
          : e.toString();
      setState(() {
        _error = message;
        _saving = false;
      });
    }
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
