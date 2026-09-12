import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../models/verdict.dart';
import '../services/prefs.dart';
import '../services/speech_service.dart';
import '../strings.dart';
import '../widgets/big_button.dart';
import 'guardian_screen.dart';

/// The whole screen IS the verdict: green / amber / red, one big icon, one big
/// word, and the explanation spoken aloud. Everything else is secondary.
class ResultScreen extends StatefulWidget {
  final Verdict verdict;
  final String originalText;
  const ResultScreen({super.key, required this.verdict, required this.originalText});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final _speech = SpeechService.instance;
  bool _showRead = false;

  Verdict get v => widget.verdict;

  Color get _color {
    switch (v.level) {
      case VerdictLevel.safe:
        return NColors.safe;
      case VerdictLevel.caution:
        return NColors.caution;
      case VerdictLevel.danger:
        return NColors.danger;
    }
  }

  IconData get _icon {
    switch (v.level) {
      case VerdictLevel.safe:
        return Icons.check_circle_rounded;
      case VerdictLevel.caution:
        return Icons.error_rounded;
      case VerdictLevel.danger:
        return Icons.dangerous_rounded;
    }
  }

  String get _title {
    switch (v.level) {
      case VerdictLevel.safe:
        return S.t('verdict_safe');
      case VerdictLevel.caution:
        return S.t('verdict_caution');
      case VerdictLevel.danger:
        return S.t('verdict_danger');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakAll());
  }

  String _titleIn(String lang) {
    final key = switch (v.level) {
      VerdictLevel.safe => 'verdict_safe',
      VerdictLevel.caution => 'verdict_caution',
      VerdictLevel.danger => 'verdict_danger',
    };
    return lang == 'ur' ? S.ur(key) : S.en(key);
  }

  /// Speaks: title, explanation, (media note if suspicious), advice — in the user's language.
  Future<void> _speakAll() async {
    final en = <String>[
      _titleIn('en'),
      v.voiceExplanation,
      if (v.authenticity != null && v.authenticity!.suspicious) v.authenticity!.note,
      if (v.advice.isNotEmpty) v.advice,
    ];
    final ur = <String>[
      _titleIn('ur'),
      v.voiceExplanationUr.isNotEmpty ? v.voiceExplanationUr : v.voiceExplanation,
      if (v.adviceUr.isNotEmpty) v.adviceUr else if (v.advice.isNotEmpty) v.advice,
    ];
    await _speech.say(en: en.join('. '), ur: ur.join('۔ '));
  }

