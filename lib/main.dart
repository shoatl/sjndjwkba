import 'package:flutter/material.dart';

import 'app/app_services.dart';
import 'app/app.dart';
import 'app/admin_shell.dart';
import 'app/field_shell.dart';
import 'core/auth/session.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = Session();
  final services = AppServices(session: session);
  runApp(MaterialApp(theme: AppTheme.light, darkTheme: AppTheme.dark, themeMode: ThemeMode.system, home: AuthGate(session: session, repository: services.auth, fieldHomeBuilder: (_) => FieldShell(session: session, auth: services.auth, nodes: services.nodes, alerts: services.alerts, users: services.users, configs: services.configs, notifications: services.notifications, nodeId: services.nodeId), adminHomeBuilder: (_) => AdminShell(session: session, auth: services.auth, users: services.users, configs: services.configs))));
}
