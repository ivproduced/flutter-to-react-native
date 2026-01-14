// lib/screens/ai_rmf_playbook_screen.dart
import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/app_data_manager.dart';
import 'package:nist_pocket_guide/models/ai_rmf_playbook_entry.dart';
import 'ai_rmf_playbook_detail_screen.dart';

class AiRmfPlaybookScreen extends StatefulWidget {
  const AiRmfPlaybookScreen({super.key});

  @override
  State<AiRmfPlaybookScreen> createState() => _AiRmfPlaybookScreenState();
}

class _AiRmfPlaybookScreenState extends State<AiRmfPlaybookScreen> {
  late List<AiRmfPlaybookEntry> _playbookEntries;
  List<AiRmfPlaybookEntry> _filteredEntries = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Ensure AppDataManager is initialized before accessing its data
    if (AppDataManager.instance.isInitialized) {
      _playbookEntries = AppDataManager.instance.aiRmfPlaybookEntries;
      _filteredEntries = _playbookEntries;
    } else {
      // Handle case where data might not be ready, though initialize() should be called at app start
      _playbookEntries = [];
      _filteredEntries = [];
      // Optionally, trigger a load or show a loading indicator
    }
    _searchController.addListener(_filterEntries);
  }

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
        _filteredEntries = _playbookEntries;
      } else {
        _filteredEntries = _playbookEntries.where((entry) {
          return entry.searchableContent.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!AppDataManager.instance.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI RMF Playbook')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI RMF Playbook'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Playbook',
                hintText: 'Enter title, category, description...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                filled: true,
                fillColor: Theme.of(context).canvasColor,
              ),
            ),
          ),
          Expanded(
            child: _filteredEntries.isEmpty && _searchController.text.isNotEmpty
              ? const Center(child: Text('No entries found.'))
              : ListView.builder(
              itemCount: _filteredEntries.length,
              itemBuilder: (context, index) {
                final entry = _filteredEntries[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12.0),
                    title: Text(entry.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text("Category: ${entry.category}"),
                        const SizedBox(height: 2),
                        Text(
                          entry.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
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
          ),
        ],
      ),
    );
  }
}