import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_router.gr.dart';
import '../../models/staff_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/notificationbar.dart';
import '../../services/title_bar.dart';

// const _kSidebarAccent = Color(0xFF6366F1); // indigo-500
const _kSidebarTextMuted = Color(0xFF64748B); // slate-500

final _kEmailReg = RegExp(
  r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
);

bool _isValidEmailOrPhone(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return false;
  if (s.contains('@')) {
    return _kEmailReg.hasMatch(s);
  }
  final digits = s.startsWith('+')
      ? s.substring(1).replaceAll(RegExp(r'\D'), '')
      : s.replaceAll(RegExp(r'\D'), '');
  return digits.length >= 10 && digits.length <= 15;
}

@RoutePage()
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, @QueryParam() this.redirectTo});

  /// Optional path to redirect after successful login.
  final String? redirectTo;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrPhoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailOrPhoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  PageRouteInfo _initialRouteForRole(String role, String accountType) {
    final at = accountType.toLowerCase();
    final r = role.toUpperCase();

    switch (at) {
      case 'front_desk':
      case 'frontdesk':
      case 'medical_records':
        return const FrontDeskDashboardRoute();
      case 'billing':
      case 'bills':
        return staffCanAccessPrivilegedBillingStrings(role, accountType)
            ? const BillingDashboardRoute()
            : const PendingBillsRoute();
      case 'hmo':
        return EnlistPaitientRoute(serviceName: 'OPD');
      case 'nurse':
      case 'head_nurse':
      case 'inpatient_nurse':
      case 'outpatient_nurse':
        return const NursesDashboardRoute();
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
      case 'store':
        return const StoreDashboardRoute();
      case 'accounting':
      case 'accounts':
      case 'ict':
        return const DashboardRoute();
      case 'cmd':
      case 'cmac':
      case 'super_admin':
        return const CMDDashboardRoute();
      case 'admin':
        return const CMDDashboardRoute();
      default:
        return const FrontDeskDashboardRoute();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(authProvider.notifier)
        .login(
          emailOrPhone: _emailOrPhoneCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
    if (ok && mounted) {
      // Replace entire stack so the user can't go back to login.
      final auth = ref.read(authProvider);
      final role = auth.staff?.role ?? '';
      final accountType = auth.staff?.accountType?.name ?? '';
      final initialChild = _initialRouteForRole(role, accountType);
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

    // Show error snackbar
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

    Widget buildTitleBar(BuildContext context) {
      return WindowTitleBarBox(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: MoveWindow(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),

                          child: Image.asset(
                            'assets/logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Helty',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  spacing: 8,
                  children: [
                    const SlidingNotificationDropdown(),
                    const WindowButtons(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          if (Platform.isWindows) buildTitleBar(context),
          Expanded(
            child: Row(
              children: [
                // ── Left panel (banner) ─────────────────────────────────────────
                if (MediaQuery.of(context).size.width > 800)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [colors.primary, colors.tertiary],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/logo.png',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Helty',
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: colors.onPrimary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Hospital Management System',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colors.onPrimary.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Right panel (form) ──────────────────────────────────────────
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(40),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Logo (small screens)
                              if (MediaQuery.of(context).size.width <= 800) ...[
                                Icon(
                                  Icons.local_hospital_rounded,
                                  size: 56,
                                  color: colors.primary,
                                ),
                                const SizedBox(height: 12),
                              ],

                              Text(
                                'Welcome back',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sign in to your staff account',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 36),

                              // Email or phone
                              TextFormField(
                                controller: _emailOrPhoneCtrl,
                                keyboardType: TextInputType.text,
                                autocorrect: false,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Email or phone',
                                  hintText: 'you@imsh.org or 080...',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Email or phone is required';
                                  }
                                  if (!_isValidEmailOrPhone(v)) {
                                    return 'Enter a valid email or phone number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Password
                              TextFormField(
                                controller: _passwordCtrl,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                ),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Password is required'
                                    : null,
                              ),
                              const SizedBox(height: 8),

                              // Forgot password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => context.router.push(
                                    const ForgotPasswordRoute(),
                                  ),
                                  child: const Text('Forgot password?'),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Login button
                              FilledButton(
                                onPressed: auth.isLoading ? null : _submit,
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
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
                                        'Sign In',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 24),

                              // Register link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account? ",
                                    style: TextStyle(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => context.router.push(
                                      const RegisterRoute(),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text('Register'),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TitleBarLogoutButton extends StatefulWidget {
  const _TitleBarLogoutButton();

  @override
  State<_TitleBarLogoutButton> createState() => _TitleBarLogoutButtonState();
}

class _TitleBarLogoutButtonState extends State<_TitleBarLogoutButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: () => context.router.replaceAll([LoginRoute()]),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            Icons.logout_rounded,
            color: _hover ? Colors.red.shade400 : _kSidebarTextMuted,
            size: 18,
          ),
        ),
      ),
    );
  }
}
