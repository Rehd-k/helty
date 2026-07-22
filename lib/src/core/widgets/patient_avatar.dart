import 'package:flutter/material.dart';

import '../utils/patient_initials.dart';
import '../../paitients/patient_model.dart';

/// Circular patient profile photo with initials fallback (see docs/frontend-patient-avatar.md).
class PatientAvatar extends StatelessWidget {
  const PatientAvatar({
    super.key,
    this.avatarUrl,
    this.firstName,
    this.surname,
    this.displayName,
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
      displayName: patient.displayName,
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
  final String? displayName;
  final double size;
  final DateTime? updatedAt;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final FontWeight? fontWeight;

  String get _initials => patientInitials(
        firstName: firstName,
        surname: surname,
        displayName: displayName,
      );

  Color _bg(BuildContext context) =>
      backgroundColor ??
      Theme.of(context).colorScheme.primary.withValues(alpha: 0.12);

  String? get _imageUrl {
    final resolved = resolvePatientAvatarUrl(avatarUrl);
    if (resolved == null) return null;
    if (updatedAt == null) return resolved;
    final sep = resolved.contains('?') ? '&' : '?';
    return '$resolved${sep}v=${updatedAt!.millisecondsSinceEpoch}';
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
            return _loadingPlaceholder(context);
          },
        ),
      );
    }
    return _initialsFallback(context);
  }

  Widget _loadingPlaceholder(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _bg(context),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _initialsFallback(BuildContext context) {
    final fg = foregroundColor ?? Theme.of(context).colorScheme.primary;

    return Semantics(
      label: _initials,
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: _bg(context),
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
