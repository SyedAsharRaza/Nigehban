import 'package:flutter/material.dart';

import '../main.dart';
import '../models/verdict.dart';
import '../services/rules_engine.dart';
import '../services/speech_service.dart';
import '../strings.dart';

/// "Nigehban is checking…" — speaks a wait message, gives an instant on-device
/// hint (Layer 1) if the text looks risky, then hands the verdict to [onVerdict].
class CheckingScreen extends StatefulWidget {
  final String text;
  final String? previewNote;
  final Future<Verdict> Function() run;
  final void Function(Verdict) onVerdict;

  const CheckingScreen({
    super.key,
    required this.text,
    required this.run,
    required this.onVerdict,
    this.previewNote,
  });

  @override
  State<CheckingScreen> createState() => _CheckingScreenState();
}

class _CheckingScreenState extends State<CheckingScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _spin;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _go();
  }

  Future<void> _go() async {
    final speech = SpeechService.instance;
    final hit = RulesEngine.evaluate(widget.text);
    // Kick off the network call immediately; speak while it runs.
    final future = widget.run();
    if (hit.risky) {
      setState(() => _status = S.t('checking_hint_risky'));
      await speech.say(en: S.en('checking_hint_risky'), ur: S.ur('checking_hint_risky'));
    } else {
      setState(() => _status = S.t('checking_speak'));
      await speech.say(en: S.en('checking_speak'), ur: S.ur('checking_speak'));
    }
    final v = await future;
    if (!mounted) return;
    widget.onVerdict(v);
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NColors.brand,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RotationTransition(
                  turns: _spin,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 10),
                      gradient: SweepGradient(colors: [Colors.white.withValues(alpha: 0), Colors.white]),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Icon(Icons.shield_rounded, color: Colors.white, size: 60),
                const SizedBox(height: 12),
                Text(S.t('checking'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                Text(_status, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 19, height: 1.4)),
                if (widget.previewNote != null) ...[
                  const SizedBox(height: 10),
                  Text(widget.previewNote!, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 16)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
