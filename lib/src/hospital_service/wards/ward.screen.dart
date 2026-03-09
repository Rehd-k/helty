import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/hospital_service/setup_widgets/setup_form_widgets.dart';
import 'package:helty/src/models/ward_models.dart';
import 'package:helty/src/services/ward_service.dart';

@RoutePage()
class WardManagementScreen extends StatefulWidget {
  const WardManagementScreen({super.key});

  @override
  State<WardManagementScreen> createState() => _WardManagementScreenState();
}

class _WardManagementScreenState extends State<WardManagementScreen> {
  final _service = WardService();

  final _searchController = TextEditingController();

  bool _isLoadingWards = false;
  bool _isLoadingBeds = false;

  List<Ward> _wards = const [];
  Ward? _selectedWard;
  List<Bed> _beds = const [];

  @override
  void initState() {
    super.initState();
    _loadWards();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWards({String? query}) async {
    setState(() {
      _isLoadingWards = true;
    });
    try {
      final wards = await _service.fetchWards(query: query);
      setState(() {
        _wards = wards;
        if (_selectedWard != null) {
          _selectedWard = wards.firstWhere(
            (w) => w.id == _selectedWard!.id,
            orElse: () => wards.isNotEmpty ? wards.first : _selectedWard!,
          );
        } else if (wards.isNotEmpty) {
          _selectedWard = wards.first;
        }
      });
      if (_selectedWard != null) {
        await _loadBedsForWard(_selectedWard!);
      } else {
        setState(() {
          _beds = const [];
        });
      }
    } catch (e) {
      _showError('Failed to load wards');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingWards = false;
        });
      }
    }
  }

  Future<void> _loadBedsForWard(Ward ward) async {
    setState(() {
      _isLoadingBeds = true;
    });
    try {
      final beds = await _service.fetchBedsForWard(ward.id);
      if (!mounted) return;
      setState(() {
        _beds = beds;
      });
    } catch (e) {
      _showError('Failed to load beds');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBeds = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openWardForm({Ward? ward}) async {
    final result = await showDialog<Ward>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: _WardForm(initial: ward),
          ),
        );
      },
    );

    if (result == null) return;

    try {
      final isEdit = ward != null;
      final saved = isEdit
          ? await _service.updateWard(result)
          : await _service.createWard(result);

      await _loadWards(query: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim());

      if (mounted) {
        setState(() {
          _selectedWard = saved;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Ward updated' : 'Ward created'),
        ),
      );
    } catch (e) {
      _showError('Failed to save ward');
    }
  }

  Future<void> _deleteWard(Ward ward) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete ward'),
        content: Text(
          'Are you sure you want to delete ward "${ward.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deleteWard(ward.id);
      await _loadWards(query: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ward deleted')),
        );
      }
    } catch (e) {
      _showError('Failed to delete ward');
    }
  }

  Future<void> _openBedForm({Bed? bed}) async {
    final ward = _selectedWard;
    if (ward == null) return;

    final result = await showDialog<Bed>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _BedForm(
              wardId: ward.id,
              initial: bed,
            ),
          ),
        );
      },
    );

    if (result == null) return;

    final isEdit = bed != null;

    try {
      if (isEdit) {
        final updated = await _service.updateBed(bed: result);
        if (!mounted) return;
        setState(() {
          _beds = _beds
              .map((b) => b.id == updated.id ? updated : b)
              .toList(growable: false);
        });
      } else {
        final created =
            await _service.createBed(wardId: ward.id, bed: result);
        if (!mounted) return;
        setState(() {
          _beds = [..._beds, created];
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Bed updated' : 'Bed created'),
        ),
      );
    } catch (e) {
      _showError('Failed to save bed');
    }
  }

  Future<void> _deleteBed(Bed bed) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete bed'),
        content: Text(
          'Are you sure you want to delete bed "${bed.bedNumber}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deleteBed(bed.id);
      if (!mounted) return;
      setState(() {
        _beds = _beds.where((b) => b.id != bed.id).toList(growable: false);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bed deleted')),
      );
    } catch (e) {
      _showError('Failed to delete bed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ward management'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _isLoadingWards ? null : () => _loadWards(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 900;

            if (_isLoadingWards && _wards.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (isNarrow) {
              return Column(
                children: [
                  _buildWardListCard(cs, isNarrow: true),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _selectedWard == null
                        ? _buildEmptyWardDetail(cs)
                        : _buildWardDetailCard(cs),
                  ),
                ],
              );
            }

            return Row(
              children: [
                SizedBox(
                  width: 360,
                  child: _buildWardListCard(cs, isNarrow: false),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _selectedWard == null
                      ? _buildEmptyWardDetail(cs)
                      : _buildWardDetailCard(cs),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openWardForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add ward'),
      ),
    );
  }

  Widget _buildWardListCard(ColorScheme cs, {required bool isNarrow}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SetupFormHeader(
              icon: Icons.meeting_room_outlined,
              title: 'Wards',
              subtitle: 'Hospital wards / Services d’hospitalisation',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search wards by name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                _loadWards(query: value.trim().isEmpty ? null : value.trim());
              },
            ),
            const SizedBox(height: 16),
            if (_wards.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.meeting_room_outlined,
                        size: 40,
                        color: cs.onSurface.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No wards yet',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create your first ward to start managing beds.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _openWardForm(),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Create ward'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _wards.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final ward = _wards[index];
                    final isSelected = _selectedWard?.id == ward.id;
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setState(() {
                          _selectedWard = ward;
                        });
                        _loadBedsForWard(ward);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? cs.primary.withValues(alpha: 0.06)
                              : cs.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? cs.primary
                                : cs.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: cs.primary.withValues(alpha: 0.12),
                              ),
                              child: Icon(
                                Icons.bed_outlined,
                                size: 18,
                                color: cs.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          ward.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                      ),
                                      _WardTypeChip(type: ward.type),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        'Capacity: ${ward.capacity}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: cs.onSurface
                                              .withValues(alpha: 0.7),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.king_bed_outlined,
                                        size: 14,
                                        color: cs.onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${ward.beds.length} beds',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: cs.onSurface
                                              .withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWardDetail(ColorScheme cs) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                size: 40,
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 12),
              Text(
                'Select a ward to view details',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose a ward from the list on the left, or create a new ward.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWardDetailCard(ColorScheme cs) {
    final ward = _selectedWard!;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ward.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _WardTypeChip(type: ward.type),
                          const SizedBox(width: 8),
                          Text(
                            'Capacity: ${ward.capacity}',
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      if (ward.departmentId != null &&
                          ward.departmentId!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Department: ${ward.departmentId}',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'Edit ward',
                      onPressed: () => _openWardForm(ward: ward),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Delete ward',
                      onPressed: () => _deleteWard(ward),
                      icon: Icon(
                        Icons.delete_outline,
                        color: cs.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Beds',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed:
                          _isLoadingBeds ? null : () => _loadBedsForWard(ward),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Refresh'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _openBedForm(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add bed'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoadingBeds
                  ? const Center(child: CircularProgressIndicator())
                  : _beds.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.king_bed_outlined,
                                size: 40,
                                color: cs.onSurface.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No beds in this ward yet',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add beds to start admitting inpatients here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _beds.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final bed = _beds[index];
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      cs.outline.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.bed_outlined,
                                    size: 20,
                                    color:
                                        cs.onSurface.withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          bed.bedNumber,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        _BedStatusChip(status: bed.status),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Edit bed',
                                    onPressed: () => _openBedForm(bed: bed),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete bed',
                                    onPressed: () => _deleteBed(bed),
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: cs.error,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WardTypeChip extends StatelessWidget {
  const _WardTypeChip({required this.type});

  final WardType type;

  String get _label {
    switch (type) {
      case WardType.general:
        return 'General';
      case WardType.private:
        return 'Private';
      case WardType.icu:
        return 'ICU';
      case WardType.maternity:
        return 'Maternity';
      case WardType.paediatric:
        return 'Paediatric';
      case WardType.surgical:
        return 'Surgical';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: cs.primary,
        ),
      ),
    );
  }
}

class _BedStatusChip extends StatelessWidget {
  const _BedStatusChip({required this.status});

  final BedStatus status;

  String get _label {
    switch (status) {
      case BedStatus.available:
        return 'Available';
      case BedStatus.occupied:
        return 'Occupied';
      case BedStatus.reserved:
        return 'Reserved';
      case BedStatus.outOfService:
        return 'Out of service';
    }
  }

  Color _background(ColorScheme cs) {
    switch (status) {
      case BedStatus.available:
        return Colors.green.withOpacity(0.08);
      case BedStatus.occupied:
        return cs.error.withValues(alpha: 0.08);
      case BedStatus.reserved:
        return Colors.orange.withOpacity(0.08);
      case BedStatus.outOfService:
        return cs.outline.withValues(alpha: 0.08);
    }
  }

  Color _foreground(ColorScheme cs) {
    switch (status) {
      case BedStatus.available:
        return Colors.green.shade700;
      case BedStatus.occupied:
        return cs.error;
      case BedStatus.reserved:
        return Colors.orange.shade800;
      case BedStatus.outOfService:
        return cs.onSurface.withValues(alpha: 0.7);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _background(cs),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: _foreground(cs),
        ),
      ),
    );
  }
}

class _WardForm extends StatefulWidget {
  const _WardForm({this.initial});

  final Ward? initial;

  @override
  State<_WardForm> createState() => _WardFormState();
}

class _WardFormState extends State<_WardForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _capacityController;
  late final TextEditingController _departmentController;
  WardType _type = WardType.general;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _capacityController =
        TextEditingController(text: initial?.capacity.toString() ?? '');
    _departmentController =
        TextEditingController(text: initial?.departmentId ?? '');
    _type = initial?.type ?? WardType.general;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final capStr = _capacityController.text.trim();
    if (name.isEmpty || capStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and capacity are required')),
      );
      return;
    }

    final capacity = int.tryParse(capStr);
    if (capacity == null || capacity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Capacity must be a positive number')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final initial = widget.initial;
    final ward = Ward(
      id: initial?.id ?? '',
      name: name,
      capacity: capacity,
      type: _type,
      departmentId:
          _departmentController.text.trim().isEmpty ? null : _departmentController.text.trim(),
      createdAt: initial?.createdAt,
      updatedAt: initial?.updatedAt,
      beds: initial?.beds ?? const [],
    );

    if (!mounted) return;
    Navigator.of(context).pop(ward);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SetupFormHeader(
            icon: Icons.meeting_room_outlined,
            title: isEdit ? 'Edit ward' : 'New ward',
            subtitle:
                isEdit ? 'Update ward details' : 'Create a new hospital ward',
          ),
          const SizedBox(height: 16),
          SetupTextField(
            label: 'Ward name',
            controller: _nameController,
          ),
          const SizedBox(height: 12),
          SetupTextField(
            label: 'Capacity (beds)',
            controller: _capacityController,
            isNumber: true,
          ),
          const SizedBox(height: 12),
          SetupDropdown(
            label: 'Ward type',
            value: _type.name,
            items: WardType.values.map((e) => e.name).toList(),
            itemLabels: const [
              'General',
              'Private',
              'ICU',
              'Maternity',
              'Paediatric',
              'Surgical',
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _type =
                    WardType.values.firstWhere((e) => e.name == value);
              });
            },
          ),
          const SizedBox(height: 12),
          SetupTextField(
            label: 'Department ID (optional)',
            controller: _departmentController,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isSaving
                    ? null
                    : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 140,
                child: SetupSubmitButton(
                  label: _isSaving
                      ? 'Saving...'
                      : (isEdit ? 'Save changes' : 'Create ward'),
                  onPressed: _isSaving ? () {} : _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BedForm extends StatefulWidget {
  const _BedForm({
    required this.wardId,
    this.initial,
  });

  final String wardId;
  final Bed? initial;

  @override
  State<_BedForm> createState() => _BedFormState();
}

class _BedFormState extends State<_BedForm> {
  late final TextEditingController _bedNumberController;
  BedStatus _status = BedStatus.available;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _bedNumberController =
        TextEditingController(text: initial?.bedNumber ?? '');
    _status = initial?.status ?? BedStatus.available;
  }

  @override
  void dispose() {
    _bedNumberController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final bedNumber = _bedNumberController.text.trim();
    if (bedNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bed number is required')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final initial = widget.initial;
    final bed = Bed(
      id: initial?.id ?? '',
      wardId: widget.wardId,
      bedNumber: bedNumber,
      status: _status,
    );

    if (!mounted) return;
    Navigator.of(context).pop(bed);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SetupFormHeader(
            icon: Icons.bed_outlined,
            title: isEdit ? 'Edit bed' : 'New bed',
            subtitle: isEdit
                ? 'Update bed details'
                : 'Create a new bed in this ward',
          ),
          const SizedBox(height: 16),
          SetupTextField(
            label: 'Bed number / label',
            controller: _bedNumberController,
          ),
          const SizedBox(height: 12),
          SetupDropdown(
            label: 'Status',
            value: _status.name,
            items: BedStatus.values.map((e) => e.name).toList(),
            itemLabels: const [
              'Available',
              'Occupied',
              'Reserved',
              'Out of service',
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _status =
                    BedStatus.values.firstWhere((e) => e.name == value);
              });
            },
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isSaving
                    ? null
                    : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 140,
                child: SetupSubmitButton(
                  label: _isSaving
                      ? 'Saving...'
                      : (isEdit ? 'Save changes' : 'Create bed'),
                  onPressed: _isSaving ? () {} : _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
