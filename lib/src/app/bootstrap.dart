import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../chat/services/chat_notification_coordinator.dart';
import '../core/providers/app_lifecycle_provider.dart';
import '../helper/app_timezone.dart';
import '../helper/theme.dart';
import '../printing/pdf/report_template_preference.dart';
import '../printing/pdf/report_templates/report_pdf_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_mode_provider.dart';
import '../services/navigation.service.dart';
import '../widgets/clock_sync_gate.dart';
import '../widgets/helty_desktop_update_layer.dart';
import '../widgets/intro_splash.dart';
import '../widgets/notifications/app_notification_host.dart';
import 'org_config.dart';
import 'product_definition.dart';
import 'product_environment.dart';

/// Shared app startup for hospital, pharmacy, and diagnostics entry points.
Future<void> bootstrapHeltyApp({AppProduct? product}) async {
  WidgetsFlutterBinding.ensureInitialized();

  await OrgConfig.load();

  if (product != null) {
    ProductEnvironment.bind(product);
  }
  ProductEnvironment.validateReleaseConfig();

  await AppTimezone.initialize();

  // On multi-user Windows PCs, SharedPreferences lives under AppData. If the
  // app was previously launched elevated, that folder/file can be unreadable
  // for a normal user (`Access denied`) and used to abort before [runApp].
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (e, st) {
    debugPrint('SharedPreferences unavailable at startup: $e\n$st');
  }
  final initialThemeMode = prefs != null
      ? ThemeModePersistence.read(prefs)
      : ThemeMode.system;
  final initialReportTemplate = prefs != null
      ? ReportTemplatePersistence.read(prefs)
      : ReportPdfTemplateId.classicNavy;

  runApp(
    ProviderScope(
      overrides: [
        themeModeProvider.overrideWith(
          (ref) => ThemeModeNotifier(initialThemeMode),
        ),
        reportTemplateProvider.overrideWith(
          (ref) => ReportTemplateNotifier(initialReportTemplate),
        ),
      ],
      child: const IntroSplash(
        child: ClockSyncGate(child: HeltyApp()),
      ),
    ),
  );

  _revealWindowsWindow();
}

void _revealWindowsWindow() {
  if (!Platform.isWindows) return;

  var revealed = false;
  void reveal() {
    if (revealed) return;
    revealed = true;
    final win = appWindow;
    win.minSize = const Size(1024, 640);
    win.maximize();
    win.title = ProductEnvironment.displayName;
    win.show();
  }

  doWhenWindowReady(reveal);
  // If the first frame never rasterizes (some GPU / fast-user-switch sessions),
  // still try to show rather than leaving a hidden process.
  Future<void>.delayed(const Duration(seconds: 2), reveal);
}

class HeltyApp extends ConsumerStatefulWidget {
  const HeltyApp({super.key});

  @override
  ConsumerState<HeltyApp> createState() => _HeltyAppState();
}

class _HeltyAppState extends ConsumerState<HeltyApp> {
  @override
  void initState() {
    super.initState();
    // Try to restore the existing session on startup.
    // If a valid token exists, staff is loaded into AuthState;
    // otherwise the AuthGuard will redirect to login.
    Future.microtask(() => ref.read(authProvider.notifier).restoreSession());
    Future.microtask(
      () => ref.read(chatNotificationCoordinatorProvider).initialize(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(appLifecycleProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: ProductEnvironment.displayName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: FlutterQuillLocalizations.localizationsDelegates,
      supportedLocales: FlutterQuillLocalizations.supportedLocales,
      routerConfig: NavigationService.router.config(),
      builder: (context, child) {
        return HeltyDesktopUpdateLayer(
          child: AppNotificationHost(
            child: SafeArea(child: child ?? const SizedBox.shrink()),
          ),
        );
      },
    );
  }
}
