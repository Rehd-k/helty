import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cmd_breakpoints.dart';

class CmdAsyncScaffold<T> extends StatelessWidget {
  const CmdAsyncScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.asyncValue,
    required this.builder,
  });

  final String title;
  final String? subtitle;
  final AsyncValue<T> asyncValue;
  final Widget Function(BuildContext context, T data) builder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bp = CmdBreakpoints.fromWidth(constraints.maxWidth);
          Widget wrapBody(Widget child) {
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: CmdBreakpoints.maxContentWidth,
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    bp.paddingH,
                    bp.paddingV,
                    bp.paddingH,
                    bp.paddingV,
                  ),
                  child: child,
                ),
              ),
            );
          }

          return asyncValue.when(
            data: (data) => wrapBody(builder(context, data)),
            loading: () => wrapBody(
              const Center(child: CircularProgressIndicator()),
            ),
            error: (e, st) => wrapBody(
              Center(
                child: SelectableText(
                  'Error: $e',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
