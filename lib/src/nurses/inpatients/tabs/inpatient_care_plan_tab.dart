import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/models/care_plan_model.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_view_scope.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';
import 'package:helty/src/services/care_plan_service.dart';

@RoutePage()
class InpatientCarePlanScreen extends StatefulWidget {
  const InpatientCarePlanScreen({super.key});

  @override
  State<InpatientCarePlanScreen> createState() =>
      _InpatientCarePlanScreenState();
}

class _InpatientCarePlanScreenState extends State<InpatientCarePlanScreen> {
  final _service = CarePlanService();
  List<CarePlanModel> _plans = [];
  bool _loading = true;
  String? _error;
  String? _lastAdmissionId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = InpatientViewScope.of(context)?.admissionId;
    if (id == null || id.isEmpty) {
      if (_lastAdmissionId != null) {
        setState(() {
          _plans = [];
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
        _plans = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _plans = [];
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

  Future<void> _patchPlan(
    BuildContext context,
    String admissionId,
    CarePlanModel plan, {
    String? status,
    String? evaluation,
  }) async {
    try {
      await _service.update(
        admissionId: admissionId,
        carePlanId: plan.id,
        status: status,
        evaluation: evaluation ?? plan.evaluation,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Care plan updated.')),
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
    }
  }

  Future<void> _openEvaluationDialog(
    BuildContext context,
    String admissionId,
    CarePlanModel plan,
  ) async {
    final ctrl = TextEditingController(text: plan.evaluation ?? '');
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update evaluation'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Evaluation',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _patchPlan(
                context,
                admissionId,
                plan,
                evaluation: ctrl.text.trim(),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = InpatientViewScope.of(context);
    final admissionId = scope?.admissionId;

    if (admissionId == null || admissionId.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('Open this patient with an admission for care plans.'),
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
            Text(_error!, textAlign: TextAlign.center),
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
        title: 'Care Plan',
        subtitle: 'Nursing problems, goals and interventions',
        child: _plans.isEmpty
            ? Text(
                'No care plans yet for this admission.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              )
            : Column(
                children: _plans
                    .map(
                      (p) => _CarePlanProblemTile(
                        plan: p,
                        onMarkAchieved: () => _patchPlan(
                          context,
                          admissionId,
                          p,
                          status: 'ACHIEVED',
                        ),
                        onUpdateEvaluation: () => _openEvaluationDialog(
                          context,
                          admissionId,
                          p,
                        ),
                      ),
                    )
                    .toList(),
              ),
        ),
      ),
    );
  }
}

class _CarePlanProblemTile extends StatelessWidget {
  const _CarePlanProblemTile({
    required this.plan,
    required this.onMarkAchieved,
    required this.onUpdateEvaluation,
  });

  final CarePlanModel plan;
  final VoidCallback onMarkAchieved;
  final VoidCallback onUpdateEvaluation;

  @override
  Widget build(BuildContext context) {
    final title = plan.problem?.trim().isNotEmpty == true
        ? plan.problem!
        : 'Care plan';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Text(
          [
            if (plan.recorderDisplayName != null &&
                plan.recorderDisplayName!.isNotEmpty)
              'Recorded by ${plan.recorderDisplayName}',
            plan.goal?.isNotEmpty == true
                ? 'Goal: ${plan.goal}'
                : 'Goal: —',
          ].join(' · '),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        children: [
          if (plan.interventions?.isNotEmpty == true)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Interventions: ${plan.interventions}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          if (plan.evaluation?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Evaluation: ${plan.evaluation}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
          if (plan.status?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Status: ${plan.status}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: onMarkAchieved,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Mark achieved'),
                ),
                OutlinedButton.icon(
                  onPressed: onUpdateEvaluation,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Update evaluation'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
