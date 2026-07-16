import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_notifier.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeConfig = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Akhil Bhartiya Rander Parivar Samaj',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(themeConfig, isDark: false),
      darkTheme: AppTheme.buildTheme(themeConfig, isDark: true),
      themeMode: ThemeMode.system, // Dynamically toggle light/dark based on system OS settings
      routerConfig: router,
    );
  }
}

