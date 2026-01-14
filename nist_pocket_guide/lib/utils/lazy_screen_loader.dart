// lib/utils/lazy_screen_loader.dart
import 'package:flutter/material.dart';

/// Lazy loading wrapper for heavy screens to improve navigation performance
class LazyScreenLoader extends StatelessWidget {
  final Widget Function() screenBuilder;
  final Widget? loadingWidget;
  final String? debugLabel;

  const LazyScreenLoader({
    super.key,
    required this.screenBuilder,
    this.loadingWidget,
    this.debugLabel,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _buildScreenAsync(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ??
              const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading...'),
                    ],
                  ),
                ),
              );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading screen: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        return snapshot.data ?? const SizedBox.shrink();
      },
    );
  }

  Future<Widget> _buildScreenAsync() async {
    // Add a small delay to prevent blocking the navigation animation
    await Future.delayed(const Duration(milliseconds: 1));

    // Build the screen off the main thread if possible
    return screenBuilder();
  }
}

/// Wrapper for screens that load heavy data
class HeavyDataScreenLoader<T> extends StatelessWidget {
  final Future<T> dataLoader;
  final Widget Function(BuildContext context, T data) screenBuilder;
  final Widget? loadingWidget;
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  const HeavyDataScreenLoader({
    super.key,
    required this.dataLoader,
    required this.screenBuilder,
    this.loadingWidget,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: dataLoader,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ??
              const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading data...'),
                    ],
                  ),
                ),
              );
        }

        if (snapshot.hasError) {
          return errorBuilder?.call(context, snapshot.error!) ??
              Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text('Error loading data: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                ),
              );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(body: Center(child: Text('No data available')));
        }

        return screenBuilder(context, snapshot.data as T);
      },
    );
  }
}
