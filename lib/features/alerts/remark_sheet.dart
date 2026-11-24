// lib/features/alerts/remark_sheet.dart
//
// "Add remark" bottom sheet. A remark is free text, and posting one
// automatically credits the author. Works even if nobody acknowledged.
//
// The caller passes [onSubmit], which does the real post. If it throws, the
// error shows inside the sheet and the text is kept.

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_ui.dart';
import '../../shared/widgets/sheet_helper.dart';

/// Returns true if a remark was posted.
Future<bool> showRemarkSheet(
  BuildContext context, {
  required Future<void> Function(String text) onSubmit,
}) async {
  final posted = await showAppSheet<bool>(
    context,
    title: 'Add remark',
    subtitle: 'You are credited on this incident when you post.',
    builder: (sheetContext) => _RemarkForm(onSubmit: onSubmit),
  );
  return posted ?? false;
}

class _RemarkForm extends StatefulWidget {
  const _RemarkForm({required this.onSubmit});

  final Future<void> Function(String text) onSubmit;

  @override
  State<_RemarkForm> createState() => _RemarkFormState();
}

class _RemarkFormState extends State<_RemarkForm> {
  static const int _maxLength = 500;

  final TextEditingController _controller = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSend => !_sending && _controller.text.trim().isNotEmpty;

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.onSubmit(text);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = errorText(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          enabled: !_sending,
          autofocus: true,
          minLines: 4,
          maxLines: 6,
          maxLength: _maxLength,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
          decoration: appInputDecoration(
            context,
            label: 'What did you see or do?',
            hint: 'For example: cleared leaves from the grate.',
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.shield_outlined, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Do not write phone numbers or other personal details.',
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          InlineError(message: _error!),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _canSend ? _send : null,
          style: bigFilledStyle(),
          icon: _sending
              ? const ButtonSpinner()
              : const Icon(Icons.send_rounded),
          label: const Text('Post remark'),
        ),
      ],
    );
  }
}
