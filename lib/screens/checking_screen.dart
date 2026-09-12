import 'package:flutter/material.dart';

import '../models/verdict.dart';
import '../services/prefs.dart';
import '../services/rules_engine.dart';
import '../services/speech_service.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// "Nigehban is checking…" — Lottie scan, an instant on-device hint (Layer 1) if the text looks risky,
/// then hands the verdict to [onVerdict]. Speech here is short and only when there is something to say.
class CheckingScreen extends StatefulWidget {
  final String text;
  final String? previewNote;
  final Future<Verdict> Function() run;
  final void Function(Verdict) onVerdict;

  const CheckingScreen({super.key, required this.text, required this.run, required this.onVerdict, this.previewNote});

  @override
  State<CheckingScreen> createState() => _CheckingScreenState();
}

class _CheckingScreenState extends State<CheckingScreen> {
  String _status = '';
  bool _risky = false;

  @override
  void initState() {
    super.initState();
    _go();
  }

  Future<void> _go() async {
    final hit = RulesEngine.evaluate(widget.text);
    final future = widget.run(); // start network immediately
    if (hit.risky) {
      setState(() {
        _risky = true;
        _status = S.t('checking_hint_risky');
      });
      await SpeechService.instance.say(en: S.en('checking_hint_risky'), ur: S.ur('checking_hint_risky'));
    } else {
      setState(() => _status = S.t('checking_speak'));
    }
    final v = await future;
    if (!mounted) return;
    widget.onVerdict(v);
  }

  @override
  Widget build(BuildContext context) {
    final dir = Prefs.lang == 'ur' ? TextDirection.rtl : TextDirection.ltr;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Motion('scan', size: 170),
              const SizedBox(height: 24),
              Text(S.t('checking'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: N.ink)),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Container(
                  key: ValueKey(_status),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: _risky ? N.cautionSoft : N.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: _risky ? N.caution.withValues(alpha: 0.4) : N.line)),
                  child: Text(
                    (_risky ? '⚠️ ' : '') + _status,
                    textAlign: TextAlign.center,
                    textDirection: dir,
                    style: TextStyle(fontSize: 14.5, height: 1.4, color: _risky ? const Color(0xFF7A5200) : N.ink2),
                  ),
                ),
              ),
              if (widget.previewNote != null) ...[
                const SizedBox(height: 16),
                Pill(icon: Icons.attach_file_rounded, text: widget.previewNote!, color: N.ink2),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
