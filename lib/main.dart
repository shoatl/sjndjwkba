import 'package:flutter/material.dart';

import 'app/admin_shell.dart';
import 'app/app.dart';
import 'app/field_shell.dart';
import 'core/auth/session.dart';
import 'core/data/mock_repositories.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const DrainageApp());
}

class DrainageApp extends StatefulWidget {
  const DrainageApp({super.key});

  @override
  State<DrainageApp> createState() => _DrainageAppState();
}

class _DrainageAppState extends State<DrainageApp> {
  final _session = Session();
  final _auth = InMemoryAuthRepository();
  final _alerts = InMemoryAlertRepository();
  final _nodes = InMemoryNodeRepository();
  final _users = InMemoryUserRepository();
  final _configs = InMemoryConfigRepository();
  final _notifications = InMemoryNotificationService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drainage Monitor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: AuthGate(
        session: _session,
        repository: _auth,
        fieldHomeBuilder: (_) => FieldShell(
          session: _session,
          auth: _auth,
          nodes: _nodes,
          alerts: _alerts,
          users: _users,
          configs: _configs,
          notifications: _notifications,
          nodeId: 'node-1',
        ),
        adminHomeBuilder: (_) => AdminShell(
          session: _session,
          auth: _auth,
          users: _users,
          configs: _configs,
        ),
      ),
    );
  }
}
