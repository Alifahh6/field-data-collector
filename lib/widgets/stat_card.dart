import 'package:flutter/material.dart';

/// Kartu dasar aplikasi: permukaan + sudut membulat + garis tepi tipis.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(18);
    final gelap = cs.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: gelap
            ? null
            : [
                BoxShadow(color: const Color(0xFF1B2F7E).withValues(alpha: 0.07), blurRadius: 18, offset: const Offset(0, 6)),
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 3, offset: const Offset(0, 1)),
              ],
      ),
      child: Material(
        color: color ?? cs.surface,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: gelap ? Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)) : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final warnaTeks = dark ? Color.lerp(color, Colors.white, 0.4)! : color;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: dark ? 0.25 : 0.13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: warnaTeks, size: 22),
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.toDouble()),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            builder: (context, v, _) => Text(
              v.round().toString(),
              style: tt.headlineSmall?.copyWith(color: warnaTeks, height: 1.1),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, maxLines: 2, style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
