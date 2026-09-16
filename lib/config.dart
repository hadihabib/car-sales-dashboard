class AppConfig {
  static const String supabaseUrl =
      'https://lrophfpjnsuutvqwkabx.supabase.co';

  static const String supabaseAnonKey =
      'sb_secret_2L_tGTLh1bv_ABkVibR4iQ_J1Tgjz4F';

  static bool get isConfigured =>
      supabaseUrl.startsWith('https://') &&
      supabaseUrl.contains('.supabase.co') &&
      supabaseAnonKey.isNotEmpty;
}
