import 'package:flutter/material.dart';

import '../helper/theme.dart';
import 'helty_surface.dart';

/// Width below which Filters open as a right-edge slide panel.
const double kHeltySlideBreakpoint = 1100;

bool heltyUseSlideFilters(BuildContext context) =>
    MediaQuery.sizeOf(context).width < kHeltySlideBreakpoint;

/// One row in the mobile Filters panel Quick Actions block.
class HeltySlideAction {
  const HeltySlideAction({
    required this.label,
    required this.icon,
    required this.colors,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback? onPressed;
}

/// Tune button used on mobile screens that have no other Filters control.
class HeltyMobileFiltersButton extends StatelessWidget {
  const HeltyMobileFiltersButton({
    super.key,
    required this.onPressed,
    this.color,
  });

  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? Theme.of(context).colorScheme.primary;
    return IconButton(
      tooltip: 'Filters',
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: HeltySolidIcon(
        icon: Icons.tune,
        color: accent,
        size: 32,
        iconSize: 16,
        radius: 8,
      ),
    );
  }
}

/// Full-height panel that slides in from the right. Mobile only.
Future<void> showHeltySlidePanel({
  required BuildContext context,
  WidgetBuilder? bodyBuilder,
  Widget? body,
  List<HeltySlideAction> quickActions = const [],
  Widget? below,
}) {
  assert(
    bodyBuilder != null ||
        body != null ||
        quickActions.isNotEmpty ||
        below != null,
  );
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Filters',
    barrierColor: Colors.black.withValues(alpha: 0.18),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, animation, secondaryAnimation) {
      final theme = Theme.of(ctx);
      final cs = theme.colorScheme;
      final screenWidth = MediaQuery.sizeOf(ctx).width;
      final panelWidth = screenWidth < 520 ? screenWidth : 400.0;
      final content = bodyBuilder?.call(ctx) ?? body;

      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: cs.surface,
          elevation: 8,
          child: SizedBox(
            width: panelWidth,
            height: MediaQuery.sizeOf(ctx).height,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                    child: Row(
                      children: [
                        HeltySolidIcon(
                          icon: Icons.tune,
                          color: cs.primary,
                          size: 28,
                          iconSize: 15,
                          radius: 7,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Filters',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(ctx).maybePop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: cs.outlineVariant),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: [
                        ?content,
                        if (quickActions.isNotEmpty) ...[
                          if (content != null) const SizedBox(height: 20),
                          Row(
                            children: [
                              HeltySolidIcon(
                                icon: Icons.flash_on,
                                color: cs.tertiary,
                                size: 26,
                                iconSize: 14,
                                radius: 7,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Quick Actions',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          for (var i = 0; i < quickActions.length; i++) ...[
                            if (i > 0) const SizedBox(height: 8),
                            _SlideActionButton(
                              action: quickActions[i],
                              onTap: () => _runSlideAction(ctx, quickActions[i]),
                            ),
                          ],
                        ],
                        if (below != null) ...[
                          if (content != null || quickActions.isNotEmpty)
                            const SizedBox(height: 20),
                          below,
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}

void _runSlideAction(BuildContext context, HeltySlideAction action) {
  final callback = action.onPressed;
  Navigator.of(context).maybePop();
  if (callback == null) return;
  WidgetsBinding.instance.addPostFrameCallback((_) => callback());
}

class _SlideActionButton extends StatelessWidget {
  const _SlideActionButton({required this.action, required this.onTap});

  final HeltySlideAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = action.onPressed != null;
    final cs = Theme.of(context).colorScheme;
    final colors = enabled
        ? action.colors
        : [cs.outlineVariant, cs.outline];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(action.icon, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    action.label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
