import 'package:flutter/material.dart';

class ThemeConfig {
  final String name;
  final Map<String, String> colors;
  final Map<String, double> spacing;
  final Map<String, double> rounded;

  ThemeConfig({
    required this.name,
    required this.colors,
    required this.spacing,
    required this.rounded,
  });

  /// Factory constructor to load default 'Heritage & Lineage' design system.
  factory ThemeConfig.defaultHeritage() {
    return ThemeConfig(
      name: 'Heritage & Lineage',
      colors: {
        'surface': '#fbf9f8',
        'surface-dim': '#dcd9d9',
        'surface-bright': '#fbf9f8',
        'surface-container-lowest': '#ffffff',
        'surface-container-low': '#f6f3f2',
        'surface-container': '#f0eded',
        'surface-container-high': '#eae8e7',
        'surface-container-highest': '#e4e2e1',
        'on-surface': '#1b1c1c',
        'on-surface-variant': '#4f4634',
        'inverse-surface': '#303030',
        'inverse-on-surface': '#f3f0f0',
        'outline': '#817662',
        'outline-variant': '#d3c5ae',
        'surface-tint': '#795900',
        'primary': '#795900',
        'on-primary': '#ffffff',
        'primary-container': '#daa520',
        'on-primary-container': '#553d00',
        'inverse-primary': '#f6be3b',
        'secondary': '#b22b1d',
        'on-secondary': '#ffffff',
        'secondary-container': '#fe624e',
        'on-secondary-container': '#650000',
        'tertiary': '#8d4f11',
        'on-tertiary': '#ffffff',
        'tertiary-container': '#ea9c59',
        'on-tertiary-container': '#663400',
        'error': '#ba1a1a',
        'on-error': '#ffffff',
        'error-container': '#ffdad6',
        'on-error-container': '#93000a',
        'primary-fixed': '#ffdea0',
        'primary-fixed-dim': '#f6be3b',
        'on-primary-fixed': '#261900',
        'on-primary-fixed-variant': '#5c4300',
        'secondary-fixed': '#ffdad4',
        'secondary-fixed-dim': '#ffb4a8',
        'on-secondary-fixed': '#410000',
        'on-secondary-fixed-variant': '#8f0f07',
        'tertiary-fixed': '#ffdcc3',
        'tertiary-fixed-dim': '#ffb77d',
        'on-tertiary-fixed': '#2f1500',
        'on-tertiary-fixed-variant': '#6e3900',
        'background': '#fbf9f8',
        'on-background': '#1b1c1c',
        'surface-variant': '#e4e2e1',
      },
      spacing: {
        'base': 8.0,
        'xs': 4.0,
        'sm': 8.0,
        'md': 16.0,
        'lg': 24.0,
        'xl': 32.0,
        'gutter': 16.0,
        'margin-mobile': 16.0,
        'margin-desktop': 64.0,
      },
      rounded: {
        'sm': 4.0, // 0.25rem = 4px
        'DEFAULT': 8.0, // 0.5rem = 8px
        'md': 12.0, // 0.75rem = 12px
        'lg': 16.0, // 1.0rem = 16px
        'xl': 24.0, // 1.5rem = 24px
        'full': 9999.0,
      },
    );
  }

  factory ThemeConfig.fromJson(Map<String, dynamic> json) {
    return ThemeConfig(
      name: json['name'] as String? ?? 'Custom Theme',
      colors: Map<String, String>.from(json['colors'] as Map? ?? {}),
      spacing: (json['spacing'] as Map? ?? {}).map(
        (k, v) => MapEntry(k as String, (v as num).toDouble()),
      ),
      rounded: (json['rounded'] as Map? ?? {}).map(
        (k, v) => MapEntry(k as String, (v as num).toDouble()),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'colors': colors,
      'spacing': spacing,
      'rounded': rounded,
    };
  }

  Color getColor(String key, Color fallback) {
    final hex = colors[key];
    if (hex == null) return fallback;
    return _parseHexColor(hex);
  }

  double getSpacing(String key, double fallback) {
    return spacing[key] ?? fallback;
  }

  double getRounded(String key, double fallback) {
    return rounded[key] ?? fallback;
  }

  static Color _parseHexColor(String hex) {
    final cleanHex = hex.replaceAll('#', '');
    if (cleanHex.length == 6) {
      return Color(int.parse('FF$cleanHex', radix: 16));
    } else if (cleanHex.length == 8) {
      return Color(int.parse(cleanHex, radix: 16));
    }
    return Colors.transparent;
  }
}
