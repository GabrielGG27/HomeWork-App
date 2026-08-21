import 'package:flutter/material.dart';

class OnboardingMessageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget? actions;
  final bool pointDown;
  final bool compact;

  const OnboardingMessageCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actions,
    this.pointDown = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Material(
        color: colors.surfaceContainerHigh,
        elevation: 10,
        shadowColor: colors.shadow.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: colors.primary.withValues(alpha: 0.24)),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: compact
                ? const EdgeInsets.fromLTRB(16, 14, 16, 12)
                : const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: compact ? 40 : 52,
                  height: compact ? 40 : 52,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: colors.onPrimaryContainer,
                    size: compact ? 22 : 28,
                  ),
                ),
                SizedBox(height: compact ? 8 : 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style:
                      (compact
                              ? Theme.of(context).textTheme.titleMedium
                              : Theme.of(context).textTheme.titleLarge)
                          ?.copyWith(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: compact ? 5 : 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                if (actions != null) ...[
                  SizedBox(height: compact ? 10 : 18),
                  actions!,
                ],
                if (pointDown) ...[
                  const SizedBox(height: 12),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: colors.primary,
                    size: 30,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
