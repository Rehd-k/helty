import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_notification_provider.dart';

/// Wraps the app (or a subtree) and paints stacked toasts top-right.
class AppNotificationHost extends ConsumerWidget {
  const AppNotificationHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(appNotificationListProvider);
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 16, 0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final n in items)
                      _ToastCard(
                        key: ValueKey(n.id),
                        notification: n,
                        onDismiss: () => ref
                            .read(appNotificationListProvider.notifier)
                            .dismiss(n.id),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ToastCard extends StatefulWidget {
  const _ToastCard({
    super.key,
    required this.notification,
    required this.onDismiss,
  });

  final AppNotification notification;
  final VoidCallback onDismiss;

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0.08, 0),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  late final Animation<double> _fade = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeOut,
  );

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _animateOut() async {
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color bg, Color onBg, IconData icon) = switch (widget.notification.level) {
      AppNotificationLevel.success => (
          scheme.primaryContainer,
          scheme.onPrimaryContainer,
          Icons.check_circle_rounded,
        ),
      AppNotificationLevel.error => (
          scheme.errorContainer,
          scheme.onErrorContainer,
          Icons.error_rounded,
        ),
      AppNotificationLevel.warning => (
          const Color(0xFFFFF4E5),
          const Color(0xFF7C4A00),
          Icons.warning_amber_rounded,
        ),
      AppNotificationLevel.info => (
          scheme.surfaceContainerHigh,
          scheme.onSurface,
          Icons.info_rounded,
        ),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            elevation: 8,
            shadowColor: Colors.black45,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _animateOut,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: widget.notification.level == AppNotificationLevel.error
                          ? scheme.error
                          : scheme.primary,
                      width: 4,
                    ),
                  ),
                  color: bg,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 22, color: onBg.withValues(alpha: 0.9)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.notification.message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: onBg,
                              height: 1.35,
                            ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: Icon(Icons.close_rounded, size: 18, color: onBg),
                      onPressed: _animateOut,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
