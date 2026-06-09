import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/staff_model.dart';
import '../../models/staff_registration_options.dart';
import '../../providers/staff_providers.dart';

@RoutePage()
class SuperAdminStaffDetailScreen extends ConsumerWidget {
  const SuperAdminStaffDetailScreen({
    super.key,
    required this.staffId,
  });

  final String staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final asyncStaff = ref.watch(currentStaffDetailProvider(staffId));

    return asyncStaff.when(
      data: (staff) => _StaffEditForm(staff: staff, staffId: staffId),
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Staff details')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Staff details')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: cs.error, size: 40),
                const SizedBox(height: 12),
                Text(e.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(currentStaffDetailProvider(staffId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StaffEditForm extends ConsumerStatefulWidget {
  const _StaffEditForm({required this.staff, required this.staffId});

  final Staff staff;
  final String staffId;

  @override
  ConsumerState<_StaffEditForm> createState() => _StaffEditFormState();
}

class _StaffEditFormState extends ConsumerState<_StaffEditForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _staffIdCtrl;
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _pharmacyRoleCtrl;

  late AccountType _selectedAccountType;
  late StaffRoleOption _selectedRoleOption;
  late bool _isActive;
  String? _departmentId;
  bool _saving = false;
  bool _deleting = false;

  bool get _busy => _saving || _deleting;

  @override
  void initState() {
    super.initState();
    _staffIdCtrl = TextEditingController();
    _firstNameCtrl = TextEditingController();
    _lastNameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _pharmacyRoleCtrl = TextEditingController();
    _syncFromStaff(widget.staff);
  }

  @override
  void didUpdateWidget(covariant _StaffEditForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.staff != widget.staff) {
      setState(() => _syncFromStaff(widget.staff));
    }
  }

  void _syncFromStaff(Staff staff) {
    final selection = resolveStaffRoleSelection(staff);
    _staffIdCtrl.text = staff.staffId;
    _firstNameCtrl.text = staff.firstName;
    _lastNameCtrl.text = staff.lastName;
    _emailCtrl.text = staff.email ?? '';
    _phoneCtrl.text = staff.phone ?? '';
    _pharmacyRoleCtrl.text = staff.pharmacyRole ?? '';
    _selectedAccountType = selection.accountType;
    _selectedRoleOption = selection.role;
    _isActive = staff.isActive;
    _departmentId = staff.departmentId;
  }

  @override
  void dispose() {
    _staffIdCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _pharmacyRoleCtrl.dispose();
    super.dispose();
  }

  bool get _showPharmacyRole =>
      _selectedAccountType == AccountType.pharmacy ||
      widget.staff.pharmacyRole?.trim().isNotEmpty == true;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final email = _emailCtrl.text.trim();
      final pharmacyRole = _pharmacyRoleCtrl.text.trim();
      final updated = widget.staff.copyWith(
        staffId: _staffIdCtrl.text.trim(),
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        staffRole: _selectedRoleOption.staffRole,
        pharmacyRole: _showPharmacyRole && pharmacyRole.isNotEmpty
            ? pharmacyRole
            : null,
        accountType: _selectedAccountType,
        email: email.isEmpty ? null : email,
        phone: _phoneCtrl.text.trim(),
        departmentId: _departmentId,
        isActive: _isActive,
      );

      await ref.read(staffServiceProvider).updateStaff(updated);

      ref.invalidate(currentStaffDetailProvider(widget.staffId));
      ref.invalidate(staffListProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Staff updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final staff = widget.staff;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete staff'),
        content: Text(
          'Permanently remove ${staff.fullName} (${staff.staffId})? '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(staffServiceProvider).deleteStaff(widget.staffId);
      ref.invalidate(staffListProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Staff deleted'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.router.maybePop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  static String _formatExpiry(DateTime? t) {
    if (t == null) return '—';
    final l = t.toLocal();
    return '${l.year}-${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')} '
        '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final staff = widget.staff;
    final asyncDepartments = ref.watch(departmentListProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff details'),
        actions: [
          IconButton(
            tooltip: 'Delete staff',
            onPressed: _busy ? null : _confirmDelete,
            icon: _deleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.delete_outline, color: cs.error),
          ),
          TextButton(
            onPressed: _busy ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentStaffDetailProvider(widget.staffId));
          await ref.read(currentStaffDetailProvider(widget.staffId).future);
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _sectionTitle(context, 'Identity'),
              TextFormField(
                controller: _staffIdCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Staff ID *',
                  prefixIcon: Icon(Icons.numbers_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Staff ID is required'
                    : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'First name *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Required'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Last name *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Required'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _sectionTitle(context, 'Account'),
              DropdownButtonFormField<AccountType>(
                key: ObjectKey(_selectedAccountType),
                initialValue: _selectedAccountType,
                decoration: const InputDecoration(
                  labelText: 'Account type *',
                  prefixIcon: Icon(Icons.manage_accounts_outlined),
                ),
                items: AccountType.departmentTypes
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text('${t.label} (${t.apiValue})'),
                      ),
                    )
                    .toList(),
                onChanged: (t) {
                  if (t == null) return;
                  final roles = rolesForAccountType(t);
                  setState(() {
                    _selectedAccountType = t;
                    _selectedRoleOption = roles.first;
                  });
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<StaffRoleOption>(
                key: ObjectKey(_selectedRoleOption),
                initialValue: _selectedRoleOption,
                decoration: const InputDecoration(
                  labelText: 'Role *',
                  prefixIcon: Icon(Icons.work_outline),
                ),
                items: rolesForAccountType(_selectedAccountType)
                    .map(
                      (r) => DropdownMenuItem(value: r, child: Text(r.label)),
                    )
                    .toList(),
                onChanged: (r) => setState(
                  () => _selectedRoleOption = r ?? _selectedRoleOption,
                ),
                validator: (v) => v == null ? 'Select a role' : null,
              ),
              if (_showPharmacyRole) ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _pharmacyRoleCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Pharmacy role',
                    prefixIcon: Icon(Icons.local_pharmacy_outlined),
                  ),
                ),
              ],
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                subtitle: Text(
                  _isActive ? 'Account is active' : 'Account is inactive',
                ),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: 20),
              _sectionTitle(context, 'Contact'),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final emailReg = RegExp(
                    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
                  );
                  if (!emailReg.hasMatch(v.trim())) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Phone number *',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  final digits = v.replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 7) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _sectionTitle(context, 'Organization'),
              asyncDepartments.when(
                data: (departments) {
                  final departmentIds = departments.map((d) => d.id).toSet();
                  final selectedDepartmentId =
                      _departmentId != null &&
                          departmentIds.contains(_departmentId)
                      ? _departmentId
                      : null;
                  return DropdownButtonFormField<String?>(
                    key: ValueKey(selectedDepartmentId),
                    initialValue: selectedDepartmentId,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No department'),
                      ),
                      ...departments.map(
                        (d) => DropdownMenuItem<String?>(
                          value: d.id,
                          child: Text(d.name),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _departmentId = v),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(
                  'Could not load departments: $e',
                  style: TextStyle(color: cs.error),
                ),
              ),
              if (staff.permissions.isNotEmpty) ...[
                const SizedBox(height: 20),
                _sectionTitle(context, 'Permissions'),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    staff.permissions.join(', '),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _sectionTitle(context, 'Password reset'),
              Card(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: staff.hasActivePasswordResetCode
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'A verification code is available for this staff member '
                              '(for example after they used “Forgot password”). '
                              'Share it only through a secure channel.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SelectableText(
                              staff.passwordResetCode!,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                letterSpacing: 4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (staff.passwordResetCodeExpiresAt != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Expires (local time): '
                                '${_formatExpiry(staff.passwordResetCodeExpiresAt)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: FilledButton.tonalIcon(
                                onPressed: () async {
                                  await Clipboard.setData(
                                    ClipboardData(
                                      text: staff.passwordResetCode!,
                                    ),
                                  );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Code copied'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.copy_rounded, size: 20),
                                label: const Text('Copy code'),
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'No active password reset code for this account.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Internal ID: ${staff.id}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
