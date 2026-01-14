// lib/screens/ai_rmf_playbook_detail_screen.dart
import 'package:flutter/material.dart';
// For Clipboard
import 'package:nist_pocket_guide/models/ai_rmf_playbook_entry.dart';
import 'package:nist_pocket_guide/ai_rmf_screens/free_screens/widgets/playbook_section_widget.dart';
import 'package:nist_pocket_guide/ai_rmf_screens/free_screens/widgets/playbook_tag_chip_widget.dart';
import 'package:nist_pocket_guide/app_data_manager.dart'; // Import AppDataManager

// Removed TextWithLinks import as it's now a separate widget file: linkable_text_widget.dart

class AiRmfPlaybookDetailScreen extends StatefulWidget {
  final AiRmfPlaybookEntry entry;

  const AiRmfPlaybookDetailScreen({super.key, required this.entry});

  @override
  State<AiRmfPlaybookDetailScreen> createState() => _AiRmfPlaybookDetailScreenState();
}

class _AiRmfPlaybookDetailScreenState extends State<AiRmfPlaybookDetailScreen> {
  bool _isDarkTheme = false; // Simple theme toggle state, you might integrate with app-wide theme

  Widget _buildTagsSection(BuildContext context, String title, List<String> items, IconData icon, [Color Function(String)? colorFn]) {
    if (items.isEmpty) return const SizedBox.shrink();
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.secondary
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.secondary, size: 20),
              const SizedBox(width: 8),
              Text(title, style: titleStyle),
            ],
          ),
          const SizedBox(height: 10.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 6.0,
            children: items.map((item) => PlaybookTagChipWidget(
              label: item,
              backgroundColor: colorFn != null ? colorFn(item).withAlpha((0.15 * 255).round()) : null,
              textColor: colorFn != null ? colorFn(item) : null,
            )).toList(),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // --- Color palettes for consistency ---
    final List<Color> topicColors = [
      Colors.blueAccent,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.teal,
      Colors.redAccent,
      Colors.amber,
      Colors.indigo,
      Colors.pinkAccent,
      Colors.cyan,
      Colors.deepOrange,
      Colors.lime,
      Colors.deepPurple,
      Colors.lightBlue,
      Colors.brown,
      Colors.lightGreen,
      Colors.blueGrey,
    ];
    // Get the sorted topic list for index-based color assignment
    final allTopics = <String>{};
    for (var entry in AppDataManager.instance.aiRmfPlaybookEntries) {
      allTopics.addAll(entry.topic);
    }
    final sortedTopics = allTopics.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    Color getTopicColor(String topic) {
      final idx = sortedTopics.indexOf(topic);
      if (idx == -1) return Colors.blueGrey;
      return topicColors[idx % topicColors.length];
    }
    // Type/category color logic (Govern - Blue, Map - Orange, etc)
    Color getTypeColor(String type) {
      switch (type.toLowerCase()) {
        case 'govern':
          return Colors.blueAccent;
        case 'map':
          return Colors.orange;
        case 'measure':
          return Colors.green;
        case 'manage':
          return Colors.purple;
        default:
          return Colors.blueGrey;
      }
    }

    // Define TextStyles for consistency (can be moved to a theme file)
    final headlineStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.primary,
    );
    Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );


    return Theme( // Apply local theme for dark/light toggle demonstration
      data: _isDarkTheme ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true).copyWith(
         colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), // Ensure your M3 colors are set
          cardTheme: CardThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 2,
          ),
          chipTheme: ChipThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          )
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.entry.title, style: const TextStyle(fontSize: 18)),
          actions: [
            IconButton(
              icon: Icon(_isDarkTheme ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
              tooltip: _isDarkTheme ? "Switch to Light Mode" : "Switch to Dark Mode",
              onPressed: () {
                setState(() {
                  _isDarkTheme = !_isDarkTheme;
                });
              },
            )
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0), // Added bottom padding for FAB
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.entry.title, style: headlineStyle),
              const SizedBox(height: 8),
              Row(
                children: [
                  PlaybookTagChipWidget(
                    label: "Category: ${widget.entry.category}",
                    icon: Icons.folder_outlined,
                    backgroundColor: getTypeColor(widget.entry.category).withAlpha((0.15 * 255).round()),
                    textColor: getTypeColor(widget.entry.category),
                  ),
                  const SizedBox(width: 8),
                  PlaybookTagChipWidget(
                    label: "Type: ${widget.entry.type}",
                    icon: Icons.type_specimen_outlined,
                    backgroundColor: getTypeColor(widget.entry.type).withAlpha((0.15 * 255).round()),
                    textColor: getTypeColor(widget.entry.type),
                  ),
                ],
              ),
              const SizedBox(height: 20), // Increased spacing

              PlaybookSectionWidget(title: 'Description', content: widget.entry.description, icon: Icons.description_outlined),
              PlaybookSectionWidget(title: 'About This Section', content: widget.entry.sectionAbout, icon: Icons.info_outline, isInitiallyExpanded: false),
              PlaybookSectionWidget(title: 'Actions', content: widget.entry.sectionActions, isBulletList: true, icon: Icons.rule_outlined),
              PlaybookSectionWidget(title: 'Documentation Guidance', content: widget.entry.sectionDoc, hasSubheadings: true, icon: Icons.document_scanner_outlined, isInitiallyExpanded: false),
              PlaybookSectionWidget(title: 'References', content: widget.entry.sectionRef, hasSubheadings: true, icon: Icons.link_outlined, isInitiallyExpanded: false),

              _buildTagsSection(context, 'AI Actors', widget.entry.aiActors, Icons.people_outline),
              _buildTagsSection(context, 'Topics', widget.entry.topic, Icons.label_outline, getTopicColor),

              const SizedBox(height: 24),
              // Removed the 'Was this helpful?' feedback section for a cleaner UI
            ],
          ),
        ),
      ),
    );
  }
}