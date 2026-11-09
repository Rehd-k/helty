import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../app_router.gr.dart';
import '../core/storage/saved_login_storage.dart';
import '../core/storage/token_storage.dart';
import '../models/staff_registration_options.dart';
import '../providers/auth_provider.dart';
import 'display_api.dart';

@RoutePage()
class DisplayBoardScreen extends ConsumerStatefulWidget {
  const DisplayBoardScreen({super.key});

  @override
  ConsumerState<DisplayBoardScreen> createState() => _DisplayBoardScreenState();
}

class _DisplayBoardScreenState extends ConsumerState<DisplayBoardScreen> {
  final _api = DisplayApi();
  Timer? _poll;
  Timer? _clock;
  DisplayBoardSnapshot? _board;
  List<DisplayVideoItem> _videos = const [];
  String? _error;
  bool _loading = true;
  bool _picking = false;
  String? _lane;
  DateTime _now = DateTime.now();

  VideoPlayerController? _player;
  int _videoIndex = 0;
  bool _videoFailed = false;
  bool _advancing = false;
  int _videoFailures = 0;

  @override
  void initState() {
    super.initState();
    _restoreLane();
    _poll = Timer.periodic(const Duration(seconds: 20), (_) => _refresh(silent: true));
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _clock?.cancel();
    _disposePlayer();
    super.dispose();
  }

  Future<void> _restoreLane() async {
    final saved = await loadSelectedDisplayLane();
    if (!mounted) return;
    setState(() {
      _lane = saved;
      _picking = saved == null;
      _loading = saved != null;
    });
    await _refresh();
  }

  Future<void> _chooseLane(String lane) async {
    await saveSelectedDisplayLane(lane);
    if (!mounted) return;
    setState(() {
      _lane = lane;
      _picking = false;
      _loading = true;
      _error = null;
      _board = null;
    });
    await _refresh();
  }

  Future<void> _refresh({bool silent = false}) async {
    final lane = _lane;
    try {
      final videos = await _api.fetchActiveVideos();
      final board = lane == null ? null : await _api.fetchBoard(lane);
      if (!mounted) return;
      final idsChanged = videos.map((v) => v.id).join() !=
          _videos.map((v) => v.id).join();
      setState(() {
        if (board != null) _board = board;
        _videos = videos;
        _error = null;
        _loading = false;
        _now = DateTime.now();
      });
      if (idsChanged || _player == null) {
        _videoIndex = 0;
        await _playCurrent();
      }
    } catch (e) {
      if (!mounted) return;
      final hasToken = await TokenStorage.hasToken();
      if (!mounted) return;
      if (!hasToken) {
        context.router.replaceAll([LoginRoute()]);
        return;
      }
      setState(() {
        _error = silent ? _error : 'The board could not refresh.';
        _loading = false;
      });
    }
  }

  Future<void> _disposePlayer() async {
    final current = _player;
    _player = null;
    if (current == null) return;
    current.removeListener(_onVideoTick);
    await current.dispose();
  }

