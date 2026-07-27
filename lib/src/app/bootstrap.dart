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
import '../providers/auth_provider.dart';
import '../providers/theme_mode_provider.dart';
import '../services/navigation.service.dart';
import '../widgets/clock_sync_gate.dart';
import '../widgets/helty_desktop_update_layer.dart';
import '../widgets/notifications/app_notification_host.dart';
import 'org_config.dart';
import 'product_definition.dart';
import 'product_environment.dart';
import '../printing/pdf/report_template_preference.dart';

/// Shared app startup for hospital, pharmacy, and diagnostics entry points.
Future<void> bootstrapHeltyApp({AppProduct? product}) async {
  WidgetsFlutterBinding.ensureInitialized();

  await OrgConfig.load();

  if (product != null) {
    ProductEnvironment.bind(product);
  }
  ProductEnvironment.validateReleaseConfig();

  await AppTimezone.initialize();
  final prefs = await SharedPreferences.getInstance();
  final initialThemeMode = ThemeModePersistence.read(prefs);
  final initialReportTemplate =
      ReportTemplatePersistence.read(prefs);

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
      child: const ClockSyncGate(child: HeltyApp()),
    ),
  );

  if (Platform.isWindows) {
    doWhenWindowReady(() {
      final win = appWindow;
      win.maximize();
      win.title = ProductEnvironment.displayName;
      win.show();
    });
  }
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
