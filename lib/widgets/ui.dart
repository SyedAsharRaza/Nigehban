import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../theme.dart';

/// Compact action tile: tinted icon disc + label + one-line caption.
class ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String caption;
  final Color color;
  final VoidCallback onTap;

  const ActionTile({super.key, required this.icon, required this.label, required this.caption, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: N.surface,
      borderRadius: BorderRadius.circular(N.radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(N.radius),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(N.radius), border: Border.all(color: N.line)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(13)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: N.ink)),
              const SizedBox(height: 2),
              Text(caption, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: N.ink2)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Primary CTA (56px), full width.
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final Color foreground;
  final VoidCallback? onTap;
  final bool outlined;

  const PrimaryButton({super.key, required this.label, this.icon, this.color = N.brand, this.foreground = Colors.white, this.onTap, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    final style = outlined
        ? OutlinedButton.styleFrom(foregroundColor: color, side: BorderSide(color: color.withValues(alpha: 0.5), width: 1.4), minimumSize: const Size.fromHeight(54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)))
        : FilledButton.styleFrom(backgroundColor: color, foregroundColor: foreground, minimumSize: const Size.fromHeight(54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)));
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 22), const SizedBox(width: 8)],
        Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700))),
      ],
    );
    return outlined ? OutlinedButton(style: style, onPressed: onTap, child: child) : FilledButton(style: style, onPressed: onTap, child: child);
  }
}

/// White card with optional eyebrow title.
class InfoCard extends StatelessWidget {
  final String? title;
  final IconData? icon;
  final Widget child;
  final Color? tint;
  final VoidCallback? onTap;

  const InfoCard({super.key, this.title, this.icon, required this.child, this.tint, this.onTap});

  @override
  Widget build(BuildContext context) {
    final body = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: tint ?? N.surface, borderRadius: BorderRadius.circular(N.radius), border: Border.all(color: N.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(children: [
              if (icon != null) ...[Icon(icon, size: 16, color: N.ink2), const SizedBox(width: 6)],
              Expanded(child: Text(title!.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, letterSpacing: 0.8, fontWeight: FontWeight.w800, color: N.ink2))),
            ]),
            const SizedBox(height: 8),
          ],
          child,
        ],
      ),
    );
    if (onTap == null) return body;
    return Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(N.radius), onTap: onTap, child: body));
  }
}

/// Small status pill (connection, offline, confidence).
class Pill extends StatelessWidget {
  final IconData? icon;
  final String text;
  final Color color;
  final Color? bg;
  const Pill({super.key, this.icon, required this.text, required this.color, this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg ?? color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 5)],
        Flexible(child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color))),
      ]),
    );
  }
}

/// Lottie from bundled assets with a safe fallback icon if the asset fails to load.
class Motion extends StatelessWidget {
  final String name; // scan | safe | caution | danger | listening
  final double size;
  final bool repeat;
  final IconData fallback;
  final Color fallbackColor;

  const Motion(this.name, {super.key, this.size = 120, this.repeat = true, this.fallback = Icons.shield_rounded, this.fallbackColor = N.brand});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        'assets/lottie/$name.json',
        repeat: repeat,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stack) => Icon(fallback, size: size * 0.7, color: fallbackColor),
      ),
    );
  }
}
