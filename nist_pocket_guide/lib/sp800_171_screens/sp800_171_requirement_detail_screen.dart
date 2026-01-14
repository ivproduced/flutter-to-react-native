// lib/sp800_171_screens/sp800_171_requirement_detail_screen_NEW.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/sp800_171_models.dart';
import 'widgets/requirement_header.dart';
import 'widgets/requirement_notes_section.dart';

class Sp800171RequirementDetailScreen extends StatefulWidget {
  final Sp800171Requirement requirement;
  final Color familyColor;
  final String? returnRoute;
  final String? returnLabel;

  const Sp800171RequirementDetailScreen({
    super.key,
    required this.requirement,
    required this.familyColor,
    this.returnRoute,
    this.returnLabel,
  });

  @override
  State<Sp800171RequirementDetailScreen> createState() => _Sp800171RequirementDetailScreenState();
}

class _Sp800171RequirementDetailScreenState extends State<Sp800171RequirementDetailScreen> {
  bool _isGuidanceExpanded = false;
  bool _isAssessmentExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: widget.returnRoute != null && widget.returnLabel != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context);
                },
                tooltip: 'Back to ${widget.returnLabel}',
              )
            : null,
        title: Text(widget.requirement.requirementId),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              _copyRequirementToClipboard(context);
            },
            tooltip: 'Copy requirement',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with favoriting
            RequirementHeader(
              requirement: widget.requirement,
              familyColor: widget.familyColor,
            ),
            
            const SizedBox(height: 8),
            
            // Security Requirement section (always expanded, compact)
            _buildRequirementCard(context),

            // Parameters section (if any, always visible but compact)
            if (widget.requirement.parameters.isNotEmpty)
              _buildParametersCard(context),

            // Guidance section (collapsible)
            if (widget.requirement.guidance.isNotEmpty)
              _buildCollapsibleSection(
                context,
                title: 'Discussion',
                icon: Icons.info_outline,
                isExpanded: _isGuidanceExpanded,
                onToggle: () => setState(() => _isGuidanceExpanded = !_isGuidanceExpanded),
                child: SelectableText(
                  widget.requirement.guidance,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),

            // Assessment Objectives section (collapsible)
            if (widget.requirement.assessmentObjectives.isNotEmpty)
              _buildCollapsibleSection(
                context,
                title: 'Assessment Objectives (${widget.requirement.assessmentObjectives.length})',
                icon: Icons.checklist,
                isExpanded: _isAssessmentExpanded,
                onToggle: () => setState(() => _isAssessmentExpanded = !_isAssessmentExpanded),
                child: Column(
                  children: widget.requirement.assessmentObjectives
                      .asMap()
                      .entries
                      .map((entry) {
                    final index = entry.key + 1;
                    final objective = entry.value;
                    return _buildAssessmentObjective(
                      context,
                      index,
                      objective,
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 16),
            
            // Notes section
            RequirementNotesSection(
              requirementId: widget.requirement.requirementId,
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.familyColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, size: 18, color: widget.familyColor),
              const SizedBox(width: 8),
              Text(
                'Security Requirement',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: widget.familyColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatementParts(context),
        ],
      ),
    );
  }

  Widget _buildParametersCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.familyColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.familyColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, size: 18, color: widget.familyColor),
              const SizedBox(width: 8),
              Text(
                'Parameters',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: widget.familyColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...widget.requirement.parameters.map((param) {
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    param.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: widget.familyColor,
                        ),
                  ),
                  if (param.guideline.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    SelectableText(
                      param.guideline,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCollapsibleSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: widget.familyColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatementParts(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.requirement.statementParts.map((part) {
        return _buildStatementPart(context, part, 0);
      }).toList(),
    );
  }

  Widget _buildStatementPart(
    BuildContext context,
    Sp800171StatementPart part,
    int level,
  ) {
    final indent = level * 12.0;

    return Container(
      margin: EdgeInsets.only(left: indent, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (part.prose.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (part.label.isNotEmpty)
                  Text(
                    '${part.label}. ',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                Expanded(
                  child: SelectableText(
                    part.prose,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          if (part.subParts.isNotEmpty)
            ...part.subParts.map((subPart) {
              return _buildStatementPart(context, subPart, level + 1);
            }),
        ],
      ),
    );
  }

  Widget _buildAssessmentObjective(
    BuildContext context,
    int index,
    Sp800171AssessmentObjective objective,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: widget.familyColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$index',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: widget.familyColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(
              objective.prose,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _copyRequirementToClipboard(BuildContext context) {
    final buffer = StringBuffer();
    buffer.writeln('${widget.requirement.requirementId}: ${widget.requirement.title}');
    buffer.writeln();
    buffer.writeln('Security Requirement:');
    buffer.writeln(widget.requirement.fullStatement);

    if (widget.requirement.guidance.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Discussion:');
      buffer.writeln(widget.requirement.guidance);
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Requirement copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
