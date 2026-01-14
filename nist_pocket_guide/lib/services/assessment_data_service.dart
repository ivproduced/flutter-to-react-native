// lib/services/assessment_data_service.dart

import '../models/assessment_models.dart';
import '../models/oscal_models.dart';
import '../app_data_manager.dart';
import '../800-53_screens/widgets/control/control_statement_section.dart';
import 'utils/params_util.dart';

/// Service for loading and managing 800-53A assessment data from OSCAL
class AssessmentDataService {
  static AssessmentDataService? _instance;
  static AssessmentDataService get instance =>
      _instance ??= AssessmentDataService._();
  AssessmentDataService._();

  // Cache for assessment data
  final Map<String, ControlAssessment> _assessmentCache = {};

  /// Load assessment data for a specific control from OSCAL catalog
  Future<ControlAssessment?> getAssessmentData(String controlId) async {
    if (_assessmentCache.containsKey(controlId)) {
      return _assessmentCache[controlId];
    }

    // Get the control from the OSCAL catalog via AppDataManager
    final appDataManager = AppDataManager.instance;
    final catalog = appDataManager.catalog;

    // Find the control in the catalog
    final control = catalog.controls.cast<Control?>().firstWhere(
      (c) => c?.id.toLowerCase() == controlId.toLowerCase(),
      orElse: () => null,
    );

    if (control == null) {
      return null; // Control not found or catalog not loaded
    }

    // Convert OSCAL control assessment objectives to our assessment format
    final assessment = _convertOscalToAssessment(control);

    if (assessment != null) {
      _assessmentCache[controlId] = assessment;
    }

    return assessment;
  }

  /// Convert OSCAL Control assessment objectives to ControlAssessment format
  ControlAssessment? _convertOscalToAssessment(Control control) {
    // Get assessment objectives from the OSCAL control
    final assessmentObjectives = control.flatAssessmentObjectives;

    if (assessmentObjectives.isEmpty) {
      return null; // No assessment objectives available
    }

    // Expand control parameters for substitution
    final expandedParams = expandParams(control.params);

    // Group objectives by control part (e.g., AC-1a, AC-1b, AC-1c)
    final Map<String, List<Part>> groupedObjectives = {};

    for (final objective in assessmentObjectives) {
      // Extract part from objective ID (e.g., "ac-1_obj.a.1" -> "AC-1a")
      final partId = _extractPartIdFromOscalObjectiveId(
        objective.id ?? '',
        control.id,
      );

      if (!groupedObjectives.containsKey(partId)) {
        groupedObjectives[partId] = [];
      }
      groupedObjectives[partId]!.add(objective);
    }

    // Convert to assessment procedures
    final procedures =
        groupedObjectives.entries.map((entry) {
          return AssessmentProcedure(
            partId: entry.key,
            title: _generateProcedureTitle(entry.key, control.title),
            objectives:
                entry.value
                    .map(
                      (oscalPart) => AssessmentObjective(
                        id: oscalPart.id ?? 'unknown',
                        description: _substituteParamsInDescription(
                          oscalPart.prose ??
                              'Assessment objective description not available',
                          expandedParams,
                        ),
                        method: _inferAssessmentMethodFromOscal(oscalPart),
                        assessmentObjects: _extractAssessmentObjectsFromOscal(
                          oscalPart,
                        ),
                        potentialEvidence: _extractPotentialEvidenceFromOscal(
                          oscalPart,
                          entry.key,
                        ),
                      ),
                    )
                    .toList(),
            assessmentGuidance: _generateAssessmentGuidanceFromControl(
              entry.key,
              control,
            ),
          );
        }).toList();

    // Sort procedures by part ID
    procedures.sort((a, b) => a.partId.compareTo(b.partId));

    return ControlAssessment(
      controlId: control.id,
      controlTitle: control.title,
      procedures: procedures,
      generalGuidance: _generateGeneralGuidanceFromControl(control),
      references: ['NIST SP 800-53A Rev. 5.1.1', 'NIST SP 800-53 Rev. 5.1.1'],
      scopeGuidance:
          'Assessment should verify implementation and effectiveness of ${control.title.toLowerCase()}.',
    );
  }

  /// Extract part ID from OSCAL objective ID (e.g., "ac-1_obj.a.1" -> "AC-1a")
  String _extractPartIdFromOscalObjectiveId(
    String objectiveId,
    String controlId,
  ) {
    // Pattern matches like: ac-1_obj.a, ac-1_obj.a.1, ac-1_obj.b.2, etc.
    final regex = RegExp(r'([a-z]+)-(\d+)_obj\.([a-z]+)', caseSensitive: false);
    final match = regex.firstMatch(objectiveId);

    if (match != null) {
      final family = match.group(1)?.toUpperCase() ?? 'XX';
      final number = match.group(2) ?? '0';
      final part = match.group(3)?.toLowerCase() ?? 'a';
      return '$family-$number$part';
    }

    // Fallback: use control ID with 'a' suffix
    return '${controlId.toUpperCase()}a';
  }

  /// Generate a human-readable title for the procedure from OSCAL data
  String _generateProcedureTitle(String partId, String controlTitle) {
    final partLetter =
        partId.toLowerCase().isNotEmpty
            ? partId.toLowerCase().substring(partId.length - 1)
            : 'a';
    final baseName = controlTitle.split(' ').take(3).join(' ');

    final partTitles = {
      'a': 'Policy and Documentation',
      'b': 'Implementation and Procedures',
      'c': 'Review and Maintenance',
      'd': 'Additional Requirements',
      'e': 'Monitoring and Assessment',
    };

    final partTitle = partTitles[partLetter] ?? 'Assessment Procedures';
    return '$baseName - $partTitle';
  }

