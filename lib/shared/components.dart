import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class AlertBanner extends StatelessWidget {
  const AlertBanner({super.key, required this.stage, required this.title, required this.countdownText, required this.onOpen});
  final int stage;
  final String title, countdownText;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Card(color: context.status.forStage(stage).withAlpha(24), child: ListTile(onTap: onOpen, leading: Icon(Icons.warning_amber_rounded, color: context.status.forStage(stage)), title: Text(title), subtitle: Text(countdownText), trailing: const Icon(Icons.chevron_right)));
}

class StaleDataBanner extends StatelessWidget {
  const StaleDataBanner({super.key, required this.lastSeenText});
  final String lastSeenText;
  @override
  Widget build(BuildContext context) => Card(color: context.status.stale.withAlpha(25), child: ListTile(leading: const Icon(Icons.cloud_off_outlined), title: const Text('No recent data'), subtitle: Text('$lastSeenText. This is not an all-clear.')));
}

class WaterLevelGauge extends StatelessWidget {
  const WaterLevelGauge({super.key, required this.currentStage});
  final int currentStage;
  @override
  Widget build(BuildContext context) {
    final active = currentStage.clamp(0, 3);
    return SizedBox(height: 82, child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(4, (i) => Column(mainAxisSize: MainAxisSize.min, children: [Container(width: 42, height: 42, decoration: BoxDecoration(shape: BoxShape.circle, color: i <= active ? context.status.forStage(i) : context.colors.outline.withAlpha(60)), child: Center(child: Text('$i', style: TextStyle(color: i <= active ? Colors.white : context.colors.onSurface)))), const SizedBox(height: 4), Text(i == 0 ? 'Normal' : 'Stage $i')])));
  }
}
