import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';

import '../../core/errors/app_exception.dart';
import '../models/purchases_model.dart';
import '../services/purchases_service.dart';

@RoutePage()
class PurchasesLocationScreen extends StatefulWidget {
  const PurchasesLocationScreen({super.key});

  @override
  State<PurchasesLocationScreen> createState() =>
      _PurchasesLocationScreenState();
}

class _PurchasesLocationScreenState extends State<PurchasesLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = PurchasesApiService();

  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  String? _selectedType; // display label: Store, Dispensary, Cold Room, Ward
  String? _selectedStaffId; // optional manager/staff id

  String _activeFilter = 'All';
  List<PurchasesLocation> _locations = [];
  bool _loading = false;
  String? _editingId; // when non-null, form is in edit mode

  static const List<String> _locationTypeLabels = [
    'Store',
    'Warehouse',
    'Department',
    'Cold Room',
  ];
  static final List<PurchasesLocationType> _locationTypeValues = [
    PurchasesLocationType.STORE,
    PurchasesLocationType.WAREHOUSE,
    PurchasesLocationType.DEPARTMENT,
    PurchasesLocationType.COLD_ROOM,
  ];

  // Optional: list of staff for manager dropdown (id -> display name). Populate from your staff API if available.
  final Map<String, String> _staffOptions = {};

  final Color _primaryRed = const Color(0xFFE50914);

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    setState(() => _loading = true);
    try {
      final resp = await _apiService.getLocations(
        const PurchasesQueryParams(pageSize: 20),
      );
      if (mounted) {
        setState(() {
          _locations = resp.items;
          _loading = false;
        });
      }
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showSnack(e.message, isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showSnack(e.toString(), isError: true);
      }
    }
  }

  List<PurchasesLocation> get _filteredLocations {
    if (_activeFilter == 'All') return _locations;
    if (_activeFilter == 'Main Stores') {
      return _locations
          .where(
            (l) =>
                l.type == PurchasesLocationType.STORE ||
                l.type == PurchasesLocationType.COLD_ROOM,
          )
          .toList();
    }
    if (_activeFilter == 'Dispensaries') {
      return _locations
          .where((l) => l.type == PurchasesLocationType.WAREHOUSE)
          .toList();
    }
    return _locations;
  }

  int _countType(String filterType) {
    if (filterType == 'All') return _locations.length;
    if (filterType == 'Main Stores') {
      return _locations
          .where(
            (l) =>
                l.type == PurchasesLocationType.STORE ||
                l.type == PurchasesLocationType.COLD_ROOM,
          )
          .length;
    }
    if (filterType == 'Dispensaries') {
      return _locations
          .where((l) => l.type == PurchasesLocationType.WAREHOUSE)
          .length;
    }
    return 0;
  }

  PurchasesLocationType _typeFromLabel(String? label) {
    if (label == null) return PurchasesLocationType.STORE;
    final i = _locationTypeLabels.indexOf(label);
    if (i >= 0 && i < _locationTypeValues.length) return _locationTypeValues[i];
    return PurchasesLocationType.STORE;
  }

  String _labelFromType(PurchasesLocationType type) {
    final i = _locationTypeValues.indexOf(type);
    if (i >= 0 && i < _locationTypeLabels.length) return _locationTypeLabels[i];
    return type.name;
  }

  void _clearForm() {
    setState(() {
      _editingId = null;
      _nameCtrl.clear();
      _descriptionCtrl.clear();
      _selectedType = null;
      _selectedStaffId = null;
    });
  }

  void _fillForm(PurchasesLocation loc) {
    _nameCtrl.text = loc.name;
    _descriptionCtrl.text = loc.description ?? '';
    _selectedType = _labelFromType(loc.type);
    _selectedStaffId = loc.staffId;
    _editingId = loc.id;
  }

  Future<void> _saveLocation() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showSnack('Location name is required', isError: true);
      return;
    }
    final type = _typeFromLabel(_selectedType);
    final description = _descriptionCtrl.text.trim();
    final staffId = _selectedStaffId?.trim().isEmpty == true
        ? null
        : _selectedStaffId;

    setState(() => _loading = true);
    try {
      if (_editingId != null) {
        final updated = PurchasesLocation(
          id: _editingId,
          name: name,
          type: type,
          description: description.isEmpty ? null : description,
          staffId: staffId,
          staffName: staffId != null ? _staffOptions[staffId] : null,
          isActive: true,
        );
        await _apiService.updateLocation(updated);
        if (mounted) {
          _showSnack('Location updated.');
          _clearForm();
          _loadLocations();
        }
      } else {
        final created = PurchasesLocation(
          name: name,
          type: type,
          description: description.isEmpty ? null : description,
          staffId: staffId,
          isActive: true,
        );
        await _apiService.createLocation(created);
        if (mounted) {
          _showSnack('Location saved.');
          _clearForm();
          _loadLocations();
        }
      }
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showSnack(e.message, isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showSnack(e.toString(), isError: true);
      }
    }
  }

  Future<void> _editLocation(PurchasesLocation location) async {
    if (location.id == null || location.id!.isEmpty) return;
    setState(() => _loading = true);
    try {
      final loc = await _apiService.getLocationById(location.id!);
      if (mounted) {
        setState(() {
          _loading = false;
          _fillForm(loc);
        });
      }
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showSnack(e.message, isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showSnack(e.toString(), isError: true);
      }
    }
  }

  Future<void> _deleteLocation(PurchasesLocation location) async {
    if (location.id == null || location.id!.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete location?'),
        content: Text('Delete "${location.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _loading = true);
    try {
      await _apiService.deleteLocation(location.id!);
      if (mounted) {
        _showSnack('Location deleted.');
        if (_editingId == location.id) _clearForm();
        _loadLocations();
      }
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showSnack(e.message, isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showSnack(e.toString(), isError: true);
      }
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) => ResponsiveRowColumn(
          first: _buildFormPanel(theme, scheme),
          second: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopBar(theme, scheme),
              const SizedBox(height: 24),
              Expanded(child: _buildLocationsGrid()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormPanel(ThemeData theme, ColorScheme scheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _editingId != null ? 'Edit Location' : 'Add New Location',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildFormLabel('Location Name', isRequired: true),
            _buildTextField(
              controller: _nameCtrl,
              hint: 'e.g. Downtown Dispensary',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            _buildFormLabel('Location Type', isRequired: true),
            _buildDropdown(
              value: _selectedType,
              hint: 'Select location type',
              items: _locationTypeLabels,
              onChanged: (v) => setState(() => _selectedType = v),
            ),
            _buildFormLabel('Assign Manager (staff ID)'),
            _buildStaffDropdown(),
            _buildFormLabel('Description'),
            _buildTextField(
              controller: _descriptionCtrl,
              hint: 'Optional description',
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading ? null : _clearForm,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: scheme.outlineVariant),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      foregroundColor: scheme.onSurface,
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _saveLocation,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: _primaryRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _editingId != null ? 'Update' : 'Save Location',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildStaffDropdown() {
    final scheme = Theme.of(context).colorScheme;
    return DropdownButtonFormField<String>(
      initialValue:
          _selectedStaffId == null ||
              _selectedStaffId!.isEmpty ||
              !_staffOptions.containsKey(_selectedStaffId)
          ? null
          : _selectedStaffId,
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('— None —', style: TextStyle(fontSize: 13)),
        ),
        ..._staffOptions.entries.map(
          (e) => DropdownMenuItem<String>(
            value: e.key,
            child: Text(e.value, style: const TextStyle(fontSize: 13)),
          ),
        ),
      ],
      onChanged: (v) => setState(() => _selectedStaffId = v),
      decoration: InputDecoration(
        hintText: 'Select manager',
        hintStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
    );
  }

  Widget _buildFormLabel(String label, {bool isRequired = false}) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: RichText(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: onSurface,
          ),
          children: [
            if (isRequired)
              TextSpan(
                text: ' *',
                style: TextStyle(color: _primaryRed),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 13)),
            ),
          )
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      icon: Icon(
        Icons.keyboard_arrow_down,
        color: scheme.onSurfaceVariant,
        size: 20,
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme, ColorScheme scheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search locations...',
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
              ),
            ),
          const Spacer(),
          Row(
            children: [
              _buildFilterTab('All'),
              const SizedBox(width: 8),
              _buildFilterTab('Main Stores'),
              const SizedBox(width: 8),
              _buildFilterTab('Dispensaries'),
            ],
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String label) {
    final scheme = Theme.of(context).colorScheme;
    final isActive = _activeFilter == label;
    final count = _countType(label);
    return InkWell(
      onTap: () => setState(() => _activeFilter = label),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? _primaryRed.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            color: isActive ? _primaryRed : scheme.onSurface,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationsGrid() {
    if (_loading && _locations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_filteredLocations.isEmpty) {
      final muted = Theme.of(context).colorScheme.onSurfaceVariant;
      return Center(
        child: Text(
          'No locations yet. Add one using the form.',
          style: TextStyle(color: muted, fontSize: 15),
        ),
      );
    }
    return SingleChildScrollView(
      child: ResponsiveWrapGrid(
        mobileColumns: 1,
        tabletColumns: 2,
        desktopColumns: 3,
        children: _filteredLocations
            .map((location) => _buildLocationCard(location))
            .toList(),
      ),
    );
  }

  Widget _buildLocationCard(PurchasesLocation location) {
    final scheme = Theme.of(context).colorScheme;
    final typeLabel = _labelFromType(location.type);
    IconData typeIcon = Icons.store;
    Color iconColor = _primaryRed;
    if (location.type == PurchasesLocationType.COLD_ROOM) {
      typeIcon = Icons.ac_unit;
    } else if (location.type == PurchasesLocationType.WAREHOUSE) {
      typeIcon = Icons.local_pharmacy;
    } else if (location.type == PurchasesLocationType.DEPARTMENT) {
      typeIcon = Icons.medical_services_outlined;
    }

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _primaryRed.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(typeIcon, color: iconColor, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          typeLabel.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    _buildPopupMenu(location),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  location.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (location.description != null &&
                    location.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    location.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: scheme.surfaceContainerHighest,
                      child: Text(
                        _getInitials(location.staffName ?? 'Unassigned'),
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location.staffName ?? 'Unassigned',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: scheme.onSurface,
                          ),
                        ),
                        Text(
                          'Manager',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenu(PurchasesLocation location) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: scheme.onSurfaceVariant, size: 20),
      tooltip: 'Options',
      onSelected: (String value) {
        if (value == 'edit') {
          _editLocation(location);
        } else if (value == 'delete') {
          _deleteLocation(location);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: scheme.onSurface),
              const SizedBox(width: 8),
              const Text('Edit Location'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Location', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}
