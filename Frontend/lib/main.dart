import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/utils/constants.dart';

void main() {
  runApp(const ProviderScope(child: DermaCareApp()));
}

/// Root application widget
class DermaCareApp extends ConsumerWidget {
  const DermaCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppInfo.appName,
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // TODO: Make this user-configurable in M6
      // Routing configuration
      routerConfig: router,

      // Localization (future: add support for Nepali)
      // locale: const Locale('en', 'NP'),
    );
  }
}
