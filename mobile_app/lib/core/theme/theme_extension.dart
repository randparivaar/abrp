import 'dart:ui';
import 'package:flutter/material.dart';
import 'theme_config.dart';

class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  // Spacing values
  final double spacingBase;
  final double spacingXs;
  final double spacingSm;
  final double spacingMd;
  final double spacingLg;
  final double spacingXl;
  final double spacingGutter;
  final double marginMobile;
  final double marginDesktop;

  // Border radius values
  final double roundedSm;
  final double roundedDefault;
  final double roundedMd;
  final double roundedLg;
  final double roundedXl;
  final double roundedFull;

  // Family Tree specifics
  final double treeSpacing;
  final double siblingSpacing;
  final Color connectorColor;
  final double connectorWidth;
  final double nodeBorderWidth;

  // Separator & Borders
  final Color separatorColor;
  final double separatorWidth;

  // Custom colors or opacities
  final Color cardShadowColor;
  final double chipBackgroundOpacity;
  final double bottomNavInactiveOpacity;

  const AppThemeExtension({
    required this.spacingBase,
    required this.spacingXs,
    required this.spacingSm,
    required this.spacingMd,
    required this.spacingLg,
    required this.spacingXl,
    required this.spacingGutter,
    required this.marginMobile,
    required this.marginDesktop,
    required this.roundedSm,
    required this.roundedDefault,
    required this.roundedMd,
    required this.roundedLg,
    required this.roundedXl,
    required this.roundedFull,
    required this.treeSpacing,
    required this.siblingSpacing,
    required this.connectorColor,
    required this.connectorWidth,
    required this.nodeBorderWidth,
    required this.separatorColor,
    required this.separatorWidth,
    required this.cardShadowColor,
    required this.chipBackgroundOpacity,
    required this.bottomNavInactiveOpacity,
  });

  @override
  AppThemeExtension copyWith({
    double? spacingBase,
    double? spacingXs,
    double? spacingSm,
    double? spacingMd,
    double? spacingLg,
    double? spacingXl,
    double? spacingGutter,
    double? marginMobile,
    double? marginDesktop,
    double? roundedSm,
    double? roundedDefault,
    double? roundedMd,
    double? roundedLg,
    double? roundedXl,
    double? roundedFull,
    double? treeSpacing,
    double? siblingSpacing,
    Color? connectorColor,
    double? connectorWidth,
    double? nodeBorderWidth,
    Color? separatorColor,
    double? separatorWidth,
    Color? cardShadowColor,
    double? chipBackgroundOpacity,
    double? bottomNavInactiveOpacity,
  }) {
    return AppThemeExtension(
      spacingBase: spacingBase ?? this.spacingBase,
      spacingXs: spacingXs ?? this.spacingXs,
      spacingSm: spacingSm ?? this.spacingSm,
      spacingMd: spacingMd ?? this.spacingMd,
      spacingLg: spacingLg ?? this.spacingLg,
      spacingXl: spacingXl ?? this.spacingXl,
      spacingGutter: spacingGutter ?? this.spacingGutter,
      marginMobile: marginMobile ?? this.marginMobile,
      marginDesktop: marginDesktop ?? this.marginDesktop,
      roundedSm: roundedSm ?? this.roundedSm,
      roundedDefault: roundedDefault ?? this.roundedDefault,
      roundedMd: roundedMd ?? this.roundedMd,
      roundedLg: roundedLg ?? this.roundedLg,
      roundedXl: roundedXl ?? this.roundedXl,
      roundedFull: roundedFull ?? this.roundedFull,
      treeSpacing: treeSpacing ?? this.treeSpacing,
      siblingSpacing: siblingSpacing ?? this.siblingSpacing,
      connectorColor: connectorColor ?? this.connectorColor,
      connectorWidth: connectorWidth ?? this.connectorWidth,
      nodeBorderWidth: nodeBorderWidth ?? this.nodeBorderWidth,
      separatorColor: separatorColor ?? this.separatorColor,
      separatorWidth: separatorWidth ?? this.separatorWidth,
      cardShadowColor: cardShadowColor ?? this.cardShadowColor,
      chipBackgroundOpacity: chipBackgroundOpacity ?? this.chipBackgroundOpacity,
      bottomNavInactiveOpacity: bottomNavInactiveOpacity ?? this.bottomNavInactiveOpacity,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      spacingBase: lerpDouble(spacingBase, other.spacingBase, t)!,
      spacingXs: lerpDouble(spacingXs, other.spacingXs, t)!,
      spacingSm: lerpDouble(spacingSm, other.spacingSm, t)!,
      spacingMd: lerpDouble(spacingMd, other.spacingMd, t)!,
      spacingLg: lerpDouble(spacingLg, other.spacingLg, t)!,
      spacingXl: lerpDouble(spacingXl, other.spacingXl, t)!,
      spacingGutter: lerpDouble(spacingGutter, other.spacingGutter, t)!,
      marginMobile: lerpDouble(marginMobile, other.marginMobile, t)!,
      marginDesktop: lerpDouble(marginDesktop, other.marginDesktop, t)!,
      roundedSm: lerpDouble(roundedSm, other.roundedSm, t)!,
      roundedDefault: lerpDouble(roundedDefault, other.roundedDefault, t)!,
      roundedMd: lerpDouble(roundedMd, other.roundedMd, t)!,
      roundedLg: lerpDouble(roundedLg, other.roundedLg, t)!,
      roundedXl: lerpDouble(roundedXl, other.roundedXl, t)!,
      roundedFull: lerpDouble(roundedFull, other.roundedFull, t)!,
      treeSpacing: lerpDouble(treeSpacing, other.treeSpacing, t)!,
      siblingSpacing: lerpDouble(siblingSpacing, other.siblingSpacing, t)!,
      connectorColor: Color.lerp(connectorColor, other.connectorColor, t)!,
      connectorWidth: lerpDouble(connectorWidth, other.connectorWidth, t)!,
      nodeBorderWidth: lerpDouble(nodeBorderWidth, other.nodeBorderWidth, t)!,
      separatorColor: Color.lerp(separatorColor, other.separatorColor, t)!,
      separatorWidth: lerpDouble(separatorWidth, other.separatorWidth, t)!,
      cardShadowColor: Color.lerp(cardShadowColor, other.cardShadowColor, t)!,
      chipBackgroundOpacity: lerpDouble(chipBackgroundOpacity, other.chipBackgroundOpacity, t)!,
      bottomNavInactiveOpacity: lerpDouble(bottomNavInactiveOpacity, other.bottomNavInactiveOpacity, t)!,
    );
  }
}

