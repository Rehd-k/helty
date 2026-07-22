import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_router.gr.dart';
import '../../models/staff_model.dart';
import '../../models/staff_registration_options.dart';
import '../../nursing/ward_matching.dart';
import '../../providers/auth_provider.dart';
import '../../providers/staff_providers.dart';

@RoutePage()
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _staffIdCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  AccountType _selectedAccountType = AccountType.front_desk;
  late StaffRoleOption _selectedRoleOption = rolesForAccountType(
    AccountType.front_desk,
  ).first;
  String? _wardId;

  bool get _isChargeNurse =>
      isChargeNurseStaffRole(_selectedRoleOption.staffRole);

  PageRouteInfo _initialRouteAfterRegister(
    String accountTypeName,
    String role,
  ) {
    final at = accountTypeName.toLowerCase();
    final r = role.toUpperCase();

    switch (at) {
      case 'front_desk':
      case 'frontdesk':
        return const FrontDeskDashboardRoute();
      case 'billing':
      case 'bills':
        return staffCanAccessPrivilegedBillingStrings(role, accountTypeName)
            ? const BillingDashboardRoute()
            : const PendingBillsRoute();
      case 'hmo':
        return EnlistPaitientRoute(serviceName: 'OPD');
      case 'nurse':
      case 'head_nurse':
      case 'inpatient_nurse':
      case 'outpatient_nurse':
        return const NursesDashboardRoute();
      case 'admin':
        return const CMDDashboardRoute();
      case 'pharmacy':
      case 'pharmacy_store':
      case 'pharmacy_head':
        if (r == 'PHARMACY_DISPENSARY' || at == 'pharmacy_dispensary') {
          return EnlistPaitientRoute(serviceName: 'Pharmacy');
        }
        return const MedicineInventoryRoute();
      case 'pharmacy_dispensary':
        return EnlistPaitientRoute(serviceName: 'Pharmacy');
      case 'physician':
      case 'consultant':
      case 'inpatient_doctor':
        return const DoctorOutpatientListRoute();
      case 'laboratory':
      case 'lab':
        return const LabDashboardRoute();
      case 'radiology':
        return const RadiologyDashboardRoute();
      case 'dialysis':
        return const DialysisDashboardRoute();
      case 'store':
        return const StoreDashboardRoute();
      case 'purchases':
      case 'purchases_store':
      case 'purchases_head':
        return const PurchasesDashboardRoute();
      case 'accounting':
      case 'accounts':
      case 'medical_records':
      case 'ict':
        return const DashboardRoute();
      case 'cmd':
        return const CmacOverviewRoute();
      case 'cmac':
        return const CmacOverviewRoute();
      case 'super_admin':
        return const CMDDashboardRoute();
      default:
        return const DashboardRoute();
    }
  }

  @override
  void dispose() {
    _staffIdCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final assignmentError = validateNursingStaffAssignment(
      staffRole: _selectedRoleOption.staffRole,
      wardId: _wardId,
    );
    if (assignmentError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(assignmentError)));
      return;
    }

    final ok = await ref
        .read(authProvider.notifier)
        .register(
          staffId: _staffIdCtrl.text.trim(),
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          staffRole: _selectedRoleOption.staffRole,
          password: _passwordCtrl.text,
          email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          wardId: _isChargeNurse ? _wardId : null,
          accountType: _selectedAccountType,
        );
    if (ok && mounted) {
      final auth = ref.read(authProvider);
      final accountType = auth.staff?.accountType?.name ?? '';
      final staffRole = auth.staff?.staffRole ?? '';
      final initialChild = _initialRouteAfterRegister(accountType, staffRole);

      context.router.replaceAll([
        HomeRoute(children: [initialChild]),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final auth = ref.watch(authProvider);
    final asyncWards = ref.watch(wardListProvider);

    ref.listen(authProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: colors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Registration'),
        leading: BackButton(onPressed: () => context.router.maybePop()),
      ),
      body: ResponsiveBody(
        builder: (context, bp) => Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.person_add_outlined,
                      size: 48,
                      color: colors.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Create Your Account',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Fill in your staff details below',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),

                    _SectionLabel(
                      label: 'Staff Identity',
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 12),

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
                              labelText: 'First Name *',
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
                              labelText: 'Last Name *',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    DropdownButtonFormField<AccountType>(
                      key: ObjectKey(_selectedAccountType),
                      initialValue: _selectedAccountType,
                      decoration: const InputDecoration(
                        labelText: 'Account Type *',
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
                          _wardId = null;
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
                            (r) => DropdownMenuItem(
                              value: r,
                              child: Text(r.label),
                            ),
                          )
                          .toList(),
                      onChanged: (r) => setState(() {
                        _selectedRoleOption = r ?? _selectedRoleOption;
                        _wardId = null;
                      }),
                      validator: (v) => v == null ? 'Select a role' : null,
                    ),
                    if (_isChargeNurse) ...[
                      const SizedBox(height: 14),
                      asyncWards.when(
                        data: (allWards) {
                          final wards = selectableWardsForChargeNurseRole(
                            _selectedRoleOption.staffRole,
                            allWards,
                            currentWardId: _wardId,
                          );
                          if (wards.isEmpty) {
                            return Text(
                              'No wards found. Add wards in ward management first.',
                              style: TextStyle(color: colors.onSurfaceVariant),
                            );
                          }
                          final wardIds = wards.map((w) => w.id).toSet();
                          final selectedWardId =
                              _wardId != null && wardIds.contains(_wardId)
                              ? _wardId
                              : null;
                          return DropdownButtonFormField<String?>(
                            key: ValueKey(
                              'register-ward-$selectedWardId-${_selectedRoleOption.staffRole}',
                            ),
                            initialValue: selectedWardId,
                            decoration: const InputDecoration(
                              labelText: 'Home ward *',
                              prefixIcon: Icon(Icons.local_hospital_outlined),
                            ),
                            items: wards
                                .map(
                                  (w) => DropdownMenuItem<String?>(
                                    value: w.id,
                                    child: Text(w.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => _wardId = v),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Select a ward for this charge nurse role';
                              }
                              return null;
                            },
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text(
                          'Could not load wards: $e',
                          style: TextStyle(color: colors.error),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),

                    _SectionLabel(
                      label: 'Contact Information',
                      icon: Icons.contact_mail_outlined,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return null;
                        }
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
                    const SizedBox(height: 28),

                    _SectionLabel(label: 'Security', icon: Icons.lock_outline),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Password *',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Password is required';
                        }
                        if (v.length < 8) return 'Minimum 8 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _confirmPasswordCtrl,
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Confirm Password *',
                        prefixIcon: const Icon(Icons.lock_person_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Confirm your password';
                        }
                        if (v != _passwordCtrl.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    FilledButton(
                      onPressed: auth.isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                        TextButton(
                          onPressed: () => context.router.maybePop(),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Sign In'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: colors.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colors.primary,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Divider(color: colors.outlineVariant)),
      ],
    );
  }
}
