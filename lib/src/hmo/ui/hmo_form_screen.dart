import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/app_router.gr.dart';

import '../../models/hmo_models.dart';
import '../../services/hmo_service.dart';
import '../../widgets/responsive_grid.dart';

@RoutePage()
class HmoFormScreen extends StatefulWidget {
  const HmoFormScreen({super.key, this.hmoId});

  /// When set, load and update existing HMO.
  final String? hmoId;

  @override
  State<HmoFormScreen> createState() => _HmoFormScreenState();
}

class _HmoFormScreenState extends State<HmoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _notes = TextEditingController();
  final _defaultCoveragePercent = TextEditingController();
  final _listSearch = TextEditingController();
  final _svc = HmoService();

  static const _listTake = 20;
  int _listSkip = 0;
  int _listTotal = 0;
  List<HmoListItem> _listItems = [];
  bool _listLoading = true;
  String? _listError;

  bool _loading = false;
  bool _loadingDetail = true;

  @override
  void initState() {
    super.initState();
    _loadList();
    if (widget.hmoId != null && widget.hmoId!.isNotEmpty) {
      _load();
    } else {
      _loadingDetail = false;
    }
  }

  Future<void> _loadList() async {
    setState(() {
      _listLoading = true;
      _listError = null;
    });
    try {
      final r = await _svc.list(
        search: _listSearch.text,
        skip: _listSkip,
        take: _listTake,
      );
      if (!mounted) return;
      setState(() {
        _listItems = r.items;
        _listTotal = r.total;
        _listLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _listError = '$e';
        _listLoading = false;
      });
    }
  }

  Future<void> _load() async {
    try {
      final d = await _svc.getById(widget.hmoId!);
      if (!mounted) return;
      _name.text = d.name;
      _code.text = d.code ?? '';
      _notes.text = d.notes ?? '';
      _defaultCoveragePercent.text = d.defaultCoveragePercent?.toString() ?? '';
      setState(() => _loadingDetail = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingDetail = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _notes.dispose();
    _defaultCoveragePercent.dispose();
    _listSearch.dispose();
    super.dispose();
  }

  double? _parseCoveragePercent() {
    final v = double.tryParse(_defaultCoveragePercent.text.trim());
    if (v == null) return null;
    return double.parse(v.toStringAsFixed(2));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (widget.hmoId != null && widget.hmoId!.isNotEmpty) {
        await _svc.update(
          widget.hmoId!,
          name: _name.text.trim(),
          code: _code.text.trim(),
          notes: _notes.text.trim(),
          defaultCoveragePercent: _parseCoveragePercent(),
        );
      } else {
        await _svc.create(
          HmoDetail(
            id: '',
            name: _name.text.trim(),
            code: _code.text.trim().isEmpty ? null : _code.text.trim(),
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
            defaultCoveragePercent: _parseCoveragePercent(),
          ),
        );
      }
      if (!mounted) return;
      await _loadList();
      if (!mounted) return;
      context.router.maybePop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildFormCard() {
    return ModernFormCard(
      title: 'Plan details',
      leadingIcon: Icons.health_and_safety_outlined,
      footerAction: FilledButton.icon(
        onPressed: _loading ? null : _save,
        icon: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save_outlined),
        label: Text(widget.hmoId != null ? 'Save changes' : 'Create HMO'),
      ),
      children: [
        TextFormField(
          controller: _name,
          decoration: const InputDecoration(
            labelText: 'Name *',
            border: OutlineInputBorder(),
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        TextFormField(
          controller: _code,
          decoration: const InputDecoration(
            labelText: 'Code',
            border: OutlineInputBorder(),
            hintText: 'e.g. NHIS-STD',
          ),
        ),
        TextFormField(
          controller: _defaultCoveragePercent,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Default coverage percent *',
            border: OutlineInputBorder(),
            hintText: 'e.g. 80.00',
          ),
          validator: (v) {
            final t = v?.trim() ?? '';
            if (t.isEmpty) return 'Required';
            final n = double.tryParse(t);
            if (n == null) return 'Enter a valid decimal';
            if (n < 0 || n > 100) return 'Must be between 0 and 100';
            return null;
          },
        ),
        TextFormField(
          controller: _notes,
          decoration: const InputDecoration(
            labelText: 'Notes',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildListPanel(ThemeData theme) {
    final isNew = widget.hmoId == null || widget.hmoId!.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'All plans',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: isNew
                  ? null
                  : () => context.router.replace(HmoFormRoute()),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('New'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _listSearch,
          decoration: InputDecoration(
            hintText: 'Search by name or code',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () {
                _listSkip = 0;
                _loadList();
              },
            ),
          ),
          onSubmitted: (_) {
            _listSkip = 0;
            _loadList();
          },
        ),
        const SizedBox(height: 12),
        if (_listError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _listError!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        Expanded(
          child: _listLoading
              ? const Center(child: CircularProgressIndicator())
              : _listItems.isEmpty
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
                  child: RefreshIndicator(
                    onRefresh: _loadList,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _listItems.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final h = _listItems[i];
                        final selected = widget.hmoId == h.id;
                        return ListTile(
                          selected: selected,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 6,
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
                          trailing: Icon(
                            selected
                                ? Icons.check_circle_outline
                                : Icons.chevron_right,
                            color: selected
                                ? theme.colorScheme.primary
                                : null,
                          ),
                          onTap: () async {
                            if (selected) return;
                            await context.router.replace(
                              HmoFormRoute(hmoId: h.id),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
        ),
        if (_listTotal > _listTake)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _listSkip == 0
                      ? null
                      : () {
                          _listSkip =
                              (_listSkip - _listTake).clamp(0, _listTotal);
                          _loadList();
                        },
                  child: const Text('Previous'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '${_listSkip + 1}–${_listSkip + _listItems.length} of $_listTotal',
                  ),
                ),
                TextButton(
                  onPressed: _listSkip + _listTake >= _listTotal
                      ? null
                      : () {
                          _listSkip += _listTake;
                          _loadList();
                        },
                  child: const Text('Next'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loadingDetail) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(widget.hmoId != null ? 'Edit HMO' : 'Add HMO'),
      ),
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) {
          final formScroll = SingleChildScrollView(
            padding: EdgeInsets.all(bp.paddingH),
            child: Form(
              key: _formKey,
              child: _buildFormCard(),
            ),
          );

          if (!bp.stackPanels) {
            return ResponsiveRowColumn(
              firstFlex: 11,
              secondFlex: 9,
              gap: bp.isMobile ? 16 : 24,
              rowCrossAxisAlignment: CrossAxisAlignment.stretch,
              first: formScroll,
              second: _buildListPanel(theme),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 11,
                child: formScroll,
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: theme.dividerColor.withValues(alpha: 0.35),
              ),
              Expanded(
                flex: 9,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: _buildListPanel(theme),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
