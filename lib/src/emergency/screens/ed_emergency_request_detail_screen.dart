import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:helty/src/core/storage/token_storage.dart';
import 'package:helty/src/emergency/models/emergency_request_model.dart';
import 'package:helty/src/emergency/providers/emergency_request_providers.dart';
import 'package:helty/src/emergency/services/emergency_request_service.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/services/api_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

@RoutePage()
class EdEmergencyRequestDetailScreen extends ConsumerStatefulWidget {
  const EdEmergencyRequestDetailScreen({
    super.key,
    @PathParam('id') required this.id,
  });

  final String id;

  @override
  ConsumerState<EdEmergencyRequestDetailScreen> createState() =>
      _EdEmergencyRequestDetailScreenState();
}

class _EdEmergencyRequestDetailScreenState
    extends ConsumerState<EdEmergencyRequestDetailScreen> {
  final _noteController = TextEditingController();
  bool _updating = false;
  bool _noteSeeded = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _update(EmergencyRequestStatus next) async {
    setState(() => _updating = true);
    try {
      await ref.read(emergencyRequestServiceProvider).updateStatus(
            id: widget.id,
            status: next,
            staffNote: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          );
      ref.invalidate(emergencyRequestDetailProvider(widget.id));
      ref.invalidate(emergencyRequestInboxProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Marked as ${next.label}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(emergencyRequestDetailProvider(widget.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Emergency request')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (request) {
          if (!_noteSeeded && request.staffNote?.isNotEmpty == true) {
            _noteSeeded = true;
            _noteController.text = request.staffNote!;
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.patient?.displayName ?? 'Unknown patient',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Chip(label: Text(request.status.label)),
                ],
              ),
              if (request.patient?.patientId != null) ...[
                const Gap(4),
                Text('MRN / ID: ${request.patient!.patientId}'),
              ],
              if (request.patient?.phoneNumber != null) ...[
                const Gap(4),
                Text('Phone: ${request.patient!.phoneNumber}'),
              ],
              const Gap(16),
              Text(
                'Location',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Gap(4),
              Text(
                '${request.latitude.toStringAsFixed(5)}, '
                '${request.longitude.toStringAsFixed(5)}'
                '${request.accuracyMeters != null ? ' (±${request.accuracyMeters!.toStringAsFixed(0)} m)' : ''}',
              ),
              if (request.addressText?.isNotEmpty == true)
                Text(request.addressText!),
              TextButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(
                    'https://www.google.com/maps/search/?api=1&query='
                    '${request.latitude},${request.longitude}',
                  );
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.map_outlined),
                label: const Text('Open in maps'),
              ),
              const Gap(12),
              Text(
                'Submitted',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                request.createdAt == null
                    ? 'Unknown'
                    : DateFormatter.dateTime(request.createdAt!),
              ),
              if (request.description?.isNotEmpty == true) ...[
                const Gap(12),
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(request.description!),
              ],
              if (request.hasVoice) ...[
                const Gap(16),
                _StaffAudioPlayer(requestId: widget.id),
              ],
              if (request.hasVideo) ...[
                const Gap(16),
                _StaffVideoPlayer(requestId: widget.id),
              ],
              const Gap(20),
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Staff note (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const Gap(16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (request.status == EmergencyRequestStatus.submitted)
                    FilledButton(
                      onPressed: _updating
                          ? null
                          : () => _update(EmergencyRequestStatus.acknowledged),
                      child: const Text('Acknowledge'),
                    ),
                  if (request.status == EmergencyRequestStatus.acknowledged)
                    FilledButton.tonal(
                      onPressed: _updating
                          ? null
                          : () => _update(EmergencyRequestStatus.dispatched),
                      child: const Text('Dispatch ambulance'),
                    ),
                  if (request.status == EmergencyRequestStatus.dispatched)
                    FilledButton(
                      onPressed: _updating
                          ? null
                          : () => _update(EmergencyRequestStatus.closed),
                      child: const Text('Close'),
                    ),
                  if (request.status != EmergencyRequestStatus.closed &&
                      request.status != EmergencyRequestStatus.cancelled)
                    OutlinedButton(
                      onPressed: _updating
                          ? null
                          : () => _update(EmergencyRequestStatus.cancelled),
                      child: const Text('Cancel'),
                    ),
                ],
              ),
              if (request.respondedBy != null) ...[
                const Gap(16),
                Text('Last updated by ${request.respondedBy!.displayName}'),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _StaffAudioPlayer extends ConsumerStatefulWidget {
  const _StaffAudioPlayer({required this.requestId});

  final String requestId;

  @override
  ConsumerState<_StaffAudioPlayer> createState() => _StaffAudioPlayerState();
}

class _StaffAudioPlayerState extends ConsumerState<_StaffAudioPlayer> {
  final _player = AudioPlayer();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final path = ref
          .read(emergencyRequestServiceProvider)
          .mediaPath(widget.requestId, 'voice');
      final token = await TokenStorage.getAccessToken();
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse('${ApiService().apiBaseUrl}$path'),
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load voice note';
        });
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voice note',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Gap(8),
            if (_loading)
              const LinearProgressIndicator()
            else if (_error != null)
              Text(_error!)
            else
              StreamBuilder<PlayerState>(
                stream: _player.playerStateStream,
                builder: (context, snapshot) {
                  final playing = snapshot.data?.playing ?? false;
                  return IconButton.filledTonal(
                    onPressed: () {
                      if (playing) {
                        _player.pause();
                      } else {
                        _player.play();
                      }
                    },
                    icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _StaffVideoPlayer extends ConsumerStatefulWidget {
  const _StaffVideoPlayer({required this.requestId});

  final String requestId;

  @override
  ConsumerState<_StaffVideoPlayer> createState() => _StaffVideoPlayerState();
}

class _StaffVideoPlayerState extends ConsumerState<_StaffVideoPlayer> {
  VideoPlayerController? _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final path = ref
          .read(emergencyRequestServiceProvider)
          .mediaPath(widget.requestId, 'video');
      final token = await TokenStorage.getAccessToken();
      final controller = VideoPlayerController.networkUrl(
        Uri.parse('${ApiService().apiBaseUrl}$path'),
        httpHeaders: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load video';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Video',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Gap(8),
            if (_loading)
              const AspectRatio(
                aspectRatio: 16 / 9,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null || controller == null)
              Text(_error ?? 'Video unavailable')
            else ...[
              AspectRatio(
                aspectRatio: controller.value.aspectRatio == 0
                    ? 16 / 9
                    : controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    if (controller.value.isPlaying) {
                      controller.pause();
                    } else {
                      controller.play();
                    }
                  });
                },
                icon: Icon(
                  controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
