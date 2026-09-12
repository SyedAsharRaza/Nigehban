import 'package:flutter/material.dart';

/// A very large, high-contrast button: icon + one word. Designed for people who
/// may not read well — the icon and colour carry the meaning.
class BigButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final double height;
  final Color? foreground;

  const BigButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.height = 140,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? Colors.white;
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(24),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: height * 0.42, color: fg),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: fg, fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width action bar button used on result / sheets.
class WideButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final Color? foreground;

  const WideButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? Colors.white;
    return SizedBox(
      width: double.infinity,
      height: 72,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: fg,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 34),
        label: Text(label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
