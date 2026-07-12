import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/obstetrics/models/obstetrics_models.dart';
import 'package:helty/src/obstetrics/services/obstetrics_service.dart';
import 'package:helty/src/obstetrics/ui/pregnancy_view_screen.dart';
import 'package:helty/src/obstetrics/ui/widgets/obstetrics_cards.dart';
import 'package:helty/src/obstetrics/ui/widgets/obstetrics_theme.dart';
import 'package:helty/src/obstetrics/utils/obstetrics_display.dart';
import 'package:helty/src/providers/service_providers.dart';

@RoutePage()
class ObstetricsPregnancyOverviewTab extends ConsumerStatefulWidget {
  final String? pregnancyId;

  const ObstetricsPregnancyOverviewTab({
    super.key,
    this.pregnancyId,
  });

  @override
  ConsumerState<ObstetricsPregnancyOverviewTab> createState() =>
      _ObstetricsPregnancyOverviewTabState();
}

class _ObstetricsPregnancyOverviewTabState
    extends ConsumerState<ObstetricsPregnancyOverviewTab> {
  Pregnancy? _pregnancy;
  bool _loading = false;
  String? _error;

  ObstetricsService get _service => ref.read(obstetricsServiceProvider);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = PregnancyViewScope.of(context);
    final id = widget.pregnancyId ?? scope?.pregnancyId;
    if (scope?.pregnancy != null) {
      setState(() {
        _pregnancy = scope!.pregnancy;
        _loading = false;
      });
      return;
    }
    if (id != null && id.isNotEmpty && _pregnancy == null && !_loading) {
      _load(id);
    }
  }

  Future<void> _load(String id) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await _service.getPregnancy(id);
      if (!mounted) return;
      setState(() {
        _pregnancy = p;
        _loading = false;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pregnancyId =
        widget.pregnancyId ?? PregnancyViewScope.of(context)?.pregnancyId;
    if (pregnancyId == null || pregnancyId.isEmpty) {
      return const Center(child: Text('Missing pregnancy context'));
    }

    if (_loading && _pregnancy == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _pregnancy == null) {
      return Center(child: Text(_error!));
    }
    final p = _pregnancy;
    if (p == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final glance = pregnancyAtAGlance(p);
    final latest = latestAntenatalVisit(p);
    final theme = Theme.of(context);

    return ResponsiveBody(
      center: false,
      bottomPadding: 0,
      builder: (context, bp) => ListView(
        children: [
          ObSectionHeader(title: 'Summary'),
          ResponsiveWrapGrid(
            mobileColumns: 1,
            tabletColumns: 2,
            desktopColumns: 2,
            children: [
              ObInfoTile(
                icon: Icons.pregnant_woman_rounded,
                label: 'Gravida / Para',
                value: pregnancyGpLabel(p),
              ),
              ObInfoTile(
                icon: Icons.event_rounded,
                label: 'EDD countdown',
                value: formatEddCountdown(glance.daysUntilEdd),
                accentColor: theme.colorScheme.tertiary,
              ),
              ObInfoTile(
                icon: Icons.calendar_today_rounded,
                label: 'Booking',
                value: p.bookingDate != null
                    ? DateFormatter.formatFromBackend(
                        p.bookingDate,
                        DateFormatter.shortDate,
                      )
                    : '—',
              ),
              ObInfoTile(
                icon: Icons.flag_rounded,
                label: 'Outcome',
                value: (p.outcome != null && p.outcome!.isNotEmpty)
                    ? p.outcome!
                    : '—',
              ),
            ],
          ),
        if (pregnancyBookingSummaryLines(p).isNotEmpty) ...[
          const SizedBox(height: 20),
          ObSectionHeader(title: 'Booking assessment'),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: ObstetricsTheme.borderRadius,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                pregnancyBookingSummaryLines(p).join(' · '),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        ObSectionHeader(title: 'Last antenatal visit'),
        Card(
          shape: RoundedRectangleBorder(borderRadius: ObstetricsTheme.borderRadius),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: latest == null
                ? Text(
                    'No visits recorded yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatAntenatalVisitDate(latest.visitDate),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        [
                          () {
                            final (weeks, days) = gestationalAgeParts(latest);
                            final ga = formatGestationalAge(weeks, days);
                            return ga != '—' ? ga : null;
                          }(),
                          if (latest.systolicBP != null &&
                              latest.diastolicBP != null)
                            'BP ${latest.systolicBP}/${latest.diastolicBP}',
                          if (latest.fetalHeartRate != null)
                            'FHR ${latest.fetalHeartRate}',
                          if (latest.presentation != null)
                            formatPresentation(latest.presentation),
                          if (latest.descent != null &&
                              latest.descent!.isNotEmpty)
                            'Descent ${latest.descent}',
                          if (latest.urineProtein != null &&
                              latest.urineProtein!.isNotEmpty)
                            'Protein ${latest.urineProtein}',
                          if (latest.urineGlucose != null &&
                              latest.urineGlucose!.isNotEmpty)
                            'Glucose ${latest.urineGlucose}',
                          if (latest.pcv != null) 'PCV ${latest.pcv}%',
                        ].whereType<String>().join(' · '),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 20),
        ObSectionHeader(title: 'Care pathway'),
        Card(
          shape: RoundedRectangleBorder(borderRadius: ObstetricsTheme.borderRadius),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ObStatChip(
                  label:
                      '${glance.visitCount ?? 0} antenatal visit${(glance.visitCount ?? 0) == 1 ? '' : 's'}',
                  icon: Icons.event_note_rounded,
                ),
                ObStatChip(
                  label:
                      '${glance.deliveryCount ?? 0} deliver${(glance.deliveryCount ?? 0) == 1 ? 'y' : 'ies'}',
                  icon: Icons.local_hospital_rounded,
                  backgroundColor: theme.colorScheme.tertiaryContainer,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
                ObStatChip(
                  label: pregnancyStatusLabel(p.status),
                  color: pregnancyStatusColor(p.status, theme.colorScheme),
                  backgroundColor:
                      pregnancyStatusContainerColor(p.status, theme.colorScheme),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _Row(label: 'LMP', value: DateFormatter.formatFromBackend(p.lmp, DateFormatter.shortDate)),
        _Row(label: 'EDD', value: DateFormatter.formatFromBackend(p.edd, DateFormatter.shortDate)),
        if (p.patient != null && p.patient!.displayName.isNotEmpty)
          _Row(label: 'Patient', value: p.patient!.displayName),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
