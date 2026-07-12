import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';

import '../../models/hmo_models.dart';
import '../../services/hmo_service.dart';
import 'package:helty/app_router.gr.dart';

@RoutePage()
class HmoListScreen extends StatefulWidget {
  const HmoListScreen({super.key});

  @override
  State<HmoListScreen> createState() => _HmoListScreenState();
}

class _HmoListScreenState extends State<HmoListScreen> {
  final _svc = HmoService();
  final _search = TextEditingController();
  final _take = 20;
  int _skip = 0;
  int _total = 0;
  bool _loading = true;
  String? _error;
  List<HmoListItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await _svc.list(search: _search.text, skip: _skip, take: _take);
      if (!mounted) return;
      setState(() {
        _items = r.items;
        _total = r.total;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('HMO plans'),
        actions: [
          IconButton(
            tooltip: 'Configure service pricing',
            icon: const Icon(Icons.price_change_outlined),
            onPressed: () => context.router.push(HmoServicePricingRoute()),
          ),
          IconButton(
            tooltip: 'Add HMO',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () async {
              await context.router.push(HmoFormRoute());
              _load();
            },
          ),
        ],
      ),
      body: ResponsiveBody(
        builder: (context, bp) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Search by name or code',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () {
                    _skip = 0;
                    _load();
                  },
                ),
              ),
              onSubmitted: (_) {
                _skip = 0;
                _load();
              },
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                  ? Center(
                      child: Text(
                        'No HMO plans yet',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    )
                  : Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final h = _items[i];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            title: Text(
                              h.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              [
                                if (h.code != null && h.code!.isNotEmpty)
                                  'Code: ${h.code}',
                                if (h.counts != null)
                                  '${h.counts!.patients} patients · ${h.counts!.servicePrices} priced services',
                              ].join(' · '),
                              style: theme.textTheme.bodySmall,
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              await context.router.push(HmoDetailRoute(hmoId: h.id));
                              _load();
                            },
                          );
                        },
                      ),
                    ),
            ),
            if (_total > _take)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _skip == 0
                          ? null
                          : () {
                              _skip = (_skip - _take).clamp(0, _total);
                              _load();
                            },
                      child: const Text('Previous'),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '${_skip + 1}–${_skip + _items.length} of $_total',
                      ),
                    ),
                    TextButton(
                      onPressed: _skip + _take >= _total
                          ? null
                          : () {
                              _skip += _take;
                              _load();
                            },
                      child: const Text('Next'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
