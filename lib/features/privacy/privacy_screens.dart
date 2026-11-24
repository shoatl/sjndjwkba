import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({
    super.key,
    required this.onAccepted,
    required this.onReadFullNotice,
  });

  final VoidCallback onAccepted;
  final VoidCallback onReadFullNotice;

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Privacy Consent'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    Text(
                      'Before you continue',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'In accordance with the Philippine Data Privacy Act of 2012 '
                      '(Republic Act No. 10173), Drainage Monitor collects and '
                      'processes only the information needed for barangay flood '
                      'and drainage response:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    const _BulletPoint(
                      text:
                          'Your verified name, assigned role, and mobile number '
                          '(used for alert notifications and SMS fallback).',
                    ),
                    const _BulletPoint(
                      text:
                          'Incident response logs, acknowledgments, remarks, '
                          'and timestamps.',
                    ),
                    const _BulletPoint(
                      text:
                          'If your account is archived, your mobile number, '
                          'credentials, and notification tokens are deleted; only '
                          'your name, role, and service dates are retained for '
                          'official incident records.',
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: widget.onReadFullNotice,
                        icon: const Icon(Icons.description_outlined),
                        label: const Text('Read full privacy notice'),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              CheckboxListTile(
                value: _isChecked,
                onChanged: (val) => setState(() => _isChecked = val ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'I have read and understood the Data Privacy Notice and '
                  'consent to the processing of my personnel information.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _isChecked ? widget.onAccepted : null,
                child: const Text('Accept and Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  const _BulletPoint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.primary,
            ),
          ),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class PrivacySection extends StatelessWidget {
  const PrivacySection({
    super.key,
    required this.onViewNotice,
    required this.onWithdrawConsent,
    required this.onRequestData,
  });

  final VoidCallback onViewNotice;
  final VoidCallback onWithdrawConsent;
  final VoidCallback onRequestData;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Data Privacy (RA 10173)',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('View privacy notice'),
            trailing: const Icon(Icons.chevron_right),
            onTap: onViewNotice,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Request copy of my data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: onRequestData,
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.remove_circle_outline,
              color: context.colors.error,
            ),
            title: Text(
              'Withdraw consent',
              style: TextStyle(color: context.colors.error),
            ),
            subtitle: const Text(
              'Deactivates app access until consent is renewed',
            ),
            onTap: onWithdrawConsent,
          ),
        ],
      ),
    );
  }
}
