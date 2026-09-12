import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

/// Tiny settings store. Call [Prefs.init] once before runApp.
class Prefs {
  Prefs._();
  static late SharedPreferences _p;

  static Future<void> init() async {
    _p = await SharedPreferences.getInstance();
  }

  static const _kLang = 'lang';
  static const _kGuardian = 'guardian_phone';
  static const _kGuardianName = 'guardian_name';
  static const _kBaseUrl = 'base_url';
  static const _kOnboarded = 'onboarded';

  /// 'ur' (default) or 'en'
  static String get lang => _p.getString(_kLang) ?? 'ur';
  static Future<void> setLang(String v) => _p.setString(_kLang, v);

  static String get guardianPhone => _p.getString(_kGuardian) ?? '';
  static Future<void> setGuardianPhone(String v) => _p.setString(_kGuardian, v);

  static String get guardianName => _p.getString(_kGuardianName) ?? '';
  static Future<void> setGuardianName(String v) => _p.setString(_kGuardianName, v);

  static String get baseUrl => (_p.getString(_kBaseUrl) ?? '').trim().isEmpty ? AppConfig.defaultBaseUrl : _p.getString(_kBaseUrl)!.trim();
  static Future<void> setBaseUrl(String v) => _p.setString(_kBaseUrl, v.trim());

  static bool get onboarded => _p.getBool(_kOnboarded) ?? false;
  static Future<void> setOnboarded(bool v) => _p.setBool(_kOnboarded, v);
}
