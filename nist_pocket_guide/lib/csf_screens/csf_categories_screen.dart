// lib/csf_screens/csf_categories_screen.dart
import 'package:flutter/material.dart';
import '../models/csf_models.dart';
import 'csf_category_detail_screen.dart';

class CsfCategoriesScreen extends StatelessWidget {
  final CsfFunction function;

  const CsfCategoriesScreen({
    super.key,
    required this.function,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${function.id}: ${function.title}'),
      ),
      body: Column(
        children: [
          if (function.description.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              child: Text(
                function.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: function.categories.length,
              itemExtent: 165.0,
              cacheExtent: 1000.0,
              itemBuilder: (context, index) {
                final category = function.categories[index];
                return _CategoryCard(
                  category: category,
                  functionId: function.id,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CsfCategoryDetailScreen(
                          category: category,
                          functionId: function.id,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CsfCategory category;
  final String functionId;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.functionId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subcategoryCount = category.subcategories.length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.categoryId,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$subcategoryCount subcategories',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    if (category.statement.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        category.statement,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
