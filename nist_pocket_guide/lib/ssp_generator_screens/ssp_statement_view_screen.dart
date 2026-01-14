// lib/screens/ssp_statement_display_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nist_pocket_guide/app_data_manager.dart';
import 'package:nist_pocket_guide/models/assessment_objective_response.dart';
import 'package:nist_pocket_guide/models/information_system.dart';
import 'package:nist_pocket_guide/models/oscal_models.dart';
import 'package:nist_pocket_guide/models/llm_objective_data.dart';
import 'package:nist_pocket_guide/provider/project_data_manager.dart';
import 'package:nist_pocket_guide/ssp_generator_screens/ssp_statement_template_utils.dart';
import 'package:provider/provider.dart';

class SspStatementDisplayScreen extends StatefulWidget {
  final String systemId;
  final String controlId;

  const SspStatementDisplayScreen(
      {super.key, required this.systemId, required this.controlId});

  @override
  State<SspStatementDisplayScreen> createState() =>
      _SspStatementDisplayScreenState();
}

class _SspStatementDisplayScreenState extends State<SspStatementDisplayScreen> {
  InformationSystem? _system;
  Control? _control;
  LlmControlObjectiveData? _llmControlData; // To store LLM data for the control
  List<AssessmentObjectiveResponse> _objectiveResponses = [];
  List<InlineSpan> _generatedParagraphSpans = [];
  List<InlineSpan> _generatedBulletedSpans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAndGenerateData();
  }

  // --- Helper functions for labels and keys ---
  String _getObjectiveKeyFromPart(Part objectivePart) {
    if (objectivePart.id != null && objectivePart.id!.isNotEmpty) {
      return objectivePart.id!;
    }
    // if (kDebugMode) {
    //   print("SSP Display WARN: Objective part missing ID for key. Prose: \\${objectivePart.prose}");
    // }
    return "${widget.controlId}_proseHash_${(objectivePart.prose ?? '').hashCode}";
  }

 String _simplifyOscalLabel(String rawLabel) {
    if (rawLabel.isEmpty) return "?";
    String processedLabel = rawLabel;
    // Ensure widget.controlId has a hyphen before attempting to split
    String controlIdPrefix = "";
    if (widget.controlId.contains('-')) {
       controlIdPrefix = "${widget.controlId.toUpperCase().split('-').first}-${widget.controlId.split('-').last.replaceAll(RegExp(r'\..*'), '')}";
       processedLabel = processedLabel.replaceFirst(RegExp("^$controlIdPrefix", caseSensitive: false), "").trim();
    } else {
      // Handle cases where controlId might not have a hyphen (e.g., family-level or unconventional IDs)
      // This part might need adjustment based on your actual controlId formats
      processedLabel = processedLabel.replaceFirst(RegExp("^${widget.controlId.toUpperCase()}", caseSensitive: false), "").trim();
    }

    processedLabel = processedLabel.replaceFirst(RegExp(r"^[._\s]*"), "").trim();
    if (processedLabel.endsWith('.')) {
      processedLabel = processedLabel.substring(0, processedLabel.length - 1);
    }
    processedLabel = processedLabel.replaceAll('[', '(').replaceAll(']', ')');
    // Relaxed the regex slightly to better catch typical objective labels like 'a', '1', 'a.1'
    if (RegExp(r"^[a-zA-Z0-9]+(?:[\.\(\[][a-zA-Z0-9]+[\)\]])?$").hasMatch(processedLabel) && processedLabel.length <= 7) {
          return processedLabel.toLowerCase();
    }
    return processedLabel.toLowerCase().isNotEmpty ? processedLabel.toLowerCase() : rawLabel.toLowerCase();
  }

  String _getDisplayLabelFromPart(Part objectivePart) {
    try {
      final labelProp = objectivePart.props.firstWhere(
        (prop) => prop.name.toLowerCase() == 'label',
      );
      return _simplifyOscalLabel(labelProp.value);
    } catch (e) {
      if (objectivePart.id != null && objectivePart.id!.isNotEmpty) {
        String id = objectivePart.id!;
        if (id.contains("_obj.")) { id = id.substring(id.indexOf("_obj.") + 5); }
        else if (id.startsWith("${widget.controlId}_")) { id = id.substring(widget.controlId.length + 1); }
        else if (id.contains(".")) { id = id.split('.').last; }
        else if (id.contains("_")) { id = id.split('_').last; }
        return _simplifyOscalLabel(id.toUpperCase());
      }
      int indexInList = _control?.flatAssessmentObjectives.indexOf(objectivePart) ?? _objectiveResponses.indexOf(
        _objectiveResponses.firstWhere((r) => r.objectiveKey == _getObjectiveKeyFromPart(objectivePart), orElse: () => AssessmentObjectiveResponse(objectiveKey: '', objectiveProse: '', isMet: false))
      );
      return (indexInList != -1) ? String.fromCharCode('a'.codeUnitAt(0) + indexInList) : "item";
    }
  }

  String _getDisplayLabelFromResponse(AssessmentObjectiveResponse response) {
    if (_control != null) {
      try {
        final originalPart = _control!.flatAssessmentObjectives.firstWhere(
          (p) => _getObjectiveKeyFromPart(p) == response.objectiveKey
        );
        return _getDisplayLabelFromPart(originalPart);
      } catch (e) {
        // if (kDebugMode) print("Display WARN: Part for key \\${response.objectiveKey} not found.");
      }
    }
    String key = response.objectiveKey;
    if (key.contains("_obj.")) return _simplifyOscalLabel(key.substring(key.indexOf("_obj.") + 5));
    if (key.startsWith("${widget.controlId}_proseHash_")) {
      final index = _objectiveResponses.indexOf(response);
      return (index != -1) ? String.fromCharCode('a'.codeUnitAt(0) + index) : "?";
    }
    if (key.contains(".")) return _simplifyOscalLabel(key.split('.').last);
    return _simplifyOscalLabel(key);
  }
  // --- END HELPER FUNCTIONS ---

  Future<void> _loadAndGenerateData() async {
    if (!mounted) return;
    setStateIfMounted(() => _isLoading = true);

    final projectManager = Provider.of<ProjectDataManager>(context, listen: false);
    final appDataManager = AppDataManager.instance;
    _system = projectManager.getSystemById(widget.systemId);
    _control = appDataManager.getControlById(widget.controlId);

    if (_control != null) {
      // Fetch LlmControlObjectiveData for the current control
      // ASSUMPTION: AppDataManager has a method to get this data.
      // Replace 'getLlmDataForControl' with your actual method.
      _llmControlData = appDataManager.getLlmObjectiveDataForControl(_control!.id); // CORRECTED NAME
      // if (_llmControlData == null && kDebugMode) {
      //   if (kDebugMode) {
      //     print("SSP Display INFO: No LLM-generated data found for control \\${_control!.id}");
      //   }
      // }
    } else {
       _llmControlData = null; // Ensure it's null if control is null
    }


    if (_system != null && _control != null) {
      List<AssessmentObjectiveResponse> savedResponses = projectManager.getAssessmentObjectiveResponses(
        systemId: widget.systemId,
        controlId: widget.controlId,
      );
      Map<String, AssessmentObjectiveResponse> savedResponsesMap = {
        for (var resp in savedResponses) resp.objectiveKey: resp
      };
      final List<Part> actualObjectiveParts = _control!.flatAssessmentObjectives;
      _objectiveResponses.clear();
      for (var actualObjPart in actualObjectiveParts) {
        final String objectiveKey = _getObjectiveKeyFromPart(actualObjPart);
        final AssessmentObjectiveResponse respToShow;
        if (savedResponsesMap.containsKey(objectiveKey)) {
          var savedResp = savedResponsesMap[objectiveKey]!;
          respToShow = AssessmentObjectiveResponse(
              objectiveKey: savedResp.objectiveKey,
              objectiveProse: savedResp.objectiveProse,
              userNotes: savedResp.userNotes,
              isMet: savedResp.isMet);
        } else {
          respToShow = AssessmentObjectiveResponse(
            objectiveKey: objectiveKey,
            objectiveProse: actualObjPart.prose ?? 'Objective details not specified.',
            userNotes: null,
            isMet: false, // Default to true if not explicitly saved otherwise
          );
        }
        _objectiveResponses.add(respToShow);
      }
    } else {
        _objectiveResponses = [];
    }
    setStateIfMounted(() => _isLoading = false);
  }

  void setStateIfMounted(VoidCallback f) {
    if (mounted) setState(f);
  }

  void _generateStyledStatements() {
    if (!mounted || _control == null || _system == null ) {
      _generatedParagraphSpans = [const TextSpan(text: "Control or system data not available.")];
      _generatedBulletedSpans = [const TextSpan(text: "Control or system data not available.")];
      return;
    }

    final String companyName = _system!.companyAgencyName?.isNotEmpty == true
        ? _system!.companyAgencyName!
        : "The organization";

    final normalStyle = const TextStyle(
      color: Colors.black,
      decoration: TextDecoration.none,
      fontWeight: FontWeight.normal,
    );
    final substitutedStyle = normalStyle.copyWith(
      fontWeight: FontWeight.bold,
      fontStyle: FontStyle.italic,
      color: Colors.black,
    );
    final notMetStyle = normalStyle.copyWith(
      color: Colors.red.shade700,
      fontWeight: FontWeight.w500,
    );
    final objectiveLabelStyle = normalStyle.copyWith(fontWeight: FontWeight.w600);

    // --- PARAGRAPH STATEMENT ---
    List<InlineSpan> tempParagraphSpans = [];
    // Get combined summary template from _llmControlData
    String? combinedTemplate = _llmControlData?.llmGeneratedControlSummary;

    if (combinedTemplate != null && combinedTemplate.isNotEmpty) {
      // Gather all user-filled placeholder values for this control
      final allObjectivePlaceholders = <String, String>{};
      final controlImpl = _system!.controlImplementations[_control!.id];
      if (controlImpl != null && controlImpl.llmObjectivePlaceholderValues.isNotEmpty) {
        for (final objMap in controlImpl.llmObjectivePlaceholderValues.values) {
          for (final entry in objMap.entries) {
            // Remove brackets if present
            final cleanedKey = entry.key.replaceAll('[', '').replaceAll(']', '');
            allObjectivePlaceholders[cleanedKey] = entry.value;
          }
        }
      }

      // Merge with systemParameterBlockValues (user values take precedence)
      final mergedValues = Map<String, String>.from(_system!.systemParameterBlockValues)
        ..addAll(allObjectivePlaceholders);

      tempParagraphSpans = substituteBlockValuesAndStyle(
          combinedTemplate,
          mergedValues,
          companyName,
          normalStyle,
          substitutedStyle
      );
    } else {
      final mainImpl = _system!.controlImplementations[_control!.id];
      if (mainImpl != null && mainImpl.implementationDetails.trim().isNotEmpty) {
        tempParagraphSpans.add(TextSpan(text: mainImpl.implementationDetails.trim(), style: normalStyle));
        if (_objectiveResponses.isNotEmpty && _objectiveResponses.every((r) => r.isMet)) {
          tempParagraphSpans.add(TextSpan(text: "\nAll specific assessment objectives are met via this approach.", style: normalStyle));
        } else if (_objectiveResponses.isNotEmpty && _objectiveResponses.any((r) => !r.isMet)){
            tempParagraphSpans.add(TextSpan(text: "\nNote: One or more objectives are not fully met. See details.", style: normalStyle));
        }
      } else {
          tempParagraphSpans.add(TextSpan(text: "No consolidated summary or main implementation details provided.", style: normalStyle));
      }
    }
    _generatedParagraphSpans = tempParagraphSpans;

    // --- BULLETED OBJECTIVE-BASED STATEMENT ---
    List<InlineSpan> tempBulletedSpans = [];
    tempBulletedSpans.add(TextSpan(
        text: "The following implementation details apply to ${_control!.id} - ${_control!.title}. User notes provide additional context or deviations.\n\n",
        style: normalStyle));

    if (_objectiveResponses.isEmpty) {
      tempBulletedSpans.add(TextSpan(text: "(No specific assessment objectives found or processed for this control.)\n", style: normalStyle.copyWith(fontStyle: FontStyle.italic)));
      final mainImpl = _system!.controlImplementations[_control!.id];
        if (mainImpl != null && mainImpl.implementationDetails.trim().isNotEmpty) {
          tempBulletedSpans.add(TextSpan(text: "\nOverall Implementation Note: ${mainImpl.implementationDetails.trim()}", style: normalStyle));
        }
    }

    for (var response in _objectiveResponses) {
      String displayKey = _getDisplayLabelFromResponse(response);
      tempBulletedSpans.add(TextSpan(text: "($displayKey) ", style: objectiveLabelStyle));

      if (response.isMet) {
        // Get objective-specific template from _llmControlData
        String objectiveTemplate = _llmControlData?.llmGeneratedObjectiveStatements
            .firstWhere(
                (stmt) => stmt.objectiveId == response.objectiveKey,
                // Provide a default LlmObjectiveStatement if not found
                orElse: () => LlmObjectiveStatement(
                    objectiveId: response.objectiveKey, // For completeness
                    objectiveProseOriginal: response.objectiveProse, // For completeness
                    llmGeneratedStatement: "This objective is met using standard organizational parameters and procedures.", llmGeneratedQuestion: '', placeholders: []
                )
            )
            .llmGeneratedStatement // Get the statement string
            // Final fallback if _llmControlData was null or somehow firstWhere failed unexpectedly (should not with orElse)
            ?? "This objective is met using standard organizational parameters and procedures.";

// Get user-filled placeholder values for this objective
final placeholderValues = _system!
    .controlImplementations[_control!.id]
    ?.llmObjectivePlaceholderValues[response.objectiveKey] ?? {};

// If your template expects keys without brackets, ensure that's the case:
final cleanedPlaceholderValues = {
  for (var entry in placeholderValues.entries)
    entry.key.replaceAll('[', '').replaceAll(']', ''): entry.value
};

tempBulletedSpans.addAll(
  formatRichTextFromTemplate(
    context,
    objectiveTemplate,
    cleanedPlaceholderValues,
    defaultStyle: normalStyle,
    filledValueStyle: substitutedStyle,
    placeholderStyle: normalStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.red.shade700),
  )
);

        if (response.userNotes != null && response.userNotes!.trim().isNotEmpty) {
          // FIX: Use withAlpha instead of withOpacity
          Color? originalColor = normalStyle.color;
          Color? notesColor = originalColor?.withAlpha((255 * 0.8).round());
          tempBulletedSpans.add(TextSpan(
              text: "\n  ADDITIONAL NOTES: ${response.userNotes!.trim()}",
              style: normalStyle.copyWith(fontStyle: FontStyle.italic, color: notesColor)
          ));
        }
      } else {
        // Use LLM-generated template or fallback to prose for unmet objectives, with placeholders filled
        String objectiveTemplate = _llmControlData?.llmGeneratedObjectiveStatements
            .firstWhere((stmt) => stmt.objectiveId == response.objectiveKey,
                orElse: () => LlmObjectiveStatement(
                    objectiveId: response.objectiveKey,
                    objectiveProseOriginal: response.objectiveProse,
                    llmGeneratedStatement: response.objectiveProse,
                    llmGeneratedQuestion: '',
                    placeholders: []))
            .llmGeneratedStatement
            ?? response.objectiveProse;
        // Placeholder values for this objective
        final placeholderValuesUnmet = _system!
            .controlImplementations[_control!.id]
            ?.llmObjectivePlaceholderValues[response.objectiveKey] ?? {};
        final cleanedUnmetValues = {
          for (var entry in placeholderValuesUnmet.entries)
            entry.key.replaceAll('[', '').replaceAll(']', ''): entry.value
        };
        tempBulletedSpans.addAll(
          formatRichTextFromTemplate(
            context,
            objectiveTemplate,
            cleanedUnmetValues,
            defaultStyle: normalStyle,
            filledValueStyle: substitutedStyle,
            placeholderStyle: normalStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.red.shade700),
          ),
        );
        // Indicate unmet status
        tempBulletedSpans.add(TextSpan(text: "\n[OBJECTIVE NOT MET]", style: notMetStyle));
      }
      tempBulletedSpans.add(const TextSpan(text: "\n\n"));
    }
    _generatedBulletedSpans = tempBulletedSpans;

    if (_generatedParagraphSpans.isEmpty || (_generatedParagraphSpans.length == 1 && (_generatedParagraphSpans.first as TextSpan).text!.contains("not available"))){
        if (_generatedBulletedSpans.any((s) => s is TextSpan && (s.text?.contains("NOT MET") ?? false))) {
            _generatedParagraphSpans = [TextSpan(text: "This control is not fully implemented. Please refer to the detailed objective-based statement.", style: normalStyle)];
        } else {
            _generatedParagraphSpans = [TextSpan(text: "No consolidated summary. Refer to detailed objectives.", style: normalStyle)];
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoading && _system != null && _control != null) {
      // Regenerate statements if they are empty, or potentially if data changed.
      // For simplicity, we'll regenerate if they are empty, assuming _loadAndGenerateData handles data updates.
      if(_generatedBulletedSpans.isEmpty && _generatedParagraphSpans.isEmpty) {
          _generateStyledStatements();
      }
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('SSP Statement for ${widget.controlId}')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_system == null || _control == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('System or Control data not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('SSP Statement for ${_control!.id}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all_outlined),
            tooltip: 'Copy Bulleted Statement (Plain Text)',
            onPressed: () {
              String plainTextBulleted = _generatedBulletedSpans.map((s) {
                if (s is TextSpan) return s.text ?? '';
                return '';
              }).join();
              Clipboard.setData(ClipboardData(text: plainTextBulleted));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bulleted statement (plain text) copied!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Implementation (Paragraph Form)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SelectableText.rich(
                  TextSpan(
                    children: _generatedParagraphSpans.isNotEmpty
                        ? _generatedParagraphSpans
                        : [const TextSpan(text: "Generating statement...")],
                  ),
                  style: DefaultTextStyle.of(context).style.copyWith(height: 1.5, fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ExpansionTile(
              title: Text(
                'Detailed Objective-Based Statement',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              initiallyExpanded: true,
              childrenPadding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0, bottom: 8.0),
              children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SelectableText.rich(
                      TextSpan(
                        style: DefaultTextStyle.of(context).style.copyWith(height: 1.5, fontSize: 18),
                        children: _generatedBulletedSpans.isNotEmpty
                            ? _generatedBulletedSpans
                            : [const TextSpan(text: "Generating detailed statement...")],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}