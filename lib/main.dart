import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/helper/theme.dart';
import 'src/providers/auth_provider.dart';
import 'src/providers/theme_mode_provider.dart';
import 'src/services/navigation.service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final initialThemeMode = ThemeModePersistence.read(prefs);

  runApp(
    ProviderScope(
      overrides: [
        themeModeProvider.overrideWith(
          (ref) => ThemeModeNotifier(initialThemeMode),
        ),
      ],
      child: const MyApp(),
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
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Helty',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      routerConfig: NavigationService.router.config(),
      // builder: (context, child) {
      //   return Stack(
      //     children: [
      //       if (child != null) child,
      //       const Positioned.fill(child: WatermarkOverlay()),
      //     ],
      //   );
      // },
    );
  }
}
