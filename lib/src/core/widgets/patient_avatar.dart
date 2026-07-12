import 'package:flutter/material.dart';

import '../utils/patient_initials.dart';
import '../../paitients/patient_model.dart';

/// Circular patient profile photo with initials fallback (see docs/patient-avatar-frontend.md).
class PatientAvatar extends StatelessWidget {
  const PatientAvatar({
    super.key,
    this.avatarUrl,
    this.firstName,
    this.surname,
    required this.size,
    this.updatedAt,
    this.backgroundColor,
    this.foregroundColor,
    this.fontWeight,
  });

  factory PatientAvatar.fromPatient(
    Patient patient, {
    Key? key,
    required double size,
    Color? backgroundColor,
    Color? foregroundColor,
    FontWeight? fontWeight,
  }) {
    return PatientAvatar(
      key: key,
      avatarUrl: patient.avatarUrl,
      firstName: patient.firstName,
      surname: patient.surname,
      size: size,
      updatedAt: patient.updatedAt,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      fontWeight: fontWeight,
    );
  }

  final String? avatarUrl;
  final String? firstName;
  final String? surname;
  final double size;
  final DateTime? updatedAt;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final FontWeight? fontWeight;

  String get _initials =>
      patientInitials(firstName: firstName, surname: surname);

  String? get _imageUrl {
    if (avatarUrl == null || avatarUrl!.isEmpty) return null;
    if (updatedAt == null) return avatarUrl;
    final sep = avatarUrl!.contains('?') ? '&' : '?';
    return '$avatarUrl${sep}v=${updatedAt!.millisecondsSinceEpoch}';
  }

  @override
  Widget build(BuildContext context) {
    final url = _imageUrl;
    if (url != null) {
      return ClipOval(
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialsFallback(context),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _initialsFallback(context);
          },
        ),
      );
    }
    return _initialsFallback(context);
  }

  Widget _initialsFallback(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? cs.primary.withValues(alpha: 0.12);
    final fg = foregroundColor ?? cs.primary;

    return Semantics(
      label: _initials,
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: bg,
        child: Text(
          _initials,
          style: TextStyle(
            fontSize: size * 0.35,
            color: fg,
            fontWeight: fontWeight ?? FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
