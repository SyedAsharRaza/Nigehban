import 'package:flutter/material.dart';

/// Nigehban design tokens. Calm, warm neutrals; colour is reserved for meaning.
class N {
  N._();

  // Brand
  static const Color brand = Color(0xFF0B5D4B);
  static const Color brandDark = Color(0xFF073F33);
  static const Color brandSoft = Color(0xFFE3F0EB);

  // Verdicts
  static const Color safe = Color(0xFF1B8A4C);
  static const Color safeSoft = Color(0xFFE4F4EA);
  static const Color caution = Color(0xFFE39B00);
  static const Color cautionSoft = Color(0xFFFFF3DC);
  static const Color danger = Color(0xFFC62828);
  static const Color dangerSoft = Color(0xFFFDE7E7);

  // Actions
  static const Color message = Color(0xFF2F63D6);
  static const Color speak = Color(0xFF7B3FBF);
  static const Color photo = Color(0xFFE0632A);
  static const Color voice = Color(0xFF0E8C8C);

  // Surfaces
  static const Color bg = Color(0xFFF7F6F2);
  static const Color surface = Colors.white;
  static const Color ink = Color(0xFF14201C);
  static const Color ink2 = Color(0xFF5B6660);
  static const Color line = Color(0xFFE6E4DD);

  static const double radius = 18;

  static List<BoxShadow> get shadow => [
        BoxShadow(color: const Color(0xFF14201C).withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 6)),
      ];

  static ThemeData theme() {
    final base = ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: brand, surface: bg));
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
      appBarTheme: const AppBarTheme(backgroundColor: bg, foregroundColor: ink, elevation: 0, scrolledUnderElevation: 0, centerTitle: false),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: brand, width: 1.6)),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: bg, surfaceTintColor: Colors.transparent),
      dialogTheme: const DialogThemeData(backgroundColor: surface, surfaceTintColor: Colors.transparent),
    );
  }
}
