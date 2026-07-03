import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String _read(String key) {
    try {
      return dotenv.env[key]?.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Normalizes the project URL to `https://PROJECT_REF.supabase.co`.
  /// The Supabase SDK adds `/auth/v1`, `/rest/v1`, etc. automatically —
  /// including those in `.env` causes "Invalid path specified in request URL".
  static String _normalizeUrl(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return value;

    // Strip trailing slashes and common mistaken paths copied from the dashboard.
    value = value.replaceAll(RegExp(r'/+$'), '');
    for (final suffix in ['/auth/v1', '/rest/v1', '/storage/v1', '/graphql/v1']) {
      if (value.endsWith(suffix)) {
        value = value.substring(0, value.length - suffix.length);
        value = value.replaceAll(RegExp(r'/+$'), '');
      }
    }

    return value;
  }

  static String get url => _normalizeUrl(_read('SUPABASE_URL'));

  static String get anonKey => _read('SUPABASE_ANON_KEY');

  static bool get isConfigured {
    if (url.isEmpty || anonKey.isEmpty) return false;
    if (url.contains('YOUR_PROJECT')) return false;
    if (anonKey.contains('YOUR_ANON')) return false;
    if (!url.startsWith('https://') || !url.contains('.supabase.co')) {
      return false;
    }
    return true;
  }
}
