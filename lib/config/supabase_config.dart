class SupabaseConfig {
  const SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: '',
    ),
  );

  /// Cho phép cấu hình giới hạn chỉ email sinh viên HUTECH (@hutech.edu.vn / @student.hutech.edu.vn)
  static const bool enforceHutechDomain = bool.fromEnvironment(
    'ENFORCE_HUTECH_DOMAIN',
    defaultValue: false,
  );

  static bool get isConfigured =>
      url.trim().isNotEmpty && publishableKey.trim().isNotEmpty;

  static bool isValidHutechEmail(String email) {
    final lower = email.trim().toLowerCase();
    if (!enforceHutechDomain) return true;
    return lower.endsWith('@hutech.edu.vn') ||
        lower.endsWith('@student.hutech.edu.vn');
  }
}
