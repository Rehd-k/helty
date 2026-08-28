import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/system_announcements/models/system_announcement.dart';
import 'package:helty/src/system_announcements/services/system_announcement_service.dart';
import 'package:helty/src/system_announcements/utils/announcement_icon_map.dart';

@RoutePage()
class AnnouncementManagementScreen extends StatefulWidget {
  const AnnouncementManagementScreen({super.key});

  @override
  State<AnnouncementManagementScreen> createState() =>
      _AnnouncementManagementScreenState();
}

class _AnnouncementManagementScreenState
    extends State<AnnouncementManagementScreen> {
  final _service = SystemAnnouncementService();
  bool _loading = false;
  String? _error;
  List<SystemAnnouncement> _items = const [];

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
      final items = await _service.listAll(take: 100);
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

  Future<void> _openEditor([SystemAnnouncement? existing]) async {
    final result = await showDialog<SystemAnnouncementWritePayload>(
      context: context,
      builder: (ctx) => _AnnouncementEditorDialog(
        title: existing == null ? 'New announcement' : 'Edit announcement',
        initialTitle: existing?.title ?? '',
        initialDescription: existing?.description ?? '',
        initialIconKey: existing?.iconKey ?? 'info',
        initialActive: existing?.isActive ?? false,
        initialSortOrder: existing?.sortOrder ?? 0,
        initialExpiresAt: existing?.expiresAt,
      ),
    );
    if (result == null) return;
    try {
      if (existing == null) {
        await _service.create(result);
      } else {
        await _service.update(existing.id, result);
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  Future<void> _delete(SystemAnnouncement item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete announcement?'),
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
      await _service.delete(item.id);
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
        title: const Text('Announcements'),
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
        label: const Text('New announcement'),
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
            return const Center(child: Text('No announcements yet.'));
          }
          return ListView.separated(
            itemCount: _items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final item = _items[i];
              final icon = announcementIconForKey(item.iconKey);
              return ListTile(
                leading: Icon(icon),
                title: Text(item.title),
                subtitle: Text(
                  [
                    item.isActive ? 'Active' : 'Inactive',
                    'Order ${item.sortOrder}',
                    if (item.expiresAt != null)
                      'Expires ${DateFormatter.shortDate(item.expiresAt!)}',
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

class _AnnouncementEditorDialog extends StatefulWidget {
  const _AnnouncementEditorDialog({
    required this.title,
    required this.initialTitle,
    required this.initialDescription,
    required this.initialIconKey,
    required this.initialActive,
    required this.initialSortOrder,
    this.initialExpiresAt,
  });

  final String title;
  final String initialTitle;
  final String initialDescription;
  final String initialIconKey;
  final bool initialActive;
  final int initialSortOrder;
  final DateTime? initialExpiresAt;

  @override
  State<_AnnouncementEditorDialog> createState() =>
      _AnnouncementEditorDialogState();
}

class _AnnouncementEditorDialogState extends State<_AnnouncementEditorDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _sortOrderCtrl;
  late String _iconKey;
  late bool _active;
  DateTime? _expiresAt;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle);
    _descriptionCtrl = TextEditingController(text: widget.initialDescription);
    _sortOrderCtrl = TextEditingController(
      text: widget.initialSortOrder.toString(),
    );
    _iconKey = widget.initialIconKey;
    _active = widget.initialActive;
    _expiresAt = widget.initialExpiresAt;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _sortOrderCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickExpiresAt() async {
    final initial =
        _expiresAt ?? DateTime.now().add(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _expiresAt = picked);
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
                controller: _descriptionCtrl,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _iconKey,
                decoration: const InputDecoration(
                  labelText: 'Icon',
                  border: OutlineInputBorder(),
                ),
                items: announcementIconOptions
                    .map(
                      (o) => DropdownMenuItem(
                        value: o.key,
                        child: Row(
                          children: [
                            Icon(o.icon, size: 20),
                            const SizedBox(width: 8),
                            Text(o.label),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _iconKey = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _sortOrderCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Sort order',
                  border: OutlineInputBorder(),
                  helperText: 'Lower numbers appear first',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Expires at'),
                subtitle: Text(
                  _expiresAt == null
                      ? 'Not set'
                      : DateFormatter.shortDate(_expiresAt!),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_expiresAt != null)
                      IconButton(
                        tooltip: 'Clear',
                        onPressed: () => setState(() => _expiresAt = null),
                        icon: const Icon(Icons.clear),
                      ),
                    const Icon(Icons.event_outlined),
                  ],
                ),
                onTap: _pickExpiresAt,
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
            final description = _descriptionCtrl.text.trim();
            if (title.isEmpty || description.isEmpty) return;
            final sortOrder = int.tryParse(_sortOrderCtrl.text.trim()) ?? 0;
            Navigator.pop(
              context,
              SystemAnnouncementWritePayload(
                title: title,
                description: description,
                iconKey: _iconKey,
                isActive: _active,
                sortOrder: sortOrder,
                expiresAt: _expiresAt,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
