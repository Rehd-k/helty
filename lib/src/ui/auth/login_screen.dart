import 'dart:io';
import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_router.gr.dart';
import '../../models/super_admin_department_preview.dart';
import '../../providers/auth_provider.dart';
import '../../routing/initial_route_for_role.dart';
import '../../services/notificationbar.dart';
import '../../services/title_bar.dart';

const _kLogoAsset = 'assets/logo.png';

/// Side-by-side brand / form when wide enough (desktop & large tablet).
const _kLoginSplitBreakpoint = 900.0;

const _kFormMaxWidth = 440.0;

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

  void _openStaffRegister() {
    context.router.push(const RegisterRoute());
  }

  /// Logo with long-press → staff registration (no visible register CTA).
  Widget _brandLogo({
    required double maxWidth,
    required double maxHeight,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(20)),
  }) {
    return Tooltip(
      message: 'Long-press for staff registration',
      child: Semantics(
        label: 'Helty logo',
        onLongPressHint: 'Opens staff registration',
        child: Material(
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          borderRadius: borderRadius,
          child: InkWell(
            onLongPress: _openStaffRegister,
            borderRadius: borderRadius,
            child: Padding(
              padding: padding,
              child: Image.asset(
                _kLogoAsset,
                fit: BoxFit.contain,
                width: maxWidth,
                height: maxHeight,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, _, __) => Icon(
                  Icons.local_hospital_rounded,
                  size: math.min(maxWidth, maxHeight) * 0.42,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
      final staffRole = auth.staff?.staffRole ?? '';
      final accountType = auth.staff?.accountType?.name ?? '';
      final PageRouteInfo initialChild = staffIsSuperAdmin(auth.staff)
          ? const SuperAdminHubRoute()
          : initialRouteForRole(staffRole, accountType);
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
                        _brandLogo(
                          maxWidth: 30,
                          maxHeight: 30,
                          borderRadius: BorderRadius.circular(10),
                          padding: EdgeInsets.zero,
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final split = w >= _kLoginSplitBreakpoint;
                final padH = w < 400 ? 20.0 : w < 600 ? 24.0 : 32.0;
                final padV = w < 600 ? 20.0 : 28.0;

                if (split) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 46,
                        child: _brandingHero(theme, colors),
                      ),
                      Expanded(
                        flex: 54,
                        child: ColoredBox(
                          color: colors.surface,
                          child: Center(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.symmetric(
                                horizontal: padH,
                                vertical: padV,
                              ),
                              child: _loginFormCard(
                                theme: theme,
                                colors: colors,
                                auth: auth,
                                showHeroLogo: false,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colors.surface,
                        colors.primary.withValues(alpha: 0.05),
                        colors.tertiary.withValues(alpha: 0.07),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: padH,
                          vertical: padV,
                        ),
                        child: _loginFormCard(
                          theme: theme,
                          colors: colors,
                          auth: auth,
                          showHeroLogo: true,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _brandingHero(ThemeData theme, ColorScheme colors) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.tertiary],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _brandLogo(
                maxWidth: 240,
                maxHeight: 110,
                padding: const EdgeInsets.all(12),
              ),
              const SizedBox(height: 28),
              Text(
                'Hospital Management System',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colors.onPrimary.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Secure staff access to wards, clinical workflows, and operations.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onPrimary.withValues(alpha: 0.78),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(
    ColorScheme colors, {
    required String label,
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    final r = BorderRadius.circular(14);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.4),
      border: OutlineInputBorder(borderRadius: r),
      enabledBorder: OutlineInputBorder(
        borderRadius: r,
        borderSide: BorderSide(color: colors.outline.withValues(alpha: 0.22)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: r,
        borderSide: BorderSide(color: colors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
    );
  }

  Widget _loginFormCard({
    required ThemeData theme,
    required ColorScheme colors,
    required AuthState auth,
    required bool showHeroLogo,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _kFormMaxWidth),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.outline.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 14),
              spreadRadius: -6,
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.surface,
              colors.surfaceContainerHighest.withValues(alpha: 0.22),
            ],
          ),
        ),
        child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: showHeroLogo ? 24 : 32,
              vertical: showHeroLogo ? 26 : 36,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showHeroLogo) ...[
                    Center(
                      child: _brandLogo(
                        maxWidth: 240,
                        maxHeight: 100,
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Text(
                    'Welcome back',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to your staff account',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: showHeroLogo ? 28 : 32),

                  TextFormField(
                    controller: _emailOrPhoneCtrl,
                    keyboardType: TextInputType.text,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    decoration: _fieldDecoration(
                      colors,
                      label: 'Email or phone',
                      hint: 'you@imsh.org or 080…',
                      prefixIcon: const Icon(Icons.person_outline),
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

                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: _fieldDecoration(
                      colors,
                      label: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword ? 'Show password' : 'Hide',
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
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Password is required'
                        : null,
                  ),
                  const SizedBox(height: 10),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.router.push(
                        const ForgotPasswordRoute(),
                      ),
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  FilledButton(
                    onPressed: auth.isLoading ? null : _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: auth.isLoading
                        ? SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: colors.onPrimary,
                            ),
                          )
                        : const Text(
                            'Sign in',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }
}
