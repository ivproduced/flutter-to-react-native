// lib/widgets/playbook_section_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'linkable_text_widget.dart';
import 'playbook_action_item_widget.dart'; // Will create this

class PlaybookSectionWidget extends StatelessWidget {
  final String title;
  final String content;
  final bool isBulletList;
  final bool isInitiallyExpanded;
  final bool hasSubheadings;
  final IconData? icon;

  const PlaybookSectionWidget({
    super.key,
    required this.title,
    required this.content,
    this.isBulletList = false,
    this.isInitiallyExpanded = true,
    this.hasSubheadings = false,
    this.icon,
  });

  List<Widget> _buildContentWidgets(BuildContext context, TextStyle contentStyle) {
    List<Widget> contentWidgets = [];
    final lines = content.split('\n').where((line) => line.trim().isNotEmpty).toList();

    if (isBulletList) {
      for (var line in lines) {
        contentWidgets.add(PlaybookActionItemWidget(text: line, style: contentStyle));
      }
    } else if (hasSubheadings) {
      for (var line in lines) {
        if (line.startsWith('### ')) {
          contentWidgets.add(Padding(
            padding: const EdgeInsets.only(top: 12.0, bottom: 6.0),
            child: Text(
              line.substring(4),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600, // Bolder subheadings
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
          ));
        } else if (line.trim().isNotEmpty) {
          contentWidgets.add(LinkableTextWidget(text: line, style: contentStyle));
          contentWidgets.add(const SizedBox(height: 6)); // Spacing after paragraphs
        }
      }
    } else {
      contentWidgets.add(LinkableTextWidget(text: content, style: contentStyle));
    }
    return contentWidgets;
  }

  @override
  Widget build(BuildContext context) {
    if (content.trim().isEmpty) return const SizedBox.shrink();

    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          // color: Theme.of(context).colorScheme.primary, // Use primary color for titles
        );
    final contentStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          height: 1.5, // Improved line height
        );

    final sectionContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _buildContentWidgets(context, contentStyle ?? const TextStyle()),
    );

    Widget titleWidget = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              if (icon != null) Icon(icon, color: Theme.of(context).colorScheme.primary),
              if (icon != null) const SizedBox(width: 8),
              Expanded(child: Text(title, style: titleStyle)),
            ],
          ),
        ),
        if (hasSubheadings || isBulletList) // Only show copy for specific sections or make it always available
          IconButton(
            icon: const Icon(Icons.copy_outlined, size: 20),
            tooltip: 'Copy section content',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: content));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$title content copied to clipboard')),
              );
            },
          ),
      ],
    );


    if (content.length > 300 && !isBulletList && !isInitiallyExpanded) { // Threshold for expansion
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        elevation: 2,
        child: ExpansionTile(
          key: PageStorageKey(title), // Preserve expanded state
          iconColor: Theme.of(context).colorScheme.primary,
          collapsedIconColor: Theme.of(context).colorScheme.onSurfaceVariant,
          title: titleWidget,
          initiallyExpanded: false, // isInitiallyExpanded controls this
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0).copyWith(top:0),
              child: sectionContent,
            ),
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            titleWidget,
            const SizedBox(height: 12.0),
            sectionContent,
          ],
        ),
      ),
    );
  }
}