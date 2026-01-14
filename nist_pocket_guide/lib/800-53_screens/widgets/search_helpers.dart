import 'dart:async';
import 'package:flutter/material.dart';

/// Mixin to add debounced search functionality to widgets
mixin DebouncedSearchMixin<T extends StatefulWidget> on State<T> {
  Timer? _searchTimer;

  /// Debounces search input to avoid excessive API calls or filtering
  void debouncedSearch(String query, Function(String) onSearch) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 300), () {
      onSearch(query);
    });
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }
}

/// Widget wrapper to add loading states and error handling consistently
class SearchableListView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext, T) itemBuilder;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final String emptyMessage;

  const SearchableListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.emptyMessage = 'No items found',
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(errorMessage!),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return Center(child: Text(emptyMessage));
    }

    return ListView.builder(
      itemCount: items.length,
      cacheExtent: 1000.0,
      itemBuilder: (context, index) => itemBuilder(context, items[index]),
    );
  }
}
