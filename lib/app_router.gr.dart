// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i18;
import 'package:flutter/material.dart' as _i19;
import 'package:helty/src/paitients/patient_form_screen.dart' as _i10;
import 'package:helty/src/paitients/patient_list_screen.dart' as _i11;
import 'package:helty/src/paitients/patient_model.dart' as _i20;
import 'package:helty/src/ui/appointments/appointment_list_screen.dart' as _i4;
import 'package:helty/src/ui/auth/forgot_password_screen.dart' as _i7;
import 'package:helty/src/ui/auth/login_screen.dart' as _i9;
import 'package:helty/src/ui/auth/register_screen.dart' as _i13;
import 'package:helty/src/ui/auth/reset_password_screen.dart' as _i15;
import 'package:helty/src/ui/dashboard/dashboard_screen.dart' as _i5;
import 'package:helty/src/ui/home/home_screen.dart' as _i8;
import 'package:helty/src/ui/patients/today_patients.dart' as _i16;
import 'package:helty/src/ui/patinets_services/add_category_screen.dart' as _i1;
import 'package:helty/src/ui/patinets_services/add_department_screen.dart'
    as _i2;
import 'package:helty/src/ui/patinets_services/add_service_screen.dart' as _i3;
import 'package:helty/src/ui/patinets_services/enlist_service_screen.dart'
    as _i6;
import 'package:helty/src/ui/patinets_services/render_services.dart' as _i14;
import 'package:helty/src/ui/patinets_services/view_services.dart' as _i17;
import 'package:helty/src/ui/transactions/pending_transactions.dart' as _i12;

/// generated route for
/// [_i1.AddCategoryScreen]
class AddCategoryRoute extends _i18.PageRouteInfo<void> {
  const AddCategoryRoute({List<_i18.PageRouteInfo>? children})
    : super(AddCategoryRoute.name, initialChildren: children);

  static const String name = 'AddCategoryRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      return const _i1.AddCategoryScreen();
    },
  );
}

/// generated route for
/// [_i2.AddDepartmentScreen]
class AddDepartmentRoute extends _i18.PageRouteInfo<void> {
  const AddDepartmentRoute({List<_i18.PageRouteInfo>? children})
    : super(AddDepartmentRoute.name, initialChildren: children);

  static const String name = 'AddDepartmentRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      return const _i2.AddDepartmentScreen();
    },
  );
}

/// generated route for
/// [_i3.AddServiceScreen]
class AddServiceRoute extends _i18.PageRouteInfo<void> {
  const AddServiceRoute({List<_i18.PageRouteInfo>? children})
    : super(AddServiceRoute.name, initialChildren: children);

  static const String name = 'AddServiceRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      return const _i3.AddServiceScreen();
    },
  );
}

/// generated route for
/// [_i4.AppointmentListScreen]
class AppointmentListRoute extends _i18.PageRouteInfo<void> {
  const AppointmentListRoute({List<_i18.PageRouteInfo>? children})
    : super(AppointmentListRoute.name, initialChildren: children);

  static const String name = 'AppointmentListRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      return const _i4.AppointmentListScreen();
    },
  );
}

/// generated route for
/// [_i5.DashboardScreen]
class DashboardRoute extends _i18.PageRouteInfo<void> {
  const DashboardRoute({List<_i18.PageRouteInfo>? children})
    : super(DashboardRoute.name, initialChildren: children);

  static const String name = 'DashboardRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      return const _i5.DashboardScreen();
    },
  );
}

/// generated route for
/// [_i6.EnlistServiceScreen]
class EnlistServiceRoute extends _i18.PageRouteInfo<void> {
  const EnlistServiceRoute({List<_i18.PageRouteInfo>? children})
    : super(EnlistServiceRoute.name, initialChildren: children);

  static const String name = 'EnlistServiceRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      return const _i6.EnlistServiceScreen();
    },
  );
}

/// generated route for
/// [_i7.ForgotPasswordScreen]
class ForgotPasswordRoute extends _i18.PageRouteInfo<void> {
  const ForgotPasswordRoute({List<_i18.PageRouteInfo>? children})
    : super(ForgotPasswordRoute.name, initialChildren: children);

  static const String name = 'ForgotPasswordRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      return const _i7.ForgotPasswordScreen();
    },
  );
}

/// generated route for
/// [_i8.HomeScreen]
class HomeRoute extends _i18.PageRouteInfo<void> {
  const HomeRoute({List<_i18.PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      return const _i8.HomeScreen();
    },
  );
}

/// generated route for
/// [_i9.LoginScreen]
class LoginRoute extends _i18.PageRouteInfo<LoginRouteArgs> {
  LoginRoute({
    _i19.Key? key,
    String? redirectTo,
    List<_i18.PageRouteInfo>? children,
  }) : super(
         LoginRoute.name,
         args: LoginRouteArgs(key: key, redirectTo: redirectTo),
         rawQueryParams: {'redirectTo': redirectTo},
         initialChildren: children,
       );

  static const String name = 'LoginRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      final queryParams = data.queryParams;
      final args = data.argsAs<LoginRouteArgs>(
        orElse: () =>
            LoginRouteArgs(redirectTo: queryParams.optString('redirectTo')),
      );
      return _i9.LoginScreen(key: args.key, redirectTo: args.redirectTo);
    },
  );
}

