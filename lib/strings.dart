import 'services/prefs.dart';

/// All UI text in both languages. `S.t('key')` returns the current language.
/// Keep every string SHORT — it is read aloud and shown at large font sizes.
class S {
  S._();

  static const Map<String, Map<String, String>> _m = {
    'app_name': {'en': 'Nigehban', 'ur': 'نگہبان'},
    'tagline': {'en': 'Your digital shield', 'ur': 'آپ کی ڈیجیٹل ڈھال'},
    'home_speak': {'en': 'What do you want to check? Paste a message, speak, take a photo, or pick a voice note.', 'ur': 'آپ کیا جانچنا چاہتے ہیں؟ پیغام چسپاں کریں، بولیں، تصویر لیں، یا وائس نوٹ چنیں۔'},
    'btn_paste': {'en': 'Message', 'ur': 'پیغام'},
    'btn_speak': {'en': 'Speak', 'ur': 'بولیں'},
    'btn_photo': {'en': 'Photo', 'ur': 'تصویر'},
    'btn_voice': {'en': 'Voice note', 'ur': 'وائس نوٹ'},
    'btn_guardian': {'en': 'Guardian', 'ur': 'محافظ'},
    'btn_check': {'en': 'Check', 'ur': 'جانچیں'},
    'btn_paste_clip': {'en': 'Paste', 'ur': 'چسپاں کریں'},
    'btn_clear': {'en': 'Clear', 'ur': 'صاف کریں'},
    'btn_camera': {'en': 'Camera', 'ur': 'کیمرہ'},
    'btn_gallery': {'en': 'Gallery', 'ur': 'گیلری'},
    'btn_replay': {'en': 'Hear again', 'ur': 'دوبارہ سنیں'},
    'btn_tell_guardian': {'en': 'Tell my guardian', 'ur': 'محافظ کو بتائیں'},
    'btn_done': {'en': 'Done', 'ur': 'ہو گیا'},
    'btn_retry': {'en': 'Try again', 'ur': 'دوبارہ کوشش'},
    'btn_save': {'en': 'Save', 'ur': 'محفوظ کریں'},
    'btn_skip': {'en': 'Skip', 'ur': 'چھوڑیں'},
    'btn_stop': {'en': 'Stop', 'ur': 'رکیں'},
    'paste_hint': {'en': 'Type or paste the message here', 'ur': 'پیغام یہاں لکھیں یا چسپاں کریں'},
    'paste_speak': {'en': 'Paste the message, then press Check.', 'ur': 'پیغام چسپاں کریں، پھر جانچیں دبائیں۔'},
    'speak_title': {'en': 'I am listening…', 'ur': 'میں سن رہا ہوں…'},
    'speak_speak': {'en': 'Tell me what happened. For example: someone called from the bank and asked for a code.', 'ur': 'مجھے بتائیں کیا ہوا۔ مثلاً: بینک سے کال آئی اور کوڈ مانگا۔'},
    'speak_hint': {'en': 'Say what the message or call said', 'ur': 'بتائیں پیغام یا کال میں کیا کہا گیا'},
    'speak_unavailable': {'en': 'Voice input is not available on this phone. Please type instead.', 'ur': 'اس فون پر آواز سے لکھنا دستیاب نہیں۔ براہ کرم ٹائپ کریں۔'},
    'photo_speak': {'en': 'Take a photo of the message, or choose a screenshot.', 'ur': 'پیغام کی تصویر لیں یا اسکرین شاٹ چنیں۔'},
    'voice_speak': {'en': 'Choose the voice note you received.', 'ur': 'وہ وائس نوٹ چنیں جو آپ کو ملا۔'},
    'checking': {'en': 'Nigehban is checking…', 'ur': 'نگہبان جانچ رہا ہے…'},
    'checking_speak': {'en': 'Please wait, I am checking this for you.', 'ur': 'ذرا رکیں، میں آپ کے لیے جانچ رہا ہوں۔'},
    'checking_hint_risky': {'en': 'Careful, this looks like it asks for money or a code. Let me check properly.', 'ur': 'خیال رکھیں، یہ پیسے یا کوڈ مانگتا لگتا ہے۔ میں ٹھیک سے جانچتا ہوں۔'},
    'verdict_safe': {'en': 'Looks safe', 'ur': 'محفوظ لگتا ہے'},
    'verdict_caution': {'en': 'Be careful', 'ur': 'خیال رکھیں'},
    'verdict_danger': {'en': 'Scam! Stop', 'ur': 'دھوکا! رک جائیں'},
    'i_read': {'en': 'What I read', 'ur': 'میں نے یہ پڑھا'},
    'reasons': {'en': 'Why', 'ur': 'کیوں'},
    'advice': {'en': 'What to do', 'ur': 'کیا کریں'},
    'lesson': {'en': 'Remember', 'ur': 'یاد رکھیں'},
    'media_note': {'en': 'About the picture / voice', 'ur': 'تصویر / آواز کے بارے میں'},
    'radar_one': {'en': 'Others reported this scam too', 'ur': 'دوسروں نے بھی یہ دھوکا رپورٹ کیا'},
    'radar_many': {'en': 'reports of this kind this week', 'ur': 'اس طرح کی رپورٹیں اس ہفتے'},
    'offline_banner': {'en': 'No internet — basic check only', 'ur': 'انٹرنیٹ نہیں — صرف بنیادی جانچ'},
    'guardian_title': {'en': 'Your guardian', 'ur': 'آپ کا محافظ'},
    'guardian_speak': {'en': 'Choose a family member. If I find a scam, one tap will warn them on WhatsApp.', 'ur': 'گھر کا کوئی فرد چنیں۔ دھوکا ملنے پر ایک ٹچ سے انہیں واٹس ایپ پر خبر ہو گی۔'},
    'guardian_name': {'en': 'Name (e.g. Ahmed)', 'ur': 'نام (مثلاً احمد)'},
    'guardian_phone': {'en': 'WhatsApp number (e.g. 03001234567)', 'ur': 'واٹس ایپ نمبر (مثلاً 03001234567)'},
    'guardian_saved': {'en': 'Saved. I will warn them if needed.', 'ur': 'محفوظ ہو گیا۔ ضرورت پڑی تو میں انہیں خبر دوں گا۔'},
    'guardian_missing': {'en': 'First choose a guardian.', 'ur': 'پہلے محافظ چنیں۔'},
    'no_whatsapp': {'en': 'Could not open WhatsApp.', 'ur': 'واٹس ایپ نہیں کھل سکا۔'},
    'server_ok': {'en': 'Connected', 'ur': 'جڑا ہوا'},
    'server_down': {'en': 'Not connected', 'ur': 'جڑا نہیں'},
    'settings_title': {'en': 'Settings', 'ur': 'ترتیبات'},
    'settings_url': {'en': 'Backend URL', 'ur': 'بیک اینڈ یو آر ایل'},
    'language': {'en': 'اردو', 'ur': 'English'},
    'nothing_selected': {'en': 'Nothing was selected.', 'ur': 'کچھ منتخب نہیں ہوا۔'},
    'empty_text': {'en': 'Please paste or type a message first.', 'ur': 'پہلے پیغام چسپاں کریں یا لکھیں۔'},
  };

  static String t(String key) {
    final e = _m[key];
    if (e == null) return key;
    return e[Prefs.lang] ?? e['en'] ?? key;
  }

  static String en(String key) => _m[key]?['en'] ?? key;
  static String ur(String key) => _m[key]?['ur'] ?? _m[key]?['en'] ?? key;
}
