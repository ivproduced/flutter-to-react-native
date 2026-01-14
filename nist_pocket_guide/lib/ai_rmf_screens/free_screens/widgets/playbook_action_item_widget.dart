// lib/widgets/playbook_action_item_widget.dart
import 'package:flutter/material.dart';
import 'linkable_text_widget.dart';

class PlaybookActionItemWidget extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const PlaybookActionItemWidget({super.key, required this.text, this.style});

  @override
  Widget build(BuildContext context) {
    String itemText = text.trim();
    if (itemText.startsWith('*')) {
      itemText = itemText.substring(1).trim();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0, top: 2.0), // Adjusted for better alignment
            child: Icon(
              Icons.check_circle_outline, // Changed bullet to a check icon
              size: 18,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          Expanded(child: LinkableTextWidget(text: itemText, style: style)),
        ],
      ),
    );
  }
}