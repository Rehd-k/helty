import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pending_orders_models.dart';
import '../services/internal_chat_socket.dart';
import '../services/pending_orders_notification_service.dart';

class PendingOrdersTickState {
  const PendingOrdersTickState({
    this.lastTickAt,
    this.lastTickReceivedAt,
    this.isStale = false,
  });

  final DateTime? lastTickAt;
  final DateTime? lastTickReceivedAt;
  final bool isStale;

  PendingOrdersTickState copyWith({
    DateTime? lastTickAt,
    DateTime? lastTickReceivedAt,
    bool? isStale,
  }) {
    return PendingOrdersTickState(
      lastTickAt: lastTickAt ?? this.lastTickAt,
      lastTickReceivedAt: lastTickReceivedAt ?? this.lastTickReceivedAt,
      isStale: isStale ?? this.isStale,
    );
  }
}

class PendingOrdersTickNotifier extends Notifier<PendingOrdersTickState> {
  StreamSubscription<Map<String, dynamic>>? _tickSub;
  Timer? _staleCheckTimer;
  bool _staleLogged = false;

  @override
  PendingOrdersTickState build() {
    ref.listen(internalChatSocketProvider, (_, __) {
      _bindSocket();
    });
    _bindSocket();
    _staleCheckTimer?.cancel();
    _staleCheckTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _checkStale(),
    );
    ref.onDispose(() {
      _tickSub?.cancel();
      _staleCheckTimer?.cancel();
    });
    return const PendingOrdersTickState();
  }

  void _bindSocket() {
    _tickSub?.cancel();
    _tickSub = ref
        .read(internalChatSocketProvider)
        .pendingOrdersTickStream
        .listen(_onTick);
  }

  Future<void> _onTick(Map<String, dynamic> raw) async {
    final parsed = PendingOrdersTick.tryParse(raw);
    if (parsed == null) return;

    final activeItems = parsed.items
        .where((item) => _shouldNotify(item))
        .map((item) => item.toNotificationState())
        .toList(growable: false);

    await ref.read(pendingOrdersNotificationServiceProvider).reconcile(activeItems);
    state = state.copyWith(
      lastTickAt: parsed.tickAt,
      lastTickReceivedAt: DateTime.now(),
      isStale: false,
    );
    _staleLogged = false;
  }

  bool _shouldNotify(PendingOrdersItem item) {
    final normalizedStatus = item.status.trim().toUpperCase();
    final resolvedStatuses = <String>{'DONE', 'COMPLETED', 'RESOLVED', 'CLOSED'};
    if (resolvedStatuses.contains(normalizedStatus)) return false;
    final eventAt = item.eventAt;
    if (eventAt == null) return true;
    final age = DateTime.now().difference(eventAt.toLocal());
    return age.inDays <= 3;
  }

  void _checkStale() {
    final last = state.lastTickReceivedAt;
    if (last == null) return;
    final stale = DateTime.now().difference(last).inSeconds > 45;
    if (stale && !_staleLogged) {
      _staleLogged = true;
      if (kDebugMode) {
        debugPrint(
          'pending_orders_tick stale: no events for >45 seconds',
        );
      }
    }
    if (stale != state.isStale) {
      state = state.copyWith(isStale: stale);
    }
  }
}

final pendingOrdersTickProvider =
    NotifierProvider<PendingOrdersTickNotifier, PendingOrdersTickState>(
  PendingOrdersTickNotifier.new,
);
