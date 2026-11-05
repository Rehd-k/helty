import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/admin_audit_service.dart';

final adminAuditServiceProvider = Provider<AdminAuditService>(
  (ref) => AdminAuditService(),
);
