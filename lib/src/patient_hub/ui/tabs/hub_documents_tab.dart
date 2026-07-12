import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../patient_chart/models/archived_encounter_models.dart';
import '../../../patient_chart/providers/patient_chart_providers.dart';
import '../../../patient_chart/ui/widgets/archived_encounter_tile.dart';
import '../../../patient_chart/ui/widgets/archived_encounter_upload_sheet.dart';
import '../../../providers/auth_provider.dart';
import '../../permissions/patient_hub_permissions.dart';
import '../../providers/patient_hub_providers.dart';
import '../../widgets/hub_empty_state.dart';
import '../../widgets/patient_hub_scope.dart';

@RoutePage()
class HubDocumentsScreen extends ConsumerStatefulWidget {
  const HubDocumentsScreen({super.key});

  @override
  ConsumerState<HubDocumentsScreen> createState() => _HubDocumentsScreenState();
}

class _HubDocumentsScreenState extends ConsumerState<HubDocumentsScreen> {
  bool _loading = true;
  List<PatientArchivedEncounter> _groups = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final patientUuid = PatientHubScope.requirePatientUuid(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ref
          .read(patientHubServiceProvider)
          .listArchivedEncounters(patientUuid);
      if (mounted) {
        setState(() {
          _groups = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _upload() async {
    final patientUuid = PatientHubScope.requirePatientUuid(context);
    final chartService = ref.read(patientChartServiceProvider);
    final uploaded = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ArchivedEncounterUploadSheet(
        patientUuid: patientUuid,
        service: chartService,
        onUploaded: () {},
      ),
    );
    if (uploaded == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(authProvider).staff;
    final canUpload = canUploadDocumentsInPatientHub(staff);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    return ResponsiveBody(
      builder: (context, bp) => Stack(
      children: [
        _groups.isEmpty
            ? HubEmptyState(
                title: 'No uploaded documents',
                subtitle: canUpload
                    ? 'Upload scanned encounters and files. A description is required for each upload.'
                    : 'Scanned encounters and files appear here.',
                icon: Icons.folder_copy_outlined,
                action: canUpload
                    ? FilledButton.icon(
                        onPressed: _upload,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload document'),
                      )
                    : null,
              )
            : ArchivedEncountersList(
                groups: _groups,
                service: ref.read(patientChartServiceProvider),
                staff: staff,
                onChanged: _load,
              ),
        if (canUpload && _groups.isNotEmpty)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: _upload,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload'),
            ),
          ),
      ],
      ),
    );
  }
}