  Future<void> _playCurrent() async {
    await _disposePlayer();
    if (!mounted || _videos.isEmpty) {
      if (mounted) setState(() => _videoFailed = false);
      return;
    }
    final index = _videoIndex.clamp(0, _videos.length - 1);
    final video = _videos[index];
    final token = await TokenStorage.getAccessToken();
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(_api.fileUrl(video.id)),
      httpHeaders: {if (token != null) 'Authorization': 'Bearer $token'},
    );
    try {
      await controller.initialize();
      await controller.setVolume(1);
      controller.addListener(_onVideoTick);
      await controller.play();
      if (!mounted) {
        controller.removeListener(_onVideoTick);
        await controller.dispose();
        return;
      }
      setState(() {
        _player = controller;
        _videoIndex = index;
        _videoFailed = false;
        _advancing = false;
        _videoFailures = 0;
      });
    } catch (_) {
      await controller.dispose();
      if (!mounted) return;
      _videoFailures += 1;
      if (_videoFailures >= _videos.length) {
        setState(() => _videoFailed = true);
        return;
      }
      setState(() => _videoFailed = true);
      _advanceVideo();
    }
  }

  void _onVideoTick() {
    final controller = _player;
    if (controller == null || _advancing || !controller.value.isInitialized) {
      return;
    }
    final duration = controller.value.duration;
    if (duration == Duration.zero) return;
    if (controller.value.position + const Duration(milliseconds: 250) >=
        duration) {
      _advancing = true;
      Future.microtask(_advanceVideo);
    }
  }

  void _advanceVideo() {
    if (_videos.isEmpty) return;
    _videoIndex = (_videoIndex + 1) % _videos.length;
    _playCurrent();
  }

  Future<void> _signOut() async {
    final password = await showDialog<String>(
      context: context,
      builder: (ctx) => const _DisplaySignOutDialog(),
    );
    if (password == null || password.isEmpty || !mounted) return;

    final staff = ref.read(authProvider).staff;
    final saved = await SavedLoginStorage.load();
    final identifier = saved.isNotEmpty
        ? saved.first.emailOrPhone
        : (staff?.email?.trim().isNotEmpty == true
            ? staff!.email!.trim()
            : staff?.phone?.trim());
    if (identifier == null || identifier.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This screen has no saved sign-in.')),
      );
      return;
    }

    final ok = await ref.read(authProvider.notifier).login(
      emailOrPhone: identifier,
      password: password,
    );
    if (!mounted) return;
    if (!ok) {
      final message = ref.read(authProvider).error ?? 'Password was not accepted.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    await clearSelectedDisplayLane();
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    context.router.replaceAll([LoginRoute()]);
  }

  @override
  Widget build(BuildContext context) {
    final lane = _lane ?? _board?.lane ?? '';
    final rows = _board?.rows ?? const <DisplayBoardRow>[];

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 900;
            final video = _VideoPane(
              player: _player,
              title: _videos.isEmpty
                  ? null
                  : _videos[_videoIndex.clamp(0, _videos.length - 1)].title,
              empty: _videos.isEmpty,
              failed: _videoFailed && _player == null,
            );
            final queue = _picking
                ? _LanePicker(
                    onSelect: _chooseLane,
                    onCancel: _lane == null
                        ? null
                        : () => setState(() => _picking = false),
                    onSignOut: _signOut,
                  )
                : _QueuePane(
                    title: displayLaneTitle(lane),
                    rows: rows,
                    now: _now,
                    loading: _loading,
                    error: _error,
                    onSignOut: _signOut,
                    onChangeList: () => setState(() => _picking = true),
                  );
            if (stacked) {
              return Column(
                children: [
                  SizedBox(height: constraints.maxHeight * 0.42, child: video),
                  Expanded(child: queue),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: video),
                Expanded(child: queue),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _VideoPane extends StatelessWidget {
  const _VideoPane({
    required this.player,
    required this.title,
    required this.empty,
    required this.failed,
  });

  final VideoPlayerController? player;
  final String? title;
  final bool empty;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final ready = player != null && player!.value.isInitialized;
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (ready)
            Center(
              child: AspectRatio(
                aspectRatio: player!.value.aspectRatio == 0
                    ? 16 / 9
                    : player!.value.aspectRatio,
                child: VideoPlayer(player!),
              ),
            )
          else
            Center(
              child: Text(
                empty
                    ? 'No videos yet'
                    : failed
                        ? 'Skipping a video that will not play'
                        : 'Starting video',
                style: const TextStyle(color: Colors.white70, fontSize: 22),
              ),
            ),
          if (title != null && title!.isNotEmpty)
            Positioned(
              left: 20,
              right: 20,
              bottom: 16,
              child: Text(
                title!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }
}

class _QueuePane extends StatelessWidget {
  const _QueuePane({
    required this.title,
    required this.rows,
    required this.now,
    required this.loading,
    required this.error,
    required this.onSignOut,
    required this.onChangeList,
  });

  final String title;
  final List<DisplayBoardRow> rows;
  final DateTime now;
  final bool loading;
  final String? error;
  final VoidCallback onSignOut;
  final VoidCallback onChangeList;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF8FAFC),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                Text(
                  '${rows.length}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F766E),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onChangeList,
                  child: const Text('Change list'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              error ?? 'Waiting now',
              style: TextStyle(
                fontSize: 16,
                color: error == null
                    ? const Color(0xFF64748B)
                    : const Color(0xFFB91C1C),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: loading && rows.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : rows.isEmpty
                      ? const Center(
                          child: Text(
                            'No one is waiting',
                            style: TextStyle(
                              fontSize: 28,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: rows.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final row = rows[index];
                            return _QueueRow(
                              position: index + 1,
                              row: row,
                              waited: waitingDurationLabel(row.waitingSince, now),
                              showLane: title == 'Waiting patients',
                            );
                          },
                        ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onSignOut,
                child: const Text('Staff sign out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({
    required this.position,
    required this.row,
    required this.waited,
    required this.showLane,
  });

  final int position;
  final DisplayBoardRow row;
  final String waited;
  final bool showLane;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Text(
              '$position',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F766E),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.displayName,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  showLane
                      ? '${displayLaneTitle(row.lane)} · ${row.place}'
                      : row.place,
                  style: const TextStyle(fontSize: 16, color: Color(0xFF475569)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                row.ticket,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                waited,
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LanePicker extends StatelessWidget {
  const _LanePicker({
    required this.onSelect,
    required this.onSignOut,
    this.onCancel,
  });

  final ValueChanged<String> onSelect;
  final VoidCallback onSignOut;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF8FAFC),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Which waiting list?',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You can change this later.',
              style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: kDisplayLaneOptions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final option = kDisplayLaneOptions[index];
                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onSelect(option.$1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 18,
                        ),
                        child: Text(
                          option.$2,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                if (onCancel != null)
                  TextButton(onPressed: onCancel, child: const Text('Back')),
                TextButton(onPressed: onSignOut, child: const Text('Staff sign out')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DisplaySignOutDialog extends StatefulWidget {
  const _DisplaySignOutDialog();

  @override
  State<_DisplaySignOutDialog> createState() => _DisplaySignOutDialogState();
}

class _DisplaySignOutDialogState extends State<_DisplaySignOutDialog> {
  final _ctrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Staff sign out'),
      content: TextField(
        controller: _ctrl,
        obscureText: _obscure,
        autofocus: true,
        onSubmitted: (_) => Navigator.pop(context, _ctrl.text),
        decoration: InputDecoration(
          labelText: 'Display account password',
          suffixIcon: IconButton(
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _ctrl.text),
          child: const Text('Sign out'),
        ),
      ],
    );
  }
}
