// lib/shared/widgets/load_view.dart
//
// Loads something once, shows a spinner, shows a friendly error with
// "Try again", and hands the loaded data to [builder]. The builder also
// receives a reload function for pull-to-refresh.
//
// Use [compact] when this sits inside a scrolling list (it then takes only
// the space it needs, instead of filling the screen).

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'app_ui.dart';
import 'empty_state.dart';

class LoadView<T> extends StatefulWidget {
  const LoadView({
    super.key,
    required this.load,
    required this.builder,
    this.compact = false,
  });

  final Future<T> Function() load;
  final Widget Function(
    BuildContext context,
    T data,
    Future<void> Function() reload,
  ) builder;
  final bool compact;

  @override
  State<LoadView<T>> createState() => _LoadViewState<T>();
}

class _LoadViewState<T> extends State<LoadView<T>> {
  T? _data;
  bool _hasData = false;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      final result = await widget.load();
      if (!mounted) return;
      setState(() {
        _data = result;
        _hasData = true;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _retry() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await _run();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasData) {
      return widget.builder(context, _data as T, _run);
    }

    if (_loading) {
      return widget.compact
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          : const Center(child: CircularProgressIndicator());
    }

    final message = errorText(_error ?? 'error');
    if (widget.compact) {
      final scheme = context.colors;
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, color: scheme.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
            TextButton(onPressed: _retry, child: const Text('Try again')),
          ],
        ),
      );
    }
    return EmptyState(
      icon: Icons.cloud_off_outlined,
      title: 'Could not load',
      message: message,
      actionLabel: 'Try again',
      onAction: _retry,
    );
  }
}
