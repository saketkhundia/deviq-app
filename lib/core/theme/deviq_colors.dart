import 'package:flutter/material.dart';

/// DevIQ design tokens. Monochrome system is dominant; semantic colors
/// are used sparingly for platform / status accents.
class DevIQColors {
  const DevIQColors._();

  // ---- Dark (primary experience: AMOLED pure black) ----
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkBackground2 = Color(0xFF101214);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkBorder = Color(0xFF2A2A2A);
  static const Color darkBorderStrong = Color(0xFF404040);
  static const Color darkTextPrimary = Color(0xFFFAFAFA);
  static const Color darkTextSecondary = Color(0xFFA3A3A3);
  static const Color darkTextTertiary = Color(0xFF525252);
  static const Color darkTrack = Color(0xFF2A2A2A);
  static const Color darkAccent = Color(0xFFFAFAFA);
  static const Color darkAccentFg = Color(0xFF0A0A0A);

  // ---- Light ----
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightBackground2 = Color(0xFFEBEBEB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE0E0E0);
  static const Color lightBorderStrong = Color(0xFFBDBDBD);
  static const Color lightTextPrimary = Color(0xFF0A0A0A);
  static const Color lightTextSecondary = Color(0xFF525252);
  static const Color lightTextTertiary = Color(0xFFA3A3A3);
  static const Color lightTrack = Color(0xFFE5E5E5);
  static const Color lightAccent = Color(0xFF0A0A0A);
  static const Color lightAccentFg = Color(0xFFFFFFFF);

  // ---- Semantic (sparing) ----
  static const Color github = Color(0xFF58A6FF); // blue
  static const Color leetcode = Color(0xFFEAB308); // amber/yellow
  static const Color codeforces = Color(0xFFA78BFA); // purple
  static const Color success = Color(0xFF22C55E); // green
  static const Color warning = Color(0xFFF59E0B); // amber
  static const Color error = Color(0xFFF43F5E); // rose/red
  static const Color ai = Color(0xFFFB7185); // subtle red/pink
  static const Color teal = Color(0xFF2DD4BF);

  // ---- DevIQ signal identity ----
  // Signature green: owns the unified score, its ring, the activity
  // fingerprint, skill bars and achievement states. Platform colors
  // stay on their own platforms; nothing else borrows this green.
  static const Color signal = Color(0xFF42E58B);
  static const Color signalLight = Color(0xFF0E9F5D);

  /// Signal color with guaranteed contrast per brightness.
  static Color signalFor(bool dark) => dark ? signal : signalLight;

  /// Contribution-fingerprint intensity ramp (GitHub-legible greens
  /// tuned toward the DevIQ signal hue).
  static Color heatCell(bool dark, int level) {
    const darkRamp = [
      Color(0xFF121619),
      Color(0xFF0B3B24),
      Color(0xFF0E6B38),
      Color(0xFF1FA855),
      Color(0xFF42E58B),
    ];
    const lightRamp = [
      Color(0xFFEBEDF0),
      Color(0xFFB7F0CD),
      Color(0xFF6FDD9B),
      Color(0xFF25B862),
      Color(0xFF0E9F5D),
    ];
    final ramp = dark ? darkRamp : lightRamp;
    return ramp[level.clamp(0, 4)];
  }

  /// Score color used by ScoreRing: >=80 green, >=60 blue, >=40 amber, else rose.
  static Color scoreColor(double score) {
    if (score >= 80) return success;
    if (score >= 60) return github;
    if (score >= 40) return leetcode;
    return error;
  }

  /// Codeforces rank color.
  static Color cfRankColor(String? rank) {
    final r = (rank ?? '').toLowerCase();
    if (r.contains('grandmaster')) return error;
    if (r.contains('master') && !r.contains('candidate')) return warning;
    if (r.contains('candidate')) return codeforces;
    if (r.contains('expert')) return github;
    if (r.contains('specialist')) return teal;
    if (r.contains('pupil')) return success;
    return success;
  }
}

/// Shared radii / spacing so cards and buttons stay consistent.
class DevIQRadius {
  const DevIQRadius._();
  static const double card = 10;
  static const double button = 9;
  static const double pill = 999;
  static const double sheet = 16;
}

/// Central control dimensions. Every button variant derives its
/// height here — never hardcoded per call site — so proportions stay
/// consistent across Home, Analyze, dialogs and empty states.
class DevIQControls {
  const DevIQControls._();

  /// Primary mobile action (Analyze Profile, Run, Review Code).
  static const double primaryHeight = 52;

  /// Secondary mobile action (ghost buttons, dialogs).
  static const double secondaryHeight = 48;

  /// Compact inline action (Copy / Download / Reset trios).
  static const double compactHeight = 44;

  /// Miniature inline lens (terminal Send). Justified only beside
  /// text-height content it must share a baseline with.
  static const double miniHeight = 32;

  /// Form input text size. 16px minimum keeps iOS from zooming on
  /// focus; code-editor mono surfaces are the deliberate exception.
  static const double inputFontSize = 16;

  /// Standard glyph sizes: buttons 16–18, navigation 22–24.
  static const double buttonIcon = 18;
  static const double navIcon = 24;
}

class DevIQSpacing {
  const DevIQSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double hero = 48;
}

class DevIQShadows {
  const DevIQShadows._();
  static List<BoxShadow> card(bool dark) => [
    BoxShadow(
      color: dark
          ? const Color.fromRGBO(0, 0, 0, 0.4)
          : const Color.fromRGBO(0, 0, 0, 0.08),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: dark
          ? const Color.fromRGBO(0, 0, 0, 0.5)
          : const Color.fromRGBO(0, 0, 0, 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}
