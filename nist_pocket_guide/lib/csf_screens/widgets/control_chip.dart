import 'package:flutter/material.dart';
import '../../models/csf_models.dart';

/// Individual control chip with free/pro behavior
class ControlChip extends StatelessWidget {
  final String controlId;
  final String? title;
  final FrameworkType framework;
  final bool isPro;
  final VoidCallback? onTap;
  
  const ControlChip({
    super.key,
    required this.controlId,
    this.title,
    required this.framework,
    required this.isPro,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final color = framework.primaryColor;
    final bgColor = framework.lightColor;
    
    return Tooltip(
      message: title ?? controlId,
      child: isPro 
        ? ActionChip(
            label: Text(controlId, style: TextStyle(color: color, fontSize: 12)),
            avatar: Icon(framework.icon, size: 14, color: color),
            backgroundColor: bgColor,
            side: BorderSide(color: color.withValues(alpha: 0.3)),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            onPressed: onTap,
          )
        : Chip(
            label: Text(controlId, style: TextStyle(color: color, fontSize: 12)),
            avatar: Icon(framework.icon, size: 14, color: color),
            backgroundColor: bgColor,
            side: BorderSide(color: color.withValues(alpha: 0.3)),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
    );
  }
}
