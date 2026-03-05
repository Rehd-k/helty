import 'dart:ui';
import 'package:flutter/material.dart';

/// App-wide snackbar with glassmorphism and color-coded glow.
///
/// - [message]: text to display.
/// - [isError]: if true → reddish hue; if false → greenish hue.
void showSnackBar(
  BuildContext context, {
  required String message,
  bool isError = false,
}) {
  final theme = Theme.of(context);
  final accent = isError ? Colors.redAccent : Colors.greenAccent;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      content: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: accent.withValues(alpha: 0.10),
              border: Border.all(color: accent.withValues(alpha: 0.6)),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.4),
                  blurRadius: 24,
                  spreadRadius: 1,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  isError
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_rounded,
                  color: Colors.white,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      duration: const Duration(seconds: 3),
    ),
  );
}
