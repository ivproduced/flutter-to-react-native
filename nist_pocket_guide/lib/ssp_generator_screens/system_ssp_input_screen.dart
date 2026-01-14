import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/models/information_system.dart';
import 'package:nist_pocket_guide/provider/project_data_manager.dart';
import 'package:nist_pocket_guide/services/utils/ssp/ssp_utils.dart';
import 'package:nist_pocket_guide/ssp_generator_screens/widgets/parameter_input_widget.dart';
import 'package:nist_pocket_guide/models/system_parameter_block.dart';
import 'package:nist_pocket_guide/app_data_manager.dart';
import 'package:nist_pocket_guide/models/oscal_models.dart';
import 'package:nist_pocket_guide/models/assessment_objective_response.dart';
import 'package:provider/provider.dart';

// Add these within your _SystemSspInputScreenState class or at the file level

enum _MatchType {
  parameter,
  link,
}

class _MatchInfo {
  final RegExpMatch match;
  final _MatchType type;

  _MatchInfo(this.match, this.type);
}

class SystemSspInputScreen extends StatefulWidget {
  final String systemId;
  final Control control;

  const SystemSspInputScreen({
    super.key,
    required this.systemId,
    required this.control, // <<-- ADD THIS
  });

  @override
  State<SystemSspInputScreen> createState() => _SystemSspInputScreenState();
}

class _SystemSspInputScreenState extends State<SystemSspInputScreen> {
  bool _isDocumentationMode = true;
  InformationSystem? _system;
  List<SystemParameterBlock> _definedParameterBlocks = [];
  List<Part> _objectives = [];
  final Map<String, TextEditingController> _notesControllers = {};
  final List<AssessmentObjectiveResponse> _currentResponses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final projectManager = Provider.of<ProjectDataManager>(context, listen: false);
    _system = projectManager.getSystemById(widget.systemId);

    if (_system != null) {
      if (AppDataManager.instance.isInitialized) {
        _definedParameterBlocks = AppDataManager.instance.systemParameterBlocks;
        final appDataManager = AppDataManager.instance;
        // Load assessment data
        final control = appDataManager.getControlById("ac-2"); // Assuming a default control ID for testing
        if (control != null) {
          _objectives = control.flatAssessmentObjectives;
          final existingResponsesList = projectManager.getAssessmentObjectiveResponses(
            systemId: widget.systemId,
            controlId: "ac-2", // Assuming a default control ID for testing
          );
          final Map<String, AssessmentObjectiveResponse> existingResponsesMap = {
            for (var resp in existingResponsesList) resp.objectiveKey: resp
          };

          _currentResponses.clear();
          _notesControllers.clear();

          for (var objPart in _objectives) {
            final objectiveKey = getObjectiveKey(objPart);
            final existingResp = existingResponsesMap[objectiveKey];

            _notesControllers[objectiveKey] = TextEditingController(
              text: existingResp?.userNotes ?? '',
            );
            _currentResponses.add(AssessmentObjectiveResponse(
              objectiveKey: objectiveKey,
              objectiveProse: objPart.prose ?? 'Objective prose not available.',
              userNotes: existingResp?.userNotes,
              isMet: existingResp?.isMet == true, // Only true if explicitly true, otherwise false
            ));
          }
        }
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _notesControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  

  Future<bool> _saveDraftResponses({bool showSnackbar = true}) async {
    if (_system == null) return false;

    for (var response in _currentResponses) {
      final controller = _notesControllers[response.objectiveKey];
      if (controller != null) {
        response.userNotes = controller.text.trim();
      }
    }

    final projectManager = Provider.of<ProjectDataManager>(context, listen: false);
    bool success = await projectManager.saveAssessmentObjectiveResponses(
      systemId: widget.systemId,
      controlId: "ac-2", // Assuming a default control ID
      responses: _currentResponses,
    );

    if (mounted && showSnackbar) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Draft responses saved!' : 'Error saving draft.')),
      );
    }
    return success;
  }

