// lib/widgets/playbook_tag_chip_widget.dart
import 'package:flutter/material.dart';

class PlaybookTagChipWidget extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;

  const PlaybookTagChipWidget({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: icon != null ? Icon(icon, size: 16, color: textColor ?? Theme.of(context).colorScheme.onSecondaryContainer) : null,
      label: Text(label),
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.secondaryContainer,
      labelStyle: TextStyle(color: textColor ?? Theme.of(context).colorScheme.onSecondaryContainer, fontSize: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}