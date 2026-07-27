import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/lab/widgets/lab_order_results_dialog.dart';
import 'package:helty/src/models/lab_order_model.dart';
import 'package:helty/src/obstetrics/models/pregnancy_clinical_models.dart';
import 'package:helty/src/obstetrics/ui/pregnancy_view_screen.dart';
import 'package:helty/src/providers/service_providers.dart';
import 'package:helty/src/radiology/models/radiology_models.dart';
import 'package:helty/src/radiology/services/radiology_service.dart';
import 'package:helty/src/radiology/ui/widgets/radiology_image_viewer.dart';

@RoutePage()
class ObstetricsPregnancyClinicalResultsTab extends ConsumerStatefulWidget {
  const ObstetricsPregnancyClinicalResultsTab({super.key});

  @override
  ConsumerState<ObstetricsPregnancyClinicalResultsTab> createState() =>
      _ObstetricsPregnancyClinicalResultsTabState();
}

class _ObstetricsPregnancyClinicalResultsTabState
    extends ConsumerState<ObstetricsPregnancyClinicalResultsTab> {
  PregnancyClinicalResultsBundle? _bundle;
  bool _loading = true;
  String? _error;
  bool _loadScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadScheduled) {
      _loadScheduled = true;
      _load();
    }
  }

  Future<void> _load() async {
    final scope = PregnancyViewScope.of(context);
    if (scope == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bundle = await ref
          .read(obstetricsServiceProvider)
          .getClinicalResults(scope.pregnancyId);
      if (!mounted) return;
      setState(() {
        _bundle = bundle;
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

  bool _labHasResults(LabOrderModel order) {
    if (order.resultLines != null && order.resultLines!.isNotEmpty) {
      return true;
    }
    final status = order.status.toUpperCase();
    return status.contains('COMPLET') || status.contains('RESULT');
  }

  bool _radiologyHasReport(RadiologyOrder order) {
    if (order.status == RadiologyOrderStatus.COMPLETED) return true;
    return order.items.any((i) {
      final report = i.report;
      if (report == null) return false;
      return (report.findings?.trim().isNotEmpty ?? false) ||
          (report.impression?.trim().isNotEmpty ?? false);
    });
  }

  void _openLabResults(LabOrderModel order) {
    showLabOrderResultsDialog(context, order: order);
  }

  Future<void> _openRadiologyResults(RadiologyOrder order) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          order.items.isNotEmpty
              ? order.items.first.studyLabel()
              : 'Imaging results',
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final item in order.items) ...[
                  if (item.report?.findings?.trim().isNotEmpty ?? false)
                    Text('Findings: ${item.report!.findings!.trim()}'),
                  if (item.report?.impression?.trim().isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('Impression: ${item.report!.impression!.trim()}'),
                    ),
                  if (item.images != null && item.images!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: RadiologyImageCarousel(
                        service: RadiologyService(),
                        images: item.images!,
                      ),
                    ),
                  const Divider(),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatLabDate(LabOrderModel order) {
    final raw = order.createdAt;
    if (raw == null || raw.isEmpty) return order.status;
    return DateFormatter.formatFromBackend(raw, DateFormatter.dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final bundle = _bundle ?? const PregnancyClinicalResultsBundle();
    final labs = bundle.labOrders.where(_labHasResults).toList();
    final imaging = bundle.radiologyOrders.where(_radiologyHasReport).toList();

    if (labs.isEmpty && imaging.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.3,
              child: Center(
                child: Text(
                  'No clinical results yet for this pregnancy.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ResponsiveBody(
        center: false,
        builder: (context, bp) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (labs.isNotEmpty) ...[
              Text('Laboratory', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              ...labs.map(
                (o) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.biotech_outlined),
                    title: Text(o.testType),
                    subtitle: Text(_formatLabDate(o)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openLabResults(o),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (imaging.isNotEmpty) ...[
              Text('Radiology', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              ...imaging.map(
                (o) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.image_search_outlined),
                    title: Text(
                      o.items.isNotEmpty
                          ? o.items.first.studyLabel()
                          : 'Imaging study',
                    ),
                    subtitle: Text(o.status.name),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openRadiologyResults(o),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
