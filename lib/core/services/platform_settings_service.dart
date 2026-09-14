import '../constants/api_endpoints.dart';
import '../network/api_client.dart';

/// Platform-wide values served by `GET /api/settings` (public, no auth).
///
/// The app previously hardcoded the support phone and email in three places
/// and assumed `₹` everywhere, so changing any of them meant shipping a build.
/// It also ignored `codEnabled` / `onlineEnabled`, which is how a customer
/// could pick an online method the server would then refuse with a 503.
class PlatformSettings {
  final String appName;
  final String supportEmail;
  final String supportPhone;
  final String currencySymbol;
  final bool codEnabled;
  final bool onlineEnabled;

  const PlatformSettings({
    this.appName = 'SunGguard',
    this.supportEmail = 'support@sungguard.com',
    this.supportPhone = '+91 98765 43210',
    this.currencySymbol = '₹',
    this.codEnabled = true,
    this.onlineEnabled = true,
  });

  static PlatformSettings fromJson(dynamic res) {
    const fallback = PlatformSettings();
    final data = (res is Map) ? (res['result'] ?? res['data'] ?? res) : null;
    if (data is! Map) return fallback;

    String pick(String key, String fallbackValue) {
      final value = data[key]?.toString().trim() ?? '';
      return value.isEmpty ? fallbackValue : value;
    }

    return PlatformSettings(
      appName: pick('appName', fallback.appName),
      supportEmail: pick('supportEmail', fallback.supportEmail),
      supportPhone: pick('supportPhone', fallback.supportPhone),
      currencySymbol: pick('currencySymbol', fallback.currencySymbol),
      // Absent means "not restricted"; only an explicit false disables.
      codEnabled: data['codEnabled'] != false,
      onlineEnabled: data['onlineEnabled'] != false,
    );
  }
}

/// Loads and caches platform settings for the lifetime of the process.
class PlatformSettingsService {
  static final PlatformSettingsService _instance =
      PlatformSettingsService._internal();

  factory PlatformSettingsService() => _instance;

  PlatformSettingsService._internal();

  PlatformSettings _current = const PlatformSettings();
  bool _loaded = false;

  /// Last known values. Safe to read before [load] completes — it starts as
  /// the same defaults the app used to hardcode.
  PlatformSettings get current => _current;

  Future<PlatformSettings> load({bool force = false}) async {
    if (_loaded && !force) return _current;
    try {
      final res = await ApiClient.createDefault().get(ApiEndpoints.settings);
      _current = PlatformSettings.fromJson(res);
      _loaded = true;
    } catch (_) {
      // Defaults stand; the app must stay usable if settings are unreachable.
    }
    return _current;
  }
}
