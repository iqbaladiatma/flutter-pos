import 'package:flutter/material.dart';

/// Determines the device form factor based on screen width.
enum DeviceType { mobile, tablet, desktop }

/// Helper for responsive layout decisions.
class ResponsiveHelper {
  ResponsiveHelper._();

  /// Returns the [DeviceType] based on the given [context].
  static DeviceType deviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) return DeviceType.desktop;
    if (width >= 600) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  /// Whether the current device is a mobile (phone).
  static bool isMobile(BuildContext context) =>
      deviceType(context) == DeviceType.mobile;

  /// Whether the current device is a tablet.
  static bool isTablet(BuildContext context) =>
      deviceType(context) == DeviceType.tablet;

  /// Whether the current device is a desktop.
  static bool isDesktop(BuildContext context) =>
      deviceType(context) == DeviceType.desktop;

  /// Returns the number of grid columns appropriate for the device.
  static int gridColumns(BuildContext context) {
    return switch (deviceType(context)) {
      DeviceType.mobile => 2,
      DeviceType.tablet => 4,
      DeviceType.desktop => 6,
    };
  }

  /// Returns the max content width for centered layouts on larger screens.
  static double maxContentWidth(BuildContext context) {
    return switch (deviceType(context)) {
      DeviceType.mobile => double.infinity,
      DeviceType.tablet => 800,
      DeviceType.desktop => 1200,
    };
  }

  /// Returns appropriate padding for the device.
  static EdgeInsets contentPadding(BuildContext context) {
    return switch (deviceType(context)) {
      DeviceType.mobile => const EdgeInsets.all(16),
      DeviceType.tablet => const EdgeInsets.all(24),
      DeviceType.desktop => const EdgeInsets.all(32),
    };
  }

  /// Whether to use a NavigationRail (tablet/desktop) instead of BottomNav.
  static bool useNavigationRail(BuildContext context) =>
      isTablet(context) || isDesktop(context);
}
