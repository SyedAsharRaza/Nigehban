import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'services/prefs.dart';
import 'services/speech_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Prefs.init();
  // Speech init can be slow on first launch; don't block the first frame on it.
  SpeechService.instance.init();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const NigehbanApp());
}

/// Palette — colour carries meaning everywhere in the app.
class NColors {
  NColors._();
  static const Color safe = Color(0xFF1B8A4C);
  static const Color caution = Color(0xFFE39B00);
  static const Color danger = Color(0xFFC62828);
  static const Color brand = Color(0xFF0B5D4B);
  static const Color brandDark = Color(0xFF073F33);
  static const Color paste = Color(0xFF1F5FBF);
  static const Color speak = Color(0xFF7B3FBF);
  static const Color photo = Color(0xFFD9541E);
  static const Color voice = Color(0xFF0E8C8C);
  static const Color bg = Color(0xFFF6F4EE);
}

class NigehbanApp extends StatelessWidget {
  const NigehbanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nigehban',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: NColors.brand),
        scaffoldBackgroundColor: NColors.bg,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 18),
          bodyLarge: TextStyle(fontSize: 20),
          titleLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
