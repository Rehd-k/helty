// import 'dart:io';

// import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/helper/theme.dart';
import 'src/providers/auth_provider.dart';
import 'src/services/navigation.service.dart';

void main() {
  runApp(ProviderScope(child: const MyApp()));

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
    return MaterialApp.router(
      title: 'Helty Hospital',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      routerConfig: NavigationService.router.config(),
    );
  }
}
