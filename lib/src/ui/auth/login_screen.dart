import 'dart:async';
import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app_router.gr.dart';
import '../../app/product_definition.dart';
import '../../app/product_environment.dart';
import '../../core/responsive.dart';
import '../../core/storage/saved_login_storage.dart';
import '../../helper/app_timezone.dart';
import '../../helper/theme.dart';
import '../../models/saved_login.dart';
import '../../models/super_admin_department_preview.dart';
import '../../providers/auth_provider.dart';
import '../../routing/initial_route_for_role.dart';
import '../../core/platform/helty_platform.dart';
import '../../services/notificationbar.dart';
import '../../services/title_bar.dart';
import '../../services/window_chrome.dart';
import '../../system_announcements/providers/system_announcement_providers.dart';
import '../../system_announcements/services/system_announcement_service.dart';
import '../../system_announcements/widgets/announcement_modal.dart';
import '../../widgets/helty_surface.dart';

/// Helty product mark (not the org logo from `ORG_LOGO`).
const _kLogoAsset = 'assets/logo.png';

const _kFormMaxWidth = 440.0;

const _kAccentBlue = Color(0xFF2563EB);
const _kAccentTeal = Color(0xFF0D9488);
const _kAccentPurple = Color(0xFF7C3AED);
const _kAccentPink = Color(0xFFDB2777);
const _kAccentIndigo = Color(0xFF4F46E5);
const _kAccentGreen = Color(0xFF16A34A);
const _kAccentAmber = Color(0xFFEA580C);

