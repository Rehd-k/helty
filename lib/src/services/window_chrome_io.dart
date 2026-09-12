import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';

import '../app/product_environment.dart';
import '../core/platform/helty_platform.dart';

export 'package:bitsdojo_window/bitsdojo_window.dart'
    show
        MoveWindow,
        WindowTitleBarBox,
        WindowButtonColors,
        MinimizeWindowButton,
        MaximizeWindowButton,
        CloseWindowButton;

void revealHeltyDesktopWindow() {
  if (!HeltyPlatform.isWindows) return;

  var revealed = false;
  void reveal() {
    if (revealed) return;
    revealed = true;
    final win = appWindow;
    win.minSize = const Size(1024, 640);
    win.maximize();
    win.title = ProductEnvironment.displayName;
    win.show();
  }

  doWhenWindowReady(reveal);
  Future<void>.delayed(const Duration(seconds: 2), reveal);
}
