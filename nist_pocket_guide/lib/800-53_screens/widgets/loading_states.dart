import 'package:flutter/material.dart';

class StandardLoadingState extends StatelessWidget {
  final String? message;
  const StandardLoadingState({super.key, this.message});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message ?? 'Loading controls...'),
        ],
      ),
    );
  }
}

class ErrorBoundary extends StatelessWidget {
  final Widget child;
  final String? errorMessage;
  final VoidCallback? onRetry;
  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorMessage,
    this.onRetry,
  });
  @override
  Widget build(BuildContext context) {
    return errorMessage != null
        ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ],
          ),
        )
        : child;
  }
}
