import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

// Mock model for a Pharmacy Location
class PharmacyLocation {
  final String id;
  final String name;
  final String type; // 'MAIN STORE', 'COLD ROOM', 'DISPENSARY'
  final String managerName;
  final String? managerAvatarUrl; // null means use initials
  final int currentItems;
  final int maxCapacity;

  PharmacyLocation({
    required this.id,
    required this.name,
    required this.type,
    required this.managerName,
    this.managerAvatarUrl,
    required this.currentItems,
    required this.maxCapacity,
  });

  double get capacityPercentage => currentItems / maxCapacity;
}

@RoutePage()
class PharmacyLocationScreen extends StatefulWidget {
  const PharmacyLocationScreen({super.key});

  @override
  State<PharmacyLocationScreen> createState() => _PharmacyLocationScreenState();
}

class _PharmacyLocationScreenState extends State<PharmacyLocationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _nameCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  String? _selectedType;
  String? _selectedManager;

  // Filter State
  String _activeFilter = 'All';

  // Mock Data matching the screenshot
  final List<PharmacyLocation> _locations = [
    PharmacyLocation(
      id: 'loc-1',
      name: 'Central Hospital Pharmacy',
      type: 'MAIN STORE',
      managerName: 'Dr. Sarah Jenkins',
      managerAvatarUrl: 'avatar', // Simulated avatar presence
      currentItems: 8500,
      maxCapacity: 10000,
    ),
    PharmacyLocation(
      id: 'loc-2',
      name: 'Vaccine Storage Alpha',
      type: 'COLD ROOM',
      managerName: 'Mark Thompson',
      managerAvatarUrl:
          null, // Will show initials 'MR' (Using MT for Mark Thompson)
      currentItems: 840,
      maxCapacity: 2000,
    ),
    PharmacyLocation(
      id: 'loc-3',
      name: 'Downtown Dispensary',
      type: 'DISPENSARY',
      managerName: 'Alice Cooper',
      managerAvatarUrl: null,
      currentItems: 1200,
      maxCapacity: 5000,
    ),
  ];

  final List<String> _locationTypes = [
    'Store',
    'Dispensary',
    'Cold Room',
    'Ward',
  ];
  final List<String> _managers = [
    'Dr. Sarah Jenkins',
    'Mark Thompson',
    'Alice Cooper',
    'Unassigned',
  ];

  // Theme Red Color from the screenshot
  final Color _primaryRed = const Color(
    0xFFE50914,
  ); // Adjust to match exact hex if needed

  List<PharmacyLocation> get _filteredLocations {
    if (_activeFilter == 'All') return _locations;
    if (_activeFilter == 'Main Stores') {
      return _locations
          .where((l) => l.type == 'MAIN STORE' || l.type == 'COLD ROOM')
          .toList();
    }
    if (_activeFilter == 'Dispensaries') {
      return _locations.where((l) => l.type == 'DISPENSARY').toList();
    }
    return _locations;
  }

  int _countType(String filterType) {
    if (filterType == 'All') return _locations.length;
    if (filterType == 'Main Stores') {
      return _locations
          .where((l) => l.type == 'MAIN STORE' || l.type == 'COLD ROOM')
          .length;
    }
    if (filterType == 'Dispensaries') {
      return _locations.where((l) => l.type == 'DISPENSARY').length;
    }
    return 0;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8), // Light grey background
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Side: Form Panel
            SizedBox(width: 320, child: _buildFormPanel()),
            const SizedBox(width: 24),
            // Right Side: Locations Grid and Filters
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

  // --- Left Panel: Form ---

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
            const Text(
              'Add New Location',
              style: TextStyle(
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
            ),

            _buildFormLabel('Location Type', isRequired: true),
            _buildDropdown(
              value: _selectedType,
              hint: 'Select location type',
              items: _locationTypes,
              onChanged: (v) => setState(() => _selectedType = v),
            ),

            _buildFormLabel('Assign Manager'),
            _buildDropdown(
              value: _selectedManager,
              hint: 'Select a manager',
              items: _managers,
              onChanged: (v) => setState(() => _selectedManager = v),
            ),

            _buildFormLabel('Storage Capacity (Items)'),
            _buildTextField(
              controller: _capacityCtrl,
              hint: 'e.g. 5000',
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _nameCtrl.clear();
                      _capacityCtrl.clear();
                      setState(() {
                        _selectedType = null;
                        _selectedManager = null;
                      });
                    },
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
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Submit logic here
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Location Saved!')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: _primaryRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Save Location',
                      style: TextStyle(fontWeight: FontWeight.w600),
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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
      icon: Icon(
        Icons.keyboard_arrow_down,
        color: Colors.grey.shade600,
        size: 20,
      ),
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
    );
  }

  // --- Right Panel: Top Bar & Filters ---

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
          // Search Input
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
          // Filter Tabs
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

  // --- Right Panel: Locations Grid ---

  Widget _buildLocationsGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400, // Max width of a card before it wraps
        childAspectRatio: 1.5, // Aspect ratio to match screenshot proportions
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
    final pct = location.capacityPercentage;

    // Determine progress bar color based on capacity
    Color progressColor = Colors.green;
    if (pct > 0.8) {
      progressColor = _primaryRed;
    } else if (pct > 0.4) {
      progressColor = Colors.orange;
    }

    // Determine Icon based on type
    IconData typeIcon = Icons.store;
    Color iconColor = _primaryRed;
    if (location.type == 'COLD ROOM') {
      typeIcon = Icons.ac_unit;
    } else if (location.type == 'DISPENSARY') {
      typeIcon = Icons.local_pharmacy;
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
          // Subtle background blob/shape at top right
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
                // Header Row (Type + Menu)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(typeIcon, color: iconColor, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          location.type,
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
                // Title
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

                const SizedBox(height: 16),
                // Manager Row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: location.managerAvatarUrl == 'avatar'
                          ? const NetworkImage(
                              'https://i.pravatar.cc/150?img=1',
                            )
                          : null,
                      child: location.managerAvatarUrl == null
                          ? Text(
                              _getInitials(location.managerName),
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location.managerName,
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

                const Spacer(),
                // Capacity Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Capacity Status',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(pct * 100).toInt()}% Full',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${_formatNumber(location.currentItems)} / ${_formatNumber(location.maxCapacity)} items',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper for the three-dot menu
  Widget _buildPopupMenu(PharmacyLocation location) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.black54, size: 20),
      tooltip: 'Options',
      onSelected: (String value) {
        if (value == 'edit') {
          // Handle Edit
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Editing ${location.name}...')),
          );
        } else if (value == 'delete') {
          // Handle Delete
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleting ${location.name}...')),
          );
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

  // Helper to get initials from a name (e.g. "Mark Thompson" -> "MT")
  String _getInitials(String name) {
    List<String> parts = name.split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '??';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  // Helper to format numbers with commas (e.g. 8500 -> 8,500)
  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
