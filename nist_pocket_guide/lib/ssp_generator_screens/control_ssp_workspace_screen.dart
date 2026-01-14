// lib/ssp_generator_screens/control_ssp_workspace_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/app_data_manager.dart';
import 'package:nist_pocket_guide/models/assessment_objective_response.dart';
import 'package:nist_pocket_guide/models/information_system.dart';
import 'package:nist_pocket_guide/models/llm_objective_data.dart';
import 'package:nist_pocket_guide/models/oscal_models.dart';
import 'package:nist_pocket_guide/provider/project_data_manager.dart';
import 'package:nist_pocket_guide/models/system_parameter_block.dart'; // Kept for "Manage Global" button context';
import 'package:nist_pocket_guide/800-53_screens/widgets/control/control_statement_section.dart';
import 'package:nist_pocket_guide/ssp_generator_screens/ssp_statement_view_screen.dart';
import 'package:nist_pocket_guide/ssp_generator_screens/objective_placeholder_entry_screen.dart';
import 'package:provider/provider.dart';

enum SspWorkspaceViewMode {
  objectiveStatements, // Renamed from documentationParameters
  assessmentChecklist, // Renamed from assessmentObjectives
  stakeholderSummary,
}

class ControlSspWorkspaceScreen extends StatefulWidget {
  final String systemId;
  final String controlId;

  const ControlSspWorkspaceScreen({
    super.key,
    required this.systemId,
    required this.controlId,
  });

  @override
  State<ControlSspWorkspaceScreen> createState() =>
      _ControlSspWorkspaceScreenState();
}

class _ControlSspWorkspaceScreenState extends State<ControlSspWorkspaceScreen> {
  InformationSystem? _system;
  Control? _control;
  ControlImplementation _controlImplementation = ControlImplementation(
    status: controlStatusOptions.first,
  );
  LlmControlObjectiveData? _llmControlData;

  final List<AssessmentObjectiveResponse> _objectiveResponses = [];
  final Map<String, TextEditingController> _objectiveNotesControllers = {};

  late TextEditingController _mainImplementationDetailsController;
  late TextEditingController _controlNotesController;

  List<SystemParameterBlock> _definedSystemParameterBlocks = [];

