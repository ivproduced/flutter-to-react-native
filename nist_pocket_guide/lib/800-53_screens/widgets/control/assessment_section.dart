// lib/800-53_screens/widgets/control/assessment_section.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/assessment_models.dart';
import '../../../services/assessment_data_service.dart';
import '../../../services/purchase_service.dart';

/// Widget that displays 800-53A assessment information for a control
class AssessmentSection extends StatefulWidget {
  final String controlId;

  const AssessmentSection({super.key, required this.controlId});

  @override
  State<AssessmentSection> createState() => _AssessmentSectionState();
}

class _AssessmentSectionState extends State<AssessmentSection> {
  ControlAssessment? assessmentData;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _loadAssessmentData();
  }

  Future<void> _loadAssessmentData() async {
    try {
      final data = await AssessmentDataService.instance.getAssessmentData(
        widget.controlId,
      );
      if (mounted) {
        setState(() {
          assessmentData = data;
          isLoading = false;
          hasError = data == null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PurchaseService>(
      builder: (context, purchaseService, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Assessment content
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (hasError || assessmentData == null)
              _buildNoAssessmentData()
            else
              _buildAssessmentView(),
          ],
        );
      },
    );
  }

  Widget _buildNoAssessmentData() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_outlined,
                color: Colors.amber.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Assessment Data Unavailable',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'NIST SP 800-53A assessment information is not yet available '
            'for ${widget.controlId}. Assessment data is being added '
            'progressively.',
            style: TextStyle(color: Colors.amber.shade700, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentView() {
    if (assessmentData == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Assessment Objectives Header
        Text(
          "Assessment Objectives",
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // General guidance if available
        if (assessmentData!.generalGuidance?.isNotEmpty == true) ...[
          _buildGuidanceCard(),
          const SizedBox(height: 16),
        ],

        // Assessment procedures
        ...assessmentData!.procedures.map(
          (procedure) => _buildProcedureCard(procedure),
        ),
      ],
    );
  }

  Widget _buildGuidanceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assessment Guidance',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          // Assessment guidance text
          Text(
            assessmentData!.generalGuidance!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),

          // Assessment methods info below guidance text
          Text(
            'Assessment Methods:',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children:
                assessmentData!.allMethods
                    .map((method) => _buildMethodChip(method))
                    .toList(),
          ),
          const SizedBox(height: 4),
          Text(
            '${assessmentData!.totalObjectives} total assessment objectives',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodChip(AssessmentMethod method) {
    IconData icon;
    MaterialColor color;

    switch (method) {
      case AssessmentMethod.examine:
        icon = Icons.search;
        color = Colors.blue;
        break;
      case AssessmentMethod.interview:
        icon = Icons.people;
        color = Colors.orange;
        break;
      case AssessmentMethod.test:
        icon = Icons.science;
        color = Colors.purple;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color.shade700),
          const SizedBox(width: 6),
          Text(
            method.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcedureCard(AssessmentProcedure procedure) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          procedure.title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${procedure.objectives.length} objectives • ${procedure.partId}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        ),
        children: [
          ...procedure.objectives.map(
            (objective) => _buildObjectiveTile(objective, procedure),
          ),
          if (procedure.assessmentGuidance?.isNotEmpty == true) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assessment Guidance:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Assessment guidance text
                  Text(
                    procedure.assessmentGuidance!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildObjectiveTile(
    AssessmentObjective objective,
    AssessmentProcedure procedure,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Objective ID
          Text(
            objective.id,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          // Assessment method chip
          _buildMethodChip(objective.method),
          const SizedBox(height: 12),

          // Objective description
          Text(
            objective.description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.4),
          ),

          // Assessment objects
          if (objective.assessmentObjects.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Assessment Objects:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children:
                  objective.assessmentObjects
                      .map(
                        (obj) => Chip(
                          label: Text(
                            obj,
                            style: const TextStyle(fontSize: 11),
                          ),
                          backgroundColor: Colors.grey.shade100,
                          side: BorderSide(color: Colors.grey.shade300),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
            ),
          ],

          // Potential evidence
          if (objective.potentialEvidence.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Potential Evidence:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            ...objective.potentialEvidence.map(
              (evidence) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•', style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        evidence,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (objective != procedure.objectives.last) const Divider(),
        ],
      ),
    );
  }
}
