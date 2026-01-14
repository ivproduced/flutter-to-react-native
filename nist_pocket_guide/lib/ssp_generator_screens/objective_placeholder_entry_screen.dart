// lib/ssp_generator_screens/objective_statement_and_parameters_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:nist_pocket_guide/app_data_manager.dart';
import 'package:nist_pocket_guide/models/information_system.dart';
import 'package:nist_pocket_guide/models/llm_objective_data.dart';
import 'package:nist_pocket_guide/models/oscal_models.dart'; // For Part, Prop
import 'package:nist_pocket_guide/models/reusable_placeholder_model.dart';
import 'package:nist_pocket_guide/provider/project_data_manager.dart';
import 'package:nist_pocket_guide/ssp_generator_screens/widgets/unified_parameter_input.dart';
import 'package:provider/provider.dart';

// LlmPlaceholderInputWidget will now be primarily used as the content for the dialog.
// We can simplify it or use its parts. For this integration, we'll build the dialog's
// content directly in the _showEditPlaceholderDialog method for clarity,
// but you could refactor it into a dedicated dialog widget later.

class ObjectiveStatementAndPlaceholderScreen extends StatefulWidget {
  final String systemId;
  final String controlId;
  // Assuming 'Part objectivePart' was used to derive the objective ID or key.
  // The LlmObjectiveStatement contains the objectiveId which is more direct.
  final Part
  objectivePart; // Keep for now if used for display label or other non-placeholder logic
  final LlmObjectiveStatement llmObjectiveStatement;
  final InformationSystem system;

  const ObjectiveStatementAndPlaceholderScreen({
    super.key,
    required this.systemId,
    required this.controlId,
    required this.objectivePart, // OSCAL Part from which this objective was derived
    required this.llmObjectiveStatement, // Contains the statement and specific objective ID
    required this.system,
  });

  @override
  State<ObjectiveStatementAndPlaceholderScreen> createState() =>
      _ObjectiveStatementAndPlaceholderScreenState();
}

