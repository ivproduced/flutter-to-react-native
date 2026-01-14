// lib/ssdf_screens/free_screens/ssdf_practice_groups_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_data_manager.dart';
import '../../models/ssdf_models.dart';
import 'ssdf_practices_list_screen.dart';
import 'ssdf_devsecops_screen.dart';

class SsdfPracticeGroupsScreen extends StatelessWidget {
  const SsdfPracticeGroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<AppDataManager>(context);
    final catalog = dataManager.ssdfCatalog;

    if (catalog == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('SSDF - Secure Software Development'),
        ),
        body: const Center(
          child: Text('SSDF catalog not loaded'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('SSDF Practice Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.developer_mode),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SsdfDevSecOpsScreen(),
                ),
              );
            },
            tooltip: 'DevSecOps Tools',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showAboutDialog(context, catalog);
            },
            tooltip: 'About SSDF',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NIST SP 800-218',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Secure Software Development Framework',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Recommendations for mitigating software vulnerabilities through secure development practices.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: catalog.practiceGroups.length,
              itemExtent: 170.0,
              cacheExtent: 1000.0,
              addAutomaticKeepAlives: false,
              itemBuilder: (context, index) {
                final group = catalog.practiceGroups[index];
                return _PracticeGroupCard(
                  key: ValueKey(group.id),
                  group: group,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SsdfPracticesListScreen(
                          practiceGroup: group,
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

  void _showAboutDialog(BuildContext context, SsdfCatalog catalog) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About SSDF'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                catalog.metadata.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Version: ${catalog.metadata.version}'),
              const SizedBox(height: 16),
              const Text(
                'The Secure Software Development Framework (SSDF) provides recommendations for mitigating the risk of software vulnerabilities by establishing secure development practices.',
              ),
              const SizedBox(height: 12),
              const Text(
                'The framework organizes practices into four groups:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• PO: Prepare the Organization'),
              const Text('• PS: Protect the Software'),
              const Text('• PW: Produce Well-Secured Software'),
              const Text('• RV: Respond to Vulnerabilities'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _PracticeGroupCard extends StatelessWidget {
  final SsdfPracticeGroup group;
  final VoidCallback onTap;

  const _PracticeGroupCard({
    super.key,
    required this.group,
    required this.onTap,
  });

  Color _getGroupColor(String id) {
    switch (id) {
      case 'PO':
        return Colors.blue;
      case 'PS':
        return Colors.green;
      case 'PW':
        return Colors.orange;
      case 'RV':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getGroupColor(group.id);
    final practiceCount = group.practices.length;

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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        group.icon,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              group.id,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$practiceCount practices',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          group.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                group.overview,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
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
