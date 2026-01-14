// lib/screens/ai_rmf_topic_entries_screen.dart
import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/app_data_manager.dart';
import 'package:nist_pocket_guide/models/ai_rmf_playbook_entry.dart';
import 'ai_rmf_playbook_detail_screen.dart';

class AiRmfTopicEntriesScreen extends StatefulWidget {
  final String selectedTopic;

  const AiRmfTopicEntriesScreen({super.key, required this.selectedTopic});

  @override
  State<AiRmfTopicEntriesScreen> createState() =>
      _AiRmfTopicEntriesScreenState();
}

class _AiRmfTopicEntriesScreenState extends State<AiRmfTopicEntriesScreen> {
  List<AiRmfPlaybookEntry> _entriesForTopic = [];
  // Optional: Add search within topic if desired later
  // List<AiRmfPlaybookEntry> _filteredEntriesForTopic = [];
  // final TextEditingController _searchController = TextEditingController();


  @override
  void initState() {
    super.initState();
    if (AppDataManager.instance.isInitialized) {
      _entriesForTopic = AppDataManager.instance.aiRmfPlaybookEntries
          .where((entry) => entry.topic.map((t) => t.toLowerCase()).contains(widget.selectedTopic.toLowerCase()))
          .toList();
      // _filteredEntriesForTopic = _entriesForTopic;
    }
    // _searchController.addListener(_filterEntries);
  }

  /* Optional search within topic
  @override
  void dispose() {
    _searchController.removeListener(_filterEntries);
    _searchController.dispose();
    super.dispose();
  }

  void _filterEntries() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredEntriesForTopic = _entriesForTopic;
      } else {
        _filteredEntriesForTopic = _entriesForTopic.where((entry) {
          return entry.searchableContent.contains(query);
        }).toList();
      }
    });
  }
  */

  @override
  Widget build(BuildContext context) {
    if (!AppDataManager.instance.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.selectedTopic)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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

    if (_entriesForTopic.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.selectedTopic)),
        body: Center(
          child: Text(
            'No entries found for topic: ${widget.selectedTopic}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectedTopic),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        itemCount: _entriesForTopic.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final entry = _entriesForTopic[index];
          final color = getTypeColor(entry.type);
          return Card(
            elevation: 3,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              leading: CircleAvatar(
                backgroundColor: color.withAlpha((0.15 * 255).round()),
                radius: 24,
                child: Icon(Icons.psychology_alt_outlined, color: color, size: 26),
              ),
              title: Text(
                entry.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text("Type: ${entry.type} | Category: ${entry.category}", style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(
                    entry.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AiRmfPlaybookDetailScreen(entry: entry),
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