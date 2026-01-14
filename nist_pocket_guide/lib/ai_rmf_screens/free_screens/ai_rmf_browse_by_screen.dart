// lib/screens/ai_rmf_browse_by_screen.dart
import 'package:flutter/material.dart';
import 'ai_rmf_playbook_hub_screen.dart';
import 'ai_rmf_topic_list_screen.dart';

class AiRmfBrowseByScreen extends StatelessWidget {
  const AiRmfBrowseByScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI RMF Playbook - Browse'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blueAccent.withAlpha((0.15 * 255).round()),
                radius: 26,
                child: const Icon(Icons.category_outlined, color: Colors.blueAccent, size: 28),
              ),
              title: const Text('Browse by Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              subtitle: const Text('Govern, Map, Manage, Measure'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AiRmfPlaybookHubScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange.withAlpha((0.15 * 255).round()),
                radius: 26,
                child: const Icon(Icons.topic_outlined, color: Colors.orange, size: 28),
              ),
              title: const Text('Browse by Topic', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              subtitle: const Text('View entries grouped by topic'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AiRmfTopicListScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}