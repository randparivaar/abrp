import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_notifier.dart';
import 'core/services/admob_service.dart';
import 'core/services/version_service.dart';
import 'core/services/version_provider.dart';
import 'features/version/presentation/force_update_screen.dart';

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initial launch ad & version check after splash / initial frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      VersionService.initialize().then((_) {
        if (mounted) {
          ref.read(versionStateProvider.notifier).checkForUpdates();
        }
      });

      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          final isForced = ref.read(versionStateProvider).isForceUpdate;
          if (!isForced) {
            AdmobService.instance.showRewardedAdOnLaunchOrResume();
          }
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(versionStateProvider.notifier).checkForUpdates();
      final isForced = ref.read(versionStateProvider).isForceUpdate;
      if (!isForced) {
        AdmobService.instance.showRewardedAdOnLaunchOrResume();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeConfig = ref.watch(themeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final versionInfo = ref.watch(versionStateProvider);

    return MaterialApp.router(
      title: 'Akhil Bhartiya Rander Parivar Samaj',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(themeConfig, isDark: false),
      darkTheme: AppTheme.buildTheme(themeConfig, isDark: true),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        if (versionInfo.isForceUpdate) {
          return ForceUpdateScreen(versionInfo: versionInfo);
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}


