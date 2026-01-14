// lib/ssdf_screens/free_screens/ssdf_practices_list_screen.dart
import 'package:flutter/material.dart';
import '../../models/ssdf_models.dart';
import '../widgets/ssdf_practice_detail_card.dart';

class SsdfPracticesListScreen extends StatelessWidget {
  final SsdfPracticeGroup practiceGroup;

  const SsdfPracticesListScreen({
    super.key,
    required this.practiceGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              practiceGroup.id,
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              practiceGroup.title,
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _getGroupColor(practiceGroup.id).withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      practiceGroup.icon,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            practiceGroup.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${practiceGroup.practices.length} practices',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  practiceGroup.overview,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[800],
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: practiceGroup.practices.length,
              itemExtent: 195.0,
              cacheExtent: 1000.0,
              addAutomaticKeepAlives: false,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                final practice = practiceGroup.practices[index];
                return _PracticeCard(
                  key: ValueKey(practice.id),
                  practice: practice,
                  groupColor: _getGroupColor(practiceGroup.id),
                  onTap: () {
                    _showPracticeDetails(context, practice);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

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

  void _showPracticeDetails(BuildContext context, SsdfPractice practice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SsdfPracticeDetailCard(
            practice: practice,
            scrollController: scrollController,
          );
        },
      ),
    );
  }
}

class _PracticeCard extends StatelessWidget {
  final SsdfPractice practice;
  final Color groupColor;
  final VoidCallback onTap;

  const _PracticeCard({
    super.key,
    required this.practice,
    required this.groupColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final taskCount = practice.tasks.length;

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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: groupColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: groupColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      practice.id,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: groupColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      practice.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                practice.statement,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.checklist, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '$taskCount tasks',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
