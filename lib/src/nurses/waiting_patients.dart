import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import '../helper/date.formatter.dart';
import '../models/consulting_room_model.dart';
import '../widgets/date.filter.dart';
import '../models/patient_vitals_model.dart';
import '../models/waiting_patient_model.dart';
import '../services/waiting_patient_service.dart';

@RoutePage()
class WaitingPatientsScreen extends StatefulWidget {
  const WaitingPatientsScreen({super.key});

  @override
  State<WaitingPatientsScreen> createState() => _WaitingPatientsScreenState();
}

class _WaitingPatientsScreenState extends State<WaitingPatientsScreen> {
  /// Vitals use the right-hand panel at this width; below, a bottom sheet.
  static const double _vitalsSidePanelMinWidth = 960;

  final _waitingService = WaitingPatientService();
  DateTime? _fromDate;
  DateTime? _toDate;
  Function? doRefresh;

  // Server-backed waiting patients (current page)
  List<WaitingPatientModel> _visiblePatients = [];
  int _total = 0;

  // Consulting rooms from API
  List<ConsultingRoomModel> _consultingRooms = [];

  WaitingPatientModel? _selectedPatient;
  ConsultingRoomModel? _selectedRoom;

  final _searchCtrl = TextEditingController();
  String _statusFilter = 'Unassigned'; // Unassigned, Assigned, All
  ConsultingRoomModel? _filterRoom;

  final int _rowsPerPage = 20;
  int _currentPage = 0;
  bool _sending = false;
  bool _loading = true; // cleared when FromToDateFilter triggers first load

