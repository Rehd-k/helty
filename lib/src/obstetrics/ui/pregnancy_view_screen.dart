import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/obstetrics/models/obstetrics_models.dart';
import 'package:helty/src/obstetrics/services/obstetrics_service.dart';
import 'package:helty/src/providers/service_providers.dart';

/// Provides pregnancyId to tab content when router builds tabs without args.
class PregnancyViewScope extends InheritedWidget {
  const PregnancyViewScope({
    super.key,
    required this.pregnancyId,
    required super.child,
  });

  final String pregnancyId;

  static PregnancyViewScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PregnancyViewScope>();

  @override
  bool updateShouldNotify(PregnancyViewScope old) =>
      pregnancyId != old.pregnancyId;
}

@RoutePage()
class ObstetricsPregnancyViewScreen extends ConsumerStatefulWidget {
  final String pregnancyId;

  const ObstetricsPregnancyViewScreen({
    super.key,
    required this.pregnancyId,
  });

  @override
  ConsumerState<ObstetricsPregnancyViewScreen> createState() =>
      _ObstetricsPregnancyViewScreenState();
}

class _ObstetricsPregnancyViewScreenState
    extends ConsumerState<ObstetricsPregnancyViewScreen> {
  Pregnancy? _pregnancy;
  bool _loading = true;
  String? _error;

  ObstetricsService get _service => ref.read(obstetricsServiceProvider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await _service.getPregnancy(widget.pregnancyId);
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
    final theme = Theme.of(context);

    if (_loading && _pregnancy == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pregnancy')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null && _pregnancy == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Pregnancy'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.router.maybePop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.router.maybePop(),
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final p = _pregnancy!;
    return PregnancyViewScope(
      pregnancyId: widget.pregnancyId,
      child: AutoTabsRouter(
        routes: [
          ObstetricsPregnancyOverviewTab(),
          ObstetricsAntenatalVisitsTab(),
          ObstetricsLabourDeliveryTab(),
          ObstetricsPostnatalTab(),
        ],
        builder: (context, child) {
          final tabsRouter = AutoTabsRouter.of(context);
        const labels = [
          'Overview',
          'Antenatal visits',
          'Labour & delivery',
          'Postnatal',
        ];
        return Scaffold(
          appBar: AppBar(
            title: Text('Pregnancy · G${p.gravida}P${p.para}'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.router.maybePop(),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Material(
                color: theme.colorScheme.surface,
                child: Row(
                  children: List.generate(4, (index) {
                    final selected = tabsRouter.activeIndex == index;
                    return Expanded(
                      child: InkWell(
                        onTap: () => tabsRouter.setActiveIndex(index),
                        child: Center(
                          child: Text(
                            labels[index],
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: selected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight:
                                  selected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: _load,
            child: child,
          ),
        );
        },
      ),
    );
  }
}
