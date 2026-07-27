import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/models/discount_policy_models.dart';
import 'package:helty/src/accounts/accounts_palette.dart';
import 'package:helty/src/services/discount_policy_service.dart';

@RoutePage()
class DiscountPolicyManagementScreen extends StatefulWidget {
  const DiscountPolicyManagementScreen({super.key});

  @override
  State<DiscountPolicyManagementScreen> createState() =>
      _DiscountPolicyManagementScreenState();
}

class _DiscountPolicyManagementScreenState
    extends State<DiscountPolicyManagementScreen> {
  final _service = DiscountPolicyService();
  bool _loading = true;
  String? _error;
  List<DiscountPolicy> _items = const [];

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
      final items = await _service.list();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _upsert({DiscountPolicy? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final valueCtrl = TextEditingController(
      text: existing == null ? '' : existing.value.toString(),
    );
    String reason = existing?.reason ?? 'CMD';
    String mode = _normalizeMode(existing?.mode) ?? 'PERCENT';
    bool active = existing?.active ?? true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(existing == null ? 'Create policy' : 'Edit policy'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: valueCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Value'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: reason,
                  items: const [
                    DropdownMenuItem(value: 'CMD', child: Text('CMD')),
                    DropdownMenuItem(value: 'CMAC', child: Text('CMAC')),
                    DropdownMenuItem(value: 'SUPER_ADMIN', child: Text('SUPER_ADMIN')),
                  ],
                  onChanged: (v) => setDialog(() => reason = v ?? reason),
                  decoration: const InputDecoration(labelText: 'Reason'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: mode,
                  items: const [
                    DropdownMenuItem(value: 'PERCENT', child: Text('PERCENT')),
                    DropdownMenuItem(value: 'FIXED', child: Text('FIXED')),
                  ],
                  onChanged: (v) => setDialog(() => mode = v ?? mode),
                  decoration: const InputDecoration(labelText: 'Mode'),
                ),
                SwitchListTile(
                  value: active,
                  onChanged: (v) => setDialog(() => active = v),
                  title: const Text('Active'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;

    final payload = DiscountPolicyPayload(
      name: nameCtrl.text.trim(),
      reason: reason,
      mode: _normalizeMode(mode) ?? 'PERCENT',
      value: double.tryParse(valueCtrl.text.trim()) ?? 0,
      active: active,
      ownerStaffId: existing?.ownerStaffId,
    );
    if (existing == null) {
      await _service.create(payload);
    } else {
      await _service.update(existing.id, payload);
    }
    await _load();
  }

  String? _normalizeMode(String? mode) {
    final raw = mode?.trim().toUpperCase();
    if (raw == null || raw.isEmpty) return null;
    if (raw == 'FLAT') return 'FIXED';
    if (raw == 'FIXED' || raw == 'PERCENT') return raw;
    return raw;
  }

  Future<void> _delete(DiscountPolicy item) async {
    await _service.delete(item.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discount Policies'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: () => _upsert(), icon: const Icon(Icons.add)),
        ],
      ),
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) {
          final theme = Theme.of(context);
          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_error != null) {
            return Center(
              child: Card(
                margin: const EdgeInsets.all(24),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _error!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final p = _items[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: AccountsPalette.primary.withValues(
                      alpha: 0.15,
                    ),
                    child: Icon(
                      p.active ? Icons.sell_outlined : Icons.sell,
                      color: AccountsPalette.primary,
                    ),
                  ),
                  title: Text(p.name),
                  subtitle: Text('${p.reason} · ${p.mode} ${p.value}'),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        onPressed: () => _upsert(existing: p),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        onPressed: () => _delete(p),
                        icon: Icon(
                          Icons.delete_outline,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: _items.length,
          );
        },
      ),
    );
  }
}
