import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'models/verdict.dart';
import 'screens/checking_screen.dart';
import 'screens/home_screen.dart';
import 'screens/result_screen.dart';
import 'services/api_service.dart';
import 'services/prefs.dart';
import 'services/speech_service.dart';
import 'strings.dart';
import 'theme.dart';

/// Global navigator so shared content can open the checking flow from anywhere.
final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Prefs.init();
  SpeechService.instance.init(); // don't block first frame
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark));
  runApp(const NigehbanApp());
}

class NigehbanApp extends StatefulWidget {
  const NigehbanApp({super.key});

  @override
  State<NigehbanApp> createState() => _NigehbanAppState();
}

class _NigehbanAppState extends State<NigehbanApp> {
  StreamSubscription<List<SharedMediaFile>>? _shareSub;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) _wireShareIntents();
  }

  /// Share → Nigehban from WhatsApp / SMS / Gallery / any app.
  void _wireShareIntents() {
    final rsi = ReceiveSharingIntent.instance;
    // App was launched by a share.
    rsi.getInitialMedia().then((files) {
      if (files.isNotEmpty) {
        _handleShared(files);
        rsi.reset();
      }
    }).catchError((_) {});
    // App already running and a share arrives.
    _shareSub = rsi.getMediaStream().listen(_handleShared, onError: (_) {});
  }

  Future<void> _handleShared(List<SharedMediaFile> files) async {
    if (files.isEmpty) return;
    final f = files.first;
    // Wait until the navigator exists (cold start).
    for (var i = 0; i < 20 && navKey.currentState == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    final nav = navKey.currentState;
    if (nav == null) return;

    String text = '';
    Uint8List? bytes;
    String? name;
    try {
      switch (f.type) {
        case SharedMediaType.text:
        case SharedMediaType.url:
          text = f.path;
          break;
        default:
          final file = File(f.path);
          if (await file.exists()) {
            bytes = await file.readAsBytes();
            name = f.path.split('/').last;
            if (!name.contains('.')) {
              final m = (f.mimeType ?? '').toLowerCase();
              name = m.startsWith('image/') ? '$name.jpg' : m.startsWith('audio/') ? '$name.ogg' : m.startsWith('video/') ? '$name.mp4' : name;
            }
          }
          if ((f.message ?? '').trim().isNotEmpty) text = f.message!.trim();
      }
    } catch (_) {}
    if (text.isEmpty && (bytes == null || bytes.isEmpty)) return;

    nav.popUntil((r) => r.isFirst);
    nav.push(MaterialPageRoute(
      builder: (_) => CheckingScreen(
        text: text,
        previewNote: S.t('shared_received'),
        run: () => ApiService.check(text: text, fileBytes: bytes, fileName: name, source: CheckSource.shared),
        onVerdict: (Verdict v) => nav.pushReplacement(MaterialPageRoute(builder: (_) => ResultScreen(verdict: v, originalText: text))),
      ),
    ));
  }

  @override
  void dispose() {
    _shareSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nigehban',
      navigatorKey: navKey,
      debugShowCheckedModeBanner: false,
      theme: N.theme(),
      home: const HomeScreen(),
    );
  }
}
