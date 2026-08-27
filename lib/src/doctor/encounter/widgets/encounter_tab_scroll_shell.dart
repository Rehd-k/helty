import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';

/// Wraps encounter tab content so it can sit in a parent [CustomScrollView].
///
/// Standalone tabs keep [ResponsiveBody] and (unless [expand] is true) an
/// inner [SingleChildScrollView]. Embedded sections return [child] only.
class EncounterTabScrollShell extends StatelessWidget {
  const EncounterTabScrollShell({
    super.key,
    required this.embedded,
    required this.child,
    this.expand = false,
  });

  final bool embedded;
  final Widget child;

  /// When not embedded, fill the tab viewport so flex children work.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    if (embedded) return child;
    return ResponsiveBody(
      center: false,
      expand: expand,
      builder: (context, bp) {
        if (expand) return child;
        return SingleChildScrollView(padding: EdgeInsets.zero, child: child);
      },
    );
  }
}
