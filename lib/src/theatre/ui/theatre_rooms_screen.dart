import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/auth/theatre_permissions.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/theatre/models/theatre_models.dart';
import 'package:helty/src/theatre/providers/theatre_providers.dart';

@RoutePage()
class TheatreRoomsScreen extends ConsumerStatefulWidget {
  const TheatreRoomsScreen({super.key});

  @override
  ConsumerState<TheatreRoomsScreen> createState() =>
      _TheatreRoomsScreenState();
}

class _TheatreRoomsScreenState extends ConsumerState<TheatreRoomsScreen> {
  List<TheatreRoom> _rooms = [];
  bool _loading = true;
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
      final rooms = await ref.read(theatreApiServiceProvider).getRooms();
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
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

  Future<void> _showRoomDialog({TheatreRoom? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    var isActive = existing?.isActive ?? true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add theatre room' : 'Edit room'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Room name *'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: isActive,
                onChanged: (v) => setDialogState(() => isActive = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;

    try {
      final api = ref.read(theatreApiServiceProvider);
      if (existing == null) {
        await api.createRoom(name: name, isActive: isActive);
      } else {
        await api.patchRoom(existing.id, name: name, isActive: isActive);
      }
      invalidateTheatreRooms(ref);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room saved')),
      );
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(authProvider).staff;
    final canManage = canManageTheatreRooms(staff);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theatre rooms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _showRoomDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add room'),
            )
          : null,
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) => _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _rooms.isEmpty
                    ? const Center(child: Text('No theatre rooms configured'))
                    : ListView.separated(
                        padding: EdgeInsets.zero,
              itemCount: _rooms.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final room = _rooms[index];
                return Card(
                  child: ListTile(
                    title: Text(room.name),
                    subtitle: Text(room.isActive ? 'Active' : 'Inactive'),
                    trailing: canManage
                        ? IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _showRoomDialog(existing: room),
                          )
                        : null,
                  ),
                );
              },
            ),
      ),
    );
  }
}
