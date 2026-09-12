import 'dart:io' show Platform;

class HeltyPlatform {
  HeltyPlatform._();

  static bool get isWindows => Platform.isWindows;
  static bool get isAndroid => Platform.isAndroid;
  static bool get isIOS => Platform.isIOS;
  static bool get isMacOS => Platform.isMacOS;
  static bool get isLinux => Platform.isLinux;
  static String get pathSeparator => Platform.pathSeparator;
}
