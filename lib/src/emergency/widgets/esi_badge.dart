import 'package:flutter/material.dart';

class EsiBadge extends StatelessWidget {
  const EsiBadge({
    super.key,
    required this.esiLevel,
    this.compact = false,
  });

  final int? esiLevel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (esiLevel == null) {
      return Text(
        '—',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      );
    }

    final level = esiLevel!.clamp(1, 5);
    final color = _esiColor(level);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        'ESI $level',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: compact ? 11 : 12,
        ),
      ),
    );
  }

  Color _esiColor(int level) {
    switch (level) {
      case 1:
        return Colors.red.shade700;
      case 2:
        return Colors.orange.shade800;
      case 3:
        return Colors.amber.shade900;
      case 4:
        return Colors.blue.shade700;
      default:
        return Colors.green.shade700;
    }
  }
}
