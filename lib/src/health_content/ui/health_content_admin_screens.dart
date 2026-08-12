import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/health_content/models/health_content_models.dart';
import 'package:helty/src/health_content/services/health_content_service.dart';
import 'package:helty/src/helper/date.formatter.dart';

@RoutePage()
class HealthCampaignsAdminScreen extends StatefulWidget {
  const HealthCampaignsAdminScreen({super.key});

  @override
  State<HealthCampaignsAdminScreen> createState() =>
      _HealthCampaignsAdminScreenState();
}

class _HealthCampaignsAdminScreenState extends State<HealthCampaignsAdminScreen> {
  final _service = HealthContentService();
  bool _loading = false;
  String? _error;
  List<HealthCampaign> _items = const [];

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
      final items = await _service.listCampaigns();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openEditor([HealthCampaign? existing]) async {
    final result = await showDialog<HealthContentWritePayload>(
      context: context,
      builder: (ctx) => _HealthContentEditorDialog(
        title: existing == null ? 'New campaign' : 'Edit campaign',
        initialTitle: existing?.title ?? '',
        initialBody: existing?.body ?? '',
        initialImageUrl: existing?.imageUrl ?? '',
        initialPublished: existing?.isPublished ?? false,
        initialPublishedAt: existing?.publishedAt,
        initialExpiresAt: existing?.expiresAt,
      ),
    );
    if (result == null) return;
    try {
      if (existing == null) {
        await _service.createCampaign(result);
      } else {
        await _service.updateCampaign(existing.id, result);
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  Future<void> _delete(HealthCampaign item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete campaign?'),
        content: Text(item.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.deleteCampaign(item.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Health campaigns'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('New campaign'),
      ),
      body: ResponsiveBody(
        builder: (context, bp) {
          if (_loading && _items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_error != null && _items.isEmpty) {
            return Center(child: Text(_error!));
          }
          if (_items.isEmpty) {
            return const Center(child: Text('No campaigns yet.'));
          }
          return ListView.separated(
            itemCount: _items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final item = _items[i];
              return ListTile(
                title: Text(item.title),
                subtitle: Text(
                  [
                    item.isPublished ? 'Published' : 'Draft',
                    if (item.publishedAt != null)
                      DateFormatter.shortDate(item.publishedAt!),
                  ].join(' · '),
                ),
                trailing: Wrap(
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: () => _openEditor(item),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: () => _delete(item),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
                onTap: () => _openEditor(item),
              );
            },
          );
        },
      ),
    );
  }
}

@RoutePage()
class HealthNewsAdminScreen extends StatefulWidget {
  const HealthNewsAdminScreen({super.key});

  @override
  State<HealthNewsAdminScreen> createState() => _HealthNewsAdminScreenState();
}

class _HealthNewsAdminScreenState extends State<HealthNewsAdminScreen> {
  final _service = HealthContentService();
  bool _loading = false;
  String? _error;
  List<HealthNewsArticle> _items = const [];

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
      final items = await _service.listNews();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openEditor([HealthNewsArticle? existing]) async {
    final result = await showDialog<HealthContentWritePayload>(
      context: context,
      builder: (ctx) => _HealthContentEditorDialog(
        title: existing == null ? 'New news article' : 'Edit news article',
        initialTitle: existing?.title ?? '',
        initialBody: existing?.body ?? '',
        initialImageUrl: existing?.imageUrl ?? '',
        initialPublished: existing?.isPublished ?? false,
        initialPublishedAt: existing?.publishedAt,
        initialExpiresAt: existing?.expiresAt,
      ),
    );
    if (result == null) return;
    try {
      if (existing == null) {
        await _service.createNews(result);
      } else {
        await _service.updateNews(existing.id, result);
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  Future<void> _delete(HealthNewsArticle item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete news article?'),
        content: Text(item.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.deleteNews(item.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Health news'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('New article'),
      ),
      body: ResponsiveBody(
        builder: (context, bp) {
          if (_loading && _items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_error != null && _items.isEmpty) {
            return Center(child: Text(_error!));
          }
          if (_items.isEmpty) {
            return const Center(child: Text('No news articles yet.'));
          }
          return ListView.separated(
            itemCount: _items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final item = _items[i];
              return ListTile(
                title: Text(item.title),
                subtitle: Text(
                  [
                    item.isPublished ? 'Published' : 'Draft',
                    if (item.publishedAt != null)
                      DateFormatter.shortDate(item.publishedAt!),
                  ].join(' · '),
                ),
                trailing: Wrap(
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: () => _openEditor(item),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: () => _delete(item),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
                onTap: () => _openEditor(item),
              );
            },
          );
        },
      ),
    );
  }
}

class _HealthContentEditorDialog extends StatefulWidget {
  const _HealthContentEditorDialog({
    required this.title,
    required this.initialTitle,
    required this.initialBody,
    required this.initialImageUrl,
    required this.initialPublished,
    this.initialPublishedAt,
    this.initialExpiresAt,
  });

  final String title;
  final String initialTitle;
  final String initialBody;
  final String initialImageUrl;
  final bool initialPublished;
  final DateTime? initialPublishedAt;
  final DateTime? initialExpiresAt;

  @override
  State<_HealthContentEditorDialog> createState() =>
      _HealthContentEditorDialogState();
}

class _HealthContentEditorDialogState extends State<_HealthContentEditorDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  late final TextEditingController _imageCtrl;
  late bool _published;
  DateTime? _publishedAt;
  DateTime? _expiresAt;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle);
    _bodyCtrl = TextEditingController(text: widget.initialBody);
    _imageCtrl = TextEditingController(text: widget.initialImageUrl);
    _published = widget.initialPublished;
    _publishedAt = widget.initialPublishedAt;
    _expiresAt = widget.initialExpiresAt;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool published}) async {
    final initial = published
        ? (_publishedAt ?? DateTime.now())
        : (_expiresAt ?? DateTime.now().add(const Duration(days: 30)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (published) {
        _publishedAt = picked;
      } else {
        _expiresAt = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bodyCtrl,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Body',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _imageCtrl,
                decoration: const InputDecoration(
                  labelText: 'Image URL (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Published'),
                value: _published,
                onChanged: (v) => setState(() => _published = v),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Published at'),
                subtitle: Text(
                  _publishedAt == null
                      ? 'Not set'
                      : DateFormatter.shortDate(_publishedAt!),
                ),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () => _pickDate(published: true),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Expires at'),
                subtitle: Text(
                  _expiresAt == null
                      ? 'Not set'
                      : DateFormatter.shortDate(_expiresAt!),
                ),
                trailing: const Icon(Icons.event_busy_outlined),
                onTap: () => _pickDate(published: false),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final title = _titleCtrl.text.trim();
            final body = _bodyCtrl.text.trim();
            if (title.isEmpty || body.isEmpty) return;
            Navigator.pop(
              context,
              HealthContentWritePayload(
                title: title,
                body: body,
                imageUrl: _imageCtrl.text.trim().isEmpty
                    ? null
                    : _imageCtrl.text.trim(),
                publishedAt: _publishedAt,
                expiresAt: _expiresAt,
                isPublished: _published,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