class _ObjectiveStatementAndPlaceholderScreenState
    extends State<ObjectiveStatementAndPlaceholderScreen> {
  late String _objectiveStatementTemplate;
  // This holds the user's current values for placeholders for THIS objective instance
  final Map<String, String> _currentPlaceholderValues = {};
  String _livePreviewStatement = "";
  bool _isSaving = false;
  List<LlmPlaceholderDefinition> _relevantPlaceholderDefinitions = [];

  // Controllers for TextFormFields (likely in your dialog)
  final Map<String, TextEditingController> _placeholderControllers = {};

  // Holds the selection from the "reusable values" dropdown for each placeholder (if used in a dialog)
  // final Map<String, ReusablePlaceholderValue?> _selectedReusableValuesInDialog = {};

  @override
  void initState() {
    super.initState();

    // --- SINGLE, CORRECTED initState LOGIC ---
    _objectiveStatementTemplate =
        widget.llmObjectiveStatement.llmGeneratedStatement;

    final appDataManager = AppDataManager.instance;
    final controlLlmData = appDataManager.getLlmObjectiveDataForControl(
      widget.controlId,
    );

    if (kDebugMode) {
      print("--- Placeholder Debugging (ObjectiveScreen initState) ---");
      print("Control ID: ${widget.controlId}");
      print(
        "LlmObjectiveStatement ID: ${widget.llmObjectiveStatement.objectiveId}",
      );
      // ... other initial debug prints you have ...
    }

    if (controlLlmData != null) {
      // This part correctly determines which placeholders are relevant for this objective
      _relevantPlaceholderDefinitions =
          controlLlmData.placeholders.where((pDef) {
            bool belongs = pDef.id.startsWith(
              widget.llmObjectiveStatement.objectiveId,
            );
            bool inTemplate = _objectiveStatementTemplate.contains(pDef.label);
            // ... your relevance check debug prints ...
            return belongs && inTemplate;
          }).toList();
      // ... your debug prints for relevant definitions ...
    }

    // 1. Load the actual current values for THIS objective's placeholders
    _loadCurrentValuesForThisObjectivePlaceholders();

    // 2. Initialize TextEditingControllers for these placeholders (used in your dialog)
    //    This step was missing or misplaced in your combined code.
    _initializeAllPlaceholderControllers();

    // 3. Fetch globally reusable placeholder values for dropdowns
    _fetchReusablePlaceholderValues();

    // 4. Update the live preview statement
    _updateLivePreviewStatement();

    if (kDebugMode) {
      print("--- End Placeholder Debugging (ObjectiveScreen initState) ---");
    }
    // --- END OF initState ---
  }

  // Renamed your existing _loadCurrentPlaceholderValues for clarity
  void _loadCurrentValuesForThisObjectivePlaceholders() {
    final controlImpl = widget.system.controlImplementations[widget.controlId];
    Map<String, String> loadedValues = {};
    if (controlImpl != null) {
      final valuesForThisObjective =
          controlImpl.llmObjectivePlaceholderValues[widget
              .llmObjectiveStatement
              .objectiveId];
      if (valuesForThisObjective != null) {
        loadedValues = Map<String, String>.from(valuesForThisObjective);
      }
    }
    // Ensure all relevant placeholders have an entry in _currentPlaceholderValues
    // and initialize controllers for them
    _currentPlaceholderValues.clear();
    for (var def in _relevantPlaceholderDefinitions) {
      _currentPlaceholderValues[def.label] = loadedValues[def.label] ?? '';
    }
  }

  // Helper to initialize all placeholder controllers at once
  void _initializeAllPlaceholderControllers() {
    _placeholderControllers.forEach(
      (_, controller) => controller.dispose(),
    ); // Dispose old ones if any
    _placeholderControllers.clear();
    for (var placeholderDef in _relevantPlaceholderDefinitions) {
      final placeholderKey = placeholderDef.label;
      // Use the _currentPlaceholderValues map from the state, which is now populated
      final String existingValue =
          _currentPlaceholderValues[placeholderKey] ?? '';
      _placeholderControllers[placeholderKey] = TextEditingController(
        text: existingValue,
      );
    }
  }

  // Fetches reusable values and sets up listener
  Future<void> _fetchReusablePlaceholderValues() async {
    final appDataManager = AppDataManager.instance;
    if (!appDataManager.isInitialized) {
      await appDataManager.initialize();
    }
    appDataManager.addListener(_onReusableValuesChanged);
    _onReusableValuesChanged(); // Initial fetch

    if (mounted) {
      setState(() {});
    }
  }

  // Listener callback for AppDataManager
  void _onReusableValuesChanged() {
    if (mounted) {
      setState(() {
        // Refresh the UI when reusable values change
      });
    }
  }

  @override
  void dispose() {
    _placeholderControllers.forEach((_, controller) => controller.dispose());
    AppDataManager.instance.removeListener(_onReusableValuesChanged);
    super.dispose();
  }

  // This method updates the _currentPlaceholderValues map for THIS objective
  // when a value is selected from a dropdown or typed in the dialog for a specific placeholder
  void _updatePlaceholderValueForThisObjective(
    String placeholderLabel,
    String newValue,
  ) {
    if (mounted) {
      setState(() {
        _currentPlaceholderValues[placeholderLabel] = newValue;
        // If you have individual controllers per placeholder *directly in the ExpansionTile*, update them too:
        _placeholderControllers[placeholderLabel]?.text = newValue;
        _updateLivePreviewStatement();
      });
    }
  }

  // _updateLivePreviewStatement remains largely the same
  void _updateLivePreviewStatement() {
    String tempStatement = _objectiveStatementTemplate;
    for (var def in _relevantPlaceholderDefinitions) {
      final value =
          _currentPlaceholderValues[def.label] ?? ''; // Use state variable
      tempStatement = tempStatement.replaceAll(
        def.label,
        value.isNotEmpty ? value : "${def.label}(Value Needed)",
      );
    }
    // ... (your fallback logic if needed) ...
    if (mounted) {
      setState(() {
        _livePreviewStatement = tempStatement;
      });
    }
  }

  // _savePlaceholderValues (saves all current values for THIS objective) remains the same
  Future<void> _savePlaceholderValues() async {
    if (!mounted) return;
    setState(() => _isSaving = true);

    final projectManager = Provider.of<ProjectDataManager>(
      context,
      listen: false,
    );
    final String objectiveKeyForStorage =
        widget.llmObjectiveStatement.objectiveId;

    // Ensure _currentPlaceholderValues reflects the latest from controllers IF you edit directly
    // If editing is only via dialog which then updates _currentPlaceholderValues, this might not be needed here.
    // _placeholderControllers.forEach((key, controller) {
    //   _currentPlaceholderValues[key] = controller.text;
    // });

    Map<String, String> valuesToSave = Map.from(_currentPlaceholderValues);

    bool success = await projectManager.saveLlmObjectivePlaceholderValues(
      systemId: widget.systemId,
      controlId: widget.controlId,
      objectiveId: objectiveKeyForStorage,
      placeholderValues: valuesToSave,
    );
    // ... (rest of your _savePlaceholderValues method) ...
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Placeholder values saved!'
                : 'Failed to save placeholder values.',
          ),
        ),
      );
    }
  }

  // --- NEW: Method to show the dialog for editing a placeholder ---
  Future<void> _showEditPlaceholderDialog(
    BuildContext context,
    LlmPlaceholderDefinition placeholderDef,
  ) async {
    final TextEditingController dialogTextController = TextEditingController(
      text: _currentPlaceholderValues[placeholderDef.label] ?? '',
    );

    // --- SEMANTIC GROUP LOGIC ---
    // Determine the semantic group key for this placeholder
    final String groupKey =
        placeholderDef.semanticGroup ?? placeholderDef.label;
    // Gather all LLM examples for this group across all controls
    final allLlmExamples = <String>{};
    final allUserValues = <ReusablePlaceholderValue>[];
    final appDataManager = AppDataManager.instance;
    for (final control in appDataManager.llmControlData.values) {
      for (final p in control.placeholders) {
        final pGroup = p.semanticGroup ?? p.label;
        if (pGroup == groupKey) {
          allLlmExamples.addAll(p.examples);
        }
      }
    }
    for (final userVal in appDataManager.userSavedPlaceholderValues) {
      if (userVal.associatedPlaceholderLabel == groupKey) {
        allUserValues.add(userVal);
      }
    }
    // --- END SEMANTIC GROUP LOGIC ---

    ReusablePlaceholderValue? selectedReusableValueForDialog;
    String? selectedPredefinedExampleForDialog;

    final String? newDialogValue = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (stfContext, setDialogState) {
            return AlertDialog(
              title: Text("Define Value For:", style: TextStyle(fontSize: 18)),
              contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      placeholderDef.label,
                      style: Theme.of(stfContext).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (placeholderDef.description.isNotEmpty) ...[
                      Text(
                        placeholderDef.description,
                        style: Theme.of(stfContext).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Unified input with autocomplete for all available options
                    UnifiedParameterInput(
                      controller: dialogTextController,
                      predefinedExamples: allLlmExamples.toList(),
                      savedValues: allUserValues.map((v) => v.value).toList(),
                      onValueSelected: (value) {
                        setDialogState(() {
                          // Update tracking variables based on source
                          if (allLlmExamples.contains(value)) {
                            selectedPredefinedExampleForDialog = value;
                            selectedReusableValueForDialog = null;
                          } else if (allUserValues.any(
                            (v) => v.value == value,
                          )) {
                            selectedReusableValueForDialog = allUserValues
                                .firstWhere((v) => v.value == value);
                            selectedPredefinedExampleForDialog = null;
                          } else {
                            selectedPredefinedExampleForDialog = null;
                            selectedReusableValueForDialog = null;
                          }
                        });
                      },
                      onSaveValue: () {
                        if (dialogTextController.text.trim().isNotEmpty) {
                          AppDataManager.instance.addUserSavedPlaceholderValue(
                            dialogTextController.text.trim(),
                            associatedPlaceholderLabel: groupKey,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '"${dialogTextController.text.trim()}" saved for reuse!',
                              ),
                            ),
                          );
                          setDialogState(() {});
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Cannot save an empty value for reuse.',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                FilledButton(
                  child: const Text('Apply Value'),
                  onPressed:
                      () => Navigator.of(
                        dialogContext,
                      ).pop(dialogTextController.text),
                ),
              ],
            );
          },
        );
      },
    );

    if (newDialogValue != null && mounted) {
      if (_currentPlaceholderValues[placeholderDef.label] != newDialogValue) {
        _updatePlaceholderValueForThisObjective(
          placeholderDef.label,
          newDialogValue,
        );
      }
    }
  }
  // --- END NEW DIALOG METHOD ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use the objective label from LlmObjectiveStatement if available, else from Part

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Control: ${widget.controlId.toUpperCase()} ",
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              "Objective ID: ${widget.llmObjectiveStatement.objectiveId}",
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
            ),
          ],
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
          TextButton(
            onPressed: _isSaving ? null : _savePlaceholderValues,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(
                  "Guiding Question:",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SelectableText(
                  widget.llmObjectiveStatement.llmGeneratedQuestion.isNotEmpty
                      ? widget.llmObjectiveStatement.llmGeneratedQuestion
                      : "No specific question provided for this objective.",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),

                // REMOVE Implementation Statement Template section and move Live Preview here
                Text(
                  "Live Preview of Implementation Statement:",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12.0),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: SelectableText(
                    _livePreviewStatement,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const Divider(height: 24),

                // --- MODIFIED PLACEHOLDER SECTION ---
                ExpansionTile(
                  title: Text(
                    "Define Values for Placeholders (${_relevantPlaceholderDefinitions.length})",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  maintainState: true,
                  initiallyExpanded: _relevantPlaceholderDefinitions.isNotEmpty,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 0.0),
                  children: <Widget>[
                    if (_relevantPlaceholderDefinitions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 16.0,
                        ),
                        child: Text(
                          "No placeholders identified in this objective's statement template that require user input.",
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else ...[
                      // --- Frequency Grouped Placeholders ---
                      ..._relevantPlaceholderDefinitions.frequencyGroups.entries.map((
                        entry,
                      ) {
                        final groupPlaceholders = entry.value;
                        // If all values are the same, show it; otherwise, show the first (should always be the same)
                        final groupValue =
                            groupPlaceholders
                                        .map(
                                          (p) =>
                                              _currentPlaceholderValues[p
                                                  .label] ??
                                              '',
                                        )
                                        .toSet()
                                        .length ==
                                    1
                                ? (_currentPlaceholderValues[groupPlaceholders
                                        .first
                                        .label] ??
                                    '')
                                : '';
                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.symmetric(
                            vertical: 4.0,
                            horizontal: 8.0,
                          ),
                          child: ListTile(
                            title: Text(
                              groupPlaceholders.map((p) => p.label).join(' / '),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              groupValue.isNotEmpty
                                  ? groupValue
                                  : "Tap to define value",
                              style: TextStyle(
                                fontStyle:
                                    groupValue.isNotEmpty
                                        ? FontStyle.normal
                                        : FontStyle.italic,
                                color:
                                    groupValue.isNotEmpty
                                        ? theme.textTheme.bodySmall?.color
                                        : theme.hintColor,
                                overflow: TextOverflow.ellipsis,
                              ),
                              maxLines: 2,
                            ),
                            trailing: Icon(
                              Icons.edit_note_outlined,
                              size: 22,
                              color: theme.colorScheme.primary,
                            ),
                            onTap: () async {
                              // Use the first placeholderDef for dialog (they share the value)
                              final placeholderDef = groupPlaceholders.first;
                              await _showEditPlaceholderDialog(
                                context,
                                placeholderDef,
                              );
                              // After dialog, update all in group to the same value
                              final newValue =
                                  _currentPlaceholderValues[placeholderDef
                                      .label] ??
                                  '';
                              setState(() {
                                for (final p in groupPlaceholders) {
                                  _currentPlaceholderValues[p.label] = newValue;
                                  _placeholderControllers[p.label]?.text =
                                      newValue;
                                }
                                _updateLivePreviewStatement();
                              });
                            },
                          ),
                        );
                      }),
                      // --- Non-frequency-grouped Placeholders ---
                      ..._relevantPlaceholderDefinitions
                          .nonFrequencyGroupedPlaceholders
                          .map((placeholderDef) {
                            String currentValue =
                                _currentPlaceholderValues[placeholderDef
                                    .label] ??
                                '';
                            return Card(
                              elevation: 1,
                              margin: const EdgeInsets.symmetric(
                                vertical: 4.0,
                                horizontal: 8.0,
                              ),
                              child: ListTile(
                                title: Text(
                                  placeholderDef.label,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  currentValue.isNotEmpty
                                      ? currentValue
                                      : "Tap to define value",
                                  style: TextStyle(
                                    fontStyle:
                                        currentValue.isNotEmpty
                                            ? FontStyle.normal
                                            : FontStyle.italic,
                                    color:
                                        currentValue.isNotEmpty
                                            ? theme.textTheme.bodySmall?.color
                                            : theme.hintColor,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  maxLines: 2,
                                ),
                                trailing: Icon(
                                  Icons.edit_note_outlined,
                                  size: 22,
                                  color: theme.colorScheme.primary,
                                ),
                                onTap: () {
                                  _showEditPlaceholderDialog(
                                    context,
                                    placeholderDef,
                                  );
                                },
                              ),
                            );
                          }),
                    ],
                  ],
                ),

                // --- END MODIFIED PLACEHOLDER SECTION ---
                const SizedBox(height: 20),
                const Divider(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
