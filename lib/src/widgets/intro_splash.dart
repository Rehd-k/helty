import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

/// Plays [assetPath] in a small centered window over [child], then fades out.
///
/// Wrap this *around* [ClockSyncGate] so the intro can play while the server
/// time check runs underneath. When the overlay fades, the user sees login if
/// the check already passed, or the loading/error screen if it has not.
class IntroSplash extends StatefulWidget {
  const IntroSplash({
    super.key,
    required this.child,
    this.assetPath = 'assets/intro.mp4',
    this.fadeDuration = const Duration(milliseconds: 600),
    this.maxWait = const Duration(seconds: 12),
  });

  final Widget child;
  final String assetPath;
  final Duration fadeDuration;

  /// Hard cap so a stuck player never blocks the app.
  final Duration maxWait;

  @override
  State<IntroSplash> createState() => _IntroSplashState();
}

class _IntroSplashState extends State<IntroSplash>
    with SingleTickerProviderStateMixin {
  static const _navy = Color(0xFF0F172A);
  static const _videoMaxWidth = 480.0;

  VideoPlayerController? _controller;
  late final AnimationController _fade;
  bool _overlayVisible = true;
  bool _startedFade = false;
  bool _seenPlayback = false;
  Timer? _maxWaitTimer;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: widget.fadeDuration,
      value: 1,
    );
    _fade.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && mounted) {
        setState(() => _overlayVisible = false);
        _disposePlayer();
      }
    });
    _maxWaitTimer = Timer(widget.maxWait, _beginFade);
    unawaited(_start());
  }

  /// Windows Media Foundation cannot read Flutter's asset protocol. Copy the
  /// bytes to a real file, then play that. Other platforms use the asset URI.
  Future<VideoPlayerController> _openController() async {
    if (Platform.isWindows) {
      final data = await rootBundle.load(widget.assetPath);
      final file = File('${Directory.systemTemp.path}\\helty_intro.mp4');
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      return VideoPlayerController.file(file);
    }
    return VideoPlayerController.asset(widget.assetPath);
  }

  Future<void> _start() async {
    VideoPlayerController? controller;
    try {
      controller = await _openController();
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.setVolume(1.0);
      controller
        ..setLooping(false)
        ..addListener(_onTick);
      setState(() => _controller = controller);
      await controller.play();
    } catch (e, st) {
      debugPrint('IntroSplash: failed to play ${widget.assetPath}: $e\n$st');
      await controller?.dispose();
      if (mounted) _beginFade();
    }
  }

  void _onTick() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final duration = c.value.duration;
    if (duration == Duration.zero) return;

    // Windows can report isCompleted (position == duration) before the first
    // frame. Wait until playback has actually advanced.
    if (!_seenPlayback) {
      if (c.value.isPlaying && c.value.position > Duration.zero) {
        _seenPlayback = true;
      } else {
        return;
      }
    }

    final remaining = duration - c.value.position;
    if (remaining <= widget.fadeDuration || c.value.isCompleted) {
      _beginFade();
    }
  }

  void _beginFade() {
    if (_startedFade || !mounted) return;
    _startedFade = true;
    _maxWaitTimer?.cancel();
    _controller?.removeListener(_onTick);
    _fade.reverse();
  }

  void _disposePlayer() {
    final c = _controller;
    _controller = null;
    c?.removeListener(_onTick);
    unawaited(c?.dispose() ?? Future<void>.value());
  }

  @override
  void dispose() {
    _maxWaitTimer?.cancel();
    _fade.dispose();
    _disposePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Above MaterialApp — no Directionality / MediaQuery yet.
    // VideoPlayer is a Windows GPU texture. FadeTransition/Opacity/ClipRRect
    // ancestors make that texture draw blank, so the clip stays a sibling of
    // the fading navy, not a child of it.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          widget.child,
          if (_overlayVisible)
            AbsorbPointer(
              child: Stack(
                alignment: Alignment.center,
                fit: StackFit.expand,
                children: [
                  FadeTransition(
                    opacity: _fade,
                    child: const ColoredBox(color: _navy),
                  ),
                  Center(child: _buildVideo()),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideo() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return const SizedBox.shrink();
    }
    final ratio = c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _videoMaxWidth),
      child: AspectRatio(
        aspectRatio: ratio,
        child: ColoredBox(
          color: Colors.black,
          child: VideoPlayer(c),
        ),
      ),
    );
  }
}
