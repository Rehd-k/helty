// import 'dart:io';

// import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';

import 'src/helper/theme.dart';
import 'src/services/navigation.service.dart';
import 'src/services/theme_provider.dart';

void main() {
  runApp(ProviderScope(child: const MyApp()));
  // if (Platform.isWindows) {
  //   doWhenWindowReady(() {
  //     final win = appWindow;
  //     win.maximize();
  //     win.title = "Helty";
  //     win.alignment = Alignment.center;
  //     win.show();
  //   });
  // }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // final themeProvider = context.watch<ThemeProvider>();
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
