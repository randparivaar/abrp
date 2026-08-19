import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/app.dart';
import 'package:mobile_app/core/theme/theme_notifier.dart';

void main() {
  testWidgets('MyApp configures system themeMode and darkTheme correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.system);
    expect(app.theme, isNotNull);
    expect(app.darkTheme, isNotNull);
    expect(app.theme?.brightness, Brightness.light);
    expect(app.darkTheme?.brightness, Brightness.dark);

    // Advance all pending splash screen timers
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('App renders in light mode when system brightness is light', (WidgetTester tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(() {
      tester.platformDispatcher.clearPlatformBrightnessTestValue();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    final BuildContext context = tester.element(find.byType(Navigator));
    expect(Theme.of(context).brightness, Brightness.light);

    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('App renders in dark mode when system brightness is dark', (WidgetTester tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(() {
      tester.platformDispatcher.clearPlatformBrightnessTestValue();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    final BuildContext context = tester.element(find.byType(Navigator));
    expect(Theme.of(context).brightness, Brightness.dark);

    await tester.pump(const Duration(seconds: 10));
  });

  test('themeModeProvider updates state correctly between light, dark, and system', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(themeModeProvider), ThemeMode.system);

    await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
    expect(container.read(themeModeProvider), ThemeMode.dark);

    await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
    expect(container.read(themeModeProvider), ThemeMode.light);

    await container.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
    expect(container.read(themeModeProvider), ThemeMode.system);
  });
}
