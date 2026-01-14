// lib/ssdf_screens/widgets/sdlc_phase_mapper_widget.dart
import 'package:flutter/material.dart';
import '../../models/ssdf_models.dart';

class SdlcPhaseMapperWidget extends StatelessWidget {
  final List<SsdfPracticeGroup> practiceGroups;

  const SdlcPhaseMapperWidget({
    super.key,
    required this.practiceGroups,
  });

  @override
  Widget build(BuildContext context) {
    final phaseMap = _buildPhaseMap();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SDLC Phase Mapping',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Map SSDF practices to your Software Development Lifecycle phases',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
              ),
        ),
        const SizedBox(height: 24),
        ...phaseMap.entries.map((entry) {
          return _PhaseSection(
            phaseName: entry.key,
            tasks: entry.value,
          );
        }),
      ],
    );
  }

  Map<String, List<SsdfTask>> _buildPhaseMap() {
    final Map<String, List<SsdfTask>> phaseMap = {
      'Planning': [],
      'Design & Development': [],
      'Implementation & Testing': [],
      'Operations & Maintenance': [],
    };

    for (var group in practiceGroups) {
      for (var practice in group.practices) {
        for (var task in practice.tasks) {
          final phase = task.sdlcPhase;
          phaseMap[phase]?.add(task);
        }
      }
    }

    return phaseMap;
  }
}

class _PhaseSection extends StatefulWidget {
  final String phaseName;
  final List<SsdfTask> tasks;

  const _PhaseSection({
    required this.phaseName,
    required this.tasks,
  });

  @override
  State<_PhaseSection> createState() => _PhaseSectionState();
}

class _PhaseSectionState extends State<_PhaseSection> {
  bool _isExpanded = false;

  Color _getPhaseColor() {
    switch (widget.phaseName) {
      case 'Planning':
        return Colors.blue;
      case 'Design & Development':
        return Colors.green;
      case 'Implementation & Testing':
        return Colors.orange;
      case 'Operations & Maintenance':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getPhaseIcon() {
    switch (widget.phaseName) {
      case 'Planning':
        return Icons.edit_note;
      case 'Design & Development':
        return Icons.architecture;
      case 'Implementation & Testing':
        return Icons.code;
      case 'Operations & Maintenance':
        return Icons.settings;
      default:
        return Icons.folder;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getPhaseColor();
    final icon = _getPhaseIcon();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.phaseName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.tasks.length} tasks',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Column(
                children: widget.tasks.map((task) {
                  return _TaskListItem(task: task, phaseColor: color);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _TaskListItem extends StatelessWidget {
  final SsdfTask task;
  final Color phaseColor;

  const _TaskListItem({
    required this.task,
    required this.phaseColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: phaseColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        task.id,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  task.statement,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
