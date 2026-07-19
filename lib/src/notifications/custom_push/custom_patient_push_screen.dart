import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/notifications/custom_push/custom_push_endpoints.dart';
import 'package:helty/src/notifications/custom_push/custom_push_models.dart';
import 'package:helty/src/notifications/custom_push/custom_push_providers.dart';
import 'package:helty/src/notifications/custom_push_permissions.dart';
import 'package:helty/src/paitients/patient_model.dart';
import 'package:helty/src/providers/auth_provider.dart';

@RoutePage()
class CustomPatientPushScreen extends ConsumerStatefulWidget {
  const CustomPatientPushScreen({super.key});

  @override
  ConsumerState<CustomPatientPushScreen> createState() =>
      _CustomPatientPushScreenState();
}

class _CustomPatientPushScreenState
    extends ConsumerState<CustomPatientPushScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  /// `true` = all registered patients; `false` = selected only.
  bool _broadcastAll = true;
  final Map<String, Patient> _selected = {};
  List<Patient> _searchResults = [];
  bool _searching = false;
  bool _sending = false;
  String? _searchError;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _imageUrlCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _runSearch(query);
    });
  }

  Future<void> _runSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _searchResults = [];
        _searchError = null;
        _searching = false;
      });
      return;
    }
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final patients = await ref
          .read(customPushPatientServiceProvider)
          .searchPatients(q, true);
      if (!mounted) return;
      setState(() {
        _searchResults = patients;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _searchError = _errorMessage(e);
        _searchResults = [];
      });
    }
  }

  String _errorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        final msg = data['message'];
        if (msg is List) return msg.join(', ');
        return msg.toString();
      }
      if (e.response?.statusCode == 403) {
        return 'You do not have permission to send patient notifications.';
      }
      if (e.response?.statusCode == 401) {
        return 'Session expired. Please sign in again.';
      }
      return e.message ?? e.toString();
    }
    return e.toString();
  }

  Future<void> _send() async {
    final validationError = validateCustomPushFields(
      title: _titleCtrl.text,
      body: _bodyCtrl.text,
      imageUrl: _imageUrlCtrl.text,
    );
    if (validationError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }

    if (!_broadcastAll && _selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one patient, or choose all patients.'),
        ),
      );
      return;
    }

    if (_broadcastAll) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Broadcast to all patients?'),
          content: const Text(
            'This will send a push notification to every patient who has a '
            'registered device. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Send to all'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _sending = true);
    try {
      final result = await ref
          .read(customPushServiceProvider)
          .sendCustomPush(
            title: _titleCtrl.text,
            body: _bodyCtrl.text,
            imageUrl: _imageUrlCtrl.text,
            patientIds: _broadcastAll ? null : _selected.keys.toList(),
          );
      if (!mounted) return;
      _titleCtrl.clear();
      _bodyCtrl.clear();
      _imageUrlCtrl.clear();
      _searchCtrl.clear();
      setState(() {
        _selected.clear();
        _searchResults = [];
        _broadcastAll = true;
        _sending = false;
      });
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Notification sent'),
          content: Text(
            'Target: ${result.targetType}\n'
            'Patients reached: ${result.targetedPatients}\n'
            'Deliveries succeeded: ${result.successCount}\n'
            'Deliveries failed: ${result.failureCount}',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(currentStaffProvider);
    if (!canSendCustomPatientPush(staff)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Patient notifications')),
        body: const Center(child: Text('Access denied for this account.')),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Patient notifications')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send patient notification (POST ${CustomPushEndpoints.custom})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manual announcements and marketing pushes. Appointment '
              'notifications are sent automatically by the server.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _titleCtrl,
                      maxLength: kCustomPushTitleMaxLength,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'Clinic update',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _bodyCtrl,
                      maxLength: kCustomPushBodyMaxLength,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Message body',
                        hintText: 'OPD opens at 9am tomorrow…',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _imageUrlCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Image URL (optional)',
                        hintText: 'https://cdn.example.com/notice.png',
                        helperText:
                            'Public HTTPS URL only — do not upload files here.',
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Recipients',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(
                          value: true,
                          label: Text('All patients'),
                          icon: Icon(Icons.groups_outlined),
                        ),
                        ButtonSegment<bool>(
                          value: false,
                          label: Text('Selected'),
                          icon: Icon(Icons.person_search_outlined),
                        ),
                      ],
                      selected: {_broadcastAll},
                      onSelectionChanged: (s) {
                        setState(() => _broadcastAll = s.first);
                      },
                    ),
                    if (!_broadcastAll) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          labelText: 'Search patients',
                          hintText: 'Name, card no, or patient ID',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searching
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        onChanged: _onSearchChanged,
                      ),
                      if (_searchError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _searchError!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                      if (_searchResults.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 220),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final p = _searchResults[index];
                              final id = p.id;
                              if (id == null || id.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              final selected = _selected.containsKey(id);
                              return ListTile(
                                dense: true,
                                title: Text(p.displayName),
                                subtitle: Text(
                                  [
                                    if (p.patientId.isNotEmpty) p.patientId,
                                    if (p.cardNo.isNotEmpty) 'Card ${p.cardNo}',
                                  ].join(' · '),
                                ),
                                trailing: Icon(
                                  selected
                                      ? Icons.check_circle
                                      : Icons.add_circle_outline,
                                  color: selected
                                      ? theme.colorScheme.primary
                                      : null,
                                ),
                                onTap: () {
                                  setState(() {
                                    if (selected) {
                                      _selected.remove(id);
                                    } else {
                                      _selected[id] = p;
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                      if (_selected.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          '${_selected.length} selected',
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final entry in _selected.entries)
                              InputChip(
                                label: Text(entry.value.displayName),
                                onDeleted: () {
                                  setState(() => _selected.remove(entry.key));
                                },
                              ),
                          ],
                        ),
                      ],
                    ],
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: _sending ? null : _send,
                        icon: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_outlined),
                        label: Text(
                          _broadcastAll ? 'Send to all patients' : 'Send',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
