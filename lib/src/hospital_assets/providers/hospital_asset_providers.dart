import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../models/hospital_asset_models.dart';
import '../services/hospital_assets_api_service.dart';

final hospitalAssetsApiProvider = Provider<HospitalAssetsApiService>(
  (ref) => HospitalAssetsApiService(),
);

final hospitalAssetAccessProvider = FutureProvider<HospitalAssetAccessMe?>((
  ref,
) async {
  final staff = ref.watch(authProvider).staff;
  if (staff == null) return null;
  return ref.read(hospitalAssetsApiProvider).me();
});
