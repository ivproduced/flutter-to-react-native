// lib/csf_screens/csf_search_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_data_manager.dart';
import '../models/csf_models.dart';

class CsfSearchScreen extends StatefulWidget {
  const CsfSearchScreen({super.key});

  @override
  State<CsfSearchScreen> createState() => _CsfSearchScreenState();
}

class _CsfSearchScreenState extends State<CsfSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<CsfSubcategory> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final dataManager = Provider.of<AppDataManager>(context, listen: false);
    final results = dataManager.searchCsfSubcategories(query);

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search CSF subcategories...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 18),
          onChanged: _performSearch,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _performSearch('');
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.isEmpty) {
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
              'Search CSF subcategories',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
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
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemExtent: 120.0,
      cacheExtent: 1000.0,
      addAutomaticKeepAlives: false,
      itemBuilder: (context, index) {
        final subcategory = _searchResults[index];
        return _SearchResultCard(
          subcategory: subcategory,
          searchQuery: _searchController.text,
        );
      },
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final CsfSubcategory subcategory;
  final String searchQuery;

  const _SearchResultCard({
    required this.subcategory,
    required this.searchQuery,
  });

  TextSpan _highlightText(String text, String query, TextStyle? style) {
    if (query.isEmpty) {
      return TextSpan(text: text, style: style);
    }

    final lowercaseText = text.toLowerCase();
    final lowercaseQuery = query.toLowerCase();
    final matches = <TextSpan>[];
    int currentIndex = 0;

    while (currentIndex < text.length) {
      final matchIndex = lowercaseText.indexOf(lowercaseQuery, currentIndex);
      if (matchIndex == -1) {
        matches.add(TextSpan(
          text: text.substring(currentIndex),
          style: style,
        ));
        break;
      }

      if (matchIndex > currentIndex) {
        matches.add(TextSpan(
          text: text.substring(currentIndex, matchIndex),
          style: style,
        ));
      }

      matches.add(TextSpan(
        text: text.substring(matchIndex, matchIndex + query.length),
        style: style?.copyWith(
          backgroundColor: Colors.yellow,
          fontWeight: FontWeight.bold,
        ),
      ));

      currentIndex = matchIndex + query.length;
    }

    return TextSpan(children: matches);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subcategory.subcategoryId,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (subcategory.statement.isNotEmpty) ...[
              const SizedBox(height: 8),
              RichText(
                text: _highlightText(
                  subcategory.statement,
                  searchQuery,
                  Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
            if (subcategory.examples.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${subcategory.examples.length} examples available',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
