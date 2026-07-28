import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/responsive.dart';
import '../../helper/date.formatter.dart';
import '../../models/staff_model.dart';
import '../../models/super_admin_department_preview.dart';
import '../../providers/auth_provider.dart';
import '../../providers/super_admin_preview_provider.dart';
import '../models/purchases_model.dart';
import '../services/purchases_service.dart';

bool _viewerIsPurchasesHead(Staff? staff, SuperAdminPreviewState preview) {
  if (staffIsSuperAdmin(staff) && preview.isActive) {
    final r = (preview.previewRole ?? '').toLowerCase().trim();
    final at = (preview.previewAccountType ?? '').toLowerCase().trim();
    return r == 'purchases_head' || at == 'purchases_head';
  }
  final r = staff?.staffRole.toLowerCase().replaceAll('-', '_') ?? '';
  return r == 'purchases_head';
}

@RoutePage()
class PurchasesRequisitionHistoryScreen extends ConsumerStatefulWidget {
  const PurchasesRequisitionHistoryScreen({super.key});

  @override
  ConsumerState<PurchasesRequisitionHistoryScreen> createState() =>
      _PurchasesRequisitionHistoryScreenState();
}

class _PurchasesRequisitionHistoryScreenState
    extends ConsumerState<PurchasesRequisitionHistoryScreen> {
  final PurchasesApiService _api = PurchasesApiService();
  List<Requisition> _rows = [];
  bool _loading = true;
  String? _error;
  String? _statusFilter;
  String? _departmentFilter;

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
      final filters = <String, dynamic>{};
      if (_statusFilter != null) filters['status'] = _statusFilter;
      if (_departmentFilter != null) {
        filters['requestingDepartment'] = _departmentFilter;
      }
      final page = await _api.getRequisitions(
        PurchasesQueryParams(
          pageSize: 50,
          sortBy: 'createdAt',
          filters: filters,
        ),
      );
      if (!mounted) return;
      setState(() => _rows = page.items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(Requisition req) async {
    if (req.id == null) return;
    try {
      await _api.approveRequisition(req.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Requisition approved')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _reject(Requisition req) async {
    if (req.id == null) return;
    try {
      await _api.rejectRequisition(req.id!, reason: 'Rejected by purchases');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Requisition rejected')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _convertToPo(Requisition req) async {
    if (req.id == null) return;
    try {
      await _api.convertRequisitionToPo(req.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase order created')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  void _showDetail(Requisition req) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Requisition ${req.id ?? ''}'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Department: ${req.requestingDepartment}'),
              Text('Status: ${req.status.name}'),
              if (req.requestedByName != null &&
                  req.requestedByName!.trim().isNotEmpty)
                Text('Requested by: ${req.requestedByName}'),
              if (req.createdAt != null)
                Text('Created: ${DateFormatter.dateTime(req.createdAt!)}'),
              const SizedBox(height: 12),
              const Text('Line items:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...req.lines.map(
                (l) => Text('• ${l.itemName} × ${l.quantity} (${l.priority})'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(authProvider).staff;
    final preview = ref.watch(superAdminPreviewProvider);
    final isHead = _viewerIsPurchasesHead(staff, preview);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Requisition History'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: ResponsiveBody(
        builder: (context, bp) => Column(
          children: [
            ResponsiveWrapGrid(
              mobileColumns: 1,
              tabletColumns: 2,
              desktopColumns: 2,
              children: [
                DropdownButton<String?>(
                  value: _statusFilter,
                  hint: const Text('All statuses'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All statuses')),
                    ...RequisitionStatus.values.map(
                      (s) => DropdownMenuItem(value: s.name, child: Text(s.name)),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() => _statusFilter = v);
                    _load();
                  },
                ),
                DropdownButton<String?>(
                  value: _departmentFilter,
                  hint: const Text('All departments'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All departments')),
                    DropdownMenuItem(value: 'PHARMACY', child: Text('Pharmacy')),
                    DropdownMenuItem(value: 'STORE', child: Text('Store')),
                    DropdownMenuItem(value: 'LAB', child: Text('Lab')),
                    DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                  ],
                  onChanged: (v) {
                    setState(() => _departmentFilter = v);
                    _load();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _rows.isEmpty
                  ? const Center(child: Text('No requisitions found.'))
                  : ListView.separated(
                      itemCount: _rows.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final req = _rows[index];
                        return ListTile(
                          onTap: () => _showDetail(req),
                          title: Text(
                            '${req.requestingDepartment} · ${req.lines.length} item(s)',
                          ),
                          subtitle: Text(
                            [
                              req.status.name,
                              if (req.requestedByName != null &&
                                  req.requestedByName!.trim().isNotEmpty)
                                req.requestedByName!,
                              if (req.createdAt != null)
                                DateFormatter.dateTime(req.createdAt!),
                            ].join(' · '),
                          ),
                          trailing: req.status == RequisitionStatus.PENDING && isHead
                              ? Wrap(
                                  spacing: 4,
                                  children: [
                                    TextButton(
                                      onPressed: () => _approve(req),
                                      child: const Text('Approve'),
                                    ),
                                    TextButton(
                                      onPressed: () => _reject(req),
                                      child: const Text('Reject'),
                                    ),
                                    TextButton(
                                      onPressed: () => _convertToPo(req),
                                      child: const Text('To PO'),
                                    ),
                                  ],
                                )
                              : Chip(label: Text(req.status.name)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
