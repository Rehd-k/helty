import 'package:auto_route/auto_route.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:helty/src/services/service_service.dart';

import '../../models/service_model.dart';
import '../../widgets/table/reusable_async_table.dart';
import 'add_category_screen.dart';
import 'add_department_screen.dart';
import 'add_service_screen.dart';

@RoutePage()
class ViewServiceScreen extends StatefulWidget {
  const ViewServiceScreen({super.key});

  @override
  ViewServiceScreenState createState() => ViewServiceScreenState();
}

class ViewServiceScreenState extends State<ViewServiceScreen> {
  final serviceService = ServiceService();
  final TextEditingController _searchController = TextEditingController();

  Future<PagedData<ServiceModel>> fetchServices(int start, int count) async {
    final service = await serviceService.fetchServices();

    return PagedData(totalCount: service.length, items: service);
  }

  void _handleRowAction(String action, ServiceModel service, BuildContext ctx) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text('Action "\$action" on \\$service.name')),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchServices(0, 10);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        leading: SizedBox(
          width: 200,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                fillColor: Colors.white,
                filled: true,
                prefixIcon: Icon(Icons.search),
                hintText: 'Search services',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
      ),
      body: ReusableAsyncTable<ServiceModel>(
        fetchData: fetchServices,
        idGetter: (s) => s.id,
        columns: const [
          DataColumn2(label: Text('Name'), size: ColumnSize.L),
          DataColumn2(label: Text('Category'), size: ColumnSize.M),
          DataColumn2(label: Text('Department'), size: ColumnSize.M),
          DataColumn2(label: Text('Cost'), size: ColumnSize.S),
          DataColumn2(label: Text('Description'), size: ColumnSize.L),
          DataColumn2(label: Text('Action'), fixedWidth: 64),
        ],
        rowBuilder: (service) {
          return [
            DataCell(Text(service.name)),
            DataCell(Text(service.categoryName ?? '–')),
            DataCell(Text(service.departmentName ?? '–')),
            DataCell(Text(service.cost.toStringAsFixed(2))),
            DataCell(Text(service.description ?? '')),
            DataCell(
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (v) => _handleRowAction(v, service, context),
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: 'view', child: Text('View')),
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ),
          ];
        },
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        distance: 80,

        openButtonBuilder: RotateFloatingActionButtonBuilder(
          child: const Icon(Icons.account_box),
          fabSize: ExpandableFabSize.small,
          shape: const CircleBorder(),
        ),
        closeButtonBuilder: DefaultFloatingActionButtonBuilder(
          child: const Icon(Icons.close),
          fabSize: ExpandableFabSize.small,
          shape: const CircleBorder(),
        ),
        children: [
          FloatingActionButton.small(
            tooltip: 'New Service',

            onPressed: () {
              showModalBottomSheet(
                context: context,
                // Add this shape property
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(25.0),
                  ),
                ),
                // This ensures the content doesn't overflow the rounded corners
                clipBehavior: Clip.antiAliasWithSaveLayer,
                builder: (BuildContext buildContext) {
                  return const AddServiceScreen();
                },
              );
            },
            child: const Icon(Icons.medical_services_outlined),
          ),
          FloatingActionButton.small(
            tooltip: 'New Category',

            onPressed: () {
              showModalBottomSheet(
                context: context,
                // Add this shape property
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(25.0),
                  ),
                ),
                // This ensures the content doesn't overflow the rounded corners
                clipBehavior: Clip.antiAliasWithSaveLayer,
                builder: (BuildContext buildContext) {
                  return const AddCategoryScreen();
                },
              );
            },
            child: const Icon(Icons.category_outlined),
          ),
          FloatingActionButton.small(
            tooltip: 'New Unit',

            onPressed: () {
              showModalBottomSheet(
                context: context,
                // Add this shape property
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(25.0),
                  ),
                ),
                // This ensures the content doesn't overflow the rounded corners
                clipBehavior: Clip.antiAliasWithSaveLayer,
                builder: (BuildContext buildContext) {
                  return const AddDepartmentScreen();
                },
              );
            },
            child: const Icon(Icons.apartment_outlined),
          ),
        ],
      ),
    );
  }
}
