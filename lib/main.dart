import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/helper/app_timezone.dart';
import 'src/helper/theme.dart';
import 'src/chat/services/chat_notification_coordinator.dart';
import 'src/core/providers/app_lifecycle_provider.dart';
import 'src/providers/auth_provider.dart';
import 'src/providers/theme_mode_provider.dart';
import 'src/services/navigation.service.dart';
import 'src/widgets/clock_sync_gate.dart';
import 'src/widgets/helty_desktop_update_layer.dart';
import 'src/widgets/notifications/app_notification_host.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppTimezone.initialize();
  final prefs = await SharedPreferences.getInstance();
  final initialThemeMode = ThemeModePersistence.read(prefs);

  runApp(
    ProviderScope(
      overrides: [
        themeModeProvider.overrideWith(
          (ref) => ThemeModeNotifier(initialThemeMode),
        ),
      ],
      child: const ClockSyncGate(child: MyApp()),
    ),
  );

  if (Platform.isWindows) {
    doWhenWindowReady(() {
      final win = appWindow;
      win.maximize();
      win.title = "Helty";
      win.show();
    });
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
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
      title: 'Helty',
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
