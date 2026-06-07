import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/accounts/accounts_palette.dart';
import 'package:helty/src/accounts/auth/accounting_permissions.dart';
import 'package:helty/src/accounts/widgets/accounts_access_denied.dart';
import 'package:helty/src/models/bank_model.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/services/bank_service.dart';
import 'package:helty/src/ui/system_setup/bank_management_screen.dart';

@RoutePage()
class AccountsBanksScreen extends ConsumerWidget {
  const AccountsBanksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!canAccessAccountsModule(ref.watch(authProvider).staff)) {
      return const AccountsAccessDenied(title: 'Bank accounts');
    }
    if (canManageBanks(ref.watch(authProvider).staff)) {
      return const BankManagementScreen();
    }
    return const _ReadOnlyBanksView();
  }
}

class _ReadOnlyBanksView extends StatefulWidget {
  const _ReadOnlyBanksView();

  @override
  State<_ReadOnlyBanksView> createState() => _ReadOnlyBanksViewState();
}

class _ReadOnlyBanksViewState extends State<_ReadOnlyBanksView> {
  final _service = BankService();
  List<BankModel> _banks = [];
  bool _loading = true;
  String? _error;

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
      final result = await _service.fetchBanks();
      if (!mounted) return;
      setState(() {
        _banks = result.data;
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
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Bank accounts'),
        backgroundColor: AccountsPalette.primary.withValues(alpha: 0.08),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: _banks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final b = _banks[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.account_balance_outlined),
                        title: Text(b.name),
                        subtitle: Text(b.accountNumber),
                      ),
                    );
                  },
                ),
    );
  }
}
