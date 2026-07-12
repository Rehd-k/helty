import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/bank_model.dart';
import '../../services/bank_service.dart';

@RoutePage()
class BankManagementScreen extends ConsumerStatefulWidget {
  const BankManagementScreen({super.key});

  @override
  ConsumerState<BankManagementScreen> createState() =>
      _BankManagementScreenState();
}

class _BankManagementScreenState extends ConsumerState<BankManagementScreen> {
  final _bankService = BankService();
  final _nameController = TextEditingController();
  final _accountNumberController = TextEditingController();

  List<BankModel> _banks = [];
  bool _loading = true;
  BankModel? _editingBank;

  @override
  void initState() {
    super.initState();
    _loadBanks();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadBanks() async {
    setState(() => _loading = true);
    try {
      final paginated = await _bankService.fetchBanks();
      if (mounted) {
        setState(() {
          _banks = paginated.data;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load banks: $e')));
      setState(() => _loading = false);
    }
  }

  Future<void> _saveBank() async {
    final name = _nameController.text.trim();
    final accountNumber = _accountNumberController.text.trim();

    if (name.isEmpty || accountNumber.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and Account Number are required')),
      );
      return;
    }

    try {
      if (_editingBank != null) {
        await _bankService.updateBank(_editingBank!.id, name, accountNumber);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bank updated successfully')),
        );
      } else {
        await _bankService.createBank(name, accountNumber);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bank created successfully')),
        );
      }
      _clearForm();
      await _loadBanks();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteBank(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bank'),
        content: const Text('Are you sure you want to delete this bank?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _bankService.deleteBank(id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bank deleted successfully')),
        );
        await _loadBanks();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _editBank(BankModel bank) {
    setState(() {
      _editingBank = bank;
      _nameController.text = bank.name;
      _accountNumberController.text = bank.accountNumber;
    });
  }

  void _clearForm() {
    setState(() {
      _editingBank = null;
      _nameController.clear();
      _accountNumberController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bank Management')),
      body: ResponsiveBody(
        builder: (context, bp) => _loading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Form on the left
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _editingBank != null
                                  ? 'Edit Bank'
                                  : 'Add New Bank',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Bank Name',
                                hintText: 'e.g., GTBank - Operations',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _accountNumberController,
                              decoration: const InputDecoration(
                                labelText: 'Account Number',
                                hintText: 'e.g., 0123456789',
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: _saveBank,
                                  child: Text(
                                    _editingBank != null ? 'Update' : 'Create',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (_editingBank != null)
                                  TextButton(
                                    onPressed: _clearForm,
                                    child: const Text('Cancel'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Table on the right
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Banks',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: SingleChildScrollView(
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('Name')),
                                    DataColumn(label: Text('Account Number')),
                                    DataColumn(label: Text('Actions')),
                                  ],
                                  rows: _banks.map((bank) {
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(bank.name)),
                                        DataCell(Text(bank.accountNumber)),
                                        DataCell(
                                          PopupMenuButton<String>(
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                _editBank(bank);
                                              } else if (value == 'delete') {
                                                _deleteBank(bank.id);
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Text('Edit'),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }
}
