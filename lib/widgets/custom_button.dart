import 'package:flutter/material.dart';

enum ButtonKind { filled, tonal, outlined }

/// Tombol besar (tinggi 52dp) dengan ikon + label, mendukung status loading.
class CustomButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool loading;
  final ButtonKind kind;
  final Color? color;
  final bool expand;

  const CustomButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.loading = false,
    this.kind = ButtonKind.filled,
    this.color,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = kind == ButtonKind.filled ? (color != null ? Colors.white : cs.onPrimary) : (color ?? cs.primary);

    final child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: loading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.6, color: fg),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22),
                const SizedBox(width: 8),
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              ],
            ),
    );

    // Saat loading, tombol tetap berwarna normal tetapi tidak merespons sentuhan.
    final VoidCallback? aksi = loading ? () {} : onPressed;

    Widget tombol;
    switch (kind) {
      case ButtonKind.filled:
        tombol = FilledButton(
          onPressed: aksi,
          style: color == null ? null : FilledButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
          child: child,
        );
        break;
      case ButtonKind.tonal:
        tombol = FilledButton.tonal(
          onPressed: aksi,
          style: color == null ? null : FilledButton.styleFrom(foregroundColor: color),
          child: child,
        );
        break;
      case ButtonKind.outlined:
        tombol = OutlinedButton(
          onPressed: aksi,
          style: color == null
              ? null
              : OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color!.withValues(alpha: 0.6)),
                ),
          child: child,
        );
        break;
    }
    return SizedBox(width: expand ? double.infinity : null, height: 52, child: tombol);
  }
}