  /// Infer assessment method from OSCAL part properties and content
  AssessmentMethod _inferAssessmentMethodFromOscal(Part oscalPart) {
    final content = (oscalPart.prose ?? '').toLowerCase();
    final props =
        oscalPart.props
            .map((p) => '${p.name}:${p.value}')
            .join(' ')
            .toLowerCase();
    final combinedContent = '$content $props';

    // Look for method indicators in the content
    if (combinedContent.contains('test') ||
        combinedContent.contains('verify') ||
        combinedContent.contains('validate') ||
        combinedContent.contains('execute')) {
      return AssessmentMethod.test;
    } else if (combinedContent.contains('interview') ||
        combinedContent.contains('discuss') ||
        combinedContent.contains('question') ||
        combinedContent.contains('personnel')) {
      return AssessmentMethod.interview;
    } else {
      return AssessmentMethod.examine; // Default for document review
    }
  }

  /// Extract assessment objects from OSCAL part content
  List<String> _extractAssessmentObjectsFromOscal(Part oscalPart) {
    final objects = <String>{};
    final content = (oscalPart.prose ?? '').toLowerCase();

    // Extract common assessment objects from prose
    final objectPatterns = {
      'policy': 'Organizational policies',
      'procedure': 'Implementation procedures',
      'documentation': 'System documentation',
      'plan': 'System security plan',
      'record': 'Implementation records',
      'log': 'System logs and records',
      'configuration': 'System configuration',
      'personnel': 'Organizational personnel',
      'training': 'Training materials',
      'mechanism': 'Access control mechanisms',
    };

    for (final entry in objectPatterns.entries) {
      if (content.contains(entry.key)) {
        objects.add(entry.value);
      }
    }

    // Add objects from OSCAL properties if any
    for (final prop in oscalPart.props) {
      if (prop.name.toLowerCase().contains('object') ||
          prop.name.toLowerCase().contains('evidence')) {
        objects.add(prop.value);
      }
    }

    return objects.isEmpty
        ? ['System documentation', 'Implementation evidence']
        : objects.toList();
  }

  /// Extract potential evidence from OSCAL content and control part
  List<String> _extractPotentialEvidenceFromOscal(
    Part oscalPart,
    String partId,
  ) {
    final evidence = <String>{};
    final content = (oscalPart.prose ?? '').toLowerCase();

    // Add evidence based on content and part type
    if (content.contains('policy') || partId.toLowerCase().endsWith('a')) {
      evidence.addAll([
        'Documented organizational policies',
        'Policy approval documentation',
        'Policy distribution records',
      ]);
    }

    if (content.contains('procedure') || content.contains('implement')) {
      evidence.addAll([
        'Implementation procedures',
        'Standard operating procedures',
        'Process documentation',
      ]);
    }

    if (content.contains('review') || content.contains('update')) {
      evidence.addAll([
        'Review records and schedules',
        'Update documentation',
        'Approval records for changes',
      ]);
    }

    if (content.contains('training') || content.contains('personnel')) {
      evidence.addAll([
        'Training records and materials',
        'Personnel assignments and roles',
        'Competency documentation',
      ]);
    }

    return evidence.isEmpty
        ? [
          'Implementation documentation',
          'Compliance evidence',
          'Review records',
        ]
        : evidence.toList();
  }

  /// Generate assessment guidance from control information
  String _generateAssessmentGuidanceFromControl(
    String partId,
    Control control,
  ) {
    final guidance =
        control.parts
            .where((p) => p.name.toLowerCase() == 'guidance')
            .map((p) => p.prose)
            .where((prose) => prose != null && prose.isNotEmpty)
            .join(' ')
            .trim();

    if (guidance.isNotEmpty) {
      final truncatedGuidance =
          guidance.length > 200 ? '${guidance.substring(0, 200)}...' : guidance;
      return 'Assessment should focus on: $truncatedGuidance';
    }

    return 'Focus assessment on verifying effective implementation of $partId requirements. '
        'Ensure evidence demonstrates compliance with control objectives.';
  }

  /// Generate general guidance from control
  String _generateGeneralGuidanceFromControl(Control control) {
    return 'Assessment of ${control.title} focuses on evaluating the implementation, '
        'effectiveness, and compliance with the specified requirements. '
        'Assessors should verify both the presence and proper functioning of required controls.';
  }

  /// Get all available control IDs that have assessment data from the catalog
  Future<List<String>> getAvailableControls() async {
    final appDataManager = AppDataManager.instance;
    final catalog = appDataManager.catalog;

    // Return all control IDs that have assessment objectives
    return catalog.controls
        .where((control) => control.flatAssessmentObjectives.isNotEmpty)
        .map((control) => control.id)
        .toList();
  }

  /// Check if assessment data is available for a control
  Future<bool> hasAssessmentData(String controlId) async {
    final assessment = await getAssessmentData(controlId);
    return assessment != null;
  }

  /// Clear the assessment data cache
  void clearCache() {
    _assessmentCache.clear();
  }

  /// Substitute parameters in assessment objective descriptions using the same logic as control statements
  String _substituteParamsInDescription(String text, List<Parameter> params) {
    return ControlStatementSection.replaceParamsInString(text, params);
  }
}
