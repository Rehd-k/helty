import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/reports/services/hospital_reports_service.dart';

@RoutePage()
class HospitalReportsHubScreen extends StatelessWidget {
  const HospitalReportsHubScreen({
    super.key,
    this.presetRequestType,
  });

  /// When set (lab / radiology / pharmacy), opens requests-by-ward with that type first.
  final String? presetRequestType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reports = <_Tile>[
      _Tile(
        'Ward admissions',
        Icons.bed_outlined,
        HospitalReportKind.wardAdmissions,
      ),
      _Tile(
        'Requests by ward',
        Icons.account_tree_outlined,
        HospitalReportKind.requestsByWard,
        requestType: presetRequestType ?? 'lab',
      ),
      _Tile(
        'Discharge history',
        Icons.logout_outlined,
        HospitalReportKind.dischargeHistory,
      ),
      _Tile(
        'Attendance (medical records)',
        Icons.fact_check_outlined,
        HospitalReportKind.medicalRecordsAttendance,
      ),
      _Tile(
        'Admissions summary',
        Icons.analytics_outlined,
        HospitalReportKind.medicalRecordsAdmissions,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Hospital reports'),
      ),
      body: ResponsiveBody(
        builder: (context, bp) => ListView(
          children: [
            Text(
              'Date-ranged operational reports with CSV / Excel export and print.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            ResponsiveWrapGrid(
              mobileColumns: 1,
              tabletColumns: 2,
              desktopColumns: 3,
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final r in reports)
                  Card(
                    elevation: 0,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    child: InkWell(
                      onTap: () => context.router.push(
                        HospitalReportRoute(
                          kind: r.kind,
                          initialRequestType: r.requestType,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(r.icon, color: theme.colorScheme.primary),
                            Text(
                              r.label,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile {
  const _Tile(this.label, this.icon, this.kind, {this.requestType});
  final String label;
  final IconData icon;
  final HospitalReportKind kind;
  final String? requestType;
}
