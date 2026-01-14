// lib/sp800_171_screens/sp800_171_search_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_data_manager.dart';
import '../models/sp800_171_models.dart';
import 'sp800_171_requirement_detail_screen.dart';

class Sp800171SearchScreen extends StatefulWidget {
  const Sp800171SearchScreen({super.key});

  @override
  State<Sp800171SearchScreen> createState() => _Sp800171SearchScreenState();
}

class _Sp800171SearchScreenState extends State<Sp800171SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Sp800171Requirement> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    final dataManager = Provider.of<AppDataManager>(context, listen: false);
    setState(() {
      _isSearching = true;
      _searchResults = dataManager.searchSp800171Requirements(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search SP 800-171'),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search requirements...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _performSearch,
            ),
          ),

          // Search results
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (!_isSearching && _searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Search SP 800-171 requirements',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter keywords, requirement IDs, or phrases',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords or check spelling',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemExtent: 110.0,
      cacheExtent: 1000.0,
      addAutomaticKeepAlives: false,
      itemBuilder: (context, index) {
        final requirement = _searchResults[index];
        return _SearchResultTile(
          requirement: requirement,
          query: _searchController.text,
          onTap: () {
            final dataManager = Provider.of<AppDataManager>(context, listen: false);
            final family = dataManager.getSp800171FamilyById(requirement.familyId);
            
            Color familyColor = Colors.grey;
            if (family != null) {
              familyColor = _getFamilyColor(family.colorCode);
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Sp800171RequirementDetailScreen(
                  requirement: requirement,
                  familyColor: familyColor,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getFamilyColor(String colorCode) {
    switch (colorCode) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'red':
        return Colors.red;
      case 'teal':
        return Colors.teal;
      case 'indigo':
        return Colors.indigo;
      case 'pink':
        return Colors.pink;
      case 'amber':
        return Colors.amber;
      case 'cyan':
        return Colors.cyan;
      case 'lime':
        return Colors.lime;
      case 'deepOrange':
        return Colors.deepOrange;
      case 'lightBlue':
        return Colors.lightBlue;
      case 'deepPurple':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }
}

class _SearchResultTile extends StatelessWidget {
  final Sp800171Requirement requirement;
  final String query;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.requirement,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      requirement.requirementId,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      requirement.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildHighlightedText(
                context,
                requirement.statementPreview,
                query,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedText(
    BuildContext context,
    String text,
    String query,
  ) {
    if (query.isEmpty) {
      return Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    final lowercaseText = text.toLowerCase();
    final lowercaseQuery = query.toLowerCase();
    
    if (!lowercaseText.contains(lowercaseQuery)) {
      return Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    final spans = <TextSpan>[];
    int start = 0;
    
    while (start < text.length) {
      final index = lowercaseText.indexOf(lowercaseQuery, start);
      
      if (index == -1) {
        // Add remaining text
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      
      // Add text before match
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      
      // Add highlighted match
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: const TextStyle(
            backgroundColor: Colors.yellow,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      
      start = index + query.length;
    }

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
        children: spans,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