  Future<void> _tellGuardian() async {
    var phone = Prefs.guardianPhone;
    if (phone.isEmpty) {
      await _speech.say(en: S.en('guardian_missing'), ur: S.ur('guardian_missing'));
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GuardianScreen()));
      phone = Prefs.guardianPhone;
      if (phone.isEmpty) return;
    }
    final snippet = (widget.originalText.isNotEmpty ? widget.originalText : v.extractedText).replaceAll('\n', ' ');
    final short = snippet.length > 160 ? '${snippet.substring(0, 160)}…' : snippet;
    final reason = v.reasons.isNotEmpty ? v.reasons.join(', ') : v.voiceExplanation;
    final level = v.isDanger ? '🛑 SCAM' : '⚠️ SUSPICIOUS';
    final msg = '$level — Nigehban alert\n\n'
        'I received this message and Nigehban says it may be a scam:\n"$short"\n\n'
        'Reason: $reason\n'
        'Please call me before I do anything.\n\n'
        '(نگہبان: یہ پیغام دھوکا لگتا ہے۔ مہربانی کر کے مجھے کال کریں۔)';
    final intl = _toIntl(phone);
    final uri = Uri.parse('https://wa.me/$intl?text=${Uri.encodeComponent(msg)}');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) throw Exception('launch failed');
    } catch (_) {
      // Fallback: plain SMS
      try {
        await launchUrl(Uri.parse('sms:$phone?body=${Uri.encodeComponent(msg)}'));
      } catch (_) {
        _speech.say(en: S.en('no_whatsapp'), ur: S.ur('no_whatsapp'));
      }
    }
  }

  /// 03001234567 -> 923001234567 ; +92… -> 92… ; anything else left as digits.
  static String _toIntl(String raw) {
    var d = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (d.startsWith('+')) d = d.substring(1);
    if (d.startsWith('00')) d = d.substring(2);
    if (d.startsWith('0') && d.length == 11) d = '92${d.substring(1)}';
    return d;
  }

  @override
  Widget build(BuildContext context) {
    final lang = Prefs.lang;
    final ur = lang == 'ur';
    final dir = ur ? TextDirection.rtl : TextDirection.ltr;
    final showGuardian = !v.isSafe;
    return Scaffold(
      backgroundColor: _color,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            _speech.stopSpeaking();
                            Navigator.of(context).popUntil((r) => r.isFirst);
                          },
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 32),
                        ),
                        const Spacer(),
                        if (v.offline)
                          _pill(Icons.wifi_off_rounded, S.t('offline_banner'))
                        else
                          _pill(Icons.verified_rounded, '${v.confidence}%'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Icon(_icon, size: 150, color: Colors.white),
                    const SizedBox(height: 8),
                    Text(_title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, height: 1.1)),
                    const SizedBox(height: 14),
                    Text(
                      v.explanationFor(lang),
                      textAlign: TextAlign.center,
                      textDirection: dir,
                      style: const TextStyle(color: Colors.white, fontSize: 24, height: 1.45, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 18),
                    if (v.radarCount > 1 || v.categoryReportsThisWeek > 1)
                      _card(
                        icon: Icons.radar_rounded,
                        title: v.radarCount > 1 ? S.t('radar_one') : '${v.categoryReportsThisWeek} ${S.t('radar_many')}',
                        body: v.radarCount > 1 ? '×${v.radarCount}' : null,
                        dir: dir,
                      ),
                    if (v.reasons.isNotEmpty)
                      _card(icon: Icons.help_outline_rounded, title: S.t('reasons'), body: v.reasons.map((r) => '• $r').join('\n'), dir: TextDirection.ltr),
                    if (v.adviceFor(lang).isNotEmpty) _card(icon: Icons.directions_walk_rounded, title: S.t('advice'), body: v.adviceFor(lang), dir: dir),
                    if (v.authenticity != null && v.authenticity!.checked)
                      _card(
                        icon: v.authenticity!.kind == 'audio' ? Icons.graphic_eq_rounded : Icons.image_search_rounded,
                        title: S.t('media_note'),
                        body: '${v.authenticity!.note}${v.authenticity!.suspicious ? '  (${v.authenticity!.confidence}%)' : ''}',
                        dir: TextDirection.ltr,
                      ),
                    if (v.lessonFor(lang).isNotEmpty) _card(icon: Icons.lightbulb_rounded, title: S.t('lesson'), body: v.lessonFor(lang), dir: dir),
                    if (v.extractedText.isNotEmpty)
                      InkWell(
                        onTap: () => setState(() => _showRead = !_showRead),
                        child: _card(
                          icon: _showRead ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                          title: S.t('i_read'),
                          body: _showRead ? v.extractedText : (v.extractedText.length > 80 ? '${v.extractedText.substring(0, 80)}…' : v.extractedText),
                          dir: TextDirection.ltr,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Action bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.12)),
              child: Column(
                children: [
                  if (showGuardian) ...[
                    WideButton(icon: Icons.family_restroom_rounded, label: S.t('btn_tell_guardian'), color: Colors.white, foreground: _color, onTap: _tellGuardian),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: WideButton(icon: Icons.volume_up_rounded, label: S.t('btn_replay'), color: Colors.white.withValues(alpha: 0.22), onTap: _speakAll),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: WideButton(
                          icon: Icons.home_rounded,
                          label: S.t('btn_done'),
                          color: Colors.white.withValues(alpha: 0.22),
                          onTap: () {
                            _speech.stopSpeaking();
                            Navigator.of(context).popUntil((r) => r.isFirst);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _card({required IconData icon, required String title, String? body, required TextDirection dir}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(18)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                if (body != null && body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(body, textDirection: dir, style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.4)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
