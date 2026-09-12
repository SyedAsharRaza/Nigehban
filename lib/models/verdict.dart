/// Mirrors the backend response shape exactly (see backend README).
/// Every field is null-safe: a missing/invalid field never crashes the UI.
enum VerdictLevel { safe, caution, danger }

VerdictLevel _levelFrom(dynamic v) {
  switch ((v ?? '').toString()) {
    case 'safe':
      return VerdictLevel.safe;
    case 'danger':
      return VerdictLevel.danger;
    default:
      return VerdictLevel.caution;
  }
}

class Authenticity {
  final String kind; // image | audio
  final bool checked;
  final String note;
  final int confidence;
  final bool suspicious;

  const Authenticity({
    required this.kind,
    required this.checked,
    required this.note,
    required this.confidence,
    required this.suspicious,
  });

  static Authenticity? fromJson(dynamic j) {
    if (j is! Map) return null;
    return Authenticity(
      kind: (j['kind'] ?? '').toString(),
      checked: j['checked'] == true,
      note: (j['note'] ?? '').toString(),
      confidence: _toInt(j['confidence']),
      suspicious: j['suspicious'] == true,
    );
  }
}

class LinkResult {
  final String url;
  final String finalUrl;
  final bool flagged;
  final List<String> reasons;
  const LinkResult({required this.url, required this.finalUrl, required this.flagged, required this.reasons});
}

int _toInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.round();
  return int.tryParse((v ?? '').toString()) ?? 0;
}

List<String> _toStrList(dynamic v) {
  if (v is! List) return const [];
  return v.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
}

class Verdict {
  final VerdictLevel level;
  final int confidence;
  final String category;
  final String voiceExplanation;
  final String voiceExplanationUr;
  final List<String> reasons;
  final String advice;
  final String adviceUr;
  final String lesson;
  final String lessonUr;
  final String extractedText;
  final Authenticity? authenticity;
  final bool linkFlagged;
  final List<LinkResult> links;
  final int radarCount;
  final int categoryReportsThisWeek;
  final String requestId;
  final String? model;
  final String? error;
  final int totalMs;

  /// True when this verdict was produced on-device (no network) by the rules engine.
  final bool offline;

  const Verdict({
    required this.level,
    required this.confidence,
    required this.category,
    required this.voiceExplanation,
    required this.voiceExplanationUr,
    required this.reasons,
    required this.advice,
    required this.adviceUr,
    required this.lesson,
    required this.lessonUr,
    this.extractedText = '',
    this.authenticity,
    this.linkFlagged = false,
    this.links = const [],
    this.radarCount = 0,
    this.categoryReportsThisWeek = 0,
    this.requestId = '',
    this.model,
    this.error,
    this.totalMs = 0,
    this.offline = false,
  });

  factory Verdict.fromJson(Map<String, dynamic> j) {
    final lc = j['link_check'];
    final links = <LinkResult>[];
    if (lc is Map && lc['urls'] is List) {
      for (final u in (lc['urls'] as List)) {
        if (u is Map) {
          links.add(LinkResult(
            url: (u['url'] ?? '').toString(),
            finalUrl: (u['final_url'] ?? u['url'] ?? '').toString(),
            flagged: u['flagged'] == true,
            reasons: _toStrList(u['reasons']),
          ));
        }
      }
    }
    final radar = j['radar'];
    final meta = j['meta'];
    return Verdict(
      level: _levelFrom(j['verdict']),
      confidence: _toInt(j['confidence']),
      category: (j['category'] ?? 'other').toString(),
      voiceExplanation: (j['voice_explanation'] ?? '').toString(),
      voiceExplanationUr: (j['voice_explanation_ur'] ?? '').toString(),
      reasons: _toStrList(j['reasons']),
      advice: (j['advice'] ?? '').toString(),
      adviceUr: (j['advice_ur'] ?? '').toString(),
      lesson: (j['lesson'] ?? '').toString(),
      lessonUr: (j['lesson_ur'] ?? '').toString(),
      extractedText: (j['extracted_text'] ?? '').toString(),
      authenticity: Authenticity.fromJson(j['authenticity']),
      linkFlagged: lc is Map && lc['flagged'] == true,
      links: links,
      radarCount: _toInt(j['radar_count']),
      categoryReportsThisWeek: radar is Map ? _toInt(radar['category_reports_this_week']) : 0,
      requestId: (j['request_id'] ?? '').toString(),
      model: meta is Map ? meta['model']?.toString() : null,
      error: meta is Map ? meta['error']?.toString() : null,
      totalMs: meta is Map ? _toInt(meta['total_ms']) : 0,
    );
  }

  /// Built on the phone when the backend cannot be reached.
  factory Verdict.offline({
    required VerdictLevel level,
    required List<String> reasons,
    required String explanation,
    required String explanationUr,
  }) {
    return Verdict(
      level: level,
      confidence: level == VerdictLevel.safe ? 40 : 60,
      category: 'other',
      voiceExplanation: explanation,
      voiceExplanationUr: explanationUr,
      reasons: reasons,
      advice: 'I could not reach the checking service. Do not send money or codes until you can check again.',
      adviceUr: 'میں جانچ کی سروس تک نہیں پہنچ سکا۔ دوبارہ جانچنے تک پیسے یا کوڈ نہ دیں۔',
      lesson: 'When unsure, wait and ask someone you trust.',
      lessonUr: 'شک ہو تو رک جائیں اور کسی بھروسے والے سے پوچھیں۔',
      offline: true,
    );
  }

  bool get isDanger => level == VerdictLevel.danger;
  bool get isCaution => level == VerdictLevel.caution;
  bool get isSafe => level == VerdictLevel.safe;

  String explanationFor(String lang) => lang == 'ur' && voiceExplanationUr.isNotEmpty ? voiceExplanationUr : voiceExplanation;
  String adviceFor(String lang) => lang == 'ur' && adviceUr.isNotEmpty ? adviceUr : advice;
  String lessonFor(String lang) => lang == 'ur' && lessonUr.isNotEmpty ? lessonUr : lesson;
}
