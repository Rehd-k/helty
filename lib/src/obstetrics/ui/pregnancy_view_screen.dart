import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/obstetrics/models/obstetrics_models.dart';
import 'package:helty/src/obstetrics/services/obstetrics_service.dart';
import 'package:helty/src/obstetrics/ui/widgets/obstetrics_cards.dart';
import 'package:helty/src/obstetrics/utils/obstetrics_display.dart';
import 'package:helty/src/providers/service_providers.dart';

/// Provides pregnancy context to tab content.
class PregnancyViewScope extends InheritedWidget {
  const PregnancyViewScope({
    super.key,
    required this.pregnancyId,
    this.encounterId,
    this.pregnancy,
    this.onRefresh,
    required super.child,
  });

  final String pregnancyId;
  final String? encounterId;
  final Pregnancy? pregnancy;
  final Future<void> Function()? onRefresh;

  static PregnancyViewScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PregnancyViewScope>();

  @override
  bool updateShouldNotify(PregnancyViewScope old) =>
      pregnancyId != old.pregnancyId ||
      encounterId != old.encounterId ||
      pregnancy != old.pregnancy;
}

@RoutePage()
class ObstetricsPregnancyViewScreen extends ConsumerStatefulWidget {
  final String pregnancyId;
  final String? encounterId;

  const ObstetricsPregnancyViewScreen({
    super.key,
    required this.pregnancyId,
    this.encounterId,
  });

  @override
  ConsumerState<ObstetricsPregnancyViewScreen> createState() =>
      _ObstetricsPregnancyViewScreenState();
}

class _ObstetricsPregnancyViewScreenState
    extends ConsumerState<ObstetricsPregnancyViewScreen>
    with SingleTickerProviderStateMixin {
  Pregnancy? _pregnancy;
  bool _loading = true;
  String? _error;
  TabController? _tabController;

  ObstetricsService get _service => ref.read(obstetricsServiceProvider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
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

  int _tabCount(Pregnancy p, int index) {
    switch (index) {
      case 1:
        return p.antenatalVisits?.length ?? 0;
      case 2:
        return p.labourDeliveries?.length ?? 0;
      case 3:
        // Postnatal visits are not embedded on LabourDelivery in our current
        // model. The Postnatal tab fetches them separately, so we avoid
        // misleading counts here.
        return 0;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_loading && _pregnancy == null) {
      return Scaffold(
        backgroundColor: colorScheme.surfaceContainerLowest,
        appBar: AppBar(title: const Text('Pregnancy')),
        body: ResponsiveBody(
          builder: (context, bp) => const Center(child: CircularProgressIndicator()),
        ),
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
        body: ResponsiveBody(
          builder: (context, bp) => Center(
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
        ),
      );
    }

    final p = _pregnancy!;
    return PregnancyViewScope(
      pregnancyId: widget.pregnancyId,
      encounterId: widget.encounterId,
      pregnancy: p,
      onRefresh: _load,
      child: AutoTabsRouter(
        routes: [
          ObstetricsPregnancyOverviewTab(),
          ObstetricsAntenatalVisitsTab(),
          ObstetricsLabourDeliveryTab(),
          ObstetricsPostnatalTab(),
        ],
        builder: (context, child) {
          final tabsRouter = AutoTabsRouter.of(context);
          _tabController ??= TabController(
            length: 4,
            vsync: this,
            initialIndex: tabsRouter.activeIndex,
          );
          if (_tabController!.index != tabsRouter.activeIndex) {
            _tabController!.index = tabsRouter.activeIndex;
          }
          final tabLabels = [
            'Overview',
            _badgeLabel('Antenatal', _tabCount(p, 1)),
            _badgeLabel('Labour', _tabCount(p, 2)),
            _badgeLabel('Postnatal', _tabCount(p, 3)),
          ];

          return Scaffold(
            backgroundColor: colorScheme.surfaceContainerLowest,
            appBar: AppBar(
              title: Text('Pregnancy · ${pregnancyGpLabel(p)}'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.router.maybePop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loading ? null : _load,
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                onTap: tabsRouter.setActiveIndex,
                tabs: List.generate(
                  4,
                  (i) => Tab(text: tabLabels[i]),
                ),
              ),
            ),
            body: ResponsiveBody(
              center: false,
              bottomPadding: 0,
              builder: (context, bp) => Column(
                children: [
                  PregnancyHeroHeader(pregnancy: p),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _load,
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _badgeLabel(String base, int count) =>
      count > 0 ? '$base ($count)' : base;
}
