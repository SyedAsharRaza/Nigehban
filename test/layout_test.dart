// Layout regression tests: every screen must render at small phone sizes with NO overflow,
// in both languages. `flutter test` fails on any "RenderFlex overflowed" exception.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_nova_app/models/verdict.dart';
import 'package:social_nova_app/screens/checking_screen.dart';
import 'package:social_nova_app/screens/guardian_screen.dart';
import 'package:social_nova_app/screens/home_screen.dart';
import 'package:social_nova_app/screens/result_screen.dart';
import 'package:social_nova_app/services/prefs.dart';
import 'package:social_nova_app/theme.dart';

const sizes = [Size(320, 568), Size(360, 640), Size(412, 915)];

Verdict sample(VerdictLevel level) => Verdict(
      level: level,
      confidence: 97,
      category: 'job_scam',
      voiceExplanation: 'This looks like a fake job message asking for money upfront, which is a common scam pattern.',
      voiceExplanationUr: 'یہ نوکری کے نام پر پیسے مانگنے والا دھوکا لگتا ہے، جو ایک عام دھوکے کا طریقہ ہے۔',
      reasons: const ['Asks for a fee before a job', 'Creates urgency', 'Unknown sender claims authority'],
      advice: 'Do not send any money. Call the company on its official number listed on its real website.',
      adviceUr: 'کوئی پیسے نہ بھیجیں۔ کمپنی کو اس کے اصلی نمبر پر کال کریں۔',
      lesson: 'No real job asks you to pay a fee first.',
      lessonUr: 'کوئی اصلی نوکری پہلے فیس نہیں مانگتی۔',
      extractedText: 'Ap ka OGDCL mein job confirm hai, 5000 fee bhejain. Sirf 2 ghante baqi hain warna offer khatam. ' * 3,
      authenticity: const Authenticity(kind: 'audio', checked: true, note: 'The voice sounds robotic with unnatural pacing, typical of computer-generated speech.', confidence: 90, suspicious: true),
      radarCount: 4,
      categoryReportsThisWeek: 12,
    );

Future<void> pumpAt(WidgetTester tester, Size size, Widget screen) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  _captured.clear();
  final prev = FlutterError.onError;
  FlutterError.onError = (details) {
    final txt = details.toString();
    if (!txt.contains('overflowed')) { prev?.call(details); return; }
    // Keep only the lines that name the widget and its source location.
    final keep = txt.split('\n').where((l) => l.contains('overflowed') || l.contains('error-causing widget') || RegExp(r'^\s*\w+ .*lib/').hasMatch(l) || l.contains('lib/')).take(6).join('\n');
    _captured.add(keep);
    prev?.call(details);
  };
  addTearDown(() => FlutterError.onError = prev);
  await tester.pumpWidget(MaterialApp(theme: N.theme(), home: screen));
  await tester.pump(const Duration(milliseconds: 600));
}

/// Fails with the *creator chain* of any overflow so the offending widget is obvious.
final List<String> _captured = [];
void expectNoOverflow(WidgetTester tester) {
  final e = tester.takeException();
  if (e != null || _captured.isNotEmpty) {
    final msg = _captured.join('\n---\n');
    _captured.clear();
    fail('$e\n$msg');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final lang in ['en', 'ur']) {
    group('lang=$lang', () {
      setUp(() async {
        SharedPreferences.setMockInitialValues({'lang': lang, 'onboarded': true, 'guardian_phone': '03001234567', 'guardian_name': 'Ahmed Bhai Very Long Name Here'});
        await Prefs.init();
      });

      for (final size in sizes) {
        testWidgets('home fits ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
          await pumpAt(tester, size, const HomeScreen());
          expectNoOverflow(tester);
        });

        for (final level in VerdictLevel.values) {
          testWidgets('result $level fits ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
            await pumpAt(tester, size, ResultScreen(verdict: sample(level), originalText: 'x'));
            expectNoOverflow(tester);
          });
        }

        testWidgets('guardian fits ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
          await pumpAt(tester, size, const GuardianScreen());
          expectNoOverflow(tester);
        });

        testWidgets('checking fits ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
          await pumpAt(
            tester,
            size,
            CheckingScreen(
              text: 'URGENT send OTP now fee bhejain',
              previewNote: 'Voice note',
              run: () => Completer<Verdict>().future, // never completes: no pending timers
              onVerdict: (_) {},
            ),
          );
          expectNoOverflow(tester);
        });
      }
    });
  }
}
