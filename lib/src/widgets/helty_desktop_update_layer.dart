import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:updat/updat.dart';
import 'package:updat/utils/file_handler.dart' as updat_file;

import '../services/helty_desktop_update_service.dart';

/// Same behavior as [defaultChipWithSilentDownload] from `updat`, but without [Tooltip].
///
/// [MaterialApp.router] `builder` places this chip in a [Stack] next to the route subtree,
/// which is **not** under [Navigator]'s [Overlay]. [Tooltip] requires that ancestor and
/// throws when the update finishes and the "ready to install" button builds.
Widget _heltyUpdateChipWithoutTooltip({
  required BuildContext context,
  required String? latestVersion,
  required String appVersion,
  required UpdatStatus status,
  required void Function() checkForUpdate,
  required void Function() openDialog,
  required void Function() startUpdate,
  required Future<void> Function() launchInstaller,
  required void Function() dismissUpdate,
}) {
  if (UpdatStatus.available == status ||
      UpdatStatus.availableWithChangelog == status) {
    startUpdate();
  }

  if (UpdatStatus.readyToInstall == status) {
    return ElevatedButton.icon(
      onPressed: launchInstaller,
      icon: const Icon(Icons.check_circle),
      label: const Text('Update Ready to install'),
    );
  }

  return const SizedBox.shrink();
}

/// Overlays [UpdatWidget] on Windows so the app uses the same API origin as [ApiService].
///
/// Placed around the whole app (e.g. [MaterialApp.router] `builder`) so update checks run at
/// startup—including on the login screen—not only after sign-in.
///
/// Avoids [UpdatWindowManager] (requires `window_manager`, which conflicts with `bitsdojo_window`).
class HeltyDesktopUpdateLayer extends StatefulWidget {
  const HeltyDesktopUpdateLayer({super.key, required this.child});

  final Widget child;

  @override
  State<HeltyDesktopUpdateLayer> createState() =>
      _HeltyDesktopUpdateLayerState();
}

class _HeltyDesktopUpdateLayerState extends State<HeltyDesktopUpdateLayer> {
  String? _version;
  UpdatStatus? _previousStatus;

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) {
      PackageInfo.fromPlatform().then((p) {
        if (mounted) {
          // `updat` expects semver core (major.minor.patch). Flutter desktop
          // package versions often include "+build", which can trigger parse
          // errors and emit a generic update failure even when the API responds.
          setState(() => _version = p.version.trim());
        }
      });
    }
  }

  void _maybeShowErrorSnack(UpdatStatus status) {
    if (status != UpdatStatus.error) return;
    final fromDownload = _previousStatus == UpdatStatus.downloading;
    String message;
    if (fromDownload) {
      message =
          'The installer could not be downloaded. Check your network connection, free disk space, '
          'and firewall rules for this app. You can retry from Check for updates in the title bar.';
    } else {
      message =
          HeltyDesktopUpdateService.lastVersionCheckMessage ??
          'Could not check for updates. Verify the API server address in the app and your network, then try again.';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 8),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows || _version == null) {
      return widget.child;
    }

    final v = _version!;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: widget.child),
        Positioned(
          right: 16,
          bottom: 16,
          child: Material(
            type: MaterialType.transparency,
            child: UpdatWidget(
              currentVersion: v,
              appName: 'Helty',
              openOnDownload: true,
              // `updat` uses `url.split('.').last` as the file extension. URLs like
              // `.../download/latest` yield `.latest`, so the installer is saved with
              // the wrong extension and `url_launcher` fails to open it.
              getDownloadFileLocation: (latestVersion) =>
                  updat_file.getDownloadFileLocation(
                    latestVersion ?? v,
                    'Helty',
                    'exe',
                  ),
              getLatestVersion: () async {
                var latestVersion =
                    await HeltyDesktopUpdateService.getLatestVersionForUpdat(v);
                print('latestVersion: $latestVersion');
                print('v: $v');
                return latestVersion;
              },
              getBinaryUrl: (String? version) async {
                print('version: $version');
                var binaryUrl =
                    await HeltyDesktopUpdateService.getBinaryDownloadUrl(
                      version ?? v,
                    );
                print('binaryUrl: $binaryUrl');
                return binaryUrl;
              },
              // HeltyDesktopUpdateService.getBinaryDownloadUrl,
              callback: (status) {
                print('status: $status');
                _maybeShowErrorSnack(status);
                _previousStatus = status;
              },
              updateChipBuilder:
                  ({
                    required BuildContext context,
                    required String? latestVersion,
                    required String appVersion,
                    required UpdatStatus status,
                    required void Function() checkForUpdate,
                    required void Function() openDialog,
                    required void Function() startUpdate,
                    required Future<void> Function() launchInstaller,
                    required void Function() dismissUpdate,
                  }) {
                    HeltyDesktopUpdateService.checkForUpdate = checkForUpdate;
                    return _heltyUpdateChipWithoutTooltip(
                      context: context,
                      latestVersion: latestVersion,
                      appVersion: appVersion,
                      status: status,
                      checkForUpdate: checkForUpdate,
                      openDialog: openDialog,
                      startUpdate: startUpdate,
                      launchInstaller: launchInstaller,
                      dismissUpdate: dismissUpdate,
                    );
                  },
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    HeltyDesktopUpdateService.checkForUpdate = null;
    super.dispose();
  }
}
