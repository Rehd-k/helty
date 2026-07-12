import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/models/staff_model.dart';
import 'package:helty/src/providers/staff_providers.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/theatre/models/theatre_models.dart';
import 'package:helty/src/theatre/providers/theatre_providers.dart';

@RoutePage()
class TheatreScheduleFormScreen extends ConsumerStatefulWidget {
  const TheatreScheduleFormScreen({
    super.key,
    required this.surgeryRequestId,
    this.scheduleId,
  });

  final String surgeryRequestId;
  final String? scheduleId;

  @override
  ConsumerState<TheatreScheduleFormScreen> createState() =>
      _TheatreScheduleFormScreenState();
}

class _TheatreScheduleFormScreenState
    extends ConsumerState<TheatreScheduleFormScreen> {
  SurgeryRequest? _request;
  List<TheatreRoom> _rooms = [];
  List<Staff> _doctors = [];
  List<Staff> _nurses = [];
  TheatreRoom? _selectedRoom;
  Staff? _selectedSurgeon;
  Staff? _selectedScrubNurse;
  DateTime? _scheduledAt;
  final _durationCtrl = TextEditingController(text: '120');
  final _anaesthetistIdCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool get _isEdit =>
      widget.scheduleId != null && widget.scheduleId!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _durationCtrl.dispose();
    _anaesthetistIdCtrl.dispose();
    super.dispose();
  }

  Staff? _resolveStaff(String? id, List<Staff> options) {
    if (id == null || id.isEmpty) return null;
    for (final s in options) {
      if (s.id == id || s.staffId == id) return s;
    }
    final placeholder = Staff(
      id: id,
      staffId: id,
      firstName: id,
      lastName: '',
      staffRole: '',
    );
    options.add(placeholder);
    return placeholder;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(theatreApiServiceProvider);
      final staffService = ref.read(staffServiceProvider);
      final results = await Future.wait([
        api.getSurgeryRequestById(widget.surgeryRequestId),
        api.getRooms(),
        staffService.fetchStaff(limit: 250, isActive: true),
      ]);
      if (!mounted) return;

      final request = results[0] as SurgeryRequest;
      final rooms = results[1] as List<TheatreRoom>;
      final staffList = results[2] as List<Staff>;
      final doctors =
          staffList
              .where(
                (s) =>
                    s.accountType == AccountType.physician &&
                    s.isActive != false,
              )
              .toList()
            ..sort((a, b) => a.fullName.compareTo(b.fullName));
      final nurses =
          staffList
              .where(
                (s) =>
                    s.accountType == AccountType.nurse && s.isActive != false,
              )
              .toList()
            ..sort((a, b) => a.fullName.compareTo(b.fullName));

      final schedule = request.schedule;
      setState(() {
        _request = request;
        _rooms = rooms.where((r) => r.isActive).toList();
        _doctors = doctors;
        _nurses = nurses;
        _loading = false;
      });

      if (schedule != null) {
        TheatreRoom? room;
        for (final r in _rooms) {
          if (r.id == schedule.theatreRoomId) {
            room = r;
            break;
          }
        }
        room ??= TheatreRoom(
          id: schedule.theatreRoomId,
          name: schedule.theatreRoom?.name ?? schedule.theatreRoomId,
        );
        if (!_rooms.any((r) => r.id == room!.id)) {
          _rooms = [..._rooms, room];
        }
        _selectedRoom = room;
        _scheduledAt = schedule.scheduledAt;
        if (schedule.estimatedDurationMins != null) {
          _durationCtrl.text = schedule.estimatedDurationMins.toString();
        }
        _anaesthetistIdCtrl.text = schedule.anaesthetistId ?? '';
        setState(() {
          _selectedSurgeon = _resolveStaff(schedule.surgeonId, _doctors);
          _selectedScrubNurse = _resolveStaff(schedule.scrubNurseId, _nurses);
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _pickDateTime() async {
    final base = _scheduledAt ?? DateTime.now().add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (time == null || !mounted) return;
    setState(() {
      _scheduledAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (_selectedRoom == null) {
      setState(() => _error = 'Select a theatre room.');
      return;
    }
    if (_scheduledAt == null) {
      setState(() => _error = 'Select date and time.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final duration = int.tryParse(_durationCtrl.text.trim());
    final surgeonId = _selectedSurgeon?.id;
    final anaesthetistId = _anaesthetistIdCtrl.text.trim();
    final scrubNurseId = _selectedScrubNurse?.id;

    try {
      final api = ref.read(theatreApiServiceProvider);
      if (_isEdit && widget.scheduleId != null) {
        await api.patchSchedule(
          widget.scheduleId!,
          theatreRoomId: _selectedRoom!.id,
          scheduledAt: _scheduledAt,
          estimatedDurationMins: duration,
          surgeonId: surgeonId,
          anaesthetistId: anaesthetistId.isEmpty ? null : anaesthetistId,
          scrubNurseId: scrubNurseId,
        );
      } else {
        await api.createSchedule(
          surgeryRequestId: widget.surgeryRequestId,
          theatreRoomId: _selectedRoom!.id,
          scheduledAt: _scheduledAt!,
          estimatedDurationMins: duration,
          surgeonId: surgeonId,
          anaesthetistId: anaesthetistId.isEmpty ? null : anaesthetistId,
          scrubNurseId: scrubNurseId,
        );
      }

      invalidateSurgeryRequests(ref);
      invalidateTheatreSchedules(ref);
      if (!mounted) return;
      context.router.replace(
        TheatreCaseDetailRoute(surgeryRequestId: widget.surgeryRequestId),
      );
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? 'Reschedule' : 'Schedule surgery'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final request = _request;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Reschedule surgery' : 'Schedule surgery'),
      ),
      body: ResponsiveBody(
        maxWidth: 560,
        expand: false,
        builder: (context, bp) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (request != null) ...[
                Text(
                  request.service?.name ?? 'Surgery',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(request.patient?.displayName ?? request.patientId),
                const SizedBox(height: 24),
              ],
              if (_error != null) ...[
                Text(
                  _error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              DropdownButtonFormField<TheatreRoom>(
                decoration: const InputDecoration(labelText: 'Theatre room *'),
                initialValue: _selectedRoom,
                items: _rooms
                    .map((r) => DropdownMenuItem(value: r, child: Text(r.name)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedRoom = v),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickDateTime,
                icon: const Icon(Icons.event_outlined),
                label: Text(
                  _scheduledAt == null
                      ? 'Scheduled date & time *'
                      : _scheduledAt!.toLocal().toString(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _durationCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Estimated duration (minutes)',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Staff?>(
                decoration: const InputDecoration(labelText: 'Surgeon'),
                initialValue: _selectedSurgeon,
                items: [
                  const DropdownMenuItem<Staff?>(
                    value: null,
                    child: Text('— None —'),
                  ),
                  ..._doctors.map(
                    (s) => DropdownMenuItem(value: s, child: Text(s.fullName)),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedSurgeon = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _anaesthetistIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Anaesthetist staff ID',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Staff?>(
                decoration: const InputDecoration(labelText: 'Scrub nurse'),
                initialValue: _selectedScrubNurse,
                items: [
                  const DropdownMenuItem<Staff?>(
                    value: null,
                    child: Text('— None —'),
                  ),
                  ..._nurses.map(
                    (s) => DropdownMenuItem(value: s, child: Text(s.fullName)),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedScrubNurse = v),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEdit ? 'Update schedule' : 'Create schedule'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
