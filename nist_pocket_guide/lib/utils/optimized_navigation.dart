// lib/utils/optimized_navigation.dart
import 'package:flutter/material.dart';

/// Optimized navigation utilities for better performance
class OptimizedNavigation {
  // Debounce navigation to prevent double-taps
  static DateTime? _lastNavigationTime;
  static const Duration _navigationDebounce = Duration(milliseconds: 500);

  /// Push a screen with debouncing to prevent double navigation
  static void pushScreen(
    BuildContext context,
    Widget Function() screenBuilder, {
    String? routeName,
    bool useCustomTransition = false,
  }) {
    final now = DateTime.now();

    // Debounce check
    if (_lastNavigationTime != null &&
        now.difference(_lastNavigationTime!) < _navigationDebounce) {
      return; // Ignore rapid taps
    }
    _lastNavigationTime = now;

    Route<dynamic> route;

    if (useCustomTransition) {
      // Use optimized transition for heavy screens
      route = _createOptimizedRoute(screenBuilder, routeName);
    } else {
      // Standard MaterialPageRoute
      route = MaterialPageRoute(
        builder: (_) => screenBuilder(),
        settings: routeName != null ? RouteSettings(name: routeName) : null,
      );
    }

    Navigator.push(context, route);
  }

  /// Push a screen and remove all previous routes (for main navigation)
  static void pushAndClearStack(
    BuildContext context,
    Widget Function() screenBuilder, {
    String? routeName,
  }) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => screenBuilder(),
        settings: routeName != null ? RouteSettings(name: routeName) : null,
      ),
      (route) => false, // Remove all previous routes
    );
  }

  /// Create an optimized route with fade transition for heavy screens
  static Route<dynamic> _createOptimizedRoute(
    Widget Function() screenBuilder,
    String? routeName,
  ) {
    return PageRouteBuilder<dynamic>(
      settings: routeName != null ? RouteSettings(name: routeName) : null,
      pageBuilder: (context, animation, secondaryAnimation) => screenBuilder(),
      transitionDuration: const Duration(milliseconds: 250), // Slightly faster
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Use fade transition for better performance with heavy screens
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  /// Optimized replacement for screens with heavy data
  static void pushHeavyScreen(
    BuildContext context,
    Widget Function() screenBuilder, {
    String? routeName,
  }) {
    pushScreen(
      context,
      screenBuilder,
      routeName: routeName,
      useCustomTransition: true,
    );
  }

  /// Safe pop with mounted check
  static void safePop(BuildContext context, [dynamic result]) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context, result);
    }
  }

  /// Pop to specific route by name
  static void popToRoute(BuildContext context, String routeName) {
    Navigator.popUntil(context, (route) {
      return route.settings.name == routeName || route.isFirst;
    });
  }
}
