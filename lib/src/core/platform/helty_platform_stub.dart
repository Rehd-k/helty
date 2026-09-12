/// Web / non-IO stand-in for `dart:io` [Platform].
class HeltyPlatform {
  HeltyPlatform._();

  static bool get isWindows => false;
  static bool get isAndroid => false;
  static bool get isIOS => false;
  static bool get isMacOS => false;
  static bool get isLinux => false;
  static const String pathSeparator = '/';
}
