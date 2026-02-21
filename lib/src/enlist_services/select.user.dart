import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/widgets/empty.widget.dart';

import '../../app_router.gr.dart';
import '../paitients/patient_model.dart';
import '../widgets/patients.tiles.dart';

class SelectUser extends StatefulWidget {
  final List<Patient> patients;
  final ValueChanged<String> onSearch;
  final ValueChanged<Patient> onPatientSelected;

  const SelectUser({
    super.key,
    required this.patients,
    required this.onSearch,
    required this.onPatientSelected,
  });

  @override
  State<SelectUser> createState() => _SelectUserState();
}

class _SelectUserState extends State<SelectUser> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    // Logic to determine which view to show
    Widget content;

    if (!_isSearching && _searchCtrl.text.isEmpty) {
      // 1. Initial State: User hasn't typed yet
      content = const EmptyStateWidget(
        icon: Icons.search_rounded,
        title: "Start Searching",
        message: "Find a patient to view pending bills and encounters.",
      );
    } else if (widget.patients.isEmpty) {
      // 2. No Results State: User typed, but list is empty
      content = EmptyStateWidget(
        icon: Icons.person_off_outlined,
        title: "Oops, such empty",
        message: "We couldn't find any patient matching '${_searchCtrl.text}'.",
        buttonText: "Register New Patient",
        onPressed: () => context.router.push(PatientFormRoute()),
      );
    } else {
      // 3. Results List
      content = ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: widget.patients.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          return PatientTile(
            patient: widget.patients[index],
            onTap: () => widget.onPatientSelected(widget.patients[index]),
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New Invoice',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Search for a patient to begin billing.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),

        // Main Search Card
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.person_search_rounded,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Find Patient',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Modern Search Input
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.transparent),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (val) {
                            setState(() {
                              _isSearching = val.isNotEmpty;
                            });
                            widget.onSearch(val);
                          },
                          decoration: InputDecoration(
                            hintText: "Name, ID, or Phone number...",
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.grey,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                Icons.fingerprint,
                                color: Theme.of(context).primaryColor,
                              ),
                              onPressed: () {},
                              tooltip: "Scan Fingerprint",
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Dynamic Content Area
                Expanded(child: content),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
