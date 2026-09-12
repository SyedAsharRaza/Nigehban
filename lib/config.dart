/// App-wide constants. The ONLY thing you should need to change before a demo is [defaultBaseUrl].
///
/// The backend URL can also be changed at runtime from the Settings screen
/// (long-press the Nigehban title on the home screen), so you never need a
/// rebuild to switch between Vercel and the laptop-on-hotspot fallback.
class AppConfig {
  AppConfig._();

  /// Deployed backend (Vercel). Fallback on demo day: `http://LAPTOP-IP:3000`
  static const String defaultBaseUrl = 'https://social-nova-backend.vercel.app';

  /// Android emulator reaching a backend on the same PC.
  static const String emulatorLocalUrl = 'http://10.0.2.2:3000';

  static const Duration checkTimeout = Duration(seconds: 45);
  static const Duration healthTimeout = Duration(seconds: 6);

  /// Photo compression before upload (keeps requests well under Vercel's 4.5 MB body limit).
  static const int imageMaxWidth = 1600;
  static const int imageQuality = 70;

  /// Speech-to-text locale preference order.
  static const List<String> sttLocales = ['ur_PK', 'ur-PK', 'en_PK', 'en-PK', 'en_IN', 'en_US'];

  /// Text-to-speech locale preference order for Urdu.
  static const List<String> ttsUrduLocales = ['ur-PK', 'ur-IN', 'ur'];
  static const String ttsEnglishLocale = 'en-US';
}
