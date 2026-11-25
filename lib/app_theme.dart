import 'package:flutter/material.dart';

// ==================================================
// EMERALD LUXURY THEME
// ==================================================

class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF0F6B57);
  static const Color ink = Color(0xFF10332B);
  static const Color gold = Color(0xFFE2B857);
  static const Color goldLight = Color(0xFFF6E7B4);
  static const Color mint = Color(0xFFF4FAF6);
  static const Color deep = Color(0xFF06241E);

  static const List<Color> emerald = [
    Color(0xFF06241E),
    Color(0xFF0C4A3C),
    Color(0xFF14876B),
  ];

  static const List<Color> study = [
    Color(0xFF0F1B4D),
    Color(0xFF1F3A9E),
    Color(0xFF3F5BD9),
  ];

  static const List<Color> prayer = [
    Color(0xFF3A2A08),
    Color(0xFF7A5514),
    Color(0xFFC08A2B),
  ];

  static const List<Color> health = [
    Color(0xFF2E0B1A),
    Color(0xFF7A1F3D),
    Color(0xFFD6455F),
  ];

  static const List<Color> muted = [
    Color(0xFF1F2E2B),
    Color(0xFF2E4540),
  ];

  static const List<Color> splash = [
    Color(0xFF06241E),
    Color(0xFF0C4A3C),
    Color(0xFF06241E),
  ];

  static List<Color> forCategory(String category) {
    switch (category) {
      case 'Study':
        return study;
      case 'Spiritual':
        return emerald;
      case 'Prayer':
        return prayer;
      case 'Health & Fitness':
        return health;
      default:
        return emerald;
    }
  }

  static List<Color> bgFor(String category, {bool dark = false}) {
    if (dark) {
      switch (category) {
        case 'Study':
          return const [
            Color(0xFF0A0F1F),
            Color(0xFF0E1630),
            Color(0xFF0A1411),
          ];
        case 'Prayer':
          return const [
            Color(0xFF14100A),
            Color(0xFF1F170A),
            Color(0xFF0C0A06),
          ];
        case 'Health & Fitness':
          return const [
            Color(0xFF1A0B10),
            Color(0xFF24101A),
            Color(0xFF0A0709),
          ];
        default:
          return const [
            Color(0xFF08110E),
            Color(0xFF0C1B16),
            Color(0xFF0A1411),
          ];
      }
    }

    switch (category) {
      case 'Study':
        return const [
          Color(0xFFF3F6FF),
          Color(0xFFE6ECFC),
          Color(0xFFFFF8E8),
        ];
      case 'Prayer':
        return const [
          Color(0xFFFFF9EC),
          Color(0xFFFBEFD3),
          Color(0xFFFFF8E8),
        ];
      case 'Health & Fitness':
        return const [
          Color(0xFFFFF4F6),
          Color(0xFFFBE6EB),
          Color(0xFFFFF8E8),
        ];
      default:
        return const [
          Color(0xFFF4FAF6),
          Color(0xFFE8F4EE),
          Color(0xFFFFF8E8),
        ];
    }
  }

  static BoxDecoration luxury({
    List<Color> colors = emerald,
    double radius = 17,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: gold.withValues(alpha: 0.55),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: colors.last.withValues(alpha: 0.30),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
