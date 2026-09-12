import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/verdict.dart';
import '../services/prefs.dart';
import '../services/speech_service.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import 'guardian_screen.dart';

/// Coloured header band carries the verdict (icon + one line); details live in calm cards below.
/// The verdict is spoken once on open (if voice is on) and can be replayed.
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

  Color get _color => switch (v.level) { VerdictLevel.safe => N.safe, VerdictLevel.caution => N.caution, VerdictLevel.danger => N.danger };
  Color get _soft => switch (v.level) { VerdictLevel.safe => N.safeSoft, VerdictLevel.caution => N.cautionSoft, VerdictLevel.danger => N.dangerSoft };
  String get _motion => switch (v.level) { VerdictLevel.safe => 'safe', VerdictLevel.caution => 'caution', VerdictLevel.danger => 'danger' };
  IconData get _icon => switch (v.level) { VerdictLevel.safe => Icons.check_circle_rounded, VerdictLevel.caution => Icons.error_rounded, VerdictLevel.danger => Icons.dangerous_rounded };
  String _titleIn(String lang) {
    final key = switch (v.level) { VerdictLevel.safe => 'verdict_safe', VerdictLevel.caution => 'verdict_caution', VerdictLevel.danger => 'verdict_danger' };
    return lang == 'ur' ? S.ur(key) : S.en(key);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakAll());
  }

  Future<void> _speakAll({bool force = false}) async {
    final en = [_titleIn('en'), v.voiceExplanation, if (v.authenticity?.suspicious == true) v.authenticity!.note, if (v.advice.isNotEmpty) v.advice];
    final ur = [_titleIn('ur'), v.voiceExplanationUr.isNotEmpty ? v.voiceExplanationUr : v.voiceExplanation, if (v.adviceUr.isNotEmpty) v.adviceUr else if (v.advice.isNotEmpty) v.advice];
    await _speech.say(en: en.join('. '), ur: ur.join('۔ '), force: force);
  }

  Future<void> _tellGuardian() async {
    var phone = Prefs.guardianPhone;
    if (phone.isEmpty) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GuardianScreen()));
      phone = Prefs.guardianPhone;
      if (phone.isEmpty) return;
    }
    final snippet = (widget.originalText.isNotEmpty ? widget.originalText : v.extractedText).replaceAll('\n', ' ');
    final short = snippet.length > 160 ? '${snippet.substring(0, 160)}…' : snippet;
    final reason = v.reasons.isNotEmpty ? v.reasons.join(', ') : v.voiceExplanation;
    final level = v.isDanger ? '🛑 SCAM' : '⚠️ SUSPICIOUS';
    final msg = '$level — Nigehban alert\n\nI received this and Nigehban says it may be a scam:\n"$short"\n\nReason: $reason\nPlease call me before I do anything.\n\n(نگہبان: یہ پیغام دھوکا لگتا ہے۔ مہربانی کر کے مجھے کال کریں۔)';
    final uri = Uri.parse('https://wa.me/${_toIntl(phone)}?text=${Uri.encodeComponent(msg)}');
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) throw Exception('launch failed');
    } catch (_) {
      try {
        await launchUrl(Uri.parse('sms:$phone?body=${Uri.encodeComponent(msg)}'));
      } catch (_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t('no_whatsapp'))));
      }
    }
  }

  static String _toIntl(String raw) {
    var d = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (d.startsWith('+')) d = d.substring(1);
    if (d.startsWith('00')) d = d.substring(2);
    if (d.startsWith('0') && d.length == 11) d = '92${d.substring(1)}';
    return d;
  }

  void _done() {
    _speech.stopSpeaking();
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final lang = Prefs.lang;
    final dir = lang == 'ur' ? TextDirection.rtl : TextDirection.ltr;
    final radarText = v.radarCount > 1
        ? '${S.t('radar_one')} (×${v.radarCount})'
        : v.categoryReportsThisWeek > 1
            ? '${v.categoryReportsThisWeek} ${S.t('radar_many')}'
            : null;

    return Scaffold(
      backgroundColor: N.bg,
      body: Column(children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // ---- header band
              Container(
                width: double.infinity,
                decoration: BoxDecoration(color: _color, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28))),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 16, 22),
                    child: Column(children: [
                      Row(children: [
                        IconButton(onPressed: _done, icon: const Icon(Icons.arrow_back_rounded, color: Colors.white)),
                        const Spacer(),
                        Flexible(
                          child: v.offline
                              ? Pill(icon: Icons.wifi_off_rounded, text: S.t('offline_banner'), color: Colors.white, bg: Colors.white.withValues(alpha: 0.2))
                              : Pill(icon: Icons.verified_rounded, text: '${v.confidence}% ${S.t('confidence')}', color: Colors.white, bg: Colors.white.withValues(alpha: 0.2)),
                        ),
                      ]),
                      Motion(_motion, size: 110, repeat: false, fallback: _icon, fallbackColor: Colors.white),
                      const SizedBox(height: 4),
                      Text(_titleIn(lang), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, height: 1.1)),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(v.explanationFor(lang), textAlign: TextAlign.center, textDirection: dir, style: TextStyle(color: Colors.white.withValues(alpha: 0.95), fontSize: 17, height: 1.45, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ),
                ),
              ),
              // ---- details
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (radarText != null) ...[
                InfoCard(tint: _soft, child: Row(children: [Icon(Icons.radar_rounded, color: _color), const SizedBox(width: 10), Expanded(child: Text(radarText, textDirection: dir, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)))])),
                const SizedBox(height: 10),
              ],
              if (v.reasons.isNotEmpty) ...[
                InfoCard(
                  title: S.t('reasons'),
                  icon: Icons.help_outline_rounded,
                  child: Wrap(spacing: 8, runSpacing: 8, children: v.reasons.map((r) => Pill(text: r, color: _color, bg: _soft)).toList()),
                ),
                const SizedBox(height: 10),
              ],
              if (v.adviceFor(lang).isNotEmpty) ...[
                InfoCard(title: S.t('advice'), icon: Icons.directions_walk_rounded, child: Text(v.adviceFor(lang), textDirection: dir, style: const TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w600))),
                const SizedBox(height: 10),
              ],
              if (v.authenticity?.checked == true) ...[
                InfoCard(
                  title: S.t('media_note'),
                  icon: v.authenticity!.kind == 'audio' ? Icons.graphic_eq_rounded : Icons.image_search_rounded,
                  tint: v.authenticity!.suspicious ? N.cautionSoft : null,
                  child: Text('${v.authenticity!.note}${v.authenticity!.suspicious ? '  (${v.authenticity!.confidence}%)' : ''}', style: const TextStyle(fontSize: 14.5, height: 1.45)),
                ),
                const SizedBox(height: 10),
              ],
              if (v.lessonFor(lang).isNotEmpty) ...[
                InfoCard(title: S.t('lesson'), icon: Icons.lightbulb_rounded, tint: N.brandSoft, child: Text(v.lessonFor(lang), textDirection: dir, style: const TextStyle(fontSize: 15, height: 1.5, fontWeight: FontWeight.w600, color: N.brandDark))),
                const SizedBox(height: 10),
              ],
              if (v.extractedText.isNotEmpty)
                InfoCard(
                  title: S.t('i_read'),
                  icon: _showRead ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  onTap: () => setState(() => _showRead = !_showRead),
                  child: Text(v.extractedText, maxLines: _showRead ? null : 2, overflow: _showRead ? null : TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, height: 1.45, color: N.ink2)),
                ),
                ]),
              ),
            ],
          ),
        ),

        // ---- actions
        Container(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + MediaQuery.of(context).padding.bottom),
          decoration: const BoxDecoration(color: N.surface, border: Border(top: BorderSide(color: N.line))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (!v.isSafe) ...[
              PrimaryButton(label: S.t('btn_tell_guardian'), icon: Icons.family_restroom_rounded, color: _color, onTap: _tellGuardian),
              const SizedBox(height: 8),
            ],
            Row(children: [
              Expanded(child: PrimaryButton(label: S.t('btn_replay'), icon: Icons.volume_up_rounded, color: N.brand, outlined: true, onTap: () => _speakAll(force: true))),
              const SizedBox(width: 8),
              Expanded(child: PrimaryButton(label: S.t('btn_done'), icon: Icons.home_rounded, color: N.brand, outlined: v.isSafe ? false : true, onTap: _done)),
            ]),
          ]),
        ),
      ]),
    );
  }
}