  SspWorkspaceViewMode _currentViewMode =
      SspWorkspaceViewMode.objectiveStatements;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _mainImplementationDetailsController = TextEditingController();
    _controlNotesController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _mainImplementationDetailsController.dispose();
    _controlNotesController.dispose();
    _objectiveNotesControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  void _setStateIfMounted(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  Future<void> _loadData() async {
    _setStateIfMounted(() => _isLoading = true);

    final projectManager = Provider.of<ProjectDataManager>(
      context,
      listen: false,
    );
    final appDataManager = AppDataManager.instance;

    // --- CRUCIAL TIMING FIX: Ensure AppDataManager is initialized FIRST ---
    if (!appDataManager.isInitialized) {
      if (kDebugMode) {
        print(
          "DEBUG ControlSspWorkspaceScreen: AppDataManager not initialized. Calling initialize().",
        );
      }
      await appDataManager
          .initialize(); // This loads NIST catalog, LLM data, etc.
      if (kDebugMode) {
        print(
          "DEBUG ControlSspWorkspaceScreen: AppDataManager initialization completed. isInitialized: ${appDataManager.isInitialized}",
        );
      }
    } else {
      if (kDebugMode) {
        print(
          "DEBUG ControlSspWorkspaceScreen: AppDataManager already initialized.",
        );
      }
    }
    // --- END OF TIMING FIX ---

    _system = projectManager.getSystemById(widget.systemId);
    // Use the controlId from the widget, AppDataManager handles normalization if needed
    _control = appDataManager.getControlById(widget.controlId);

    if (_control != null) {
      // Now, try to get the LLM data AFTER AppDataManager is confirmed to be initialized
      _llmControlData = appDataManager.getLlmObjectiveDataForControl(
        _control!.id,
      );
      if (kDebugMode) {
        print(
          "DEBUG: flatAssessmentObjectives count: ${_control!.flatAssessmentObjectives.length}",
        );
      }
      if (kDebugMode) {
        if (_llmControlData == null) {
          // print("DEBUG ControlSspWorkspaceScreen _loadData: _llmControlData is STILL NULL for control '${_control!.id}' AFTER AppDataManager init. This means 'AC-2' (or similar, uppercased) is not a key in AppDataManager's loaded LLM data, or its value is null. Check AppDataManager logs.");
        } else {
          //  print("DEBUG ControlSspWorkspaceScreen _loadData: _llmControlData successfully loaded for control '${_control!.id}'. Number of LLM objective statements: ${_llmControlData!.llmGeneratedObjectiveStatements.length}");
        }
      }
    } else {
      if (kDebugMode) {
        //  print("DEBUG ControlSspWorkspaceScreen _loadData: _control object is NULL for id '${widget.controlId}'. Cannot load objectives or LLM data.");
      }
    }

    // This section populates _objectiveResponses for the AssessmentChecklist view
    // and depends on _control.flatAssessmentObjectives
    if (_system != null && _control != null) {
      _controlImplementation =
          _system!.controlImplementations[widget.controlId] ??
          ControlImplementation(status: controlStatusOptions.first);
      _mainImplementationDetailsController.text =
          _controlImplementation.implementationDetails;
      _controlNotesController.text = _controlImplementation.notes;

      // _definedSystemParameterBlocks loading seems fine
      if (appDataManager.isInitialized) {
        // Check again, though it should be true now
        _definedSystemParameterBlocks = List<SystemParameterBlock>.from(
          appDataManager.systemParameterBlocks,
        );
      }
      // else: It might indicate an issue if initialize() didn't set isInitialized=true

      final existingObjResponses = projectManager
          .getAssessmentObjectiveResponses(
            systemId: widget.systemId,
            controlId: widget.controlId,
          );
      final Map<String, AssessmentObjectiveResponse> existingMap = {
        for (var r in existingObjResponses) r.objectiveKey: r,
      };

      _objectiveResponses.clear();
      _objectiveNotesControllers.forEach(
        (_, controller) => controller.dispose(),
      );
      _objectiveNotesControllers.clear();

      // _control.flatAssessmentObjectives should now be correctly populated
      for (var objPart in _control!.flatAssessmentObjectives) {
        final key = _getObjectiveKey(objPart);
        final existingResp = existingMap[key];

        _objectiveNotesControllers[key] = TextEditingController(
          text: existingResp?.userNotes ?? '',
        );
        _objectiveResponses.add(
          AssessmentObjectiveResponse(
            objectiveKey: key,
            objectiveProse: objPart.prose ?? 'Objective prose not available.',
            userNotes: existingResp?.userNotes,
            builtStatement: existingResp?.builtStatement,
            isMet: existingResp?.isMet ?? true,
          ),
        );
      }
    }
    _setStateIfMounted(() => _isLoading = false);
  }

  String _getObjectiveKey(Part objectivePart) {
    if (objectivePart.id != null && objectivePart.id!.isNotEmpty) {
      return objectivePart.id!;
    }
    return "${widget.controlId}_proseHash_${(objectivePart.prose ?? DateTime.now().microsecondsSinceEpoch.toString()).hashCode}";
  }

  String _getObjectiveDisplayLabel(Part objectivePart, {int? index}) {
    try {
      final labelProp = objectivePart.props.firstWhere(
        (prop) => prop.name.toLowerCase() == 'label',
      );
      String rawLabel = labelProp.value;
      if (rawLabel.endsWith('.')) {
        rawLabel = rawLabel.substring(0, rawLabel.length - 1);
      }
      return rawLabel.isNotEmpty
          ? rawLabel
          : (index != null ? "Objective ${index + 1}" : "Objective");
    } catch (e) {
      String idBasedLabel = objectivePart.id ?? objectivePart.name;
      if (idBasedLabel.contains("obj.")) {
        idBasedLabel = idBasedLabel.substring(idBasedLabel.indexOf("obj.") + 4);
      } else if (widget.controlId.isNotEmpty &&
          idBasedLabel.startsWith(widget.controlId)) {
        idBasedLabel = idBasedLabel
            .substring(widget.controlId.length)
            .replaceAll(RegExp(r'^[._]+'), '');
      }
      if (idBasedLabel.isNotEmpty) return idBasedLabel.toUpperCase();
      return (index != null)
          ? "OBJECTIVE ${String.fromCharCode('A'.codeUnitAt(0) + index)}"
          : "Unnamed Objective";
    }
  }

  Future<void> _saveControlWorkspace({bool showSnackbar = true}) async {
    if (_system == null || _control == null || !mounted) return;
    if (_isSaving && showSnackbar) return;

    FocusScope.of(context).unfocus();
    _setStateIfMounted(() => _isSaving = true);

    _controlImplementation.implementationDetails =
        _mainImplementationDetailsController.text.trim();
    _controlImplementation.notes = _controlNotesController.text.trim();

    for (var response in _objectiveResponses) {
      final controller = _objectiveNotesControllers[response.objectiveKey];
      if (controller != null) {
        response.userNotes = controller.text.trim();
      }
    }

    final projectManager = Provider.of<ProjectDataManager>(
      context,
      listen: false,
    );

    bool implSuccess = await projectManager.updateControlImplementation(
      systemId: widget.systemId,
      controlId: widget.controlId,
      implementation: _controlImplementation,
    );

    bool objSuccess = await projectManager.saveAssessmentObjectiveResponses(
      systemId: widget.systemId,
      controlId: widget.controlId,
      responses: _objectiveResponses,
    );

    if (implSuccess || objSuccess) {
      final updatedSystem = projectManager.getSystemById(widget.systemId);
      if (updatedSystem != null && mounted) {
        _setStateIfMounted(() {
          _system = updatedSystem;
          _controlImplementation =
              _system!.controlImplementations[widget.controlId] ??
              ControlImplementation(status: controlStatusOptions.first);
          _mainImplementationDetailsController.text =
              _controlImplementation.implementationDetails;
          _controlNotesController.text = _controlImplementation.notes;
        });
      }
    }

    if (mounted) {
      _setStateIfMounted(() => _isSaving = false);
      if (showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              implSuccess && objSuccess
                  ? '${widget.controlId} workspace data saved!'
                  : 'Error saving some workspace data. LLM Placeholder values are saved on their specific screen.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _system == null || _control == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.controlId.toUpperCase())),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          // Auto-save when leaving the page
          await _saveControlWorkspace(showSnackbar: false);
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _control!.id.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                _control!.title,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.visibility_outlined),
              onPressed: () {
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
              },
              tooltip: "View Generated SSP Statement",
            ),
          ],
        ),
        body: SafeArea(
          child: GestureDetector(
            onTap: () {
              // Dismiss keyboard when tapping outside text fields
              FocusScope.of(context).unfocus();
            },
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 12.0,
                  ),
                  child: SegmentedButton<SspWorkspaceViewMode>(
                    style: SegmentedButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    segments: <ButtonSegment<SspWorkspaceViewMode>>[
                      ButtonSegment<SspWorkspaceViewMode>(
                        value: SspWorkspaceViewMode.objectiveStatements,
                        label: Text(
                          'Statement',
                          style: TextStyle(fontSize: 13),
                        ),
                        icon: Icon(Icons.description_outlined, size: 18),
                      ),
                      ButtonSegment<SspWorkspaceViewMode>(
                        value: SspWorkspaceViewMode.assessmentChecklist,
                        label: Text(
                          'Checklist',
                          style: TextStyle(fontSize: 13),
                        ),
                        icon: Icon(Icons.checklist_rtl_outlined, size: 18),
                      ),
                      ButtonSegment<SspWorkspaceViewMode>(
                        value: SspWorkspaceViewMode.stakeholderSummary,
                        label: Text('Summary', style: TextStyle(fontSize: 13)),
                        icon: Icon(Icons.summarize_outlined, size: 18),
                      ),
                    ],
                    selected: {_currentViewMode},
                    onSelectionChanged: (
                      Set<SspWorkspaceViewMode> newSelection,
                    ) {
                      _setStateIfMounted(() {
                        _currentViewMode = newSelection.first;
                      });
                    },
                  ),
                ),
                Expanded(child: _buildSelectedView()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedView() {
    switch (_currentViewMode) {
      case SspWorkspaceViewMode.objectiveStatements:
        return _buildObjectiveStatementsList();
      case SspWorkspaceViewMode.assessmentChecklist:
        return _buildAssessmentChecklistSection();
      case SspWorkspaceViewMode.stakeholderSummary:
        return _buildStakeholderSummarySection();
      // No default needed as all enum cases are handled.
    }
  }

  Widget _buildObjectiveStatementsList() {
    List<Widget> sectionChildren = [];
    // final appDataManager = AppDataManager.instance; // Keep if needed for placeholderExamples later

    sectionChildren.add(
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Divider(height: 1, indent: 16, endIndent: 16),
      ),
    );
    sectionChildren.add(
      Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
        child: Text(
          "Objective Statements:",
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );

    if (_control!.flatAssessmentObjectives.isEmpty) {
      // _control is non-null here
      sectionChildren.add(
        const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "No assessment objectives defined for this control in the OSCAL catalog.",
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    } else {
      sectionChildren.add(
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _control!.flatAssessmentObjectives.length,
          itemBuilder: (context, index) {
            final objectivePart = _control!.flatAssessmentObjectives[index];
            final objectiveKey = _getObjectiveKey(objectivePart);

            LlmObjectiveStatement? llmObjectiveStatement;
            if (_llmControlData != null) {
              try {
                llmObjectiveStatement = _llmControlData!
                    .llmGeneratedObjectiveStatements
                    .firstWhere((stmt) => stmt.objectiveId == objectiveKey);
              } catch (e) {
                /* No LLM data for this specific OSCAL objective */
              }
            }
            // In ControlSspWorkspaceScreen -> _buildObjectiveStatementsList -> itemBuilder:

            // ... (objectiveKey and initial llmObjectiveStatement lookup) ...

            if (kDebugMode) {
              print(
                "🔍 LLM MATCH ATTEMPT for Control '${_control?.id ?? "UNKNOWN_CONTROL"}', OSCAL objectiveKey: '$objectiveKey'",
              );
              if (llmObjectiveStatement == null) {
                print(
                  "  ⚠️ LLM MATCH FAILED for OSCAL objectiveKey: '$objectiveKey'.",
                );
                if (_llmControlData != null) {
                  // <<<< ADD THIS NULL CHECK
                  List<String> availableLlmIds =
                      _llmControlData!.llmGeneratedObjectiveStatements
                          .map((s) => s.objectiveId)
                          .toList();
                  if (availableLlmIds.isEmpty) {
                    print(
                      "      The 'llmGeneratedObjectiveStatements' list for control '${_control?.id ?? "UNKNOWN_CONTROL"}' is EMPTY in _llmControlData.",
                    );
                  } else {
                    print(
                      "     Available LLM objective_ids in _llmControlData for '${_control?.id ?? "UNKNOWN_CONTROL"}': ${availableLlmIds.join(', ')}",
                    );
                  }
                } else {
                  print(
                    "      _llmControlData IS NULL for control '${_control?.id ?? "UNKNOWN_CONTROL"}' during this match attempt.",
                  );
                }
              } else {
                print(
                  "  ✅ LLM MATCH FOUND for '$objectiveKey'. LLM stmt ID: '${llmObjectiveStatement.objectiveId}'",
                );
              }
            }

            // **FIX**: Check your LlmObjectiveStatement model for 'llmGeneratedQuestion'.
            // Assuming it exists and is: llmObjectiveStatement.llmGeneratedQuestion
            // If not, use a fallback like objectivePart.prose or displayLabel
            String cardTitle =
                llmObjectiveStatement
                    ?.llmGeneratedQuestion ?? // Using property directly
                _getObjectiveDisplayLabel(objectivePart, index: index);

            String cardSubtitle =
                llmObjectiveStatement != null
                    ? "Tap to provide inputs for the implementation statement."
                    : "No LLM-enhanced content available for this OSCAL objective.";
            bool canNavigate = llmObjectiveStatement != null && _system != null;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              elevation: 1.5,
              child: ListTile(
                leading: Icon(
                  canNavigate
                      ? Icons.speaker_notes_outlined
                      : Icons.notes_outlined,
                  color:
                      canNavigate
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).disabledColor,
                ),
                title: Text(
                  cardTitle,
                  style: TextStyle(
                    fontWeight:
                        canNavigate ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  cardSubtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing:
                    canNavigate
                        ? const Icon(Icons.arrow_forward_ios_rounded, size: 18)
                        : null,
                onTap:
                    canNavigate
                        ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      ObjectiveStatementAndPlaceholderScreen(
                                        systemId: widget.systemId,
                                        controlId: widget.controlId,
                                        objectivePart: objectivePart,
                                        llmObjectiveStatement:
                                            llmObjectiveStatement!,
                                        system: _system!,
                                      ),
                            ),
                          ).then((_) {
                            _loadData();
                          });
                        }
                        : null,
              ),
            );
          },
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 72.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sectionChildren,
      ),
    );
  }

  Widget _buildAssessmentChecklistSection() {
    if (mounted) {
      // Good practice to check if mounted before setState or accessing context heavily
      if (kDebugMode) {
        print(
          "DEBUG_Checklist: _buildAssessmentChecklistSection - _objectiveResponses length: ${_objectiveResponses.length}",
        );
      }
      if (_control == null) {
        if (kDebugMode) {
          print("DEBUG_Checklist: _control is NULL");
        }
      } else {
        if (kDebugMode) {
          print(
            "DEBUG_Checklist: _control ID: ${_control!.id}, flatAssessmentObjectives count: ${_control!.flatAssessmentObjectives.length}",
          );
        }
      }
    }
    if (_objectiveResponses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "No assessment objectives found for this control.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 80.0),
      itemCount: _objectiveResponses.length,
      itemBuilder: (context, index) {
        if (kDebugMode) {
          print("DEBUG_ItemBuilder: --- Item $index ---");
        }
        final objResp = _objectiveResponses[index];
        if (kDebugMode) {
          print(
            "DEBUG_ItemBuilder: objResp.objectiveKey: ${objResp.objectiveKey}",
          );
        }

        Part? objectivePart; // Initialize to null
        try {
          if (_control != null &&
              _control!.flatAssessmentObjectives.isNotEmpty) {
            objectivePart = _control!.flatAssessmentObjectives.firstWhere(
              (p) => _getObjectiveKey(p) == objResp.objectiveKey,
              // orElse is not strictly needed if we are sure keys will match,
              // but good for safety if data integrity can be an issue.
              // If orElse is hit often, it indicates a mismatch in key generation/storage.
            );
            if (kDebugMode) {
              print(
                "DEBUG_ItemBuilder: Found objectivePart with id: ${objectivePart.id} for key: ${objResp.objectiveKey}",
              );
            }
          } else {
            if (kDebugMode) {
              print(
                "DEBUG_ItemBuilder: _control is null or flatAssessmentObjectives is empty. Cannot find objectivePart for key: ${objResp.objectiveKey}",
              );
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print(
              "DEBUG_ItemBuilder: ERROR in firstWhere for key ${objResp.objectiveKey}: $e. Using fallback Part.",
            );
          }
          // Fallback if firstWhere fails (e.g., no match and no orElse, or some other error)
        }

        // If objectivePart is still null after try-catch (e.g., firstWhere threw an error not caught by orElse, or list was empty)
        // or if you want to ensure it's always populated by the orElse logic if not found:
        objectivePart ??= Part(
          id: objResp.objectiveKey,
          name: 'Fallback Objective',
          prose: objResp.objectiveProse,
          props: [],
        );

        final displayLabel = _getObjectiveDisplayLabel(
          objectivePart,
          index: index,
        );
        if (kDebugMode) {
          print("DEBUG_ItemBuilder: displayLabel: $displayLabel");
        }

        final notesController =
            _objectiveNotesControllers[objResp.objectiveKey];
        if (notesController == null) {
          if (kDebugMode) {
            print(
              "DEBUG_ItemBuilder: notesController is NULL for ${objResp.objectiveKey}. DisplayLabel: $displayLabel. Returning error card.",
            );
          }
          return Card(
            child: ListTile(
              title: Text(
                "Error loading notes UI for $displayLabel (Controller Missing)",
              ),
            ),
          );
        }

        if (kDebugMode) {
          print(
            "DEBUG_ItemBuilder: Building main card for ${objResp.objectiveKey}. DisplayLabel: $displayLabel",
          );
        }

        // Inside _buildAssessmentChecklistSection -> ListView.builder -> itemBuilder:
        // MODIFIED Card for each objResp
        return Card(
          elevation: 2.0, // Optional: slightly more elevation
          // Using surfaceContainer is generally good for cards in M3
          color: Theme.of(context).colorScheme.surfaceContainer,
          margin: const EdgeInsets.only(
            bottom: 16.0,
            left: 4.0,
            right: 4.0,
          ), // Added small horizontal margin
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ), // Softer corners
          child: Padding(
            padding: const EdgeInsets.all(
              16.0,
            ), // INCREASED padding from 12.0 to 16.0
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Objective: $displayLabel",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color:
                        Theme.of(
                          context,
                        ).colorScheme.primary, // Emphasize with primary color
                  ),
                ),
                const SizedBox(height: 8), // INCREASED spacing from 6

                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.45,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    children: ControlStatementSection.replaceParamsAsTextSpans(
                      objResp.objectiveProse,
                      _control!.params,
                      context,
                    ),
                  ),
                ),
                // Your existing SwitchListTile for isMet status - no changes needed unless desired
                SwitchListTile.adaptive(
                  title: const Text(
                    "Met by Standard Implementation",
                    style: TextStyle(fontSize: 14),
                  ),
                  value: objResp.isMet,
                  onChanged: (bool? newValue) {
                    if (newValue != null) {
                      _setStateIfMounted(() {
                        objResp.isMet = newValue;
                      });
                      _saveControlWorkspace(showSnackbar: false);
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: Theme.of(context).colorScheme.primary,
                ),

                // Conditional TextFormField for notes
                if (!objResp.isMet) ...[
                  const SizedBox(height: 8), // INCREASED spacing from 4
                  Text(
                    // Add a label for the notes field
                    "Notes / Deviations:",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: notesController,
                    textInputAction:
                        TextInputAction.done, // Add done button to keyboard
                    keyboardType: TextInputType.text, // Ensure text keyboard
                    decoration: InputDecoration(
                      // Removed labelText, using separate Text widget above
                      hintText:
                          'Detail any deviations or why this objective is not fully met...',
                      border: const OutlineInputBorder(),
                      isDense:
                          false, // CHANGED to false for a more comfortable size
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ), // ADDED content padding
                      filled: true,
                      // Use a subtle fill color, surfaceContainerHighest or similar from M3
                      fillColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    maxLines: 3, // Keep or adjust as needed
                    onChanged: (value) {
                      objResp.userNotes = value.trim();
                      // You might want to add a debouncer here if saving on change frequently
                    },
                  ),
                  const SizedBox(height: 16), // ADDED spacing after notes field
                ] else ...[
                  // If met, still ensure consistent spacing before the button
                  const SizedBox(height: 12),
                ],

                // Edit Implementation buttton
                // Align( // Align button to the start or use SizedBox(width: double.infinity) for full width
                //   alignment: Alignment.centerLeft,
                //   child: OutlinedButton.icon(
                //     icon: Icon(
                //       objResp.builtStatement != null && objResp.builtStatement!.isNotEmpty
                //           ? Icons.edit_note // Icon for "Edit"
                //           : Icons.add_comment_outlined, // Icon for "Add"
                //       size: 20,
                //     ),
                //     // MODIFIED Label for conciseness and clarity
                //     label: Text(
                //       objResp.builtStatement != null && objResp.builtStatement!.isNotEmpty
                //           ? "Edit Detailed Statement"
                //           : "Add Detailed Statement",
                //     ),
                //     // MODIFIED Style
                //     style: OutlinedButton.styleFrom(
                //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Increased padding
                //       textStyle: Theme.of(context).textTheme.labelLarge, // Use theme's labelLarge
                //       side: BorderSide(color: Theme.of(context).colorScheme.primary), // Emphasize with primary color border
                //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), // Softer corners
                //     ),
                //     onPressed: () async {
                //       // Your existing navigation logic - unchanged
                //       String initialObjTemplate = objResp.builtStatement ??
                //           _llmControlData?.llmGeneratedObjectiveStatements
                //               .firstWhere(
                //                   (s) => s.objectiveId == objResp.objectiveKey,
                //                   orElse: () => LlmObjectiveStatement(
                //                       objectiveId: objResp.objectiveKey,
                //                       objectiveProseOriginal: objResp.objectiveProse,
                //                       llmGeneratedStatement: objResp.objectiveProse,
                //                       llmGeneratedQuestion: '',
                //                       placeholders: []
                //                     ))
                //               .llmGeneratedStatement ??
                //           objResp.objectiveProse;

                //       if (_control == null) return;
                //       final result = await Navigator.push<String>(
                //           context,
                //           MaterialPageRoute(
                //               builder: (context) => ImplementationStatementBuilderScreen(
                //                   systemId: widget.systemId,
                //                   control: _control!,
                //                   initialStatementTemplate: initialObjTemplate,
                //                   objectiveKey: objResp.objectiveKey)));
                //       if (result != null && mounted) {
                //         _setStateIfMounted(() {
                //           objResp.builtStatement = result;
                //         });
                //         _saveControlWorkspace(showSnackbar: false);
                //       }
                //     },
                //   ),
                // ),

                // Display current statement (if exists)
                if (objResp.builtStatement != null &&
                    objResp.builtStatement!.isNotEmpty) ...[
                  const SizedBox(height: 16), // INCREASED spacing
                  Text(
                    // MODIFIED label style
                    "Current Detailed Statement:",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ), // MODIFIED padding
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context)
                              .colorScheme
                              .surfaceContainerHigh, // MODIFIED with M3 color
                      borderRadius: BorderRadius.circular(
                        8.0,
                      ), // Softer corners
                      // border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.7))
                    ),
                    child: Text(
                      objResp.builtStatement!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        // CHANGED to bodyMedium
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                      maxLines: 3, // Allow more lines if needed
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlStatementSection(Widget? content) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(
        (0.2 * 255).round(),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            content ??
                Text(
                  "Not defined for this control.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildStakeholderSummarySection() {
    if (_system == null || _control == null) {
      return const Center(child: Text("System or Control data not available."));
    }
    final controlImpl =
        _system!.controlImplementations[widget.controlId] ??
        ControlImplementation(status: controlStatusOptions.first);

    int objectivesMetCount = _objectiveResponses.where((r) => r.isMet).length;
    int totalObjectives = _objectiveResponses.length;
    String objectiveSummaryText =
        totalObjectives > 0
            ? "$objectivesMetCount out of $totalObjectives objective(s) met."
            : "No objectives defined or assessed for this control yet.";

    List<Widget> keyParameterWidgets = [];
    if (controlImpl.userParameterValues.isNotEmpty) {
      for (var pVal in controlImpl.userParameterValues) {
        final paramDef = _control!.params.firstWhere(
          (p) => p.id == pVal.paramId,
          orElse:
              () => Parameter(
                id: pVal.paramId,
                label: pVal.paramId,
                props: [],
                values: [],
              ),
        );
        if (pVal.value.isNotEmpty) {
          keyParameterWidgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    TextSpan(
                      text: "${paramDef.label ?? pVal.paramId}: ",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(text: pVal.value),
                  ],
                ),
              ),
            ),
          );
        }
      }
    }
    if (keyParameterWidgets.isEmpty &&
        _control!.params.any((p) => p.id.contains("_odp"))) {
      keyParameterWidgets.add(
        const Text(
          "Organization-defined parameter values (ODPs) not yet specified in detail.",
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Overall Status: ${controlImpl.status}",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildControlStatementSection(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),

            child: Theme(
              data: Theme.of(context).copyWith(
                textTheme: Theme.of(context).textTheme.copyWith(
                  bodyMedium: Theme.of(
                    context,
                  ).textTheme.bodySmall!.copyWith(fontSize: 12, height: 1.2),
                  bodyLarge: Theme.of(
                    context,
                  ).textTheme.bodySmall!.copyWith(fontSize: 12, height: 1.2),
                ),
              ),
              child: ControlStatementSection(
                parts:
                    _control?.parts.where((p) => p.isStatement).toList() ?? [],
                params: _control?.params ?? [],
              ),
            ),
          ),
        ),

        // Card(
        //   elevation: 1,
        //   margin: const EdgeInsets.symmetric(vertical: 8.0),
        //   child: Padding(
        //     padding: const EdgeInsets.all(16.0),
        //     child: Column(
        //       crossAxisAlignment: CrossAxisAlignment.start,
        //       children: [
        //         Text("Main Implementation Details", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        //         const Divider(height: 16),
        //         _mainImplementationDetailsController.text.trim().isNotEmpty
        //             ? SelectableText(
        //                 _mainImplementationDetailsController.text.trim(),
        //                 style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4))
        //             : Text(
        //                 "Main implementation details not yet provided. Use the 'Build/Edit Main Control Implementation' button in the 'Statements' tab.",
        //                 style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4, fontStyle: FontStyle.italic)),

        //         if (keyParameterWidgets.isNotEmpty) ...[
        //           const SizedBox(height: 12),
        //           Text("Key Organizational Parameters (from OSCAL Control Definition):", style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        //           ...keyParameterWidgets,
        //         ]
        //       ],
        //     ),
        //   ),
        // ),
        Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Assessment Objectives Summary",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 16),
                Text(
                  objectiveSummaryText,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 10),
                if (_objectiveResponses.any(
                  (r) =>
                      !r.isMet ||
                      (r.userNotes != null && r.userNotes!.trim().isNotEmpty) ||
                      (r.builtStatement != null &&
                          r.builtStatement!.trim().isNotEmpty),
                ))
                  Text(
                    "Key Objective Details:",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ..._objectiveResponses
                    .where(
                      (r) =>
                          !r.isMet ||
                          (r.userNotes != null &&
                              r.userNotes!.trim().isNotEmpty) ||
                          (r.builtStatement != null &&
                              r.builtStatement!.trim().isNotEmpty),
                    )
                    .map((r) {
                      final objectivePart = _control!.flatAssessmentObjectives
                          .firstWhere(
                            (p) => _getObjectiveKey(p) == r.objectiveKey,
                            orElse:
                                () => Part(
                                  id: r.objectiveKey,
                                  name: 'Unknown',
                                  prose: r.objectiveProse,
                                  props: [],
                                ),
                          );
                      final displayLabel = _getObjectiveDisplayLabel(
                        objectivePart,
                        index: _objectiveResponses.indexOf(r),
                      );
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Objective $displayLabel: ${r.isMet ? 'Met' : 'Attention Needed'}",
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (r.userNotes != null &&
                                r.userNotes!.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 16.0,
                                  top: 2.0,
                                ),
                                child: Text(
                                  "Notes/Deviations: ${r.userNotes!}",
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            if (r.builtStatement != null &&
                                r.builtStatement!.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 16.0,
                                  top: 2.0,
                                ),
                                child: Text(
                                  "Detailed Statement: ${r.builtStatement!}",
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(fontStyle: FontStyle.italic),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                if (_objectiveResponses.every(
                      (r) =>
                          r.isMet &&
                          (r.userNotes == null ||
                              r.userNotes!.trim().isEmpty) &&
                          (r.builtStatement == null ||
                              r.builtStatement!.isEmpty),
                    ) &&
                    totalObjectives > 0)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      "All objectives reported as met without specific notes or detailed statements.",
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Insert the new System Parameter Blocks section here
        _buildSystemParameterBlocksSection(),
        Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "General Control Notes",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _controlNotesController,
                  textInputAction:
                      TextInputAction.done, // Add done button to keyboard
                  keyboardType: TextInputType.text, // Ensure text keyboard
                  decoration: const InputDecoration(
                    hintText:
                        "Enter any general notes for this control's implementation...",
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    _controlImplementation.notes = value.trim();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSystemParameterBlocksSection() {
    if (_definedSystemParameterBlocks.isEmpty) {
      return const Card(
        margin: EdgeInsets.symmetric(vertical: 8.0),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "No system parameter blocks are defined for this project.",
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      );
    }
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Defined System Parameter Blocks:",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._definedSystemParameterBlocks.map(
              (block) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      block.title.isNotEmpty ? block.title : 'Untitled Block',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (block.summary.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          block.summary,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        'ID: \\${block.id}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    if (block.examples.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Examples:',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            ...block.examples.map(
                              (ex) => Text(
                                '- $ex',
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
          ],
        ),
      ),
    );
  }
}
