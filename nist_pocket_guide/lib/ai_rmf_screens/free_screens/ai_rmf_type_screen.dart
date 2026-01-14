// lib/screens/ai_rmf_type_screen.dart
import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/app_data_manager.dart';
import 'package:nist_pocket_guide/models/ai_rmf_playbook_entry.dart';
import 'ai_rmf_playbook_detail_screen.dart';

class AiRmfTypeScreen extends StatefulWidget {
  final String aiType;
  final String screenTitle;

  const AiRmfTypeScreen({
    super.key,
    required this.aiType,
    required this.screenTitle,
  });

  @override
  State<AiRmfTypeScreen> createState() => _AiRmfTypeScreenState();
}

class _AiRmfTypeScreenState extends State<AiRmfTypeScreen> {
  late List<AiRmfPlaybookEntry> _allEntriesForType;
  List<AiRmfPlaybookEntry> _filteredEntries = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (AppDataManager.instance.isInitialized) {
      _allEntriesForType = AppDataManager.instance.aiRmfPlaybookEntries
          .where((entry) =>
              entry.type.toLowerCase() == widget.aiType.toLowerCase())
          .toList();
      _filteredEntries = _allEntriesForType;
    } else {
      _allEntriesForType = [];
      _filteredEntries = [];
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
        _filteredEntries = _allEntriesForType;
      } else {
        _filteredEntries = _allEntriesForType.where((entry) {
          return entry.searchableContent.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!AppDataManager.instance.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.screenTitle)),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.screenTitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search in ${widget.screenTitle}',
                hintText: 'Enter title, category, description...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.0),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface.withAlpha((0.08 * 255).round()),
              ),
            ),
          ),
          Expanded(
            child: _filteredEntries.isEmpty && _searchController.text.isNotEmpty
                ? Center(
                    child: Text(
                      'No entries found for "${_searchController.text}".',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                    ),
                  )
                : _filteredEntries.isEmpty && _searchController.text.isEmpty
                    ? Center(
                        child: Text(
                          'No entries available for ${widget.screenTitle}.',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filteredEntries.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final entry = _filteredEntries[index];
                          final color = getTypeColor(entry.type);
                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 2.0),
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
                                  Text("Category: ${entry.category}", style: TextStyle(color: Colors.grey[700], fontSize: 13)),
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
          ),
        ],
      ),
    );
  }
}