import 'package:flutter/material.dart';

import 'custom_button.dart';

/// Tampilan ramah saat data masih kosong (ilustrasi sederhana + teks + aksi).
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final IconData actionIcon;
  final VoidCallback? onAction;
  final bool compact;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionIcon = Icons.add_rounded,
    this.onAction,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: compact ? 8 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.7, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, v, child) => Transform.scale(scale: v, child: child),
              child: SizedBox(
                width: compact ? 100 : 150,
                height: compact ? 100 : 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: compact ? 100 : 150,
                      height: compact ? 100 : 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cs.primaryContainer.withValues(alpha: 0.55),
                      ),
                    ),
                    Container(
                      width: compact ? 72 : 108,
                      height: compact ? 72 : 108,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: cs.primaryContainer),
                    ),
                    Icon(icon, size: compact ? 36 : 54, color: cs.primary),
                    Positioned(
                      top: 10,
                      right: 18,
                      child: CircleAvatar(radius: 6, backgroundColor: cs.primary.withValues(alpha: 0.35)),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 14,
                      child: CircleAvatar(radius: 4, backgroundColor: cs.primary.withValues(alpha: 0.25)),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: compact ? 10 : 20),
            Text(title, textAlign: TextAlign.center, style: compact ? tt.titleMedium : tt.titleLarge),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: (compact ? tt.bodyMedium : tt.bodyLarge)?.copyWith(color: cs.onSurface.withValues(alpha: 0.7)),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 22),
              CustomButton(
                label: actionLabel!,
                icon: actionIcon,
                onPressed: onAction,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
