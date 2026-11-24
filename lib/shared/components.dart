import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/status_colors.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textColor = StatusColors.on(color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class AlertBanner extends StatelessWidget {
  const AlertBanner({
    super.key,
    required this.stage,
    required this.title,
    required this.countdownText,
    required this.onOpen,
  });

  final int stage;
  final String title;
  final String countdownText;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final bgColor = context.status.forStage(stage);
    final fgColor = StatusColors.on(bgColor);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: fgColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: fgColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    countdownText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: fgColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  FilledButton(
                    onPressed: onOpen,
                    style: FilledButton.styleFrom(
                      backgroundColor: fgColor,
                      foregroundColor: bgColor,
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('Open alert'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WaterLevelGauge extends StatelessWidget {
  const WaterLevelGauge({
    super.key,
    required this.currentStage,
    this.isStale = false,
  });

  final int currentStage;
  final bool isStale;

  String _stageLabel() {
    if (isStale) return 'Status unknown (stale data)';
    switch (currentStage) {
      case 1:
        return 'Stage 1 — Elevated water';
      case 2:
        return 'Stage 2 — Clog warning';
      case 3:
        return 'Stage 3 — Critical (over curb)';
      default:
        return 'All normal';
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = isStale
        ? context.status.stale
        : context.status.forStage(currentStage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(3, (index) {
            final barStage = index + 1;
            final isFilled = !isStale && currentStage >= barStage;
            final barColor = isFilled
                ? context.status.forStage(barStage)
                : context.colors.outlineVariant;

            return Expanded(
              child: Container(
                height: 16,
                margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _stageLabel(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colors.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class TimelineStep {
  const TimelineStep({
    required this.title,
    required this.subtitle,
    required this.isCompleted,
  });

  final String title;
  final String subtitle;
  final bool isCompleted;
}

class EscalationTimeline extends StatelessWidget {
  const EscalationTimeline({super.key, required this.steps});

  final List<TimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;
        final dotColor = step.isCompleted
            ? context.colors.primary
            : context.colors.outline;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                child: Column(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: step.isCompleted
                            ? dotColor
                            : context.colors.surface,
                        border: Border.all(color: dotColor, width: 2),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: context.colors.outlineVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: step.isCompleted
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: step.isCompleted
                              ? context.colors.onSurface
                              : context.colors.onSurfaceVariant,
                        ),
                      ),
                      if (step.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          step.subtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: context.colors.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class StaleDataBanner extends StatelessWidget {
  const StaleDataBanner({super.key, required this.lastSeenText});

  final String lastSeenText;

  @override
  Widget build(BuildContext context) {
    final bgColor = context.status.stale;
    final fgColor = StatusColors.on(bgColor);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.sensors_off_rounded, color: fgColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No recent data. This is not an all-clear.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: fgColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Last seen: $lastSeenText',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: fgColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
