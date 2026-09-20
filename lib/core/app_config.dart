/// Global application configuration.
class AppConfig {
  AppConfig._();

  /// Base URL of the CRM backend.
  ///
  /// Production endpoint for BizForce CRM. All API requests in [ApiService]
  /// start from this value. This endpoint is deliberately not user-editable.
  static const String apiBaseUrl = 'https://bizforce-crm.online/api';

  static const String appName = 'BizForce CRM';
  static const String appVersion = '1.0.0';

  /// Human display name derived from an email, a safe fallback while the profile loads.
  static String deriveDisplayName(String email) {
    final at = email.indexOf('@');
    final raw = at > 0 ? email.substring(0, at) : email;
    final parts =
        raw.replaceAll(RegExp(r'[._\-+]'), ' ').trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'User';
    final capitalized = parts
        .map((p) => p.isNotEmpty ? p[0].toUpperCase() + p.substring(1) : p)
        .join(' ');
    return capitalized;
  }
}
