// lib/csf_screens/csf_category_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/csf_models.dart';
import 'widgets/related_controls_section.dart';

class CsfCategoryDetailScreen extends StatelessWidget {
  final CsfCategory category;
  final String functionId;

  const CsfCategoryDetailScreen({
    super.key,
    required this.category,
    required this.functionId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${category.categoryId}'),
      ),
      body: ListView(
        children: [
          // Category Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (category.statement.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    category.statement,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
          
          // Subcategories
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subcategories',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                ...category.subcategories.map((subcategory) => _SubcategoryCard(
                      subcategory: subcategory,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubcategoryCard extends StatelessWidget {
  final CsfSubcategory subcategory;

  const _SubcategoryCard({
    required this.subcategory,
  });

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Text(
                    subcategory.subcategoryId,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () => _copyToClipboard(
                    context,
                    '${subcategory.subcategoryId}: ${subcategory.statement}',
                  ),
                  tooltip: 'Copy to clipboard',
                ),
              ],
            ),
            if (subcategory.statement.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subcategory.statement,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            
            // Related Framework Controls Section (800-53 and 800-171)
            if (subcategory.related80053Controls.isNotEmpty ||
                subcategory.related800171Controls.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              RelatedControlsSection(subcategory: subcategory),
            ],
            
            if (subcategory.examples.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Examples:',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
              ),
              const SizedBox(height: 4),
              ...subcategory.examples.asMap().entries.map((entry) {
                final index = entry.key;
                final example = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${index + 1}. ',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      Expanded(
                        child: Text(
                          example,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[700],
                              ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
