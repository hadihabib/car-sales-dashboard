import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const _urlKey = 'supabase_url';
  static const _keyKey = 'supabase_publishable_key';

  final String url;
  final String publishableKey;

  const AppConfig({
    required this.url,
    required this.publishableKey,
  });

  static Future<AppConfig?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final url = (prefs.getString(_urlKey) ?? '').trim();
    final key = (prefs.getString(_keyKey) ?? '').trim();

    if (url.isEmpty || key.isEmpty) return null;

    return AppConfig(url: url, publishableKey: key);
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_urlKey, url.trim());
    await prefs.setString(_keyKey, publishableKey.trim());
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_urlKey);
    await prefs.remove(_keyKey);
  }
}
