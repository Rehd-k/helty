import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/core/utils/api_decimal.dart';
import 'package:helty/src/models/auth_response.dart';
import 'package:helty/src/models/staff_model.dart';

void main() {
  test('parses billing staff login envelope', () {
    final response = AuthResponse.fromJson({
      'accessToken':
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI4MTNjNDI3Yy02MzU2LTQ5YWEtOGZmNi0wYzM2NmRkMzVjNTgiLCJzdGFmZklkIjoiODc1Njc3IiwiYWNjb3VudFR5cGUiOiJCSUxMSU5HIiwic3RhZmZSb2xlIjoiQklMTElOR19TVEFGRiIsImRlcGFydG1lbnQiOm51bGwsImRlcGFydG1lbnRIZWFkIjpmYWxzZSwiaWF0IjoxNzgxMTc0MzU3LCJleHAiOjE3ODEyNjA3NTd9.fi5foVgdf1-Y69Kc4HaEk8prXUao7yD0a58l5Mo0iQw',
      'staff': {
        'id': '813c427c-6356-49aa-8ff6-0c366dd35c58',
        'staffId': '875677',
        'firstName': 'billing',
        'lastName': 'mine',
        'departmentId': null,
        'wardId': null,
        'accountType': 'BILLING',
        'staffRole': 'BILLING_STAFF',
        'email': 'billing@test.com',
        'phone': '9878567',
        'isActive': true,
        'createdById': null,
        'updatedById': null,
        'createdAt': '2026-03-14T07:49:24.288Z',
        'createdAtLocal': '2026-03-14T08:49:24.288+01:00',
        'updatedAt': '2026-03-14T07:49:24.288Z',
        'updatedAtLocal': '2026-03-14T08:49:24.288+01:00',
        'department': null,
        'ward': null,
        'headedDepartment': null,
      },
    });

    expect(response.accessToken, isNotEmpty);
    expect(response.staff.accountType, AccountType.billing);
    expect(response.staff.staffRole, 'BILLING_STAFF');
    expect(response.staff.email, 'billing@test.com');
  });

  test('parses login after DecimalNormalizeInterceptor reshapes the map', () {
    final raw = {
      'accessToken': 'token',
      'staff': {
        'id': '813c427c-6356-49aa-8ff6-0c366dd35c58',
        'staffId': '875677',
        'firstName': 'billing',
        'lastName': 'mine',
        'accountType': 'BILLING',
        'staffRole': 'BILLING_STAFF',
        'email': 'billing@test.com',
        'phone': '9878567',
        'isActive': true,
      },
    };

    final normalized = normalizeApiDecimals(raw);
    expect(normalized, isA<Map<String, dynamic>>());

    final response = AuthResponse.fromJson(normalized as Map<String, dynamic>);
    expect(response.staff.accountType, AccountType.billing);
  });
}
