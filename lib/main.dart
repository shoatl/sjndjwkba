final session = Session();
final services = AppServices(
  session: session, auth: yourAuth, alerts: yourAlerts, nodes: yourNodes,
  users: yourUsers, configs: yourConfigs, notifications: yourNotifications,
  nodeId: 'node-1',
);

MaterialApp(
  theme: AppTheme.light, darkTheme: AppTheme.dark, themeMode: ThemeMode.system,
  home: AuthGate(
    session: session,
    repository: services.auth,
    fieldHomeBuilder: (_) => FieldShell(services: services),
    adminHomeBuilder: (_) => AdminShell(services: services),
  ),
);