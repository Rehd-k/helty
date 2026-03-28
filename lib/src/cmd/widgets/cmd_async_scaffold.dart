import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      body: asyncValue.when(
        data: (data) => builder(context, data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SelectableText('Error: $e'),
          ),
        ),
      ),
    );
  }
}
