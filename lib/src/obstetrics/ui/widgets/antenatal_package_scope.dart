import 'package:flutter/material.dart';

/// Default antenatal package coverage for service/drug pickers on pregnancy Orders.
class AntenatalPackageScope extends InheritedWidget {
  const AntenatalPackageScope({
    super.key,
    required this.serviceIds,
    required this.drugIds,
    required super.child,
  });

  final Set<String> serviceIds;
  final Set<String> drugIds;

  static AntenatalPackageScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AntenatalPackageScope>();

  static Set<String> serviceIdsOf(BuildContext context) =>
      of(context)?.serviceIds ?? const {};

  static Set<String> drugIdsOf(BuildContext context) =>
      of(context)?.drugIds ?? const {};

  @override
  bool updateShouldNotify(AntenatalPackageScope old) =>
      serviceIds != old.serviceIds || drugIds != old.drugIds;
}

Widget antenatalPackageBadge(BuildContext context, {String? serviceId, String? drugId}) {
  final scope = AntenatalPackageScope.of(context);
  if (scope == null) return const SizedBox.shrink();
  final included = (serviceId != null && scope.serviceIds.contains(serviceId)) ||
      (drugId != null && scope.drugIds.contains(drugId));
  if (!included) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(left: 8),
    child: Chip(
      label: const Text('ANC package'),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.zero,
      labelStyle: const TextStyle(fontSize: 11),
    ),
  );
}
