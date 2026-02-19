import 'package:flutter/material.dart';

import '../../app_router.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();

  factory NavigationService() => _instance;

  NavigationService._internal();
  static final AppRouter _router = AppRouter(); // Static instance of AppRouter

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static AppRouter get router => _router;

  // Navigate to the dashboard route
  static Future<void> navigateToDashboard() async {
    // await _router.push(DashboardRoute());
  }

  // Navigate back
  static void goBack() {
    _router.pop();
  }
}
