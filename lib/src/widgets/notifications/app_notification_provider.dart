import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Severity for in-app toasts (not OS notifications).
enum AppNotificationLevel { success, error, warning, info }

@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.message,
    required this.level,
    required this.createdAt,
  });

  final String id;
  final String message;
  final AppNotificationLevel level;
  final DateTime createdAt;
}

class AppNotificationList extends StateNotifier<List<AppNotification>> {
  AppNotificationList() : super(const []);

  static const _defaultDuration = Duration(seconds: 4);
  static const _maxVisible = 6;

  /// Shows a dismissible toast. Auto-dismiss after [duration] (errors default longer).
  void show(
    String message, {
    AppNotificationLevel level = AppNotificationLevel.info,
    Duration? duration,
  }) {
    final id =
        '${DateTime.now().microsecondsSinceEpoch}_${message.hashCode}';
    final item = AppNotification(
      id: id,
      message: message,
      level: level,
      createdAt: DateTime.now(),
    );
    final next = [...state, item];
    if (next.length > _maxVisible) {
      next.removeRange(0, next.length - _maxVisible);
    }
    state = next;

    final d = duration ??
        (level == AppNotificationLevel.error
            ? const Duration(seconds: 6)
            : _defaultDuration);
    Future<void>.delayed(d, () => dismiss(id));
  }

  void dismiss(String id) {
    state = state.where((e) => e.id != id).toList();
  }

  void clear() => state = const [];
}

final appNotificationListProvider =
    StateNotifierProvider<AppNotificationList, List<AppNotification>>((ref) {
  return AppNotificationList();
});

/// Convenience for widgets with a [WidgetRef].
void showAppNotification(
  WidgetRef ref,
  String message, {
  AppNotificationLevel level = AppNotificationLevel.info,
  Duration? duration,
}) {
  ref
      .read(appNotificationListProvider.notifier)
      .show(message, level: level, duration: duration);
}
