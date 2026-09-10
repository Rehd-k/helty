import 'package:flutter/material.dart';

import '../../models/staff_model.dart';
import '../../shared/department_colors.dart';
import '../models/hospital_asset_models.dart';

Color colorForAccountType(String accountType) {
  return switch (accountType.toUpperCase()) {
    'BILLING' => DepartmentColors.billing,
    'ACCOUNTING' => DepartmentColors.accountingFinance,
    'PHARMACY' => DepartmentColors.pharmacy,
    'NURSE' => DepartmentColors.icu,
    'PHYSICIAN' => DepartmentColors.outpatientClinic,
    'LABORATORY' => DepartmentColors.laboratory,
    'RADIOLOGY' => DepartmentColors.radiology,
    'STORE' => DepartmentColors.orthopedics,
    'MEDICAL_RECORDS' => DepartmentColors.medicalRecords,
    'FRONT_DESK' => DepartmentColors.frontDesk,
    'ICT' => DepartmentColors.itDepartment,
    'HMO' => DepartmentColors.ent,
    'PURCHASES' => DepartmentColors.dental,
    'DIALYSIS' => DepartmentColors.cardiology,
    'THEATRE' => DepartmentColors.theatre,
    'JANITOR' => DepartmentColors.security,
    'CMD' ||
    'CMAC' ||
    'DA' ||
    'DIRECTOR_OF_ADMIN' ||
    'DIRECTOR_ADMIN' => DepartmentColors.administration,
    _ => DepartmentColors.administration,
  };
}

String labelForAccountType(String accountType) {
  return AccountType.fromString(accountType).label;
}

Color colorForAssetStatus(HospitalAssetStatus status) {
  return switch (status) {
    HospitalAssetStatus.inUse => const Color(0xFF16A34A),
    HospitalAssetStatus.underRepair => const Color(0xFFD97706),
    HospitalAssetStatus.decommissioned => const Color(0xFF64748B),
    HospitalAssetStatus.transferred => const Color(0xFF2563EB),
  };
}

Color colorForLogType(HospitalAssetLogType type) {
  return switch (type) {
    HospitalAssetLogType.created => const Color(0xFF16A34A),
    HospitalAssetLogType.usage => DepartmentColors.outpatientClinic,
    HospitalAssetLogType.movement => const Color(0xFF2563EB),
    HospitalAssetLogType.maintenance => const Color(0xFFD97706),
    HospitalAssetLogType.statusChange => DepartmentColors.laboratory,
    HospitalAssetLogType.transfer => DepartmentColors.theatre,
  };
}

IconData iconForAssetKind(HospitalAssetKind kind) {
  return switch (kind) {
    HospitalAssetKind.equipment => Icons.monitor_heart_outlined,
    HospitalAssetKind.machinery => Icons.precision_manufacturing_outlined,
    HospitalAssetKind.vehicle => Icons.local_shipping_outlined,
    HospitalAssetKind.furniture => Icons.chair_outlined,
    HospitalAssetKind.other => Icons.category_outlined,
  };
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final HospitalAssetStatus status;

  @override
  Widget build(BuildContext context) {
    final color = colorForAssetStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class KindChip extends StatelessWidget {
  const KindChip({super.key, required this.kind, this.color});

  final HospitalAssetKind kind;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(iconForAssetKind(kind), size: 16, color: c),
        const SizedBox(width: 4),
        Text(
          kind.label,
          style: TextStyle(color: c, fontWeight: FontWeight.w500, fontSize: 12),
        ),
      ],
    );
  }
}

class InventoryScopeBanner extends StatelessWidget {
  const InventoryScopeBanner({
    super.key,
    required this.accent,
    required this.title,
    required this.subtitle,
  });

  final Color accent;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final onAccent = accent.computeLuminance() > 0.55
        ? Colors.black87
        : Colors.white;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, accent.withValues(alpha: 0.78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: onAccent,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: onAccent.withValues(alpha: 0.9),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusCountCard extends StatelessWidget {
  const StatusCountCard({
    super.key,
    required this.status,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final HospitalAssetStatus status;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = colorForAssetStatus(status);
    return Material(
      color: selected
          ? color.withValues(alpha: 0.16)
          : Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : color.withValues(alpha: 0.28),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                status.label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AssetListCard extends StatelessWidget {
  const AssetListCard({
    super.key,
    required this.asset,
    required this.onTap,
    this.showDepartment = false,
  });

  final HospitalAsset asset;
  final VoidCallback onTap;
  final bool showDepartment;

  @override
  Widget build(BuildContext context) {
    final statusColor = colorForAssetStatus(asset.status);
    final deptColor = colorForAccountType(asset.accountType);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 6, color: statusColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: deptColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                iconForAssetKind(asset.kind),
                                color: deptColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    asset.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    asset.assetTag,
                                    style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StatusChip(status: asset.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            KindChip(kind: asset.kind, color: deptColor),
                            if (showDepartment)
                              Text(
                                labelForAccountType(asset.accountType),
                                style: TextStyle(
                                  color: deptColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            if ((asset.locationNote ?? '').isNotEmpty)
                              Text(
                                asset.locationNote!,
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
