import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/admission_alert_model.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_view_scope.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';
import 'package:helty/src/services/admission_alert_service.dart';

@RoutePage()
class InpatientAlertsScreen extends StatefulWidget {
  const InpatientAlertsScreen({super.key});

  @override
  State<InpatientAlertsScreen> createState() => _InpatientAlertsScreenState();
}

class _InpatientAlertsScreenState extends State<InpatientAlertsScreen> {
  final _service = AdmissionAlertService();
  List<AdmissionAlertModel> _alerts = [];
  bool _loading = true;
  String? _error;
  String? _lastAdmissionId;
  final Set<String> _resolving = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = InpatientViewScope.of(context)?.admissionId;
    if (id == null || id.isEmpty) {
      if (_lastAdmissionId != null) {
        setState(() {
          _alerts = [];
          _loading = false;
          _error = null;
          _lastAdmissionId = null;
        });
      }
      return;
    }
    if (id != _lastAdmissionId) {
      _lastAdmissionId = id;
      _load(id);
    }
  }

  Future<void> _load(String admissionId) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.list(admissionId);
      if (!mounted) return;
      setState(() {
        _alerts = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _alerts = [];
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String _dioMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return e.message ?? 'Request failed';
  }

  Future<void> _resolve(
    BuildContext context,
    String admissionId,
    AdmissionAlertModel alert,
  ) async {
    setState(() => _resolving.add(alert.id));
    try {
      await _service.resolve(admissionId: admissionId, alertId: alert.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alert resolved.')),
        );
      }
      await _load(admissionId);
    } on DioException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_dioMessage(e))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _resolving.remove(alert.id));
      }
    }
  }

  String _relativeTime(DateTime? t) {
    if (t == null) return '—';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes} mins ago';
    if (d.inHours < 24) return '${d.inHours} hr ago';
    return DateFormatter.dateTime(t);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final scope = InpatientViewScope.of(context);
    final admissionId = scope?.admissionId;

    if (admissionId == null || admissionId.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('Open this patient with an admission to view alerts.'),
        ),
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
            TextButton(
              onPressed: () => _load(admissionId),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return ResponsiveBody(
      expand: false,
      builder: (context, bp) => SingleChildScrollView(
        child: SectionCard(
        title: 'Alerts',
        subtitle:
            'Clinical and workflow alerts for this admission',
        child: _alerts.isEmpty
            ? Text(
                'No alerts recorded for this admission.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
              )
            : Column(
                children: [
                  for (var i = 0; i < _alerts.length; i++) ...[
                    if (i > 0) const Divider(height: 20),
                    _AlertTile(
                      alert: _alerts[i],
                      resolving: _resolving.contains(_alerts[i].id),
                      relativeTime: _relativeTime(_alerts[i].createdAt),
                      onResolve: _alerts[i].isResolved
                          ? null
                          : () => _resolve(context, admissionId, _alerts[i]),
                      onGoToMar: _alerts[i].isMedicationAlert
                          ? () => AutoTabsRouter.of(context).setActiveIndex(2)
                          : null,
                    ),
                  ],
                ],
              ),
      ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({
    required this.alert,
    required this.relativeTime,
    required this.resolving,
    this.onResolve,
    this.onGoToMar,
  });

  final AdmissionAlertModel alert;
  final String relativeTime;
  final bool resolving;
  final VoidCallback? onResolve;
  final VoidCallback? onGoToMar;

  String? get _dueLabel {
    final due = alert.dueAt;
    if (due == null) return null;
    return 'Due ${DateFormatter.timeOnly(due)} · ${DateFormatter.shortDate(due)}';
  }

  IconData get _alertIcon {
    final type = alert.type?.toUpperCase() ?? '';
    if (type.contains('OVERDUE')) return Icons.warning_amber_rounded;
    if (type.contains('MEDICATION')) return Icons.medication_outlined;
    return Icons.notifications_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Color color;
    switch ((alert.severity ?? '').toLowerCase()) {
      case 'critical':
        color = scheme.error;
        break;
      case 'high':
        color = scheme.error;
        break;
      default:
        color = scheme.tertiary;
    }

    final message = (alert.message ?? '').trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(_alertIcon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                alert.isMedicationAlert
                    ? alert.medicationDrugName
                    : (alert.title ?? 'Alert'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (alert.isMedicationAlert && alert.title != null) ...[
                const SizedBox(height: 2),
                Text(
                  alert.title!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.65),
                      ),
                ),
              ],
              if (message.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.85),
                      ),
                ),
              ],
              if (_dueLabel != null) ...[
                const SizedBox(height: 4),
                Text(
                  _dueLabel!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    alert.isResolved ? 'Resolved' : relativeTime,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                  ),
                  if (!alert.isResolved && onGoToMar != null)
                    TextButton(
                      onPressed: onGoToMar,
                      child: const Text('Go to MAR'),
                    ),
                  if (!alert.isResolved && onResolve != null)
                    OutlinedButton(
                      onPressed: resolving ? null : onResolve,
                      child: resolving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Resolve'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
