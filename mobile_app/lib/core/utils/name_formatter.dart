import 'package:flutter/material.dart';

extension StringTitleCaseExtension on String {
  /// Converts string to Title Case (e.g., "tarun saini" -> "Tarun Saini")
  String toTitleCase() {
    if (trim().isEmpty) return '';
    return trim().split(RegExp(r'\s+')).map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

/// Generates a consistent background color for avatar initials based on name hash
Color getAvatarBgColor(String name) {
  const List<Color> colors = [
    Color(0xFFE53935), // Red
    Color(0xFFD81B60), // Pink
    Color(0xFF8E24AA), // Purple
    Color(0xFF5E35B1), // Deep Purple
    Color(0xFF3949AB), // Indigo
    Color(0xFF1E88E5), // Blue
    Color(0xFF039BE5), // Light Blue
    Color(0xFF00ACC1), // Cyan
    Color(0xFF00897B), // Teal
    Color(0xFF43A047), // Green
    Color(0xFFFB8C00), // Orange
    Color(0xFFF4511E), // Deep Orange
    Color(0xFF6D4C41), // Brown
    Color(0xFF546E7A), // Blue Grey
  ];
  if (name.isEmpty) return colors[0];
  final hash = name.codeUnits.fold(0, (prev, element) => prev + element);
  return colors[hash.abs() % colors.length];
}
