import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_config.dart';
import 'theme_extension.dart';

class AppTheme {
  /// Default static Light Theme using the Heritage & Lineage design system.
  static ThemeData get lightTheme =>
      buildTheme(ThemeConfig.defaultHeritage(), isDark: false);

  /// Default static Dark Theme using the Heritage & Lineage design system (adapted for dark mode).
  static ThemeData get darkTheme =>
      buildTheme(ThemeConfig.defaultHeritage(), isDark: true);

  /// Dynamic Theme Builder that returns standard `ThemeData` compiled from `ThemeConfig`.
  static ThemeData buildTheme(ThemeConfig config, {required bool isDark}) {
    final colorScheme = _buildColorScheme(config, isDark: isDark);
    final textTheme = _buildTextTheme(config, colorScheme);
    final themeExtension = buildThemeExtension(config);

    final baseRadius = config.getRounded('DEFAULT', 8.0);
    final inputRadius = config.getRounded('sm', 4.0);

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      textTheme: textTheme,
      extensions: [themeExtension],
      scaffoldBackgroundColor: colorScheme.surface,

      // AppBar Theme Configuration
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.secondary, // Maroon for authority/culture
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.secondary,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: colorScheme.secondary),
      ),

      // Button Theme Configurations (Heritage: Saffron fill/White text, Maroon outlines)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary, // Saffron
          foregroundColor: colorScheme.onPrimary, // White
          elevation: 1,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(baseRadius),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onPrimary,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.secondary, // Maroon
          side: BorderSide(color: colorScheme.secondary, width: 1.5),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(baseRadius),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.secondary,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme (M3 Outlined, 4px corner radius, focused Maroon border)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.1)
            : colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: colorScheme.secondary, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: colorScheme.error, width: 2.0),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        floatingLabelStyle: TextStyle(color: colorScheme.secondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      // Card Theme Configuration (Level 1: White background, 8px base radius, soft shadow)
      cardTheme: CardThemeData(
        elevation: 1,
        color: isDark ? colorScheme.surfaceContainer : Colors.white,
        shadowColor: themeExtension.cardShadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(baseRadius),
        ),
        margin: EdgeInsets.zero,
      ),

      // Chip Theme Configuration (Rounded-pill, 5% Maroon background, Maroon text)
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.secondary.withValues(
          alpha: themeExtension.chipBackgroundOpacity,
        ),
        disabledColor: colorScheme.onSurface.withValues(alpha: 0.12),
        selectedColor: colorScheme.secondary.withValues(alpha: 0.2),
        secondarySelectedColor: colorScheme.primary.withValues(alpha: 0.2),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.secondary,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
        shape: const StadiumBorder(),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // Bottom Navigation Bar Theme (M3 NavigationBar & Classic BottomNavigationBar support)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? colorScheme.surfaceContainer : Colors.white,
        elevation: 2,
        indicatorColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.primary, size: 24);
          }
          return IconThemeData(
            color: colorScheme.onSurface.withValues(
              alpha: themeExtension.bottomNavInactiveOpacity,
            ),
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            );
          }
          return textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurface.withValues(
              alpha: themeExtension.bottomNavInactiveOpacity,
            ),
            fontWeight: FontWeight.w500,
          );
        }),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? colorScheme.surfaceContainer : Colors.white,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withValues(
          alpha: themeExtension.bottomNavInactiveOpacity,
        ),
        selectedLabelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  /// Builds a `ColorScheme` matching M3 tokens from the `ThemeConfig`.
  static ColorScheme _buildColorScheme(
    ThemeConfig config, {
    required bool isDark,
  }) {
    if (isDark) {
      final primary = config.getColor('primary', const Color(0xFFFF9100));
      final secondary = config.getColor('secondary', const Color(0xFFFF8A80));
      final tertiary = config.getColor('tertiary', const Color(0xFFF4C430));

      return ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: primary,
        onPrimary: config.getColor('on-primary', const Color(0xFF4D1D00)),
        primaryContainer: config.getColor(
          'primary-container',
          const Color(0xFFB33C00),
        ),
        onPrimaryContainer: config.getColor(
          'on-primary-container',
          const Color(0xFFFFD1B3),
        ),
        secondary: secondary,
        onSecondary: config.getColor('on-secondary', const Color(0xFF5C0000)),
        secondaryContainer: config.getColor(
          'secondary-container',
          const Color(0xFF9E000E),
        ),
        onSecondaryContainer: config.getColor(
          'on-secondary-container',
          const Color(0xFFFFEBEE),
        ),
        tertiary: tertiary,
        onTertiary: config.getColor('on-tertiary', const Color(0xFF4A3400)),
        tertiaryContainer: config.getColor(
          'tertiary-container',
          const Color(0xFF8F6600),
        ),
        onTertiaryContainer: config.getColor(
          'on-tertiary-container',
          const Color(0xFFFFE9A6),
        ),
        surface: const Color(0xFF120F0B), // Sacred Obsidian (near-black with deep saffron-gold undertones)
        onSurface: const Color(0xFFEAE5DF),
        surfaceContainer: const Color(0xFF1C1610), // Dark Charcoal-Sandalwood
        surfaceContainerHighest: const Color(0xFF3E342B),
        onSurfaceVariant: const Color(0xFFD2C3B4),
        outline: config.getColor('outline', const Color(0xFF9A8979)),
        outlineVariant: config.getColor(
          'outline-variant',
          const Color(0xFF4F4337),
        ),
      );
    } else {
      return ColorScheme(
        brightness: Brightness.light,
        primary: config.getColor('primary', const Color(0xFF795900)),
        onPrimary: config.getColor('on-primary', const Color(0xFFFFFFFF)),
        primaryContainer: config.getColor(
          'primary-container',
          const Color(0xFFDAA520),
        ),
        onPrimaryContainer: config.getColor(
          'on-primary-container',
          const Color(0xFF553D00),
        ),
        inversePrimary: config.getColor(
          'inverse-primary',
          const Color(0xFFF6BE3B),
        ),

        secondary: config.getColor('secondary', const Color(0xFFB22B1D)),
        onSecondary: config.getColor('on-secondary', const Color(0xFFFFFFFF)),
        secondaryContainer: config.getColor(
          'secondary-container',
          const Color(0xFFFE624E),
        ),
        onSecondaryContainer: config.getColor(
          'on-secondary-container',
          const Color(0xFF650000),
        ),

        tertiary: config.getColor('tertiary', const Color(0xFF8D4F11)),
        onTertiary: config.getColor('on-tertiary', const Color(0xFFFFFFFF)),
        tertiaryContainer: config.getColor(
          'tertiary-container',
          const Color(0xFFEA9C59),
        ),
        onTertiaryContainer: config.getColor(
          'on-tertiary-container',
          const Color(0xFF663400),
        ),

        error: config.getColor('error', const Color(0xFFBA1A1A)),
        onError: config.getColor('on-error', const Color(0xFFFFFFFF)),
        errorContainer: config.getColor(
          'error-container',
          const Color(0xFFFFDAD6),
        ),
        onErrorContainer: config.getColor(
          'on-error-container',
          const Color(0xFF93000A),
        ),

        surface: config.getColor('surface', const Color(0xFFFBF9F8)),
        onSurface: config.getColor('on-surface', const Color(0xFF1B1C1C)),
        onSurfaceVariant: config.getColor(
          'on-surface-variant',
          const Color(0xFF4F4634),
        ),

        outline: config.getColor('outline', const Color(0xFF817662)),
        outlineVariant: config.getColor(
          'outline-variant',
          const Color(0xFFD3C5AE),
        ),

        inverseSurface: config.getColor(
          'inverse-surface',
          const Color(0xFF303030),
        ),
        onInverseSurface: config.getColor(
          'inverse-on-surface',
          const Color(0xFFF3F0F0),
        ),

        surfaceTint: config.getColor('surface-tint', const Color(0xFF795900)),

        // M3 Additional specific colors
        surfaceDim: config.getColor('surface-dim', const Color(0xFFDCD9D9)),
        surfaceBright: config.getColor(
          'surface-bright',
          const Color(0xFFFBF9F8),
        ),
        surfaceContainerLowest: config.getColor(
          'surface-container-lowest',
          const Color(0xFFFFFFFF),
        ),
        surfaceContainerLow: config.getColor(
          'surface-container-low',
          const Color(0xFFF6F3F2),
        ),
        surfaceContainer: config.getColor(
          'surface-container',
          const Color(0xFFF0EDED),
        ),
        surfaceContainerHigh: config.getColor(
          'surface-container-high',
          const Color(0xFFEAE8E7),
        ),
        surfaceContainerHighest: config.getColor(
          'surface-container-highest',
          const Color(0xFFE4E2E1),
        ),
      );
    }
  }

  /// Builds a `TextTheme` using GoogleFonts.inter conforming to custom line heights and weights.
  static TextTheme _buildTextTheme(ThemeConfig config, ColorScheme scheme) {
    final primary = scheme.primary;
    final secondary = scheme.secondary;
    final neutral = scheme.onSurface;

    TextStyle getStyle({
      required double fontSize,
      required FontWeight fontWeight,
      required double lineHeight,
      double letterSpacing = 0.0,
      required Color color,
    }) {
      return GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: lineHeight / fontSize,
        letterSpacing: letterSpacing,
        color: color,
      );
    }

    return TextTheme(
      // display-lg
      displayLarge: getStyle(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        lineHeight: 64,
        letterSpacing: -0.25,
        color: secondary, // Maroon headline accents
      ),
      // headline-lg
      headlineLarge: getStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        lineHeight: 40,
        color: secondary,
      ),
      // headline-lg-mobile
      headlineMedium: getStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        lineHeight: 36,
        color: secondary,
      ),
      // title-lg
      titleLarge: getStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        lineHeight: 28,
        color: secondary,
      ),
      // title-md
      titleMedium: getStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        lineHeight: 24,
        letterSpacing: 0.15,
        color: secondary,
      ),
      // body-lg
      bodyLarge: getStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        lineHeight: 24,
        letterSpacing: 0.5,
        color: neutral, // Charcoal body
      ),
      // body-md
      bodyMedium: getStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        lineHeight: 20,
        letterSpacing: 0.25,
        color: neutral,
      ),
      // label-lg
      labelLarge: getStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        lineHeight: 20,
        letterSpacing: 0.1,
        color: primary, // Saffron buttons / highlights
      ),
      // label-sm
      labelSmall: getStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        lineHeight: 16,
        letterSpacing: 0.5,
        color: primary,
      ),
    );
  }
}