class LoginRouteArgs {
  const LoginRouteArgs({this.key, this.redirectTo});

  final _i19.Key? key;

  final String? redirectTo;

  @override
  String toString() {
    return 'LoginRouteArgs{key: $key, redirectTo: $redirectTo}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LoginRouteArgs) return false;
    return key == other.key && redirectTo == other.redirectTo;
  }

  @override
  int get hashCode => key.hashCode ^ redirectTo.hashCode;
}

/// generated route for
/// [_i10.PatientFormScreen]
class PatientFormRoute extends _i18.PageRouteInfo<PatientFormRouteArgs> {
  PatientFormRoute({
    _i19.Key? key,
    _i20.Patient? patient,
    List<_i18.PageRouteInfo>? children,
  }) : super(
         PatientFormRoute.name,
         args: PatientFormRouteArgs(key: key, patient: patient),
         initialChildren: children,
       );

  static const String name = 'PatientFormRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PatientFormRouteArgs>(
        orElse: () => const PatientFormRouteArgs(),
      );
      return _i10.PatientFormScreen(key: args.key, patient: args.patient);
    },
  );
}

class PatientFormRouteArgs {
  const PatientFormRouteArgs({this.key, this.patient});

  final _i19.Key? key;

  final _i20.Patient? patient;

  @override
  String toString() {
    return 'PatientFormRouteArgs{key: $key, patient: $patient}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PatientFormRouteArgs) return false;
    return key == other.key && patient == other.patient;
  }

  @override
  int get hashCode => key.hashCode ^ patient.hashCode;
}

/// generated route for
/// [_i11.PatientListScreen]
class PatientListRoute extends _i18.PageRouteInfo<void> {
  const PatientListRoute({List<_i18.PageRouteInfo>? children})
    : super(PatientListRoute.name, initialChildren: children);

  static const String name = 'PatientListRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      return const _i11.PatientListScreen();
    },
  );
}

/// generated route for
/// [_i12.PendingTransactionsScreen]
class PendingTransactionsRoute extends _i18.PageRouteInfo<void> {
  const PendingTransactionsRoute({List<_i18.PageRouteInfo>? children})
    : super(PendingTransactionsRoute.name, initialChildren: children);

  static const String name = 'PendingTransactionsRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      return const _i12.PendingTransactionsScreen();
    },
  );
}

/// generated route for
/// [_i13.RegisterScreen]
class RegisterRoute extends _i18.PageRouteInfo<void> {
  const RegisterRoute({List<_i18.PageRouteInfo>? children})
    : super(RegisterRoute.name, initialChildren: children);

  static const String name = 'RegisterRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      return const _i13.RegisterScreen();
    },
  );
}

/// generated route for
/// [_i14.RenderServiceScreen]
class RenderServiceRoute extends _i18.PageRouteInfo<void> {
  const RenderServiceRoute({List<_i18.PageRouteInfo>? children})
    : super(RenderServiceRoute.name, initialChildren: children);

  static const String name = 'RenderServiceRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      return const _i14.RenderServiceScreen();
    },
  );
}

/// generated route for
/// [_i15.ResetPasswordScreen]
class ResetPasswordRoute extends _i18.PageRouteInfo<ResetPasswordRouteArgs> {
  ResetPasswordRoute({
    _i19.Key? key,
    String? token,
    List<_i18.PageRouteInfo>? children,
  }) : super(
         ResetPasswordRoute.name,
         args: ResetPasswordRouteArgs(key: key, token: token),
         rawQueryParams: {'token': token},
         initialChildren: children,
       );

  static const String name = 'ResetPasswordRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      final queryParams = data.queryParams;
      final args = data.argsAs<ResetPasswordRouteArgs>(
        orElse: () =>
            ResetPasswordRouteArgs(token: queryParams.optString('token')),
      );
      return _i15.ResetPasswordScreen(key: args.key, token: args.token);
    },
  );
}

class ResetPasswordRouteArgs {
  const ResetPasswordRouteArgs({this.key, this.token});

  final _i19.Key? key;

  final String? token;

  @override
  String toString() {
    return 'ResetPasswordRouteArgs{key: $key, token: $token}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ResetPasswordRouteArgs) return false;
    return key == other.key && token == other.token;
  }

  @override
  int get hashCode => key.hashCode ^ token.hashCode;
}

/// generated route for
/// [_i16.TodayPatientsScreen]
class TodayPatientsRoute extends _i18.PageRouteInfo<void> {
  const TodayPatientsRoute({List<_i18.PageRouteInfo>? children})
    : super(TodayPatientsRoute.name, initialChildren: children);

  static const String name = 'TodayPatientsRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      return const _i16.TodayPatientsScreen();
    },
  );
}

/// generated route for
/// [_i17.ViewServiceScreen]
class ViewServiceRoute extends _i18.PageRouteInfo<void> {
  const ViewServiceRoute({List<_i18.PageRouteInfo>? children})
    : super(ViewServiceRoute.name, initialChildren: children);

  static const String name = 'ViewServiceRoute';

  static _i18.PageInfo page = _i18.PageInfo(
    name,
    builder: (data) {
      return const _i17.ViewServiceScreen();
    },
  );
}
