import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import '../helper/date.formatter.dart';
import '../helper/snack.bar.dart';
import '../models/consulting_room_model.dart';
import '../services/waiting_patient_service.dart';

@RoutePage()
class ConsultingRoomsScreen extends StatefulWidget {
  const ConsultingRoomsScreen({super.key});

  @override
  State<ConsultingRoomsScreen> createState() => _ConsultingRoomsScreenState();
}

class _ConsultingRoomsScreenState extends State<ConsultingRoomsScreen> {
  final _svc = WaitingPatientService();

  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();

  List<ConsultingRoomModel> _rooms = [];
  ConsultingRoomModel? _selected;
  bool _loading = false;
  bool _saving = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _descriptionCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    setState(() => _loading = true);
    try {
      final rooms = await _svc.fetchConsultingRooms();
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        if (_rooms.isNotEmpty && _selected == null) {
          _selected = _rooms.first;
        }
      });
    } catch (e) {
      if (!mounted) return;
      showSnackBar(
        context,
        message: 'Failed to load consulting rooms: $e',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startCreate() {
    setState(() {
      _selected = null;
      _nameCtrl.clear();
      _locationCtrl.clear();
      _descriptionCtrl.clear();
      _capacityCtrl.clear();
    });
  }

  void _startEdit(ConsultingRoomModel room) {
    setState(() {
      _selected = room;
      _nameCtrl.text = room.name;
      _locationCtrl.text = room.location ?? '';
      _descriptionCtrl.text = room.description ?? '';
      _capacityCtrl.text = room.capacity.toString();
    });
  }

  Future<void> _saveRoom() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      showSnackBar(
        context,
        message: 'Name is required',
        isError: true,
      );
      return;
    }

    final capacity =
        int.tryParse(_capacityCtrl.text.trim().isEmpty ? '0' : _capacityCtrl.text);

    setState(() => _saving = true);
    try {
      if (_selected == null) {
        // create
        final created = await _svc.createConsultingRoom(
          name: name,
          description: _descriptionCtrl.text.trim().isEmpty
              ? null
              : _descriptionCtrl.text.trim(),
          location: _locationCtrl.text.trim().isEmpty
              ? null
              : _locationCtrl.text.trim(),
          capacity: capacity ?? 0,
        );
        if (!mounted) return;
        setState(() {
          _rooms = [..._rooms, created];
          _selected = created;
        });
        showSnackBar(
          context,
          message: 'Consulting room created successfully',
          isError: false,
        );
      } else {
        // update
        final updated = await _svc.updateConsultingRoom(
          _selected!.id,
          name: name,
          description: _descriptionCtrl.text.trim(),
          location: _locationCtrl.text.trim(),
          capacity: capacity ?? _selected!.capacity,
        );
        if (!mounted) return;
        setState(() {
          _rooms = _rooms
              .map((r) => r.id == updated.id ? updated : r)
              .toList(growable: false);
          _selected = updated;
        });
        showSnackBar(
          context,
          message: 'Consulting room updated successfully',
          isError: false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      showSnackBar(
        context,
        message: 'Failed to save consulting room: $e',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteRoom(ConsultingRoomModel room) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete consulting room'),
        content: Text(
          'Are you sure you want to delete "${room.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _deleting = true);
    try {
      await _svc.deleteConsultingRoom(room.id);
      if (!mounted) return;
      setState(() {
        _rooms = _rooms.where((r) => r.id != room.id).toList(growable: false);
        if (_selected?.id == room.id) {
          _selected = _rooms.isNotEmpty ? _rooms.first : null;
        }
      });
      showSnackBar(
        context,
        message: 'Consulting room deleted',
        isError: false,
      );
    } catch (e) {
      if (!mounted) return;
      showSnackBar(
        context,
        message: 'Failed to delete consulting room: $e',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Consulting Rooms'),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _startCreate,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Room'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ResponsiveBody(
              builder: (context, bp) => ResponsiveRowColumn(
                firstFlex: 2,
                secondFlex: 3,
                gap: bp.isMobile ? 16 : 24,
                first: SizedBox(
                  height: bp.isMobile ? 320 : null,
                  child: _buildRoomsTable(context),
                ),
                second: _buildDetailsPane(context),
              ),
            ),
    );
  }

  Widget _buildRoomsTable(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.02),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'ROOM NAME',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'LOCATION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'CAPACITY',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: _rooms.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: cs.outline.withValues(alpha: 0.06),
              ),
              itemBuilder: (context, index) {
                final room = _rooms[index];
                final isSelected = _selected?.id == room.id;

                return _RoomRow(
                  room: room,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _selected = room;
                      _startEdit(room);
                    });
                  },
                  onContextMenu: (pos) async {
                    final selected = await showMenu<String>(
                      context: context,
                      position: RelativeRect.fromLTRB(
                        pos.dx,
                        pos.dy,
                        pos.dx,
                        pos.dy,
                      ),
                      items: const [
                        PopupMenuItem(
                          value: 'view',
                          child: Text('View details'),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    );

                    if (selected == null) return;
                    switch (selected) {
                      case 'view':
                        setState(() {
                          _selected = room;
                          _startEdit(room);
                        });
                        break;
                      case 'edit':
                        _startEdit(room);
                        break;
                      case 'delete':
                        await _deleteRoom(room);
                        break;
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsPane(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final room = _selected;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.meeting_room_outlined,
                  color: cs.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  room?.name ?? 'New consulting room',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (room != null) ...[
                    _InfoRow(
                      label: 'Location',
                      value: room.location ?? '—',
                    ),
                    const SizedBox(height: 6),
                    _InfoRow(
                      label: 'Capacity',
                      value: room.capacity.toString(),
                    ),
                    const SizedBox(height: 6),
                    _InfoRow(
                      label: 'Date added',
                      value: room.createdAt != null
                          ? DateFormatter.dateTime(room.createdAt!)
                          : '—',
                    ),
                    const SizedBox(height: 6),
                    _InfoRow(
                      label: 'Last updated',
                      value: room.updatedAt != null
                          ? DateFormatter.dateTime(room.updatedAt!)
                          : '—',
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Reviews & Usage',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No reviews yet. This section can later show doctor feedback, utilisation stats, etc.',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const Divider(height: 32),
                  ],
                  Text(
                    room == null ? 'Create new room' : 'Edit room details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Room name',
                      hintText: 'e.g. Cardiology – Room 201',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _locationCtrl,
                    decoration: InputDecoration(
                      labelText: 'Location (optional)',
                      hintText: 'e.g. Cardio Wing A',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _capacityCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Capacity',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText:
                          'Short notes about which physicians or services use this room.',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: cs.outline.withValues(alpha: 0.12),
                ),
              ),
            ),
            child: Row(
              children: [
                if (room != null) ...[
                  OutlinedButton.icon(
                    onPressed: _deleting ? null : () => _deleteRoom(room),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                const Spacer(),
                FilledButton.icon(
                  onPressed: _saving ? null : _saveRoom,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Saving...' : 'Save changes'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomRow extends StatelessWidget {
  const _RoomRow({
    required this.room,
    required this.isSelected,
    required this.onTap,
    required this.onContextMenu,
  });

  final ConsultingRoomModel room;
  final bool isSelected;
  final VoidCallback onTap;
  final void Function(Offset globalPosition) onContextMenu;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        onSecondaryTapDown: (details) {
          onContextMenu(details.globalPosition);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: isSelected
              ? cs.primary.withValues(alpha: 0.06)
              : Colors.transparent,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  room.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: cs.onSurface.withValues(alpha: 0.9),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  room.location ?? '—',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    room.capacity.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: cs.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

