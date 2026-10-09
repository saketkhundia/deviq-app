import 'package:flutter/material.dart';

/// Centralized responsive system. Every screen derives its layout from the
/// ACTUAL available width — never from assumed phone dimensions, and never
/// from desktop widths (no 1200/1400 constants anywhere on mobile).
class DevIQBreakpoints {
  const DevIQBreakpoints._();

  /// Mobile: phones. This is the primary Android target.
  static const double mobileMax = 600;

  /// Tablet: large tablets / foldables open.
  static const double tabletMax = 1024;

  /// Anything wider is treated as desktop (rare on this client).
  static bool isMobile(double width) => width < mobileMax;
  static bool isTablet(double width) =>
      width >= mobileMax && width <= tabletMax;
}

/// Width-derived layout helpers.
class DevIQResponsive {
  const DevIQResponsive._();

  static double widthOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  /// Controlled horizontal padding: 16px on compact phones, 20px above.
  /// Never desktop margins (100/150/200) on mobile.
  static double hPadding(BuildContext context) =>
      widthOf(context) < 380 ? 16 : 20;

  /// Adaptive column count for grids. Mobile is ALWAYS 1 column unless the
  /// caller explicitly opts a compact grid into 2 columns on wider phones.
  static int columnsForWidth(
    double width, {
    int phone = 1,
    int widePhone = 2,
    int tablet = 2,
    int desktop = 4,
  }) {
    if (width > DevIQBreakpoints.tabletMax) return desktop;
    if (width >= DevIQBreakpoints.mobileMax) return tablet;
    if (width >= 430) return widePhone;
    return phone;
  }

  /// 3-across metric tiles fit >= 360px. Below that, drop to 2-across so
  /// values never clip.
  static int metricColumns(double width) => width < 360 ? 2 : 3;
}

/// Consistent mobile page container:
///
///   scrollable content (16–20px gutters, max 720px measure)
///   + bottom spacing so content always clears the floating nav
///   + bottom safe-area handled by the shell Scaffold.
///
/// Screens pushed ABOVE the shell (no bottom nav) pass reserveNav: false.
class DevIQPage extends StatelessWidget {
  const DevIQPage({
    super.key,
    required this.children,
    this.reserveNav = true,
    this.maxWidth = 720,
    this.topPadding = 12,
    this.controller,
  });

  final List<Widget> children;
  final bool reserveNav;
  final double maxWidth;
  final double topPadding;

  /// Optional scroll controller for programmatic section navigation.
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final pad = DevIQResponsive.hPadding(context);
    // Floating pill nav ≈ 62px + 12 margin + gesture inset.
    final bottom =
        (reserveNav ? 92.0 : 28.0) +
        MediaQuery.viewPaddingOf(context).bottom * 0;
    return SingleChildScrollView(
      controller: controller,
      padding: EdgeInsets.fromLTRB(pad, topPadding, pad, bottom),
      physics: const ClampingScrollPhysics(),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// Spacing primitives so screens share one rhythm.
class DevIQGaps {
  const DevIQGaps._();
  static const Widget xs = SizedBox(height: 4);
  static const Widget sm = SizedBox(height: 8);
  static const Widget md = SizedBox(height: 12);
  static const Widget lg = SizedBox(height: 16);
  static const Widget xl = SizedBox(height: 24);
  static const Widget xxl = SizedBox(height: 32);
}

/// Scaffold host for screens pushed ABOVE the tab shell
/// (Review, Ask AI, Interview, Profile, History, Settings).
///
/// Tab screens get their Scaffold/Material from [AppShell]; pushed routes
/// do not, and every text field, ink splash, dialog and snackbar requires
/// a Material ancestor — without this the screen red-screens with
/// "No Material widget found" (plus cascading giant overflows).
/// Top inset comes from here; bottom inset is owned by each screen's own
/// SafeArea/padding so nothing double-pads.
class DevIQSubPage extends StatelessWidget {
  const DevIQSubPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    body: SafeArea(top: true, bottom: false, child: child),
  );
}
