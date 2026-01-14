// lib/screens/ai_rmf_topic_list_screen.dart
import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/app_data_manager.dart';
import 'ai_rmf_topic_entries_screen.dart';

class AiRmfTopicListScreen extends StatefulWidget {
  const AiRmfTopicListScreen({super.key});

  @override
  State<AiRmfTopicListScreen> createState() => _AiRmfTopicListScreenState();
}

class _AiRmfTopicListScreenState extends State<AiRmfTopicListScreen> {
  List<String> _uniqueTopics = [];

  @override
  void initState() {
    super.initState();
    if (AppDataManager.instance.isInitialized) {
      final allEntries = AppDataManager.instance.aiRmfPlaybookEntries;
      final topicsSet = <String>{};
      for (var entry in allEntries) {
        topicsSet.addAll(entry.topic);
      }
      _uniqueTopics = topicsSet.toList()..sort((a,b) => a.toLowerCase().compareTo(b.toLowerCase()));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define a palette of visually distinct colors
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

    if (!AppDataManager.instance.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Browse by Topic')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_uniqueTopics.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Browse by Topic')),
        body: const Center(child: Text('No topics available.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse by Topic'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        itemCount: _uniqueTopics.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final topic = _uniqueTopics[index];
          final color = topicColors[index % topicColors.length];
          return Card(
            elevation: 3,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              leading: CircleAvatar(
                backgroundColor: color.withAlpha((0.15 * 255).round()),
                radius: 24,
                child: Icon(Icons.topic_outlined, color: color, size: 26),
              ),
              title: Text(
                topic,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AiRmfTopicEntriesScreen(selectedTopic: topic),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}