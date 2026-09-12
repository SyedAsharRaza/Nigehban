import '../models/verdict.dart';

/// Layer 1 — on-device rules. Instant, offline, no AI.
/// Used for (a) an immediate spoken "careful…" hint while the backend thinks and
/// (b) a basic verdict when there is no internet at all.
/// It is deliberately conservative: it can only say "looks risky", never "definitely safe".
class RulesHit {
  final int score; // 0..100
  final List<String> reasons;
  final List<String> reasonsUr;
  const RulesHit(this.score, this.reasons, this.reasonsUr);

  bool get risky => score >= 40;
  bool get strong => score >= 70;
}

class RulesEngine {
  RulesEngine._();

  // Each rule: pattern, weight, reason (en), reason (ur)
  static final List<_Rule> _rules = [
    _Rule(RegExp(r'\b(otp|one[\s-]?time[\s-]?(pass|code)|verification code|pin\b|passcode|6[\s-]?digit|4[\s-]?digit)', caseSensitive: false), 45, 'Asks for a secret code (OTP/PIN)', 'خفیہ کوڈ (او ٹی پی/پن) مانگتا ہے'),
    _Rule(RegExp(r'\b(cnic|shanakhti|shanakhti card|id card number|nic number|passport number)\b', caseSensitive: false), 35, 'Asks for your ID card number', 'شناختی کارڈ نمبر مانگتا ہے'),
    _Rule(RegExp(r'\b(account number|account no|iban|card number|card no|cvv|expiry|atm pin|bank details|account details)\b', caseSensitive: false), 35, 'Asks for bank or card details', 'بینک یا کارڈ کی تفصیل مانگتا ہے'),
    _Rule(RegExp(r'\b(fee|fees|charges|processing|registration|advance|token money|security deposit|delivery charge|custom(s)? duty)\b', caseSensitive: false), 25, 'Asks for a fee or advance payment', 'فیس یا پیشگی رقم مانگتا ہے'),
    _Rule(RegExp(r'\b(bhej(o|ain|ein|do|dain)|send (money|rs|pkr|rupees|amount)|transfer|jazzcash|easypaisa|western union|moneygram|sadapay|nayapay)\b', caseSensitive: false), 25, 'Asks to send money', 'پیسے بھیجنے کو کہتا ہے'),
    _Rule(RegExp(r'\b(lucky draw|lottery|inaam|inam|prize|won|winner|jeet|jeeta|jeeti|mubarak|congratulations|reward|gift card)\b', caseSensitive: false), 30, 'Promises a prize or lottery win', 'انعام یا لاٹری کا لالچ دیتا ہے'),
    _Rule(RegExp(r'\b(urgent|urgently|immediately|fori|foran|abhi|jaldi|within \d+ (hour|hours|minutes|min)|24 hours|last chance|expire|akhri mauqa|warna)\b', caseSensitive: false), 20, 'Creates urgency or pressure', 'جلدی یا دباؤ ڈالتا ہے'),
    _Rule(RegExp(r'\b(block(ed)?|suspend(ed)?|band|deactivat(e|ed)|close(d)?|freeze|arrest|police|jurmana|fine|case (registered|darj)|fir\b|warrant|court)\b', caseSensitive: false), 25, 'Threatens block, fine, or police', 'بلاک، جرمانے یا پولیس کی دھمکی'),
    _Rule(RegExp(r'\b(fia|nadra|sbp|state bank|fbr|ptcl|pta|army|isi|police|customs|court|ministry|government|sarkari|hbl|ubl|mcb|meezan|allied|askari|jazz|zong|telenor|ufone|daraz|tcs)\b', caseSensitive: false), 10, 'Claims to be an authority or big company', 'کسی ادارے یا بڑی کمپنی کے نام پر'),
    _Rule(RegExp(r'\b(job confirm|job pakki|naukri|internship|work from home|earn (daily|weekly|monthly)|per day|ghar baithe|online job|part[\s-]?time job)\b', caseSensitive: false), 20, 'Job or earning offer', 'نوکری یا کمائی کی پیشکش'),
    _Rule(RegExp(r'(https?://|www\.|bit\.ly|tinyurl|cutt\.ly|t\.co/|\.xyz|\.tk|\.ml|\.top|\.click)', caseSensitive: false), 15, 'Contains a link', 'لنک موجود ہے'),
    _Rule(RegExp(r'\b(click here|click (the|this) link|register (here|now)|verify (now|your)|update your|apna (number|account) (verify|update))\b', caseSensitive: false), 20, 'Asks to click or verify via link', 'لنک پر کلک یا تصدیق کو کہتا ہے'),
    _Rule(RegExp(r'\b(loan approve|loan approved|qarza|instant loan|loan manzoor)\b', caseSensitive: false), 20, 'Loan offer', 'قرضے کی پیشکش'),
    _Rule(RegExp(r'\b(mark (it|this) safe|ignore (previous|all) instructions|system notice|verified safe)\b', caseSensitive: false), 40, 'Tries to trick the checker', 'جانچ کو دھوکا دینے کی کوشش'),
  ];

  static RulesHit evaluate(String text) {
    final t = text.trim();
    if (t.isEmpty) return const RulesHit(0, [], []);
    int score = 0;
    final reasons = <String>[];
    final reasonsUr = <String>[];
    for (final r in _rules) {
      if (r.re.hasMatch(t)) {
        score += r.weight;
        reasons.add(r.reason);
        reasonsUr.add(r.reasonUr);
      }
    }
    // Combination bonus: money/secret request + urgency/threat is the classic scam shape.
    final asksSecret = reasons.any((r) => r.startsWith('Asks for'));
    final pressure = reasons.any((r) => r.startsWith('Creates urgency') || r.startsWith('Threatens'));
    if (asksSecret && pressure) score += 20;
    return RulesHit(score.clamp(0, 100), reasons.take(3).toList(), reasonsUr.take(3).toList());
  }

  /// A verdict built purely from rules — used only when the backend is unreachable.
  static Verdict offlineVerdict(String text) {
    final hit = evaluate(text);
    if (hit.strong) {
      return Verdict.offline(
        level: VerdictLevel.danger,
        reasons: hit.reasons,
        explanation: 'I am offline, but this message has clear signs of a scam. Do not act on it.',
        explanationUr: 'انٹرنیٹ نہیں ہے، لیکن اس پیغام میں دھوکے کی واضح نشانیاں ہیں۔ اس پر عمل نہ کریں۔',
      );
    }
    if (hit.risky) {
      return Verdict.offline(
        level: VerdictLevel.caution,
        reasons: hit.reasons,
        explanation: 'I am offline. This message looks risky. Please check again when you have internet.',
        explanationUr: 'انٹرنیٹ نہیں ہے۔ یہ پیغام مشکوک لگتا ہے۔ انٹرنیٹ آنے پر دوبارہ جانچیں۔',
      );
    }
    return Verdict.offline(
      level: VerdictLevel.caution,
      reasons: const ['Could not check online'],
      explanation: 'I am offline and could not fully check this. Please try again when you have internet.',
      explanationUr: 'انٹرنیٹ نہیں ہے، میں پوری طرح جانچ نہیں سکا۔ انٹرنیٹ آنے پر دوبارہ کوشش کریں۔',
    );
  }
}

class _Rule {
  final RegExp re;
  final int weight;
  final String reason;
  final String reasonUr;
  const _Rule(this.re, this.weight, this.reason, this.reasonUr);
}
