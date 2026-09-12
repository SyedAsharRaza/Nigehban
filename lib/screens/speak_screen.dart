import 'package:flutter/material.dart';

import '../services/prefs.dart';
import '../services/speech_service.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// "I am listening" — speaks a one-line prompt (this is the one place speech is expected),
/// shows live words, and pops with the recognised text.
class SpeakScreen extends StatefulWidget {
  const SpeakScreen({super.key});

  @override
  State<SpeakScreen> createState() => _SpeakScreenState();
}

class _SpeakScreenState extends State<SpeakScreen> {
  final _speech = SpeechService.instance;
  String _words = '';
  bool _listening = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await _speech.say(en: S.en('speak_speak'), ur: S.ur('speak_speak'));
    if (!mounted) return;
    final ok = await _speech.listen(
      onWords: (w, isFinal) {
        if (mounted) setState(() => _words = w);
      },
      onDone: _finish,
    );
    if (!mounted) return;
    setState(() => _listening = ok);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t('speak_unavailable'))));
      Navigator.of(context).pop(null);
    }
  }

  Future<void> _finish() async {
    if (_done) return;
    _done = true;
    await _speech.stopListening();
    if (!mounted) return;
    Navigator.of(context).pop(_words.trim().isEmpty ? null : _words.trim());
  }

  @override
  void dispose() {
    _speech.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dir = Prefs.lang == 'ur' ? TextDirection.rtl : TextDirection.ltr;
    return Scaffold(
      backgroundColor: N.speak,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(children: [
            Row(children: [
              IconButton(
                onPressed: () {
                  _done = true;
                  _speech.stopListening();
                  Navigator.of(context).pop(null);
                },
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
            ]),
            const Spacer(),
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.14)),
              child: _listening ? const Motion('listening', size: 150, fallback: Icons.mic_rounded, fallbackColor: Colors.white) : const Icon(Icons.mic_rounded, size: 70, color: Colors.white),
            ),
            const SizedBox(height: 22),
            Text(_listening ? S.t('speak_title') : '…', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 96),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(18)),
              child: Text(
                _words.isEmpty ? S.t('speak_hint') : _words,
                textAlign: TextAlign.center,
                textDirection: _words.isEmpty ? dir : TextDirection.ltr,
                style: TextStyle(color: Colors.white.withValues(alpha: _words.isEmpty ? 0.75 : 1), fontSize: 18, height: 1.45),
              ),
            ),
            const Spacer(),
            PrimaryButton(label: _words.isEmpty ? S.t('btn_stop') : S.t('btn_check'), icon: _words.isEmpty ? Icons.stop_rounded : Icons.check_rounded, color: Colors.white, foreground: N.speak, onTap: _finish),
          ]),
        ),
      ),
    );
  }
}
