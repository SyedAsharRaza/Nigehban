import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../config.dart';
import 'prefs.dart';

/// Voice in and voice out. Everything degrades gracefully:
/// - no Urdu voice installed -> speaks the English text instead
/// - no speech recognition -> [listen] returns false and the UI offers typing
class SpeechService {
  SpeechService._();
  static final SpeechService instance = SpeechService._();

  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();

  bool _ttsReady = false;
  bool _urduVoice = false;
  bool _sttReady = false;
  String? _sttLocale;

  bool get hasUrduVoice => _urduVoice;
  bool get sttAvailable => _sttReady;
  bool get isListening => _stt.isListening;

  Future<void> init() async {
    await _initTts();
    await _initStt();
  }

  Future<void> _initTts() async {
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setSpeechRate(0.45); // slower than default: clearer for elders
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      for (final l in AppConfig.ttsUrduLocales) {
        final ok = await _tts.isLanguageAvailable(l);
        if (ok == true) {
          _urduVoice = true;
          break;
        }
      }
      _ttsReady = true;
    } catch (_) {
      _ttsReady = false;
    }
  }

  Future<void> _initStt() async {
    try {
      _sttReady = await _stt.initialize(
        onError: (SpeechRecognitionError e) {},
        onStatus: (String s) {},
        debugLogging: false,
      );
      if (_sttReady) {
        final locales = await _stt.locales();
        final ids = locales.map((l) => l.localeId).toList();
        for (final want in AppConfig.sttLocales) {
          final found = ids.firstWhere(
            (id) => id.toLowerCase().replaceAll('-', '_') == want.toLowerCase().replaceAll('-', '_'),
            orElse: () => '',
          );
          if (found.isNotEmpty) {
            _sttLocale = found;
            break;
          }
        }
      }
    } catch (_) {
      _sttReady = false;
    }
  }

  /// Speak [ur] if the user's language is Urdu AND an Urdu voice exists, else [en].
  /// Never throws; returns when speech finishes (or immediately if TTS is unavailable).
  Future<void> say({required String en, String? ur}) async {
    if (!_ttsReady) return;
    final wantUr = Prefs.lang == 'ur' && (ur ?? '').trim().isNotEmpty;
    final useUr = wantUr && _urduVoice;
    final text = useUr ? ur!.trim() : en.trim();
    if (text.isEmpty) return;
    try {
      await _tts.stop();
      if (useUr) {
        for (final l in AppConfig.ttsUrduLocales) {
          if (await _tts.isLanguageAvailable(l) == true) {
            await _tts.setLanguage(l);
            break;
          }
        }
      } else {
        await _tts.setLanguage(AppConfig.ttsEnglishLocale);
      }
      await _tts.speak(text);
    } catch (_) {
      // TTS failure must never break the flow.
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  /// Start listening. [onWords] gets partial + final text; [onDone] fires when
  /// listening ends for any reason. Returns false if recognition is unavailable.
  Future<bool> listen({
    required void Function(String words, bool isFinal) onWords,
    required void Function() onDone,
  }) async {
    if (!_sttReady) return false;
    try {
      await _tts.stop();
      await _stt.listen(
        onResult: (SpeechRecognitionResult r) {
          onWords(r.recognizedWords, r.finalResult);
          if (r.finalResult) onDone();
        },
        listenOptions: SpeechListenOptions(
          localeId: _sttLocale,
          listenFor: const Duration(seconds: 40),
          pauseFor: const Duration(seconds: 4),
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> stopListening() async {
    try {
      if (_stt.isListening) await _stt.stop();
    } catch (_) {}
  }
}
