import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/frontdesk/patient_access/patient_access_models.dart';
import 'package:helty/src/frontdesk/patient_access/patient_access_providers.dart';
import 'package:helty/src/frontdesk/patient_access_permissions.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/widgets/empty.widget.dart';

@RoutePage()
class PatientLoginCodesScreen extends ConsumerStatefulWidget {
  const PatientLoginCodesScreen({super.key});

  @override
  ConsumerState<PatientLoginCodesScreen> createState() =>
      _PatientLoginCodesScreenState();
}

class _PatientLoginCodesScreenState
    extends ConsumerState<PatientLoginCodesScreen> {
  Timer? _poll;
  List<PatientLoginCodeRow> _items = [];
  String _delivery = 'staff';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_load);
    _poll = Timer.periodic(const Duration(seconds: 8), (_) => _load(quiet: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load({bool quiet = false}) async {
    if (!quiet && mounted) {
      setState(() {
        _loading = _items.isEmpty;
        _error = null;
      });
    }
    try {
      final page = await ref.read(patientAccessServiceProvider).listLoginCodes();
      if (!mounted) return;
      setState(() {
        _items = page.items;
        _delivery = page.delivery;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load login codes.';
      });
    }
  }

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(currentStaffProvider);
    if (!canManagePatientAppAccess(staff)) {
      return Scaffold(
        appBar: AppBar(title: const Text('App login codes')),
        body: const Center(child: Text('Access denied for this account.')),
      );
    }

    final phoneOnly = _delivery == 'phone';

    return Scaffold(
      appBar: AppBar(title: const Text('App login codes')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              phoneOnly
                  ? 'Codes are sent to the patient by SMS or WhatsApp. This list shows who requested one.'
                  : 'Read the code to the patient. It expires 10 minutes after it is requested.',
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _load(),
                    child: _items.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              EmptyStateWidget(
                                icon: Icons.pin_outlined,
                                title: 'No active codes',
                                message:
                                    'When a patient starts app activation or a password reset, the code shows here.',
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: _items.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final row = _items[index];
                              final expires = row.expiresAt == null
                                  ? ''
                                  : DateFormatter.dateTime24(row.expiresAt!);
                              return Card(
                                child: ListTile(
                                  title: Text(
                                    row.patientName.isEmpty
                                        ? row.hospitalPatientId
                                        : row.patientName,
                                  ),
                                  subtitle: SelectableText(
                                    [
                                      if (row.hospitalPatientId.isNotEmpty)
                                        row.hospitalPatientId,
                                      if ((row.phoneNumber ?? '').isNotEmpty)
                                        row.phoneNumber!,
                                      row.purposeLabel,
                                      if (expires.isNotEmpty) 'Expires $expires',
                                      if (row.code != null) 'Code ${row.code}',
                                      if (row.code == null && row.sentToPhone)
                                        'Sent to the patient\'s phone',
                                    ].join('\n'),
                                  ),
                                  isThreeLine: true,
                                  trailing: row.code == null
                                      ? null
                                      : IconButton(
                                          tooltip: 'Copy',
                                          onPressed: () => _copy(row.code!),
                                          icon: const Icon(Icons.copy),
                                        ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
