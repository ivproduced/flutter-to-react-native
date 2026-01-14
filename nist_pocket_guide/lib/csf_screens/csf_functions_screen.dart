// lib/csf_screens/csf_functions_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_data_manager.dart';
import '../models/csf_models.dart';
import 'csf_categories_screen.dart';
import 'csf_search_screen.dart';

class CsfFunctionsScreen extends StatelessWidget {
  const CsfFunctionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<AppDataManager>(context);
    final catalog = dataManager.csfCatalog;

    if (catalog == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('CSF 2.0'),
        ),
        body: const Center(
          child: Text('CSF catalog not loaded'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('CSF 2.0 Functions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CsfSearchScreen(),
                ),
              );
            },
            tooltip: 'Search CSF',
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: catalog.functions.length,
        itemExtent: 140.0,
        cacheExtent: 1000.0,
        itemBuilder: (context, index) {
          final function = catalog.functions[index];
          return _FunctionCard(
            function: function,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CsfCategoriesScreen(function: function),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FunctionCard extends StatelessWidget {
  final CsfFunction function;
  final VoidCallback onTap;

  const _FunctionCard({
    required this.function,
    required this.onTap,
  });

  Color _getFunctionColor(String id) {
    switch (id) {
      case 'GV':
        return Colors.blue;
      case 'ID':
        return Colors.green;
      case 'PR':
        return Colors.orange;
      case 'DE':
        return Colors.purple;
      case 'RS':
        return Colors.red;
      case 'RC':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getFunctionColor(function.id);
    final categoryCount = function.categories.length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        function.id,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          function.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$categoryCount categories',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                function.description,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
