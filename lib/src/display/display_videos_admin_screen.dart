import 'package:auto_route/auto_route.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'display_api.dart';

@RoutePage()
class DisplayVideosAdminScreen extends StatefulWidget {
  const DisplayVideosAdminScreen({super.key});

  @override
  State<DisplayVideosAdminScreen> createState() =>
      _DisplayVideosAdminScreenState();
}

class _DisplayVideosAdminScreenState extends State<DisplayVideosAdminScreen> {
  final _api = DisplayApi();
  List<DisplayVideoItem> _videos = const [];
  bool _loading = true;
  bool _uploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final videos = await _api.fetchManagedVideos();
      if (!mounted) return;
      setState(() {
        _videos = videos;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load videos.';
      });
    }
  }

  Future<void> _upload() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp4', 'webm', 'mov', 'avi'],
      withData: false,
    );
    final file = picked?.files.singleOrNull;
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      await _api.uploadVideo(file);
      if (!mounted) return;
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload failed. Use an MP4, WebM, MOV, or AVI.')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _toggle(DisplayVideoItem video, bool active) async {
    try {
      await _api.updateVideo(video.id, isActive: active);
      if (!mounted) return;
      setState(() {
        _videos = [
          for (final item in _videos)
            if (item.id == video.id)
              DisplayVideoItem(
                id: item.id,
                title: item.title,
                isActive: active,
                sortOrder: item.sortOrder,
              )
            else
              item,
        ];
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update that video.')),
      );
    }
  }

  Future<void> _move(int index, int delta) async {
    final next = index + delta;
    if (next < 0 || next >= _videos.length) return;
    final reordered = [..._videos];
    final item = reordered.removeAt(index);
    reordered.insert(next, item);
    setState(() => _videos = reordered);
    try {
      final saved = await _api.reorder(reordered.map((v) => v.id).toList());
      if (!mounted) return;
      setState(() => _videos = saved);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the new order.')),
      );
      await _load();
    }
  }

  Future<void> _delete(DisplayVideoItem video) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove video'),
        content: Text('Remove "${video.title}" from every waiting-room screen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.deleteVideo(video.id);
      if (!mounted) return;
      setState(() {
        _videos = _videos.where((v) => v.id != video.id).toList();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not remove that video.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Waiting-room videos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploading ? null : _upload,
        icon: _uploading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.upload_outlined),
        label: const Text('Upload video'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _videos.isEmpty
                  ? const Center(
                      child: Text(
                        'No videos yet. Upload one and every display screen will play it.',
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      itemCount: _videos.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final video = _videos[index];
                        return Card(
                          child: ListTile(
                            title: Text(video.title),
                            subtitle: Text(video.isActive ? 'Playing on screens' : 'Hidden'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Move up',
                                  onPressed: index == 0 ? null : () => _move(index, -1),
                                  icon: const Icon(Icons.arrow_upward),
                                ),
                                IconButton(
                                  tooltip: 'Move down',
                                  onPressed: index == _videos.length - 1
                                      ? null
                                      : () => _move(index, 1),
                                  icon: const Icon(Icons.arrow_downward),
                                ),
                                Switch(
                                  value: video.isActive,
                                  onChanged: (v) => _toggle(video, v),
                                ),
                                IconButton(
                                  tooltip: 'Remove',
                                  onPressed: () => _delete(video),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