    void _triggerSave() {
    // Call _saveDraftResponses and handle success/failure if needed
    _saveDraftResponses();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _system == null) {
      return Scaffold(
        appBar: AppBar(
          actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _triggerSave,
          ),
        ],
          title: const Text('System SSP Input')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${_system!.name} - SSP Input'),
      ),
      body: Column(
        children: [
          SegmentedButton<bool>(
            segments: const <ButtonSegment<bool>>[
              ButtonSegment<bool>(value: true, label: Text('Documentation')),
              ButtonSegment<bool>(value: false, label: Text('Assessment')),
            ],
            selected: {_isDocumentationMode},
            onSelectionChanged: (Set<bool> newSelection) {
              setState(() {
                _isDocumentationMode = newSelection.first;
              });
            },
          ),
          Expanded(
            child: _isDocumentationMode
                ? _buildDocumentationSection()
                : _buildAssessmentSection(),
          ),
        ],
      ),
    );
  }

 Widget _buildDocumentationSection() {
  return ListView.builder(
    padding: const EdgeInsets.all(16.0),
    itemCount: _definedParameterBlocks.length,
    itemBuilder: (context, index) {
      final block = _definedParameterBlocks[index];
      return Card(
        margin: const EdgeInsets.only(bottom: 16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column( // Wrap content in a Column
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ParameterInputWidget(
                system: _system!,
                block: block,
                onChanged: () {
                  setState(() {});
                },
              ),
              const SizedBox(height: 8), // Added spacing before the button
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(40),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Statement editing is no longer available. Please use the notes field for any details.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  Widget _buildAssessmentSection() {
  // Ensure your helper functions like _replaceParamsAsTextSpans, _resolveParam, etc.,
  // are methods of this _SystemSspInputScreenState class or accessible in this scope.

  return ListView.builder(
    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
    itemCount: _objectives.length,
    itemBuilder: (context, index) {
      final objectivePart = _objectives[index];
      final displayLabel = getObjectiveDisplayLabel(objectivePart);
      final objectiveKey = getObjectiveKey(objectivePart);
      final notesController = _notesControllers[objectiveKey];
      AssessmentObjectiveResponse? currentResponseObject;
      try {
        currentResponseObject = _currentResponses.firstWhere((r) => r.objectiveKey == objectiveKey);
      } catch (e) {
        // if (kDebugMode) print("Error finding response object for $objectiveKey in build");
      }

      if (notesController == null || currentResponseObject == null) {
        return Card(child: ListTile(title: Text("Error loading for $displayLabel")));
      }

      // Assuming widget.control.params is the List<Parameter>
      // If not, adjust this to where your List<Parameter> is stored for the current control.
      final List<Parameter> currentControlParams = widget.control.params;

      return Card(
        margin: const EdgeInsets.only(bottom: 16.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Objective: $displayLabel",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              // MODIFICATION HERE: Replace SelectableText with SelectionArea and RichText
              SelectionArea( // Makes the RichText content selectable
                child: RichText(
                  text: TextSpan(
                    // Default style for the entire prose
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
                    children: _replaceParamsAsTextSpans(
                      objectivePart.prose ?? 'Objective details not specified.',
                      currentControlParams, // Pass the relevant parameters
                      context,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: currentResponseObject.isMet,
                    onChanged: (bool? newValue) {
                      if (newValue != null) {
                        setState(() {
                          currentResponseObject!.isMet = newValue;
                        });
                      }
                    },
                  ),
                  const Flexible(
                    child: Text("Objective Met by Standard Implementation"),
                  ),
                ],
              ),
              if (!currentResponseObject.isMet) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: 'Notes/Deviations for Objective $displayLabel',
                    hintText: 'Any specific details or exceptions...',
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    currentResponseObject!.userNotes = value.trim();
                  },
                ),
              ]
            ],
          ),
        ),
      );
    },
  );
}

// --- Private helper functions ---

  Parameter? _findParamById(String id, List<Parameter> params) {
    for (final param in params) {
      if (param.id == id) {
        return param;
      }
      // Assuming 'alt-identifier' is a valid way to find params.
      // Consider if 'alt-identifier' should be unique or if multiple params can have the same.
      for (final prop in param.props) {
        if (prop.name == 'alt-identifier' && prop.value == id) {
          return param;
        }
      }
    }
    return null;
  }

  String _resolveParam(String paramId, List<Parameter> params) {
    final param = _findParamById(paramId, params);

    if (param == null) {
      debugPrint('❗ Missing param for ID: $paramId');
      return '[Unknown Param: $paramId]'; // Provide paramId for better debugging
    }

    // Optional: Add check for referral prop if you implement Scenario 2 for parameter substitution
    // final referralProp = param.props.firstWhere(...)
    // if (referralProp.value.isNotEmpty) { return _resolveParam(referralProp.value, params); }


    final aggregates = param.props
        .where((prop) => prop.name == 'aggregates')
        .map((prop) => prop.value)
        .toList();

    if (aggregates.isNotEmpty) {
      final resolvedAggregates = aggregates
          .map((aggId) => _resolveParam(aggId, params))
          .toList();
      final finalAggregates = _deduplicateAndMergeSecurityPrivacy(resolvedAggregates);
      return finalAggregates.join(', ');
    }

    if (param.select != null && param.select!.choice.isNotEmpty) {
      final processedChoices = param.select!.choice
          .map((choice) => _replaceParamsInString(choice, params))
          .toList();
      final finalChoices = _deduplicateAndMergeSecurityPrivacy(processedChoices);
      return _formatChoices(finalChoices);
    }

    if (param.label != null && param.label!.isNotEmpty) {
      // NIST OSCAL Guide: "For ODPs that do not have predefined selections (i.e., select is empty),
      // the label field contains human-readable text of what the organization is to define."
      // The "Organization-defined" prefix is often part of the label itself in well-formed ODPs,
      // or it's handled by how the label is constructed in the source OSCAL data.
      // Your original logic for _odp. seems specific; ensure it aligns with your OSCAL source.
      if (param.id.contains('_odp') && (param.select == null || param.select!.choice.isEmpty)) {
         return 'Organization-defined ${param.label!}'; // This prepends "Organization-defined"
      } else {
         return param.label!;
      }
    }

    if (param.values.isNotEmpty) {
      return param.values.first;
    }

    debugPrint('❗ Parameter has no resolvable content (aggregates, select, label, or values): $paramId');
    return '[Param $paramId not fully defined]';
  }

List<TextSpan> _replaceParamsAsTextSpans(String prose, List<Parameter> params, BuildContext context) {
  final spans = <TextSpan>[];
  final paramPattern = RegExp(r'{{\s*insert:\s*param,\s*([\w\-\.]+)\s*}}');
  // Pattern for links like [display text](#target-id)
  final linkPattern = RegExp(r'\[([^\]]+?)\]\((#[\w\-\.\/]+?)\)');

  List<_MatchInfo> allMatches = [];
  paramPattern.allMatches(prose).forEach((match) {
    allMatches.add(_MatchInfo(match, _MatchType.parameter));
  });
  linkPattern.allMatches(prose).forEach((match) {
    allMatches.add(_MatchInfo(match, _MatchType.link));
  });

  allMatches.sort((a, b) => a.match.start.compareTo(b.match.start));

  int lastMatchEnd = 0;

  for (final matchInfo in allMatches) {
    final match = matchInfo.match;
    if (match.start > lastMatchEnd) {
      spans.add(TextSpan(
        text: prose.substring(lastMatchEnd, match.start),
        // Default style inherited from RichText's TextSpan in _buildPart
      ));
    }

    if (matchInfo.type == _MatchType.parameter) {
      final paramId = match.group(1);
      if (paramId != null) {
        final resolved = _resolveParam(paramId, params);
        spans.add(TextSpan(
          text: resolved,
          style: const TextStyle( // Parameters: bold and italic
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            // Color will be inherited (should be black by default from parent style)
          ),
        ));
      }
    } else if (matchInfo.type == _MatchType.link) {
      // This is where the change is:
      final displayText = match.group(1); // This is the text like "AU-2a"

      if (displayText != null) {
        spans.add(TextSpan(
          text: displayText, // Show only the display text part of the link
          style: const TextStyle( // References: just bold (and black by inheritance)
            fontWeight: FontWeight.bold,
            // Color will be inherited (should be black by default from parent style in _buildPart)
            // No decoration (underline)
          ),
          // No recognizer, so it's not tappable
        ));
      }
    }
    lastMatchEnd = match.end;
  }

  if (lastMatchEnd < prose.length) {
    spans.add(TextSpan(
      text: prose.substring(lastMatchEnd),
    ));
  }
  return spans;
}

  String _replaceParamsInString(String text, List<Parameter> params) {
    final paramPattern = RegExp(r'{{\s*insert:\s*param,\s*([\w\-\.]+)\s*}}');
    return text.replaceAllMapped(paramPattern, (match) {
      final paramId = match.group(1);
      if (paramId != null) {
        return _resolveParam(paramId, params);
      }
      return ''; // Should not happen if regex matches
    });
  }

  String _formatChoices(List<String> choices) {
    if (choices.isEmpty) return '';
    if (choices.length == 1) return choices.first;
    if (choices.length == 2) return '${choices[0]} or ${choices[1]}';
    return '${choices.sublist(0, choices.length - 1).join(', ')}, or ${choices.last}';
  }

  List<String> _deduplicateAndMergeSecurityPrivacy(List<String> inputs) {
    // Simplified deduplication, consider if case sensitivity is important
    final uniqueInputs = inputs.toSet().toList();
    
    // The security and privacy merging logic seems specific.
    // Ensure it behaves as expected with various inputs.
    final lowerInputs = uniqueInputs.map((e) => e.toLowerCase()).toList();
    bool hasSecurity = lowerInputs.any((text) => text.contains('security'));
    bool hasPrivacy = lowerInputs.any((text) => text.contains('privacy'));

    List<String> result = [];
    bool mergedTermAdded = false;

    if (hasSecurity && hasPrivacy) {
      // Preference to add merged term first if both are present
      result.add('organization-defined security and privacy attributes');
      mergedTermAdded = true;
    }

    for (final text in uniqueInputs) {
      final lower = text.toLowerCase();
      if (mergedTermAdded && (lower.contains('security') || lower.contains('privacy'))) {
        // If merged term was added, skip individual security/privacy terms
        continue;
      }
      result.add(text);
    }
    // If the result is just the merged term, or if no merge happened, this is fine.
    // If only one of security/privacy was present, it will be included.
    return result.toSet().toList(); // Final deduplication
  }
}