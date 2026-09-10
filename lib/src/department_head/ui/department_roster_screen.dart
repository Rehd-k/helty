import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../helper/app_timezone.dart';
import '../../hospital_assets/ui/asset_theme.dart';
import '../../nursing/models/nursing_models.dart';
import '../../providers/auth_provider.dart';
import '../models/department_head_models.dart';
import '../services/department_head_api_service.dart';

@RoutePage()
class DepartmentRosterScreen extends ConsumerStatefulWidget {
  const DepartmentRosterScreen({super.key});

  @override
  ConsumerState<DepartmentRosterScreen> createState() =>
      _DepartmentRosterScreenState();
}

class _DepartmentRosterScreenState
    extends ConsumerState<DepartmentRosterScreen> {
  final _api = DepartmentHeadApiService();
  DateTime _date = DateTime.now();
  bool _loading = true;
  String? _error;
  DepartmentRosterSummary? _summary;
  List<DepartmentStaffMember> _staff = [];

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
      final results = await Future.wait([
        _api.rosterSummary(shiftDate: _date),
        _api.listStaff(),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as DepartmentRosterSummary;
        _staff = results[1] as List<DepartmentStaffMember>;
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

  Future<void> _add(ShiftType shift) async {
    if (_staff.isEmpty) return;
    var staffId = _staff.first.id;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Add to ${shift.label}'),
          content: DropdownButtonFormField<String>(
            initialValue: staffId,
            items: _staff
                .map(
                  (s) => DropdownMenuItem(value: s.id, child: Text(s.fullName)),
                )
                .toList(),
            onChanged: (v) => staffId = v ?? staffId,
            decoration: const InputDecoration(labelText: 'Staff'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    await _api.addToRoster(
      staffId: staffId,
      shiftDate: _date,
      shiftType: shift,
    );
    await _load();
  }

  Widget _shiftColumn(
    String title,
    List<DepartmentRosterEntry> rows,
    ShiftType type,
    Color color,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$title (${rows.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _add(type),
                    icon: Icon(Icons.add, color: color),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: rows.length,
                  itemBuilder: (context, i) {
                    final row = rows[i];
                    return ListTile(
                      dense: true,
                      title: Text(row.staffName ?? row.staffId),
                      subtitle: Text(row.staffRole ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () async {
                          await _api.removeRoster(row.id);
                          await _load();
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    final accent = colorForAccountType(
      ref.watch(authProvider).staff?.accountType?.apiValue ?? '',
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Department shifts'),
        backgroundColor: accent.withValues(alpha: 0.12),
        foregroundColor: accent,
        actions: [
          TextButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() => _date = picked);
                await _load();
              }
            },
            child: Text(AppTimezone.dateOnlyKey(_date)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : summary == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _shiftColumn(
                    'Morning',
                    summary.morning,
                    ShiftType.morning,
                    const Color(0xFF16A34A),
                  ),
                  const SizedBox(width: 8),
                  _shiftColumn(
                    'Afternoon / evening',
                    summary.afternoon,
                    ShiftType.afternoon,
                    const Color(0xFFD97706),
                  ),
                  const SizedBox(width: 8),
                  _shiftColumn(
                    'Night',
                    summary.night,
                    ShiftType.night,
                    const Color(0xFF2563EB),
                  ),
                ],
              ),
            ),
    );
  }
}
