import 'package:flutter/material.dart';

import '../../models/admission_model.dart';
import '../../models/ward_models.dart';
import '../../services/admission_service.dart';
import '../../services/ward_service.dart';

/// Ward and bed picker for an active admission. Used by nurses on the inpatient
/// chart and by doctors on the encounter admission tab.
class AdmissionWardLocationSection extends StatefulWidget {
  const AdmissionWardLocationSection({
    super.key,
    required this.admission,
    this.onLocationUpdated,
    this.readOnly = false,
    this.compact = false,
  });

  final AdmissionModel admission;
  final VoidCallback? onLocationUpdated;
  final bool readOnly;
  final bool compact;

  @override
  State<AdmissionWardLocationSection> createState() =>
      _AdmissionWardLocationSectionState();
}

class _AdmissionWardLocationSectionState
    extends State<AdmissionWardLocationSection> {
  final _admissionService = AdmissionService();
  final _wardService = WardService();

  List<Ward> _wards = const [];
  Ward? _selectedWard;
  List<Bed> _beds = const [];
  Bed? _selectedBed;
  bool _loadingWards = false;
  bool _loadingBeds = false;
  bool _submitting = false;

  AdmissionModel get _admission => widget.admission;

  bool get _canSubmitTransfer {
    if (_submitting || widget.readOnly) return false;
    if (_selectedWard == null || _selectedBed == null) return false;
    final wardChanged = _selectedWard!.id != _admission.wardId;
    final bedChanged = _selectedBed!.id != _admission.bedId;
    return wardChanged || bedChanged;
  }

  String get _currentWardLabel {
    final fromEntity = _admission.wardEntity?['name']?.toString();
    final w = fromEntity ?? _admission.ward;
    return (w != null && w.trim().isNotEmpty) ? w.trim() : '—';
  }

  String get _currentBedLabel {
    final fromBed = _admission.bed?['bedNumber']?.toString();
    final b = fromBed ?? _admission.bedPreference;
    return (b != null && b.trim().isNotEmpty) ? b.trim() : '—';
  }

  @override
  void initState() {
    super.initState();
    if (!widget.readOnly) {
      _loadWards();
    }
  }

  @override
  void didUpdateWidget(AdmissionWardLocationSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.admission.id != widget.admission.id ||
        oldWidget.admission.wardId != widget.admission.wardId ||
        oldWidget.admission.bedId != widget.admission.bedId) {
      if (!widget.readOnly && _wards.isNotEmpty) {
        _syncSelectionFromAdmission();
      }
    }
  }

  Future<void> _loadWards() async {
    setState(() => _loadingWards = true);
    try {
      final wards = await _wardService.fetchWards();
      if (!mounted) return;
      setState(() {
        _wards = wards;
        _loadingWards = false;
      });
      await _syncSelectionFromAdmission();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingWards = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load wards')),
      );
    }
  }

  Future<void> _syncSelectionFromAdmission() async {
    final wardId = _admission.wardId;
    if (wardId == null || wardId.isEmpty || _wards.isEmpty) return;

    Ward? ward;
    for (final w in _wards) {
      if (w.id == wardId) {
        ward = w;
        break;
      }
    }
    if (ward == null) return;

    setState(() => _selectedWard = ward);
    await _loadBedsForWard(ward.id, includeBedId: _admission.bedId);
  }

  Future<void> _loadBedsForWard(String wardId, {String? includeBedId}) async {
    setState(() {
      _loadingBeds = true;
      _selectedBed = null;
      _beds = const [];
    });
    try {
      final beds = await _wardService.fetchBedsForWard(wardId);
      if (!mounted) return;
      setState(() {
        _beds = beds
            .where(
              (b) => b.status != BedStatus.occupied || b.id == includeBedId,
            )
            .toList(growable: false);
        _selectedBed = _beds.isNotEmpty ? _beds.first : null;
      });
      if (includeBedId != null && includeBedId.isNotEmpty) {
        final bed = _beds.where((b) => b.id == includeBedId).firstOrNull;
        if (bed != null && mounted) {
          setState(() => _selectedBed = bed);
        }
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load beds for ward')),
      );
    } finally {
      if (mounted) setState(() => _loadingBeds = false);
    }
  }

  Future<void> _updateAdmissionLocation() async {
    if (!_canSubmitTransfer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a different ward or bed to update location.'),
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await _admissionService.patch(_admission.id, {
        'wardId': _selectedWard!.id,
        'ward': _selectedWard!.name,
        'bedId': _selectedBed!.id,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient location updated.')),
      );
      widget.onLocationUpdated?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _buildCurrentLocationBanner(ThemeData theme, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.place_outlined, color: cs.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current location',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ward: $_currentWardLabel  ·  Bed: $_currentBedLabel',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWardBedRow(ThemeData theme, ColorScheme cs) {
    final wardField = DropdownButtonFormField<String>(
      initialValue: _selectedWard?.id,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Ward *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: _wards
          .map(
            (w) => DropdownMenuItem<String>(
              value: w.id,
              child: Text(w.name),
            ),
          )
          .toList(),
      onChanged: _loadingWards
          ? null
          : (value) {
              if (value == null) return;
              final ward = _wards.firstWhere((w) => w.id == value);
              setState(() => _selectedWard = ward);
              _loadBedsForWard(ward.id, includeBedId: _admission.bedId);
            },
    );

    final bedField = DropdownButtonFormField<String>(
      initialValue: _selectedBed?.id,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Bed *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: _beds
          .map(
            (b) => DropdownMenuItem<String>(
              value: b.id,
              child: Text(b.bedNumber),
            ),
          )
          .toList(),
      onChanged: _loadingBeds
          ? null
          : (value) {
              if (value == null) return;
              setState(() {
                _selectedBed = _beds.firstWhere((b) => b.id == value);
              });
            },
    );

    if (widget.compact) {
      return Column(
        children: [
          wardField,
          const SizedBox(height: 12),
          bedField,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: wardField),
        const SizedBox(width: 12),
        Expanded(child: bedField),
      ],
    );
  }

  Widget _buildLoadingHint(ColorScheme cs) {
    if (!_loadingWards && !_loadingBeds) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _loadingWards ? 'Loading wards...' : 'Loading available beds...',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityHint(ColorScheme cs) {
    if (_loadingWards || _loadingBeds) return const SizedBox.shrink();
    if (_wards.isEmpty) {
      return Text(
        'No wards configured. Please create wards first.',
        style: TextStyle(fontSize: 12, color: cs.error),
      );
    }
    if (_selectedWard != null && _beds.isEmpty) {
      return Text(
        'No available beds in this ward.',
        style: TextStyle(
          fontSize: 12,
          color: cs.onSurface.withValues(alpha: 0.7),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (widget.readOnly) {
      return _buildCurrentLocationBanner(theme, cs);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCurrentLocationBanner(theme, cs),
        const SizedBox(height: 16),
        _buildWardBedRow(theme, cs),
        _buildLoadingHint(cs),
        const SizedBox(height: 4),
        _buildAvailabilityHint(cs),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _canSubmitTransfer ? _updateAdmissionLocation : null,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.swap_horiz, size: 18),
            label: const Text('Update location'),
          ),
        ),
      ],
    );
  }
}
