import 'package:flutter/material.dart';

import '../../widgets/helty_surface.dart';
import '../ed_board_metrics.dart';
import '../models/ed_enums.dart';

class EdStatusChip extends StatelessWidget {
  const EdStatusChip({
    super.key,
    required this.status,
    this.compact = false,
  });

  final EdWorkflowStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return HeltyEllipsisChip(
      label: status.label,
      color: EdBoardMetrics.statusColor(status),
    );
  }
}
