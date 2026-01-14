import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/app_data_manager.dart';
import 'package:nist_pocket_guide/models/assessment_objective_response.dart';
import 'package:nist_pocket_guide/models/information_system.dart';
import 'package:nist_pocket_guide/models/oscal_models.dart';
import 'package:nist_pocket_guide/provider/project_data_manager.dart';
import 'package:provider/provider.dart';
import 'ssp_statement_view_screen.dart';

class AssessmentObjectiveInputScreen extends StatefulWidget {
  final String systemId;
  final String controlId;

  const AssessmentObjectiveInputScreen({
    super.key,
    required this.systemId,
    required this.controlId,
  });

  @override
  State<AssessmentObjectiveInputScreen> createState() =>
      _AssessmentObjectiveInputScreenState();
}

class _AssessmentObjectiveInputScreenState
    extends State<AssessmentObjectiveInputScreen> {
  InformationSystem? _system;
  Control? _control;
  List<Part> _objectives = [];
  final Map<String, TextEditingController> _notesControllers = {};
  List<AssessmentObjectiveResponse> _currentResponses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _setStateIfMounted(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  String _getObjectiveDisplayLabel(Part objectivePart) {
    try {
      final labelProp = objectivePart.props.firstWhere(
        (prop) => prop.name.toLowerCase() == 'label',
      );
      String rawLabel = labelProp.value;
      // Remove trailing period if present
      if (rawLabel.endsWith('.')) {
        rawLabel = rawLabel.substring(0, rawLabel.length - 1);
      }
      // Regex to extract common objective label patterns more reliably
      RegExp commonLabelPattern = RegExp(
        r'(?:[A-Z0-9]+-[\w.-]+[.]([a-zA-Z0-9]+(?:[(]\w+[)])?(?:[.]\w+)?))$|^(?:[a-zA-Z][.])?([a-zA-Z0-9]+(?:[(]\w+[)])?(?:[.]\w+)*)$',
      );
      Match? match = commonLabelPattern.firstMatch(rawLabel);
      if (match != null) {
        if (match.group(1) != null && match.group(1)!.isNotEmpty) {
          return match.group(1)!.toUpperCase();
        }
        if (match.group(2) != null && match.group(2)!.isNotEmpty) {
          return match.group(2)!.toUpperCase();
        }
      }
      return rawLabel; // Fallback to the original raw label if no pattern matches
    } catch (e) {
      // Fallback if 'label' prop is not found or another error occurs
      if (objectivePart.id != null && objectivePart.id!.isNotEmpty) {
        String id = objectivePart.id!;
        if (id.contains("obj.")) {
          id = id.substring(id.indexOf("obj.") + 4); // "obj.".length is 4
        } else if (id.contains(".")) {
          // Attempt to get the last part of a dotted ID
          id = id.split('.').last;
        } else if (id.length == 1 && RegExp(r'[a-zA-Z]').hasMatch(id)) {
          // Handles single letter IDs like 'a', 'b'
          // No change needed, just return it uppercased
        }
        return id.toUpperCase();
      }
      // Fallback to index if ID is not usable
      final indexInList = _objectives.indexOf(objectivePart);
      return (indexInList != -1)
          ? "ITEM ${String.fromCharCode('A'.codeUnitAt(0) + indexInList)}"
          : "OBJECTIVE";
    }
  }

  String _getObjectiveKey(Part objectivePart) {
    if (objectivePart.id != null && objectivePart.id!.isNotEmpty) {
      return objectivePart.id!;
    }
    // Fallback for parts without an ID - this should be rare for objectives
    if (kDebugMode) {
      print(
        "AssessmentInputScreen WARN: Objective part missing ID. Key generated from prose+hash. Prose: ${objectivePart.prose}",
      );
    }
    return "${widget.controlId}_proseHash_${(objectivePart.prose ?? DateTime.now().microsecondsSinceEpoch.toString()).hashCode}";
  }

  Future<void> _loadData() async {
    _setStateIfMounted(() => _isLoading = true);
    final projectManager = Provider.of<ProjectDataManager>(
      context,
      listen: false,
    );
    final appDataManager = AppDataManager.instance;

    _system = projectManager.getSystemById(widget.systemId);
    _control = appDataManager.getControlById(widget.controlId);

    if (_control != null) {
      _objectives = _control!.flatAssessmentObjectives;

      final existingResponsesList = projectManager
          .getAssessmentObjectiveResponses(
            systemId: widget.systemId,
            controlId: widget.controlId,
          );
      final Map<String, AssessmentObjectiveResponse> existingResponsesMap = {
        for (var resp in existingResponsesList) resp.objectiveKey: resp,
      };

      _currentResponses.clear();
      _notesControllers.forEach((_, controller) => controller.dispose());
      _notesControllers.clear();

      for (var objPart in _objectives) {
        final objectiveKey = _getObjectiveKey(objPart);
        final existingResp = existingResponsesMap[objectiveKey];

        _notesControllers[objectiveKey] = TextEditingController(
          text: existingResp?.userNotes ?? '', // For the notes field
        );
        _currentResponses.add(
          AssessmentObjectiveResponse(
            objectiveKey: objectiveKey,
            objectiveProse:
                objPart.prose ?? 'Objective prose not available from source.',
            userNotes: existingResp?.userNotes,
            builtStatement: existingResp?.builtStatement, // Load builtStatement
            isMet:
                existingResp?.isMet ==
                true, // Default to false unless explicitly true
          ),
        );
      }
    } else {
      _objectives = [];
      _currentResponses = [];
      _notesControllers.forEach((_, controller) => controller.dispose());
      _notesControllers.clear();
      if (kDebugMode) {
        print(
          "AssessmentObjectiveInputScreen: Control ${widget.controlId} not found.",
        );
      }
    }
    _setStateIfMounted(() => _isLoading = false);
  }

  @override
  void dispose() {
    _notesControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<bool> _saveDraftResponses({bool showSnackbar = true}) async {
    if (_system == null || _control == null) {
      if (mounted && showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error: System or Control data missing. Cannot save.',
            ),
          ),
        );
      }
      return false;
    }

    // Update userNotes in _currentResponses from their respective TextFormFields
    for (var response in _currentResponses) {
      final controller = _notesControllers[response.objectiveKey];
      if (controller != null) {
        response.userNotes = controller.text.trim();
      }
      // isMet is updated directly via setState
      // builtStatement is updated upon return from ImplementationStatementBuilderScreen
    }

    final projectManager = Provider.of<ProjectDataManager>(
      context,
      listen: false,
    );
    bool success = false;
    try {
      success = await projectManager.saveAssessmentObjectiveResponses(
        systemId: widget.systemId,
        controlId: widget.controlId,
        responses: _currentResponses,
      );
    } catch (e) {
      if (kDebugMode) {
        print("Error saving draft responses: $e");
      }
      if (mounted && showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving draft: ${projectManager.errorMessage ?? e.toString()}',
            ),
          ),
        );
      }
      return false;
    }

    if (mounted && showSnackbar) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Draft responses saved!'
                : 'Error saving draft: ${projectManager.errorMessage ?? "Unknown error"}',
          ),
        ),
      );
    }
    return success;
  }

  Future<void> _generateAndProceed() async {
    final bool draftSaved = await _saveDraftResponses(showSnackbar: false);
    if (!mounted) return;

    if (draftSaved) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => SspStatementDisplayScreen(
                systemId: widget.systemId,
                controlId: widget.controlId,
              ),
        ),
      );
    } else {
      final projectManager = Provider.of<ProjectDataManager>(
        context,
        listen: false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save responses before generating: ${projectManager.errorMessage ?? "Please try again."}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('SSP Objectives for ${_control?.id ?? widget.controlId}'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_system == null || _control == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Text(
            'System (${widget.systemId}) or Control (${widget.controlId}) not found.',
          ),
        ),
      );
    }

    if (_objectives.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('SSP Objectives for ${_control!.id}')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'No assessment objectives found for control ${_control!.id} in the catalog.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text('SSP Objectives for ${_control!.id}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt_outlined),
            tooltip: 'Save All Changes',
            onPressed: () => _saveDraftResponses(showSnackbar: true),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            16.0,
            16.0,
            16.0,
            80.0,
          ), // Bottom padding for FAB
          itemCount: _objectives.length,
          itemBuilder: (context, index) {
            final objectivePart = _objectives[index];
            final displayLabel = _getObjectiveDisplayLabel(objectivePart);
            final objectiveKey = _getObjectiveKey(objectivePart);
            final notesController = _notesControllers[objectiveKey];

            AssessmentObjectiveResponse? currentResponseObject;
            try {
              currentResponseObject = _currentResponses.firstWhere(
                (r) => r.objectiveKey == objectiveKey,
              );
            } catch (_) {
              currentResponseObject = null;
            }

            if (currentResponseObject == null) {
              currentResponseObject = AssessmentObjectiveResponse(
                objectiveKey: objectiveKey,
                objectiveProse: objectivePart.prose ?? '',
                userNotes: '',
                isMet: false,
              );
              _currentResponses.add(currentResponseObject);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Objective $displayLabel',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        objectivePart.prose ?? '',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Checkbox(
                            value: currentResponseObject.isMet,
                            onChanged: (bool? newValue) {
                              if (newValue != null) {
                                _setStateIfMounted(() {
                                  currentResponseObject!.isMet = newValue;
                                });
                              }
                            },
                          ),
                          const Expanded(
                            child: Text(
                              "Objective Met by Standard Implementation",
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: notesController,
                        textInputAction: TextInputAction.done,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText:
                              'Notes/Deviations for Objective $displayLabel',
                          hintText:
                              'Enter any specific details, deviations, or supplementary notes here...',
                          border: const OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                        onChanged: (value) {
                          currentResponseObject!.userNotes = value.trim();
                        },
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest.withAlpha(40),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withAlpha(60),
                          ),
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
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.checklist_rtl_outlined),
            label: const Text('Generate & View SSP Statement'),
            onPressed: _generateAndProceed,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
