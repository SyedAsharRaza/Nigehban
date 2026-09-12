import 'dart:async';

import 'package:flutter/material.dart';

import '../main.dart';
import '../services/prefs.dart';
import '../services/speech_service.dart';
import '../strings.dart';
import '../widgets/big_button.dart';

/// Full-screen "I am listening" with a pulsing mic. Pops with the recognised text.
class SpeakScreen extends StatefulWidget {
  const SpeakScreen({super.key});

  @override
  State<SpeakScreen> createState() => _SpeakScreenState();
}

class _SpeakScreenState extends State<SpeakScreen> with SingleTickerProviderStateMixin {
  final _speech = SpeechService.instance;
  late final AnimationController _pulse;
  String _words = '';
  bool _listening = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _start();
  }

  Future<void> _start() async {
    await _speech.say(en: S.en('speak_speak'), ur: S.ur('speak_speak'));
    if (!mounted) return;
    final ok = await _speech.listen(
      onWords: (w, isFinal) {
        if (!mounted) return;
        setState(() => _words = w);
      },
      onDone: _finish,
    );
    if (!mounted) return;
    setState(() => _listening = ok);
    if (!ok) {
      await _speech.say(en: S.en('speak_unavailable'), ur: S.ur('speak_unavailable'));
      if (mounted) Navigator.of(context).pop(null);
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
    _pulse.dispose();
    _speech.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ur = Prefs.lang == 'ur';
    return Scaffold(
      backgroundColor: NColors.speak,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () {
                    _done = true;
                    _speech.stopListening();
                    Navigator.of(context).pop(null);
                  },
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 32),
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, child) => Container(
                  width: 170 + 30 * _pulse.value,
                  height: 170 + 30 * _pulse.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.18 + 0.1 * _pulse.value),
                  ),
                  child: const Center(child: Icon(Icons.mic_rounded, size: 110, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                _listening ? S.t('speak_title') : '…',
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 110),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  _words.isEmpty ? S.t('speak_hint') : _words,
                  textAlign: TextAlign.center,
                  textDirection: ur && _words.isEmpty ? TextDirection.rtl : TextDirection.ltr,
                  style: TextStyle(color: Colors.white.withValues(alpha: _words.isEmpty ? 0.7 : 1), fontSize: 22, height: 1.4),
                ),
              ),
              const Spacer(),
              WideButton(
                icon: Icons.check_circle_rounded,
                label: _words.isEmpty ? S.t('btn_stop') : S.t('btn_check'),
                color: Colors.white,
                foreground: NColors.speak,
                onTap: _finish,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
