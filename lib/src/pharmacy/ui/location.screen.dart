import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../core/errors/app_exception.dart';
import '../models/pharmacy_model.dart';
import '../services/pharmacy_service.dart';

@RoutePage()
class PharmacyLocationScreen extends StatefulWidget {
  const PharmacyLocationScreen({super.key});

  @override
  State<PharmacyLocationScreen> createState() => _PharmacyLocationScreenState();
}

class _PharmacyLocationScreenState extends State<PharmacyLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = PharmacyApiService();

  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  String? _selectedType; // display label: Store, Dispensary, Cold Room, Ward
  String? _selectedStaffId; // optional manager/staff id

  String _activeFilter = 'All';
  List<PharmacyLocation> _locations = [];
  bool _loading = false;
  String? _editingId; // when non-null, form is in edit mode

  static const List<String> _locationTypeLabels = [
    'Store',
    'Dispensary',
    'Cold Room',
    'Ward',
  ];
  static const List<PharmacyLocationType> _locationTypeValues = [
    PharmacyLocationType.STORE,
    PharmacyLocationType.DISPENSARY,
    PharmacyLocationType.COLD_ROOM,
    PharmacyLocationType.WARD,
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
      final resp = await _apiService.getPharmacyLocations(
        const PharmacyQueryParams(pageSize: 200),
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

  List<PharmacyLocation> get _filteredLocations {
    if (_activeFilter == 'All') return _locations;
    if (_activeFilter == 'Main Stores') {
      return _locations
          .where(
            (l) =>
                l.type == PharmacyLocationType.STORE ||
                l.type == PharmacyLocationType.COLD_ROOM,
          )
          .toList();
    }
    if (_activeFilter == 'Dispensaries') {
      return _locations
          .where((l) => l.type == PharmacyLocationType.DISPENSARY)
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
                l.type == PharmacyLocationType.STORE ||
                l.type == PharmacyLocationType.COLD_ROOM,
          )
          .length;
    }
    if (filterType == 'Dispensaries') {
      return _locations
          .where((l) => l.type == PharmacyLocationType.DISPENSARY)
          .length;
    }
    return 0;
  }

  PharmacyLocationType _typeFromLabel(String? label) {
    if (label == null) return PharmacyLocationType.STORE;
    final i = _locationTypeLabels.indexOf(label);
    if (i >= 0 && i < _locationTypeValues.length) return _locationTypeValues[i];
    return PharmacyLocationType.STORE;
  }

  String _labelFromType(PharmacyLocationType type) {
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

  void _fillForm(PharmacyLocation loc) {
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
        final updated = PharmacyLocation(
          id: _editingId,
          name: name,
          type: type,
          description: description.isEmpty ? null : description,
          staffId: staffId,
          staffName: staffId != null ? _staffOptions[staffId] : null,
          isActive: true,
        );
        await _apiService.updatePharmacyLocation(updated);
        if (mounted) {
          _showSnack('Location updated.');
          _clearForm();
          _loadLocations();
        }
      } else {
        final created = PharmacyLocation(
          name: name,
          type: type,
          description: description.isEmpty ? null : description,
          staffId: staffId,
          isActive: true,
        );
        await _apiService.createPharmacyLocation(created);
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

  Future<void> _editLocation(PharmacyLocation location) async {
    if (location.id == null || location.id!.isEmpty) return;
    setState(() => _loading = true);
    try {
      final loc = await _apiService.getPharmacyLocationById(location.id!);
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

  Future<void> _deleteLocation(PharmacyLocation location) async {
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
      await _apiService.deletePharmacyLocation(location.id!);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 320, child: _buildFormPanel()),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 24),
                  Expanded(child: _buildLocationsGrid()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _editingId != null ? 'Edit Location' : 'Add New Location',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
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
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      foregroundColor: Colors.black87,
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
    );
  }

  Widget _buildStaffDropdown() {
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
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
      ),
    );
  }

  Widget _buildFormLabel(String label, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: RichText(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.black87,
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
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400),
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
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
      ),
      icon: Icon(
        Icons.keyboard_arrow_down,
        color: Colors.grey.shade600,
        size: 20,
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search locations...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
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
    );
  }

  Widget _buildFilterTab(String label) {
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
            color: isActive ? _primaryRed : Colors.black87,
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
      return Center(
        child: Text(
          'No locations yet. Add one using the form.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
        ),
      );
    }
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        childAspectRatio: 1.5,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      itemCount: _filteredLocations.length,
      itemBuilder: (context, index) {
        return _buildLocationCard(_filteredLocations[index]);
      },
    );
  }

  Widget _buildLocationCard(PharmacyLocation location) {
    final typeLabel = _labelFromType(location.type);
    IconData typeIcon = Icons.store;
    Color iconColor = _primaryRed;
    if (location.type == PharmacyLocationType.COLD_ROOM) {
      typeIcon = Icons.ac_unit;
    } else if (location.type == PharmacyLocationType.DISPENSARY) {
      typeIcon = Icons.local_pharmacy;
    } else if (location.type == PharmacyLocationType.WARD) {
      typeIcon = Icons.medical_services_outlined;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
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
                            color: Colors.grey.shade700,
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (location.description != null &&
                    location.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    location.description!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey.shade200,
                      child: Text(
                        _getInitials(location.staffName ?? 'Unassigned'),
                        style: TextStyle(
                          color: Colors.grey.shade700,
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
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Manager',
                          style: TextStyle(
                            color: Colors.grey.shade500,
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

  Widget _buildPopupMenu(PharmacyLocation location) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.black54, size: 20),
      tooltip: 'Options',
      onSelected: (String value) {
        if (value == 'edit') {
          _editLocation(location);
        } else if (value == 'delete') {
          _deleteLocation(location);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: Colors.black87),
              SizedBox(width: 8),
              Text('Edit Location'),
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
