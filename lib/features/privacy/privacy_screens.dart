import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class ConsentScreen extends StatelessWidget {
  const ConsentScreen({super.key, required this.onAccepted, required this.onReadFullNotice});
  final VoidCallback onAccepted, onReadFullNotice;
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Privacy consent')), body: SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(child: ListView(children: [Icon(Icons.privacy_tip_outlined, size: 64, color: context.colors.primary), const SizedBox(height: 16), const Text('Your privacy', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 12), const Text('The app uses your account information, node telemetry, and incident response activity for drainage monitoring and emergency coordination, in accordance with the Data Privacy Act (RA 10173).')]),), TextButton(onPressed: onReadFullNotice, child: const Text('Read the full notice')), const SizedBox(height: 8), FilledButton(onPressed: onAccepted, style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)), child: const Text('Accept and continue'))])));
}

class PrivacySection extends StatelessWidget {
  const PrivacySection({super.key, required this.onViewNotice, required this.onWithdrawConsent, required this.onRequestData});
  final VoidCallback onViewNotice, onWithdrawConsent, onRequestData;
  @override
  Widget build(BuildContext context) => Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const ListTile(title: Text('Privacy'), subtitle: Text('Data Privacy Act (RA 10173)')), ListTile(leading: const Icon(Icons.description_outlined), title: const Text('View privacy notice'), onTap: onViewNotice), ListTile(leading: const Icon(Icons.remove_circle_outline), title: const Text('Withdraw consent'), onTap: onWithdrawConsent), ListTile(leading: const Icon(Icons.download_outlined), title: const Text('Request my data'), onTap: onRequestData)]));
}