/// Helper functions to construct `AppThemeExtension` from the `ThemeConfig`.
AppThemeExtension buildThemeExtension(ThemeConfig config) {
  final primaryColor = config.getColor('primary', const Color(0xFF795900));
  final secondaryColor = config.getColor('secondary', const Color(0xFFb22b1d));

  return AppThemeExtension(
    spacingBase: config.getSpacing('base', 8.0),
    spacingXs: config.getSpacing('xs', 4.0),
    spacingSm: config.getSpacing('sm', 8.0),
    spacingMd: config.getSpacing('md', 16.0),
    spacingLg: config.getSpacing('lg', 24.0),
    spacingXl: config.getSpacing('xl', 32.0),
    spacingGutter: config.getSpacing('gutter', 16.0),
    marginMobile: config.getSpacing('margin-mobile', 16.0),
    marginDesktop: config.getSpacing('margin-desktop', 64.0),
    roundedSm: config.getRounded('sm', 4.0),
    roundedDefault: config.getRounded('DEFAULT', 8.0),
    roundedMd: config.getRounded('md', 12.0),
    roundedLg: config.getRounded('lg', 16.0),
    roundedXl: config.getRounded('xl', 24.0),
    roundedFull: config.getRounded('full', 9999.0),

    // Family Tree specific configurations from DESIGN.md
    treeSpacing: 32.0, // "use 32px vertical spacing between generations"
    siblingSpacing: 12.0, // "12px horizontal spacing between siblings"
    connectorColor: primaryColor, // "colored in Saffron"
    connectorWidth: 2.0, // "2px solid Saffron lines"
    nodeBorderWidth: 2.0, // "2px Saffron border"

    // Separator border (Maroon at 10% opacity)
    separatorColor: secondaryColor.withValues(alpha: 0.1),
    separatorWidth: 1.0,

    // Soft shadow (0px 1px 3px rgba(0,0,0,0.05))
    cardShadowColor: const Color(0x0D000000), // 0.05 opacity black
    chipBackgroundOpacity: 0.05, // "light Maroon background (5% opacity)"
    bottomNavInactiveOpacity: 0.60, // "Charcoal at 60% opacity for inactive states"
  );
}