  // --- FORM CONTROLLERS ---
  final _sysCtrl = TextEditingController();
  final _diaCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _bmiCtrl = TextEditingController();
  final _pulseCtrl = TextEditingController();
  final _spo2Ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _heightCtrl.addListener(_calculateBMI);
    _weightCtrl.addListener(_calculateBMI);
    _loadConsultingRooms();
    // First load is triggered by FromToDateFilter's onFilterChanged (postFrameCallback)
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _sysCtrl.dispose();
    _diaCtrl.dispose();
    _tempCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _bmiCtrl.dispose();
    _pulseCtrl.dispose();
    _spo2Ctrl.dispose();
    super.dispose();
  }

  void _calculateBMI() {
    final heightCm = double.tryParse(_heightCtrl.text);
    final weightKg = double.tryParse(_weightCtrl.text);

    if (heightCm != null && weightKg != null && heightCm > 0) {
      final heightM = heightCm / 100;
      final bmi = weightKg / pow(heightM, 2);
      _bmiCtrl.text = bmi.toStringAsFixed(1);
    } else {
      _bmiCtrl.text = '';
    }
  }

  int get _totalPages => _total == 0 ? 1 : (_total / _rowsPerPage).ceil();

  Future<void> _loadPage({bool reset = false}) async {
    if (reset) {
      _currentPage = 0;
    }

    final skip = _currentPage * _rowsPerPage;
    final queryText = _searchCtrl.text.trim();

    setState(() {
      _loading = true;
    });

    try {
      final resp = await _waitingService.fetchWaitingPatients(
        WaitingPatientQuery(
          q: queryText.isEmpty ? null : queryText,
          consultingRoomId: _filterRoom?.id,
          unassignedOnly: _statusFilter == 'Unassigned' ? true : null,
          fromDate: _fromDate,
          toDate: _toDate,
          skip: skip,
          take: _rowsPerPage,
        ),
      );

      // For "Assigned" filter, restrict to rows that have a consulting room.
      List<WaitingPatientModel> rows = resp.data;
      if (_statusFilter == 'Assigned') {
        rows = rows.where((p) => p.consultingRoomId != 'Waiting').toList();
      }

      setState(() {
        _visiblePatients = rows;
        _total = resp.total;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load waiting patients: $e')),
      );
    }
  }

  Future<void> _loadConsultingRooms() async {
    try {
      final rooms = await _waitingService.fetchConsultingRooms();
      if (!mounted) return;
      final unique = <String, ConsultingRoomModel>{};
      for (final r in rooms) {
        if (r.id.isNotEmpty) unique[r.id] = r;
      }
      setState(() {
        _consultingRooms = unique.values.toList();
        _selectedRoom = _roomFromList(_selectedRoom);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load consulting rooms: $e')),
      );
    }
  }

  bool _isUnassigned(WaitingPatientModel waiting) =>
      waiting.status == 'Waiting';

  /// Dropdown items must use the same instances as [value]/[initialValue].
  ConsultingRoomModel? _roomFromList(ConsultingRoomModel? room) {
    if (room == null || room.id.isEmpty) return null;
    for (final r in _consultingRooms) {
      if (r.id == room.id) return r;
    }
    return null;
  }

  ConsultingRoomModel? _roomFromListById(String? roomId) {
    if (roomId == null || roomId.isEmpty) return null;
    for (final r in _consultingRooms) {
      if (r.id == roomId) return r;
    }
    return null;
  }

  void _selectWaitingPatient(WaitingPatientModel waiting) {
    final room =
        _roomFromList(waiting.consultingRoom) ??
        _roomFromListById(waiting.consultingRoomId);
    setState(() {
      _selectedPatient = waiting;
      _selectedRoom = room;
    });
    _applyVitalsFrom(waiting.patientVitals);
    if (MediaQuery.sizeOf(context).width < _vitalsSidePanelMinWidth) {
      _openVitalsBottomSheet(waiting);
    }
  }

  void _clearVitalsControllers() {
    _sysCtrl.clear();
    _diaCtrl.clear();
    _tempCtrl.clear();
    _heightCtrl.clear();
    _weightCtrl.clear();
    _bmiCtrl.clear();
    _pulseCtrl.clear();
    _spo2Ctrl.clear();
  }

  void _applyVitalsFrom(PatientVitalsModel? vitals) {
    _clearVitalsControllers();
    if (vitals == null) return;
    void setInt(TextEditingController c, int? v) {
      if (v != null) c.text = v.toString();
    }

    void setDouble(TextEditingController c, double? v) {
      if (v != null) c.text = v.toString();
    }

    setInt(_sysCtrl, vitals.systolic);
    setInt(_diaCtrl, vitals.diastolic);
    setDouble(_tempCtrl, vitals.temperature);
    setDouble(_heightCtrl, vitals.height);
    setDouble(_weightCtrl, vitals.weight);
    setDouble(_bmiCtrl, vitals.bmi);
    setInt(_pulseCtrl, vitals.pulseRate);
    setDouble(_spo2Ctrl, vitals.spo2);
  }

  Future<void> _saveVitalsFor(WaitingPatientModel waiting) async {
    int? parseInt(String value) {
      final v = value.trim();
      if (v.isEmpty) return null;
      return int.tryParse(v);
    }

    double? parseDouble(String value) {
      final v = value.trim();
      if (v.isEmpty) return null;
      return double.tryParse(v);
    }

    final existing = waiting.patientVitals;
    if (existing != null && existing.id.isNotEmpty) {
      await _waitingService.updatePatientVitals(
        existing.id,
        UpdatePatientVitalsDto(
          systolic: parseInt(_sysCtrl.text),
          diastolic: parseInt(_diaCtrl.text),
          temperature: parseDouble(_tempCtrl.text),
          height: parseDouble(_heightCtrl.text),
          weight: parseDouble(_weightCtrl.text),
          bmi: parseDouble(_bmiCtrl.text),
          pulseRate: parseInt(_pulseCtrl.text),
          spo2: parseDouble(_spo2Ctrl.text),
        ),
      );
    } else {
      await _waitingService.createPatientVitals(
        CreatePatientVitalsDto(
          invoiceId: waiting.invoiceId,
          patientId: waiting.patientId,
          systolic: parseInt(_sysCtrl.text),
          diastolic: parseInt(_diaCtrl.text),
          temperature: parseDouble(_tempCtrl.text),
          height: parseDouble(_heightCtrl.text),
          weight: parseDouble(_weightCtrl.text),
          bmi: parseDouble(_bmiCtrl.text),
          pulseRate: parseInt(_pulseCtrl.text),
          spo2: parseDouble(_spo2Ctrl.text),
        ),
      );
    }
  }

  void _openVitalsBottomSheet(WaitingPatientModel waiting) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final viewInsets = MediaQuery.viewInsetsOf(sheetContext);
            final maxH = MediaQuery.sizeOf(sheetContext).height * 0.92;
            return Padding(
              padding: EdgeInsets.only(bottom: viewInsets.bottom),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxH),
                child: _buildVitalsPaneForPatient(
                  sheetContext,
                  setModalState,
                  waiting,
                  isSidePanel: false,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _waitingQueueSearchField(ColorScheme colorScheme) {
    return TextField(
      controller: _searchCtrl,
      decoration: InputDecoration(
        hintText: "Search name, ID, consultation...",
        prefixIcon: Icon(
          Icons.search,
          size: 18,
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary),
        ),
      ),
      style: const TextStyle(fontSize: 13),
      onChanged: (_) => _loadPage(reset: true),
    );
  }

  Widget _waitingCountChip(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, color: colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            "$_total Waiting",
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendToConsulting(
    WaitingPatientModel waiting, {
    BuildContext? popAfterSuccessContext,
    StateSetter? refreshModal,
  }) async {
    if (_selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a consulting room.'),
        ),
      );
      return;
    }

    final invoiceId = waiting.invoiceId;
    final assigned = !_isUnassigned(waiting);

    setState(() => _sending = true);
    refreshModal?.call(() {});
    try {
      await _saveVitalsFor(waiting);
      if (assigned) {
        await _waitingService.updateWaitingPatientAssignment(
          invoiceId: invoiceId,
          consultingRoomId: _selectedRoom!.id,
        );
      } else {
        await _waitingService.updateWaitingPatient(invoiceId, {
          'consultingRoomId': _selectedRoom!.id,
        });
      }

      if (!mounted) return;

      if (popAfterSuccessContext != null && popAfterSuccessContext.mounted) {
        Navigator.of(popAfterSuccessContext).pop();
      }

      setState(() {
        _selectedPatient = null;
        _selectedRoom = null;
        _clearVitalsControllers();
        _currentPage = 0;
      });
      await _loadPage(reset: true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            assigned
                ? 'Room and vitals updated.'
                : 'Patient vitals saved and sent to consulting room.',
            style: const TextStyle(color: Colors.green),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            assigned
                ? 'Failed to update room and vitals: $e'
                : 'Failed to send to consulting room: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        refreshModal?.call(() {});
      }
    }
  }

  String _sendButtonLabel(WaitingPatientModel waiting) {
    if (_sending) return 'Saving…';
    return _isUnassigned(waiting)
        ? 'Send to consulting room'
        : 'Update room & vitals';
  }

  Widget _buildQueuePanel(ColorScheme colorScheme, bool tableHScroll) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filters row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: LayoutBuilder(
              builder: (context, fc) {
                final wideFilters = fc.maxWidth >= 680;
                final statusFilter = DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: DropdownButton<String>(
                      value: _statusFilter,
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface,
                      ),
                      items: <String>['Unassigned', 'Assigned', 'All']
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() {
                          _statusFilter = val;
                          _currentPage = 0;
                        });
                        _loadPage(reset: true);
                      },
                    ),
                  ),
                );
                final roomFilter = DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: DropdownButton<ConsultingRoomModel?>(
                      value: _filterRoom,
                      hint: const Text('All rooms'),
                      icon: Icon(
                        Icons.meeting_room_outlined,
                        size: 18,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface,
                      ),
                      items: [
                        const DropdownMenuItem<ConsultingRoomModel?>(
                          value: null,
                          child: Text('All rooms'),
                        ),
                        ..._consultingRooms.map(
                          (room) => DropdownMenuItem<ConsultingRoomModel?>(
                            value: room,
                            child: Text(room.name),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _filterRoom = val;
                          _currentPage = 0;
                        });
                        _loadPage(reset: true);
                      },
                    ),
                  ),
                );
                if (wideFilters) {
                  return Row(
                    children: [
                      Expanded(child: _waitingQueueSearchField(colorScheme)),
                      const SizedBox(width: 12),
                      statusFilter,
                      const SizedBox(width: 12),
                      roomFilter,
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _waitingQueueSearchField(colorScheme),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: statusFilter),
                        const SizedBox(width: 10),
                        Expanded(child: roomFilter),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),

          FromToDateFilter(
            doRefresh: () => _loadPage(reset: true),
            dateFilter: true,
            onFilterChanged:
                (String query, String category, DateTime? from, DateTime? to) {
                  setState(() {
                    _fromDate = from;
                    _toDate = to;
                    _currentPage = 0;
                  });
                  _loadPage(reset: true);
                },
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, innerConstraints) {
                const tableMinWidth = 680.0;
                final innerTable = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withValues(alpha: 0.02),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Text(
                              "PATIENT NAME",
                              style: _headerStyle(colorScheme),
                            ),
                          ),

                          Expanded(
                            flex: 3,
                            child: Text(
                              "CONSULTATION",
                              style: _headerStyle(colorScheme),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "PAYMENT TIME",
                              style: _headerStyle(colorScheme),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "STATUS / ROOM",
                              style: _headerStyle(colorScheme),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: colorScheme.outline.withValues(alpha: 0.1),
                    ),

                    // Patient List
                    Expanded(
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.separated(
                              itemCount: _visiblePatients.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: colorScheme.outline.withValues(
                                  alpha: 0.05,
                                ),
                              ),
                              itemBuilder: (context, index) {
                                final waiting = _visiblePatients[index];
                                final patient = waiting.patient;
                                final isUnassigned =
                                    waiting.status == 'Waiting';
                                final isSelected =
                                    _selectedPatient?.id == waiting.id;

                                final displayName = patient != null
                                    ? '${patient.firstName} ${patient.surname}'
                                    : 'Unknown';

                                final consultation =
                                    waiting.consultationName ?? '\u2014';
                                final createdTime = DateFormatter.dateTime(
                                  waiting.createdAt.toLocal(),
                                );
                                final roomLabel = waiting.status;

                                return InkWell(
                                  onTap: () => _selectWaitingPatient(waiting),
                                  child: Container(
                                    color: isSelected
                                        ? colorScheme.primary.withValues(
                                            alpha: 0.05,
                                          )
                                        : Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 5,
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 16,
                                                backgroundColor: isUnassigned
                                                    ? colorScheme.primary
                                                          .withValues(
                                                            alpha: 0.1,
                                                          )
                                                    : Colors.grey.withValues(
                                                        alpha: 0.1,
                                                      ),
                                                child: Text(
                                                  displayName.trim().substring(
                                                    0,
                                                    1,
                                                  ),
                                                  style: TextStyle(
                                                    color: isUnassigned
                                                        ? colorScheme.primary
                                                        : Colors.grey,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                displayName,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: isUnassigned
                                                      ? colorScheme.onSurface
                                                      : colorScheme.onSurface
                                                            .withValues(
                                                              alpha: 0.5,
                                                            ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            consultation,
                                            style: TextStyle(
                                              color: colorScheme.onSurface
                                                  .withValues(alpha: 0.7),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            createdTime,
                                            style: TextStyle(
                                              color: colorScheme.onSurface
                                                  .withValues(alpha: 0.6),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isUnassigned
                                                    ? Colors.orange.withValues(
                                                        alpha: 0.1,
                                                      )
                                                    : Colors.green.withValues(
                                                        alpha: 0.1,
                                                      ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                roomLabel,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: isUnassigned
                                                      ? Colors.orange[800]
                                                      : Colors.green[700],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    // Pagination footer
                    Divider(
                      height: 1,
                      color: colorScheme.outline.withValues(alpha: 0.1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Showing ${_visiblePatients.length} of $_total results",
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                visualDensity: VisualDensity.compact,
                                onPressed: _currentPage > 0
                                    ? () {
                                        setState(() {
                                          _currentPage--;
                                        });
                                        _loadPage();
                                      }
                                    : null,
                              ),
                              Text(
                                "${_currentPage + 1} / $_totalPages",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                visualDensity: VisualDensity.compact,
                                onPressed: (_currentPage + 1) < _totalPages
                                    ? () {
                                        setState(() {
                                          _currentPage++;
                                        });
                                        _loadPage();
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
                if (!tableHScroll) {
                  return innerTable;
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableMinWidth,
                    height: innerConstraints.maxHeight,
                    child: innerTable,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton:
          MediaQuery.sizeOf(context).width < _vitalsSidePanelMinWidth &&
              _selectedPatient != null
          ? FloatingActionButton.extended(
              onPressed: () => _openVitalsBottomSheet(_selectedPatient!),
              icon: const Icon(Icons.monitor_heart_outlined),
              label: Text(
                _isUnassigned(_selectedPatient!)
                    ? 'Vitals'
                    : 'Update vitals / room',
              ),
            )
          : null,
      body: LayoutBuilder(
        builder: (context, screen) {
          final pad = screen.maxWidth < 600 ? 12.0 : 24.0;
          final headerNarrow = screen.maxWidth < 560;
          final useSideBySideVitals =
              screen.maxWidth >= _vitalsSidePanelMinWidth;
          final bodyContentWidth = screen.maxWidth - pad * 2;
          final queuePanelWidth = useSideBySideVitals
              ? (bodyContentWidth - 24) * 2 / 3
              : bodyContentWidth;
          final tableHScroll = queuePanelWidth < 700;
          return Padding(
            padding: EdgeInsets.all(pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- HEADER ---
                if (headerNarrow)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Triage & Vitals",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        useSideBySideVitals
                            ? "Select a waiting patient to record vitals and assign a room."
                            : "Tap an unassigned patient to record vitals and assign a room.",
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _waitingCountChip(colorScheme),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Triage & Vitals",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              useSideBySideVitals
                                  ? "Select a waiting patient to record vitals and assign a room."
                                  : "Tap an unassigned patient to record vitals and assign a room.",
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _waitingCountChip(colorScheme),
                    ],
                  ),
                const SizedBox(height: 16),
                // --- MAIN CONTENT ---
                Expanded(
                  child: useSideBySideVitals
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildQueuePanel(
                                colorScheme,
                                tableHScroll,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 1,
                              child: _buildVitalsSidePane(colorScheme),
                            ),
                          ],
                        )
                      : _buildQueuePanel(colorScheme, tableHScroll),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _wrapVitalsRoot(
    bool isSidePanel,
    ColorScheme colorScheme,
    Widget child,
  ) {
    if (isSidePanel) {
      return Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      );
    }
    return Material(color: colorScheme.surface, child: child);
  }

  Widget _buildVitalsSidePane(ColorScheme colorScheme) {
    if (_selectedPatient == null) {
      return Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.monitor_heart_outlined,
                size: 64,
                color: colorScheme.onSurface.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 16),
              Text(
                "Select a waiting patient\nto record vitals.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return _buildVitalsPaneForPatient(
      context,
      (_) {},
      _selectedPatient!,
      isSidePanel: true,
    );
  }

  Widget _buildVitalsPaneForPatient(
    BuildContext sheetContext,
    StateSetter setModalState,
    WaitingPatientModel waiting, {
    required bool isSidePanel,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final patient = waiting.patient;
    final displayName = patient != null
        ? '${patient.title} ${patient.firstName} ${patient.surname}'
        : 'Unknown';
    final patientCode = patient?.patientId ?? waiting.patientId;
    final gender = patient?.gender ?? '—';
    final ageYears = patient != null
        ? DateTime.now().year - patient.dob.year
        : null;

    final formWidth = MediaQuery.sizeOf(sheetContext).width;
    final stackThree = isSidePanel || formWidth < 520;

    return _wrapVitalsRoot(
      isSidePanel,
      colorScheme,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isSidePanel)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: Text(
                'Record vitals & assign room',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          if (!isSidePanel)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.05),
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.12),
                  ),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                    child: Text(
                      displayName.trim().isEmpty
                          ? '?'
                          : displayName.trim().substring(0, 1),
                      style: TextStyle(
                        fontSize: 18,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ageYears != null
                              ? '$patientCode • $ageYears yrs • $gender'
                              : '$patientCode • $gender',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (isSidePanel)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                    child: Text(
                      displayName.trim().isEmpty
                          ? '?'
                          : displayName.trim().substring(0, 1),
                      style: TextStyle(
                        fontSize: 20,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ageYears != null
                              ? '$patientCode • $ageYears yrs • $gender'
                              : '$patientCode • $gender',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                isSidePanel ? 20 : 16,
                20,
                isSidePanel ? 20 : 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Blood Pressure",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildVitalInput(
                          "Systolic",
                          "mmHg",
                          _sysCtrl,
                          colorScheme,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildVitalInput(
                          "Diastolic",
                          "mmHg",
                          _diaCtrl,
                          colorScheme,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Physical Measurements",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (stackThree) ...[
                    _buildVitalInput(
                      "Height (Taille)",
                      "cm",
                      _heightCtrl,
                      colorScheme,
                    ),
                    const SizedBox(height: 10),
                    _buildVitalInput(
                      "Weight (Poids)",
                      "kg",
                      _weightCtrl,
                      colorScheme,
                    ),
                    const SizedBox(height: 10),
                    _buildVitalInput(
                      "BMI",
                      "",
                      _bmiCtrl,
                      colorScheme,
                      readOnly: true,
                    ),
                  ] else
                    Row(
                      children: [
                        Expanded(
                          child: _buildVitalInput(
                            "Height (Taille)",
                            "cm",
                            _heightCtrl,
                            colorScheme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildVitalInput(
                            "Weight (Poids)",
                            "kg",
                            _weightCtrl,
                            colorScheme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildVitalInput(
                            "BMI",
                            "",
                            _bmiCtrl,
                            colorScheme,
                            readOnly: true,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  Text(
                    "Other Vitals",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (stackThree) ...[
                    _buildVitalInput(
                      "Temperature",
                      "°C",
                      _tempCtrl,
                      colorScheme,
                    ),
                    const SizedBox(height: 10),
                    _buildVitalInput(
                      "Pulse Rate",
                      "bpm",
                      _pulseCtrl,
                      colorScheme,
                    ),
                    const SizedBox(height: 10),
                    _buildVitalInput("SpO2", "%", _spo2Ctrl, colorScheme),
                  ] else
                    Row(
                      children: [
                        Expanded(
                          child: _buildVitalInput(
                            "Temperature",
                            "°C",
                            _tempCtrl,
                            colorScheme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildVitalInput(
                            "Pulse Rate",
                            "bpm",
                            _pulseCtrl,
                            colorScheme,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildVitalInput(
                            "SpO2",
                            "%",
                            _spo2Ctrl,
                            colorScheme,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  Text(
                    "Assign Consulting Room",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ConsultingRoomModel>(
                    key: ValueKey(
                      'room-${waiting.invoiceId}-${_selectedRoom?.id ?? 'none'}',
                    ),
                    initialValue: _roomFromList(_selectedRoom),
                    decoration: InputDecoration(
                      hintText: "Select Room",
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      filled: true,
                      fillColor: colorScheme.onSurface.withValues(alpha: 0.02),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: colorScheme.primary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface,
                    ),
                    items: _consultingRooms
                        .map(
                          (room) => DropdownMenuItem<ConsultingRoomModel>(
                            value: room,
                            child: Text(room.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() => _selectedRoom = val);
                      if (!isSidePanel) {
                        setModalState(() {});
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          if (isSidePanel)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: ElevatedButton.icon(
                onPressed: _sending
                    ? null
                    : () async {
                        await _sendToConsulting(waiting);
                      },
                icon: const Icon(
                  Icons.send_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                label: Text(
                  _sendButtonLabel(waiting),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (!isSidePanel)
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: ElevatedButton.icon(
                  onPressed: _sending
                      ? null
                      : () async {
                          await _sendToConsulting(
                            waiting,
                            popAfterSuccessContext: sheetContext,
                            refreshModal: setModalState,
                          );
                        },
                  icon: const Icon(
                    Icons.send_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: Text(
                    _sendButtonLabel(waiting),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVitalInput(
    String label,
    String suffix,
    TextEditingController controller,
    ColorScheme colorScheme, {
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        suffixText: suffix,
        suffixStyle: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        filled: true,
        fillColor: readOnly
            ? colorScheme.onSurface.withValues(alpha: 0.05)
            : colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      style: TextStyle(
        fontSize: 14,
        fontWeight: readOnly ? FontWeight.bold : FontWeight.normal,
        color: colorScheme.onSurface,
      ),
    );
  }

  TextStyle _headerStyle(ColorScheme colorScheme) {
    return TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
      color: colorScheme.onSurface.withValues(alpha: 0.5),
    );
  }
}