const _kAccentPalette = <Color>[
  _kAccentBlue,
  _kAccentTeal,
  _kAccentPurple,
  _kAccentPink,
  _kAccentIndigo,
  _kAccentGreen,
  _kAccentAmber,
];

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
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;
  List<SavedLogin> _savedLogins = [];
  String? _selectedLoginKey;
  bool _announcementModalShown = false;

  @override
  void initState() {
    super.initState();
    _loadSavedLogins();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeShowAnnouncements(),
    );
  }

  Future<void> _maybeShowAnnouncements() async {
    if (!mounted || _announcementModalShown) return;
    try {
      final service = SystemAnnouncementService();
      final active = await service.listActive();
      if (!mounted || active.isEmpty) return;

      final activeIds = active.map((a) => a.id).toSet();
      await AnnouncementDismissalStorage.pruneStaleIds(activeIds);

      final toShow = await AnnouncementDismissalStorage.filterForLoginModal(
        active,
      );
      if (!mounted || toShow.isEmpty) return;

      _announcementModalShown = true;
      await AnnouncementModal.show(context, announcements: toShow);
      await AnnouncementDismissalStorage.markModalSeenIds(
        toShow.map((a) => a.id).toSet(),
      );
    } catch (_) {
      // Public endpoint may fail offline; login should still work.
    }
  }

  Future<void> _loadSavedLogins() async {
    final logins = await SavedLoginStorage.load();
    if (mounted) setState(() => _savedLogins = logins);
  }

  Future<void> _saveCurrentLogin({
    required String emailOrPhone,
    required String displayName,
    String? roleLabel,
  }) async {
    await SavedLoginStorage.upsert(
      SavedLogin(
        emailOrPhone: emailOrPhone,
        displayName: displayName,
        roleLabel: roleLabel,
        lastUsedMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    await _loadSavedLogins();
  }

  void _selectSavedLogin(SavedLogin login) {
    setState(() {
      _emailOrPhoneCtrl.text = login.emailOrPhone;
      _passwordCtrl.clear();
      _selectedLoginKey = login.normalizedKey;
    });
    _passwordFocusNode.requestFocus();
  }

  Future<void> _removeSavedLogin(SavedLogin login) async {
    await SavedLoginStorage.remove(login.emailOrPhone);
    if (_selectedLoginKey == login.normalizedKey) {
      _selectedLoginKey = null;
    }
    await _loadSavedLogins();
  }

  @override
  void dispose() {
    _emailOrPhoneCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordFocusNode.dispose();
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
    return Semantics(
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
                color: Colors.white,
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
      final staff = auth.staff;
      if (staff != null) {
        final emailOrPhone = _emailOrPhoneCtrl.text.trim();
        final roleLabel = staff.departmentName ?? staff.accountType?.name;
        await _saveCurrentLogin(
          emailOrPhone: emailOrPhone,
          displayName: staff.fullName,
          roleLabel: roleLabel,
        );
      }
      if (!mounted) return;
      final staffRole = staff?.staffRole ?? '';
      final accountType = staff?.accountType?.name ?? '';
      final PageRouteInfo initialChild = staffIsSuperAdmin(staff)
          ? (ProductEnvironment.isModuleEnabled(AppModule.administration)
                ? const SuperAdminHubRoute()
                : const SuperAdminStaffListRoute())
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
      body: Column(
        children: [
          if (HeltyPlatform.isWindows) _buildTitleBar(context),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bp = AppBreakpoints.fromWidth(constraints.maxWidth);
                final form = _loginFormCard(
                  theme: theme,
                  colors: colors,
                  auth: auth,
                  compact: bp.isMobile,
                  showHeroLogo: !bp.isDesktop,
                );

                if (bp.isDesktop) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 5, child: _brandingHero(theme)),
                      Expanded(
                        flex: 6,
                        child: ColoredBox(
                          color: colors.surface,
                          child: Center(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.symmetric(
                                horizontal: bp.paddingH,
                                vertical: bp.paddingV,
                              ),
                              child: form,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF0F172A),
                            Color(0xFF312E81),
                            Color(0xFF0F766E),
                          ],
                        ),
                      ),
                    ),
                    const _ColorBlobs(),
                    SafeArea(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: bp.paddingH,
                            vertical: bp.paddingV,
                          ),
                          child: Column(
                            children: [
                              if (bp.isTablet) ...[
                                _compactHeroStrip(theme),
                                const SizedBox(height: 12),
                              ],
                              form,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBar(BuildContext context) {
    return WindowTitleBarBox(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F172A),
              Color(0xFF4F46E5),
              Color(0xFF0D9488),
              Color(0xFF7C3AED),
            ],
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
                      ),
                      const SizedBox(width: 10),
                      Text(
                        ProductEnvironment.displayName,
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
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Row(
                spacing: 8,
                children: [SlidingNotificationDropdown(), WindowButtons()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _brandingHero(ThemeData theme) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF134E4A)],
            ),
          ),
        ),
        const _ColorBlobs(),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _brandLogo(
                  maxWidth: 220,
                  maxHeight: 96,
                  padding: const EdgeInsets.all(10),
                ),
                const SizedBox(height: 16),
                Text(
                  ProductEnvironment.displayName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hospital Management System',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Secure staff access to wards, clinical workflows, and operations.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                const _LoginClock(onDark: true),
                const SizedBox(height: 16),
                const _ModuleTiles(compact: false),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _compactHeroStrip(ThemeData theme) {
    return Column(
      children: [
        Text(
          ProductEnvironment.displayName,
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const _LoginClock(onDark: true),
        const SizedBox(height: 12),
        const _ModuleTiles(compact: true),
      ],
    );
  }

  InputDecoration _fieldDecoration(
    ColorScheme colors, {
    required String label,
    String? hint,
    required Widget prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Padding(padding: const EdgeInsets.all(8), child: prefixIcon),
      prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: colors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        borderSide: BorderSide(color: colors.outline.withValues(alpha: 0.28)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        borderSide: const BorderSide(color: _kAccentIndigo, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      labelStyle: const TextStyle(fontSize: 13),
    );
  }

  Widget _loginFormCard({
    required ThemeData theme,
    required ColorScheme colors,
    required AuthState auth,
    required bool compact,
    required bool showHeroLogo,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _kFormMaxWidth),
      child: HeltySurfaceCard(
        padding: EdgeInsets.fromLTRB(16, compact ? 16 : 20, 16, 18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showHeroLogo) ...[
                Center(
                  child: _brandLogo(
                    maxWidth: 180,
                    maxHeight: 80,
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  const HeltySolidIcon(
                    icon: Icons.login_rounded,
                    color: _kAccentPurple,
                    size: 34,
                    iconSize: 18,
                    radius: AppTheme.radiusMd,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HeltyEllipsisText(
                          text: 'Welcome back',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colors.onSurface,
                          ),
                        ),
                        HeltyEllipsisText(
                          text: 'Sign in to your staff account',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_savedLogins.isNotEmpty) ...[
                const SizedBox(height: 14),
                _recentStaffSection(theme, colors),
              ],
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailOrPhoneCtrl,
                onChanged: (_) {
                  if (_selectedLoginKey != null) {
                    setState(() => _selectedLoginKey = null);
                  }
                },
                keyboardType: TextInputType.text,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                decoration: _fieldDecoration(
                  colors,
                  label: 'Email or phone',
                  hint: 'you@imsh.org or 080…',
                  prefixIcon: const HeltySolidIcon(
                    icon: Icons.person_outline,
                    color: _kAccentBlue,
                    size: 28,
                    iconSize: 16,
                    radius: 8,
                  ),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                focusNode: _passwordFocusNode,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: _fieldDecoration(
                  colors,
                  label: 'Password',
                  prefixIcon: const HeltySolidIcon(
                    icon: Icons.lock_outline,
                    color: _kAccentTeal,
                    size: 28,
                    iconSize: 16,
                    radius: 8,
                  ),
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword ? 'Show password' : 'Hide',
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: _kAccentIndigo,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Password is required' : null,
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () =>
                      context.router.push(const ForgotPasswordRoute()),
                  icon: const HeltySolidIcon(
                    icon: Icons.help_outline,
                    color: _kAccentAmber,
                    size: 20,
                    iconSize: 12,
                    radius: 6,
                  ),
                  label: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: auth.isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: _kAccentIndigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const StadiumBorder(),
                ),
                child: auth.isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const HeltySolidIcon(
                            icon: Icons.arrow_forward_rounded,
                            color: _kAccentPink,
                            size: 22,
                            iconSize: 14,
                            radius: 6,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sign in',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recentStaffSection(ThemeData theme, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const HeltySolidIcon(
              icon: Icons.groups_outlined,
              color: _kAccentPink,
              size: 22,
              iconSize: 12,
              radius: 6,
            ),
            const SizedBox(width: 8),
            Text(
              'Recent staff',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < _savedLogins.length; i++)
              _SavedLoginChip(
                login: _savedLogins[i],
                accent: _kAccentPalette[i % _kAccentPalette.length],
                selected: _selectedLoginKey == _savedLogins[i].normalizedKey,
                onTap: () => _selectSavedLogin(_savedLogins[i]),
                onRemove: () => _removeSavedLogin(_savedLogins[i]),
              ),
          ],
        ),
      ],
    );
  }
}

class _MovingBlob {
  _MovingBlob({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.color,
  });

  double x;
  double y;
  double vx;
  double vy;
  final double radius;
  final Color color;
}

class _ColorBlobs extends StatefulWidget {
  const _ColorBlobs();

  @override
  State<_ColorBlobs> createState() => _ColorBlobsState();
}

class _ColorBlobsState extends State<_ColorBlobs>
    with SingleTickerProviderStateMixin {
  static const _specs = <(Color, double)>[
    (_kAccentPurple, 110),
    (_kAccentPink, 90),
    (_kAccentTeal, 100),
    (_kAccentAmber, 80),
    (_kAccentBlue, 70),
  ];

  static const _minSpeed = 42.0;
  static const _maxSpeed = 130.0;

  late final Ticker _ticker;
  final math.Random _rng = math.Random(7);
  final List<_MovingBlob> _blobs = [];
  Size _size = Size.zero;
  Duration? _lastElapsed;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _spawn(Size size) {
    _blobs
      ..clear()
      ..addAll([
        for (final spec in _specs)
          _MovingBlob(
            x:
                spec.$2 +
                _rng.nextDouble() * math.max(1, size.width - spec.$2 * 2),
            y:
                spec.$2 +
                _rng.nextDouble() * math.max(1, size.height - spec.$2 * 2),
            vx: (_rng.nextBool() ? 1 : -1) * (48 + _rng.nextDouble() * 56),
            vy: (_rng.nextBool() ? 1 : -1) * (48 + _rng.nextDouble() * 56),
            radius: spec.$2,
            color: spec.$1,
          ),
      ]);
  }

  void _ensureBlobs(Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    if (_blobs.isEmpty) {
      _spawn(size);
      _size = size;
      setState(() {});
      return;
    }
    if (size == _size) return;
    for (final blob in _blobs) {
      blob.x = blob.x.clamp(
        blob.radius,
        math.max(blob.radius, size.width - blob.radius),
      );
      blob.y = blob.y.clamp(
        blob.radius,
        math.max(blob.radius, size.height - blob.radius),
      );
    }
    _size = size;
  }

  void _bounceWalls(_MovingBlob blob) {
    final maxX = math.max(blob.radius, _size.width - blob.radius);
    final maxY = math.max(blob.radius, _size.height - blob.radius);
    if (blob.x < blob.radius) {
      blob.x = blob.radius;
      blob.vx = blob.vx.abs();
    } else if (blob.x > maxX) {
      blob.x = maxX;
      blob.vx = -blob.vx.abs();
    }
    if (blob.y < blob.radius) {
      blob.y = blob.radius;
      blob.vy = blob.vy.abs();
    } else if (blob.y > maxY) {
      blob.y = maxY;
      blob.vy = -blob.vy.abs();
    }
  }

  void _collide(_MovingBlob a, _MovingBlob b) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    final distSq = dx * dx + dy * dy;
    final minDist = a.radius + b.radius;
    if (distSq >= minDist * minDist) return;

    final dist = distSq <= 0.0001 ? 0.0001 : math.sqrt(distSq);
    final nx = dx / dist;
    final ny = dy / dist;

    final overlap = minDist - dist;
    final massA = a.radius * a.radius;
    final massB = b.radius * b.radius;
    final massSum = massA + massB;
    a.x -= nx * overlap * (massB / massSum);
    a.y -= ny * overlap * (massB / massSum);
    b.x += nx * overlap * (massA / massSum);
    b.y += ny * overlap * (massA / massSum);

    final relVx = b.vx - a.vx;
    final relVy = b.vy - a.vy;
    final velAlongNormal = relVx * nx + relVy * ny;
    if (velAlongNormal > 0) return;

    const restitution = 1.0;
    final impulse = -(1 + restitution) * velAlongNormal / massSum;
    a.vx -= impulse * massB * nx;
    a.vy -= impulse * massB * ny;
    b.vx += impulse * massA * nx;
    b.vy += impulse * massA * ny;
  }

  void _clampSpeed(_MovingBlob blob) {
    final speed = math.sqrt(blob.vx * blob.vx + blob.vy * blob.vy);
    if (speed < 1) {
      blob.vx = _minSpeed * (_rng.nextBool() ? 1 : -1);
      blob.vy = _minSpeed * (_rng.nextBool() ? 1 : -1);
      return;
    }
    if (speed < _minSpeed) {
      final scale = _minSpeed / speed;
      blob.vx *= scale;
      blob.vy *= scale;
    } else if (speed > _maxSpeed) {
      final scale = _maxSpeed / speed;
      blob.vx *= scale;
      blob.vy *= scale;
    }
  }

  void _onTick(Duration elapsed) {
    if (!mounted || _size == Size.zero || _blobs.isEmpty) {
      _lastElapsed = elapsed;
      return;
    }

    final last = _lastElapsed ?? elapsed;
    _lastElapsed = elapsed;
    var dt = (elapsed - last).inMicroseconds / 1e6;
    if (dt <= 0) return;
    if (dt > 0.05) dt = 0.05;

    for (final blob in _blobs) {
      blob.x += blob.vx * dt;
      blob.y += blob.vy * dt;
      _bounceWalls(blob);
    }

    for (var i = 0; i < _blobs.length; i++) {
      for (var j = i + 1; j < _blobs.length; j++) {
        _collide(_blobs[i], _blobs[j]);
      }
    }

    for (final blob in _blobs) {
      _bounceWalls(blob);
      _clampSpeed(blob);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          if (size.width > 0 && size.height > 0 && size != _size) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _ensureBlobs(size);
            });
          }
          return Stack(
            children: [
              for (final blob in _blobs)
                Positioned(
                  left: blob.x - blob.radius,
                  top: blob.y - blob.radius,
                  width: blob.radius * 2,
                  height: blob.radius * 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: blob.color.withValues(alpha: 0.28),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ModuleTiles extends StatelessWidget {
  const _ModuleTiles({required this.compact});

  final bool compact;

  static const _tiles = <(IconData, String, Color)>[
    (Icons.hotel_outlined, 'Wards', _kAccentPurple),
    (Icons.medical_services_outlined, 'Clinical', _kAccentTeal),
    (Icons.medication_outlined, 'Pharmacy', _kAccentAmber),
    (Icons.biotech_outlined, 'Laboratory', _kAccentIndigo),
    (Icons.payments_outlined, 'Billing', _kAccentPink),
    (Icons.dashboard_outlined, 'Operations', _kAccentGreen),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tiles = compact ? _tiles.take(4).toList() : _tiles;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final tile in tiles)
          Container(
            width: compact ? 150 : 168,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                HeltySolidIcon(
                  icon: tile.$1,
                  color: tile.$3,
                  size: 26,
                  iconSize: 14,
                  radius: 7,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tile.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _LoginClock extends StatefulWidget {
  const _LoginClock({required this.onDark});

  final bool onDark;

  @override
  State<_LoginClock> createState() => _LoginClockState();
}

class _LoginClockState extends State<_LoginClock> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = AppTimezone.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = AppTimezone.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = DateFormat('hh:mm a').format(_now);
    final date = DateFormat('EEE, MMM d, yyyy').format(_now);
    final onDark = widget.onDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withValues(alpha: 0.12)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: onDark
              ? Colors.white.withValues(alpha: 0.22)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: _kAccentGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                time,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: onDark ? Colors.white : null,
                ),
              ),
              Text(
                date,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: onDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : theme.colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SavedLoginChip extends StatelessWidget {
  const _SavedLoginChip({
    required this.login,
    required this.accent,
    required this.selected,
    required this.onTap,
    required this.onRemove,
  });

  final SavedLogin login;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  String _formatRoleLabel(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    return raw.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final role = _formatRoleLabel(login.roleLabel);

    return Semantics(
      label: 'Sign in as ${login.displayName}',
      button: true,
      child: Material(
        color: selected
            ? accent.withValues(alpha: 0.14)
            : colors.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 260),
            padding: const EdgeInsets.fromLTRB(8, 6, 2, 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: selected
                    ? accent.withValues(alpha: 0.55)
                    : colors.outline.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    login.initials,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HeltyEllipsisText(
                        text: login.displayName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (role.isNotEmpty)
                        HeltyEllipsisText(
                          text: role,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Semantics(
                  label: 'Remove ${login.displayName} from recent staff',
                  button: true,
                  child: IconButton(
                    tooltip: 'Remove',
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: onRemove,
                    icon: Icon(Icons.close, color: colors.onSurfaceVariant),
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
