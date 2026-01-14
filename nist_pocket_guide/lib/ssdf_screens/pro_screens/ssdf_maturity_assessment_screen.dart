// lib/ssdf_screens/pro_screens/ssdf_maturity_assessment_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/ssdf_models.dart';
import '../../app_data_manager.dart';

class SsdfMaturityAssessmentScreen extends StatefulWidget {
  const SsdfMaturityAssessmentScreen({super.key});

  @override
  State<SsdfMaturityAssessmentScreen> createState() => _SsdfMaturityAssessmentScreenState();
}

class _SsdfMaturityAssessmentScreenState extends State<SsdfMaturityAssessmentScreen> {
  Map<String, SsdfMaturityAssessment> _assessments = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssessments();
  }

  Future<void> _loadAssessments() async {
    final prefs = await SharedPreferences.getInstance();
    final assessmentsJson = prefs.getString('ssdf_maturity_assessments');
    
    if (assessmentsJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(assessmentsJson);
      setState(() {
        _assessments = decoded.map((key, value) => 
          MapEntry(key, SsdfMaturityAssessment.fromJson(value as Map<String, dynamic>))
        );
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAssessments() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> toSave = _assessments.map((key, value) => 
      MapEntry(key, value.toJson())
    );
    await prefs.setString('ssdf_maturity_assessments', jsonEncode(toSave));
  }

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<AppDataManager>(context);
    final catalog = dataManager.ssdfCatalog;

    if (catalog == null || _isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('SSDF Maturity Assessment'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final overallMaturity = _calculateOverallMaturity(catalog);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SSDF Maturity Assessment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showMaturityLegend(context),
            tooltip: 'Maturity Levels',
          ),
        ],
      ),
      body: Column(
        children: [
          _MaturityOverviewCard(
            overallMaturity: overallMaturity,
            totalPractices: _getTotalPracticeCount(catalog),
            assessedPractices: _assessments.length,
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: catalog.practiceGroups.length,
              itemBuilder: (context, index) {
                final group = catalog.practiceGroups[index];
                final groupMaturity = _calculateGroupMaturity(group);
                
                return _PracticeGroupCard(
                  group: group,
                  maturity: groupMaturity,
                  assessments: _assessments,
                  onAssess: (practice, level, notes) {
                    setState(() {
                      _assessments[practice.id] = SsdfMaturityAssessment(
                        practiceId: practice.id,
                        level: level,
                        notes: notes,
                        assessmentDate: DateTime.now(),
                      );
                    });
                    _saveAssessments();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int _getTotalPracticeCount(SsdfCatalog catalog) {
    return catalog.practiceGroups.fold(
      0, 
      (sum, group) => sum + group.practices.length,
    );
  }

  double _calculateOverallMaturity(SsdfCatalog catalog) {
    if (_assessments.isEmpty) return 0.0;
    
    final totalScore = _assessments.values.fold(
      0.0,
      (sum, assessment) => sum + _getLevelScore(assessment.level),
    );
    
    return totalScore / _assessments.length;
  }

  double _calculateGroupMaturity(SsdfPracticeGroup group) {
    final groupAssessments = _assessments.entries
        .where((entry) => entry.key.startsWith(group.id))
        .toList();
    
    if (groupAssessments.isEmpty) return 0.0;
    
    final totalScore = groupAssessments.fold(
      0.0,
      (sum, entry) => sum + _getLevelScore(entry.value.level),
    );
    
    return totalScore / groupAssessments.length;
  }

  double _getLevelScore(SsdfMaturityLevel level) {
    switch (level) {
      case SsdfMaturityLevel.notStarted:
        return 0.0;
      case SsdfMaturityLevel.initial:
        return 1.0;
      case SsdfMaturityLevel.managed:
        return 2.0;
      case SsdfMaturityLevel.defined:
        return 3.0;
      case SsdfMaturityLevel.quantitativelyManaged:
        return 4.0;
      case SsdfMaturityLevel.optimizing:
        return 5.0;
    }
  }

  void _showMaturityLegend(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Maturity Levels'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              _MaturityLevelItem(
                level: '0 - Not Started',
                description: 'Practice not yet initiated',
                color: Colors.grey,
              ),
              _MaturityLevelItem(
                level: '1 - Initial',
                description: 'Ad-hoc, reactive approach',
                color: Colors.red,
              ),
              _MaturityLevelItem(
                level: '2 - Managed',
                description: 'Planned and tracked',
                color: Colors.orange,
              ),
              _MaturityLevelItem(
                level: '3 - Defined',
                description: 'Standardized and documented',
                color: Colors.yellow,
              ),
              _MaturityLevelItem(
                level: '4 - Quantitatively Managed',
                description: 'Measured and controlled',
                color: Colors.lightGreen,
              ),
              _MaturityLevelItem(
                level: '5 - Optimizing',
                description: 'Continuously improving',
                color: Colors.green,
              ),
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

class _MaturityOverviewCard extends StatelessWidget {
  final double overallMaturity;
  final int totalPractices;
  final int assessedPractices;

  const _MaturityOverviewCard({
    required this.overallMaturity,
    required this.totalPractices,
    required this.assessedPractices,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = totalPractices > 0 
        ? (assessedPractices / totalPractices * 100).round() 
        : 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Overall SSDF Maturity',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            overallMaturity.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'out of 5.0',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: 'Assessed',
                value: '$assessedPractices',
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.white30,
              ),
              _StatItem(
                label: 'Total',
                value: '$totalPractices',
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.white30,
              ),
              _StatItem(
                label: 'Complete',
                value: '$percentage%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _PracticeGroupCard extends StatefulWidget {
  final SsdfPracticeGroup group;
  final double maturity;
  final Map<String, SsdfMaturityAssessment> assessments;
  final Function(SsdfPractice, SsdfMaturityLevel, String) onAssess;

  const _PracticeGroupCard({
    required this.group,
    required this.maturity,
    required this.assessments,
    required this.onAssess,
  });

  @override
  State<_PracticeGroupCard> createState() => _PracticeGroupCardState();
}

class _PracticeGroupCardState extends State<_PracticeGroupCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
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
                  Text(
                    widget.group.icon,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.group.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Maturity: ${widget.maturity.toStringAsFixed(1)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
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
            ...widget.group.practices.map((practice) {
              final assessment = widget.assessments[practice.id];
              return _PracticeAssessmentItem(
                practice: practice,
                assessment: assessment,
                onAssess: widget.onAssess,
              );
            }),
        ],
      ),
    );
  }
}

class _PracticeAssessmentItem extends StatelessWidget {
  final SsdfPractice practice;
  final SsdfMaturityAssessment? assessment;
  final Function(SsdfPractice, SsdfMaturityLevel, String) onAssess;

  const _PracticeAssessmentItem({
    required this.practice,
    required this.assessment,
    required this.onAssess,
  });

  @override
  Widget build(BuildContext context) {
    final level = assessment?.level ?? SsdfMaturityLevel.notStarted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  practice.id,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  practice.title,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => _showAssessmentDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getLevelColor(level),
            ),
            child: Text(
              _getLevelText(level),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(SsdfMaturityLevel level) {
    switch (level) {
      case SsdfMaturityLevel.notStarted:
        return Colors.grey;
      case SsdfMaturityLevel.initial:
        return Colors.red;
      case SsdfMaturityLevel.managed:
        return Colors.orange;
      case SsdfMaturityLevel.defined:
        return Colors.yellow;
      case SsdfMaturityLevel.quantitativelyManaged:
        return Colors.lightGreen;
      case SsdfMaturityLevel.optimizing:
        return Colors.green;
    }
  }

  String _getLevelText(SsdfMaturityLevel level) {
    switch (level) {
      case SsdfMaturityLevel.notStarted:
        return 'Not Started';
      case SsdfMaturityLevel.initial:
        return 'Level 1';
      case SsdfMaturityLevel.managed:
        return 'Level 2';
      case SsdfMaturityLevel.defined:
        return 'Level 3';
      case SsdfMaturityLevel.quantitativelyManaged:
        return 'Level 4';
      case SsdfMaturityLevel.optimizing:
        return 'Level 5';
    }
  }

  void _showAssessmentDialog(BuildContext context) {
    SsdfMaturityLevel selectedLevel = assessment?.level ?? SsdfMaturityLevel.notStarted;
    final notesController = TextEditingController(text: assessment?.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assess ${practice.id}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                practice.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Select Maturity Level:'),
              const SizedBox(height: 8),
              ...SsdfMaturityLevel.values.map((level) {
                return RadioListTile<SsdfMaturityLevel>(
                  title: Text(_getLevelText(level)),
                  value: level,
                  groupValue: selectedLevel,
                  onChanged: (value) {
                    if (value != null) {
                      selectedLevel = value;
                    }
                  },
                );
              }),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onAssess(practice, selectedLevel, notesController.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _MaturityLevelItem extends StatelessWidget {
  final String level;
  final String description;
  final Color color;

  const _MaturityLevelItem({
    required this.level,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
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
