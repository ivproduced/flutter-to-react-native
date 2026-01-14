// lib/sp800_171_screens/sp800_171_families_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_data_manager.dart';
import '../models/sp800_171_models.dart';
import 'sp800_171_requirements_screen.dart';
import 'sp800_171_search_screen.dart';

class Sp800171FamiliesScreen extends StatelessWidget {
  const Sp800171FamiliesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<AppDataManager>(context);
    final catalog = dataManager.sp800171Catalog;

    if (catalog == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('SP 800-171 Rev 3'),
        ),
        body: const Center(
          child: Text('SP 800-171 catalog not loaded'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('SP 800-171 Families'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const Sp800171SearchScreen(),
                ),
              );
            },
            tooltip: 'Search Requirements',
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: catalog.families.length,
        itemExtent: 120.0,
        cacheExtent: 1000.0,
        addAutomaticKeepAlives: false,
        itemBuilder: (context, index) {
          final family = catalog.families[index];
          return _FamilyCard(
            family: family,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Sp800171RequirementsScreen(family: family),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FamilyCard extends StatelessWidget {
  final Sp800171Family family;
  final VoidCallback onTap;

  const _FamilyCard({
    required this.family,
    required this.onTap,
  });

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

  @override
  Widget build(BuildContext context) {
    final color = _getFamilyColor(family.colorCode);
    final requirementCount = family.requirements.length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    family.familyId,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      family.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$requirementCount requirements',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
