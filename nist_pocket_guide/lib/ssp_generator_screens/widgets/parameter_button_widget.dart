// lib/ssp_generator_screens/widgets/parameter_button_widget.dart
import 'package:flutter/material.dart';

enum ParameterType { systemBlock, oscalParam, userCustom }

class ParameterButtonWidget extends StatelessWidget {
  final String displayLabel;
  final String placeholderTag;
  final ParameterType type;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  const ParameterButtonWidget({
    super.key,
    required this.displayLabel,
    required this.placeholderTag,
    required this.type,
    required this.onTap,
    required this.onDoubleTap,
  });

  Color _getChipColor(BuildContext context, ParameterType type) {
    final colorScheme = Theme.of(context).colorScheme;
    const double opacity = 0.7;
    final int alpha = (255 * opacity).round();

    switch (type) {
      case ParameterType.systemBlock:
        // --- FIX for deprecated withOpacity ---
        return colorScheme.primaryContainer.withAlpha(alpha);
      case ParameterType.oscalParam:
        // --- FIX for deprecated withOpacity ---
        return colorScheme.secondaryContainer.withAlpha(alpha);
      case ParameterType.userCustom:
        // --- FIX for deprecated withOpacity ---
        return colorScheme.tertiaryContainer.withAlpha(alpha);
    }
  }

  Color _getTextColor(BuildContext context, ParameterType type) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (type) {
      case ParameterType.systemBlock:
        return colorScheme.onPrimaryContainer;
      case ParameterType.oscalParam:
        return colorScheme.onSecondaryContainer;
      case ParameterType.userCustom:
        return colorScheme.onTertiaryContainer;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip( // --- FIX: Wrap Chip with Tooltip ---
      message: 'Double-tap to insert $placeholderTag', // --- FIX: Remove unnecessary braces ---
      preferBelow: true, // Optional: suggest tooltip position
      waitDuration: const Duration(milliseconds: 500), // Optional: delay before showing
      child: InkWell(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        borderRadius: BorderRadius.circular(16), // Match Chip's default shape for ripple
        child: Chip(
          label: Text(displayLabel,
              style: TextStyle(
                  fontSize: 12, color: _getTextColor(context, type))),
          backgroundColor: _getChipColor(context, type),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          visualDensity: VisualDensity.compact,
          // 'tooltip' property removed from Chip
        ),
      ),
    );
  }
}