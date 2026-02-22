import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/services/service_service.dart';

import '../../models/service_category_model.dart';
import '../../models/service_model.dart';
import '../../services/department_service.dart';
import '../../services/service_category_service.dart';

@RoutePage()
class AddServiceScreen extends StatefulWidget {
  const AddServiceScreen({super.key});

  @override
  AddServiceScreenState createState() => AddServiceScreenState();
}

class AddServiceScreenState extends State<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final serviceService = ServiceService();
  final serviceCategoryService = ServiceCategoryService();
  final departmentService = DepartmentService();
  List<ServiceCategory> categories = [];
  List<Department> departments = [];

  String? _selectedCategoryId;
  String? _selectedDepartmentId;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    getVlaues();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    // ensure dropdowns selected
    if (_selectedCategoryId == null || _selectedDepartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick category and department')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final newService = ServiceModel(
      id: '',
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      cost: double.tryParse(_costCtrl.text.trim()) ?? 0.0,
      categoryId: _selectedCategoryId,
      departmentId: _selectedDepartmentId,
      serviceId: '',
    );

    try {
      await serviceService.createService(newService);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void getVlaues() async {
    var res = await Future.wait([
      serviceCategoryService.fetchCategories(),
      departmentService.fetchDepartments(),
    ]);

    setState(() {
      categories = res.first as List<ServiceCategory>;
      departments = res[1] as List<Department>;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add service'),
        actions: [
          IconButton(onPressed: getVlaues, icon: Icon(Icons.refresh_outlined)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _costCtrl,
                decoration: const InputDecoration(labelText: 'Cost'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Cost required';
                  if (double.tryParse(v) == null) return 'Enter valid number';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // category dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedCategoryId,
                items: categories
                    .map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                    )
                    .toList(),
                decoration: const InputDecoration(labelText: 'Category'),
                onChanged: (v) => setState(() {
                  _selectedCategoryId = v;
                }),
              ),
              // loading: () => const SizedBox(
              //   height: 48,
              //   child: Center(child: CircularProgressIndicator()),
              // ),
              // error: (e, _) => Text('Failed to load categories'),
              // ),
              const SizedBox(height: 12),
              // department dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedDepartmentId,
                items: departments
                    .map(
                      (d) => DropdownMenuItem(value: d.id, child: Text(d.name)),
                    )
                    .toList(),
                decoration: const InputDecoration(labelText: 'Department'),
                onChanged: (v) => setState(() {
                  _selectedDepartmentId = v;
                }),
              ),

              // loading: () => const SizedBox(
              //   height: 48,
              //   child: Center(child: CircularProgressIndicator()),
              // ),
              // error: (e, _) => Text('Failed to load departments'),
              const SizedBox(height: 24),
              Center(
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
