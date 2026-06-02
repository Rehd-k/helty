import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io' show Platform;

typedef NotificationTapHandler = void Function(NotificationResponse response);

class LocalNotificationPlatformService {
  LocalNotificationPlatformService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  Future<void>? _initializing;

  Future<void> initialize({NotificationTapHandler? onTap}) async {
    if (_initialized) return;
    if (_initializing != null) {
      await _initializing;
      return;
    }
    if (!_isSupportedPlatform()) {
      _initialized = true;
      return;
    }
    _initializing = _initializeInternal(onTap: onTap);
    await _initializing;
  }

  Future<void> _initializeInternal({NotificationTapHandler? onTap}) async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
      windows: WindowsInitializationSettings(
        appName: 'Helty',
        appUserModelId: 'helty.desktop.app',
        guid: '4e4ffc49-2cb4-4d99-aa91-f931cbcffca4',
      ),
    );
    try {
      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: onTap,
      );
      await _requestPermissions();
      _initialized = true;
    } catch (e) {
      // Keep app stable if the host platform/plugin bridge is unavailable.
      if (kDebugMode) {
        debugPrint('Notification platform init failed: $e');
      }
      _initialized = true;
    } finally {
      _initializing = null;
    }
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    required NotificationDetails details,
    String? payload,
  }) async {
    if (!_initialized) {
      await initialize();
    }
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  Future<void> cancel(int id) async {
    if (!_initialized) {
      await initialize();
    }
    await _plugin.cancel(id: id);
  }

  Future<void> _requestPermissions() async {
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      await _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Notification permission request failed: $e');
      }
    }
  }

  bool _isSupportedPlatform() {
    if (kIsWeb) return false;
    return Platform.isAndroid ||
        Platform.isIOS ||
        Platform.isMacOS ||
        Platform.isWindows ||
        Platform.isLinux;
  }
}

final localNotificationPlatformServiceProvider =
    Provider<LocalNotificationPlatformService>((ref) {
      return LocalNotificationPlatformService(
        FlutterLocalNotificationsPlugin(),
      );
    });
