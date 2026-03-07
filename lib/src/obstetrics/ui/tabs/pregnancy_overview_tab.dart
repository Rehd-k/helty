import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/obstetrics/models/obstetrics_models.dart';
import 'package:helty/src/obstetrics/services/obstetrics_service.dart';
import 'package:helty/src/obstetrics/ui/pregnancy_view_screen.dart';
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
  bool _loading = true;
  String? _error;

  ObstetricsService get _service => ref.read(obstetricsServiceProvider);

  String? _pregnancyIdFromScope;
  String? _loadedId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pregnancyIdFromScope = PregnancyViewScope.of(context)?.pregnancyId;
    final id = widget.pregnancyId ?? _pregnancyIdFromScope;
    if (id != null && id.isNotEmpty && _loadedId != id) {
      _loadedId = id;
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
    final pregnancyId = widget.pregnancyId ?? _pregnancyIdFromScope ?? PregnancyViewScope.of(context)?.pregnancyId;
    if (pregnancyId == null || pregnancyId.isEmpty) {
      return const Center(child: Text('Missing pregnancy context'));
    }
    final theme = Theme.of(context);

    if (_loading && _pregnancy == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _pregnancy == null) {
      return Center(child: Text(_error!));
    }
    final p = _pregnancy!;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _Row(label: 'Gravida', value: '${p.gravida}'),
                _Row(label: 'Para', value: '${p.para}'),
                _Row(label: 'LMP', value: p.lmp),
                _Row(label: 'EDD', value: p.edd),
                _Row(label: 'Status', value: p.status?.name ?? '—'),
                if (p.bookingDate != null)
                  _Row(label: 'Booking date', value: p.bookingDate!),
                if (p.outcome != null && p.outcome!.isNotEmpty)
                  _Row(label: 'Outcome', value: p.outcome!),
                if (p.patient != null)
                  _Row(
                    label: 'Patient',
                    value: p.patient!.displayName,
                  ),
              ],
            ),
          ),
        ),
      ],
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
            width: 120,
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
