/// Non-sensitive login recall entry (password is never stored).
class SavedLogin {
  const SavedLogin({
    required this.emailOrPhone,
    required this.displayName,
    this.roleLabel,
    required this.lastUsedMs,
  });

  final String emailOrPhone;
  final String displayName;
  final String? roleLabel;
  final int lastUsedMs;

  static String normalizeKey(String emailOrPhone) =>
      emailOrPhone.trim().toLowerCase();

  String get normalizedKey => normalizeKey(emailOrPhone);

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return emailOrPhone.isNotEmpty ? emailOrPhone[0].toUpperCase() : '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Map<String, dynamic> toJson() => {
        'emailOrPhone': emailOrPhone,
        'displayName': displayName,
        if (roleLabel != null) 'roleLabel': roleLabel,
        'lastUsedMs': lastUsedMs,
      };

  factory SavedLogin.fromJson(Map<String, dynamic> json) {
    return SavedLogin(
      emailOrPhone: json['emailOrPhone'] as String,
      displayName: json['displayName'] as String,
      roleLabel: json['roleLabel'] as String?,
      lastUsedMs: json['lastUsedMs'] as int,
    );
  }
}
