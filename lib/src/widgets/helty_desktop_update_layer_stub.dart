import 'package:flutter/material.dart';

/// Desktop installer updates are not used in the browser.
class HeltyDesktopUpdateLayer extends StatelessWidget {
  const HeltyDesktopUpdateLayer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
