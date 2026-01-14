import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/models/oscal_models.dart';
import 'package:nist_pocket_guide/app_data_manager.dart';
import 'package:nist_pocket_guide/services/purchase_service.dart';
import 'package:nist_pocket_guide/800-53_screens/widgets/control/control_tile.dart';
import 'package:nist_pocket_guide/services/control_search_service.dart';

class SearchResultsScreenPro extends StatefulWidget {
  final String searchQuery;
  final PurchaseService purchaseService;

  const SearchResultsScreenPro({
    super.key,
    required this.searchQuery,
    required this.purchaseService,
  });

  @override
  State<SearchResultsScreenPro> createState() => _SearchResultsScreenProState();
}

class _SearchResultsScreenProState extends State<SearchResultsScreenPro> {
  List<Control> _results = [];
  bool _isLoading = false;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
    _performSearch(widget.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
    });

    final List<Control> baseControls = AppDataManager.instance.catalog.controls;
    final List<Control> filteredResults = ControlSearchService.searchControls(
      query,
      baseControls,
    );

    if (mounted) {
      setState(() {
        _results = filteredResults;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search...',
            border: InputBorder.none,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (value) => _performSearch(value),
        ),
      ),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                ? const Center(child: Text('No results found.'))
                : ListView.builder(
                  itemCount: _results.length,
                  cacheExtent: 1000.0,
                  padding: const EdgeInsets.all(12.0),
                  itemBuilder: (context, index) {
                    return ControlTile(
                      key: ValueKey(_results[index].id),
                      control: _results[index],
                      purchaseService: widget.purchaseService,
                    );
                  },
                ),
      ),
    );
  }
}
