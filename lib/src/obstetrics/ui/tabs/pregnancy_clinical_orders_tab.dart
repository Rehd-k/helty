import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/clinical_packages/models/clinical_package_models.dart';
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_imaging_tab.dart';
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_investigations_tab.dart';
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_prescription_tab.dart';
import 'package:helty/src/obstetrics/models/obstetrics_models.dart';
import 'package:helty/src/obstetrics/ui/pregnancy_view_screen.dart';
import 'package:helty/src/obstetrics/ui/widgets/antenatal_package_scope.dart';
import 'package:helty/src/obstetrics/ui/widgets/pregnancy_encounter_scope_bridge.dart';
import 'package:helty/src/providers/service_providers.dart';

@RoutePage()
class ObstetricsPregnancyClinicalOrdersTab extends ConsumerStatefulWidget {
  const ObstetricsPregnancyClinicalOrdersTab({super.key});

  @override
  ConsumerState<ObstetricsPregnancyClinicalOrdersTab> createState() =>
      _ObstetricsPregnancyClinicalOrdersTabState();
}

class _ObstetricsPregnancyClinicalOrdersTabState
    extends ConsumerState<ObstetricsPregnancyClinicalOrdersTab>
    with SingleTickerProviderStateMixin {
  TabController? _subTabController;
  DefaultAntenatalPackage? _defaultPackage;
  bool _loadingPackage = true;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 3, vsync: this);
    _loadPackage();
  }

  @override
  void dispose() {
    _subTabController?.dispose();
    super.dispose();
  }

  Future<void> _loadPackage() async {
    setState(() => _loadingPackage = true);
    try {
      final pkg = await ref
          .read(clinicalPackageServiceProvider)
          .getDefaultAntenatal();
      if (!mounted) return;
      setState(() {
        _defaultPackage = pkg;
        _loadingPackage = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPackage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pregnancyScope = PregnancyViewScope.of(context);
    final pregnancy = pregnancyScope?.pregnancy;
    final theme = Theme.of(context);
    final notOngoing = pregnancy != null &&
        pregnancy.status != null &&
        pregnancy.status != PregnancyStatus.ONGOING;

    final serviceIds = _defaultPackage?.serviceIds ?? const {};
    final drugIds = _defaultPackage?.drugIds ?? const {};

    return AntenatalPackageScope(
      serviceIds: serviceIds,
      drugIds: drugIds,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (notOngoing)
            MaterialBanner(
              content: Text(
                'This pregnancy is ${pregnancy.status!.name.toLowerCase()}. '
                'Clinical orders are read-only.',
              ),
              leading: const Icon(Icons.info_outline),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              actions: const [SizedBox.shrink()],
            ),
          if (_loadingPackage)
            const LinearProgressIndicator(minHeight: 2),
          TabBar(
            controller: _subTabController,
            tabs: const [
              Tab(text: 'Prescriptions'),
              Tab(text: 'Labs'),
              Tab(text: 'Imaging'),
            ],
          ),
          Expanded(
            child: PregnancyEncounterScopeBridge(
              child: TabBarView(
                controller: _subTabController,
                children: const [
                  DoctorEncounterPrescriptionTab(),
                  DoctorEncounterInvestigationsTab(),
                  DoctorEncounterImagingTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
