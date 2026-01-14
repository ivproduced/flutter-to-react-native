// lib/ssp_generator_screens/objective_system_parameters_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/models/oscal_models.dart';
import 'package:nist_pocket_guide/models/system_parameter_block.dart';
import 'package:nist_pocket_guide/models/information_system.dart'; // Needed by ParameterInputWidget
import 'package:nist_pocket_guide/provider/project_data_manager.dart'; // For ProjectDataManager context
import 'package:nist_pocket_guide/ssp_generator_screens/widgets/parameter_input_widget.dart';
import 'package:provider/provider.dart';

class ObjectiveSystemParametersScreen extends StatefulWidget {
  final String systemId;
  final String controlId;
  final Part objectivePart;
  final String? objectiveTemplate;
  final List<SystemParameterBlock> allSystemParameterBlocks;
  final InformationSystem system; // This contains currentSystemParameterValues

  const ObjectiveSystemParametersScreen({
    super.key,
    required this.systemId,
    required this.controlId,
    required this.objectivePart,
    this.objectiveTemplate,
    required this.allSystemParameterBlocks,
    required this.system, // Correct: system object is passed
                          // No separate currentSystemParameterValues needed here
  });

  @override
  State<ObjectiveSystemParametersScreen> createState() =>
      _ObjectiveSystemParametersScreenState();
}


class _ObjectiveSystemParametersScreenState
    extends State<ObjectiveSystemParametersScreen> {
  List<SystemParameterBlock> _relevantBlocks = [];
  // Local copy of system parameter values to reflect live changes for preview
  late Map<String, String> _currentParameterValues;
  String _previewStatement = "";

  @override
  void initState() {
    super.initState();
    _currentParameterValues = Map<String, String>.from(widget.system.systemParameterBlockValues);
    _identifyRelevantBlocks();
    _updatePreviewStatement();
  }

  String _getObjectiveDisplayLabel(Part objectivePart) {
    try {
      final labelProp = objectivePart.props.firstWhere(
        (prop) => prop.name.toLowerCase() == 'label',
      );
      String rawLabel = labelProp.value;
      if (rawLabel.endsWith('.')) {
        rawLabel = rawLabel.substring(0, rawLabel.length - 1);
      }
      return rawLabel.isNotEmpty ? rawLabel : "Objective";
    } catch (e) {
      return objectivePart.id ?? objectivePart.name;
    }
  }
  
  List<String> _parsePlaceholders(String? text) {
    if (text == null || text.isEmpty) return [];
    final RegExp placeholderRegExp = RegExp(r"\[([a-zA-Z0-9_.-]+?)\]");
    final List<String> ids = [];
    for (Match match in placeholderRegExp.allMatches(text)) {
      final placeholderId = match.group(1);
      if (placeholderId != null) {
        ids.add(placeholderId);
      }
    }
    return ids.toSet().toList();
  }

  void _identifyRelevantBlocks() {
    if (widget.objectiveTemplate == null || widget.objectiveTemplate!.isEmpty) {
      _relevantBlocks = [];
      return;
    }
    final placeholderIds = _parsePlaceholders(widget.objectiveTemplate);
    final foundBlocks = <SystemParameterBlock>[];
    for (String id in placeholderIds) {
      try {
        final block = widget.allSystemParameterBlocks.firstWhere((b) => b.id == id);
        foundBlocks.add(block);
      } catch (e) {
        if (kDebugMode) {
          print("SystemParameterBlock ID '$id' in objective template not found in global definitions.");
        }
      }
    }
    _relevantBlocks = foundBlocks;
  }

  void _updatePreviewStatement() {
    if (widget.objectiveTemplate == null || widget.objectiveTemplate!.isEmpty) {
      _previewStatement = "No template available for this objective to preview with parameters.";
      return;
    }
    // Use a simple text replacement for preview, or the more complex TextSpan builder
    // For simplicity here, a direct string replacement is shown.
    // For rich text, use substituteBlockValuesAndStyle from ssp_statement_templates.dart
    
    String tempStatement = widget.objectiveTemplate!;
    _currentParameterValues.forEach((key, value) {
      tempStatement = tempStatement.replaceAll('[$key]', value.isNotEmpty ? value : '[$key-not-set]');
    });
    // Replace any remaining placeholders that weren't in _currentParameterValues (shouldn't happen if all relevant are shown)
    for (var block in _relevantBlocks) {
        if (!_currentParameterValues.containsKey(block.id) || _currentParameterValues[block.id]!.isEmpty) {
             tempStatement = tempStatement.replaceAll('[${block.id}]', '[${block.title}-not-set]');
        }
    }


    setState(() {
      _previewStatement = tempStatement;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String objectiveDisplayLabel = _getObjectiveDisplayLabel(widget.objectivePart);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Parameters for Objective: $objectiveDisplayLabel", style:const TextStyle(fontSize: 16)),
            Text(widget.controlId, style: theme.textTheme.bodySmall?.copyWith(fontSize: 12)),
          ],
        ),
        // No explicit save button needed if ParameterInputWidget saves on change
        // A "Done" button can just pop the screen.
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text("Objective:", style: theme.textTheme.titleMedium),
                SelectableText(widget.objectivePart.prose ?? "No prose available.", style: theme.textTheme.bodyMedium),
                const SizedBox(height: 16),
                const Divider(),
                Text("Define Values for Referenced System Parameters:", style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_relevantBlocks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      widget.objectiveTemplate == null || widget.objectiveTemplate!.isEmpty
                          ? "No specific statement template found for this objective to identify parameters."
                          : "No system parameters are referenced in this objective's statement template.",
                      style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                    ),
                  )
                else
                  ..._relevantBlocks.map((block) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ParameterInputWidget(
                        // ParameterInputWidget expects the full InformationSystem object
                        // to access system.systemParameterBlockValues for its initial value and saving.
                        system: widget.system, 
                        block: block,
                        onChanged: () {
                          // ParameterInputWidget saves to ProjectDataManager itself.
                          // We need to update our local _currentParameterValues to refresh the preview.
                          // And also refresh the _system object instance in the parent if necessary.
                           final projectManager = Provider.of<ProjectDataManager>(context, listen: false);
                           final updatedSystem = projectManager.getSystemById(widget.systemId);
                           if (updatedSystem != null) {
                               setState(() {
                                   _currentParameterValues = Map<String, String>.from(updatedSystem.systemParameterBlockValues);
                                   _updatePreviewStatement();
                               });
                           }
                        },
                      ),
                    );
                  }),
                const SizedBox(height: 16),
                const Divider(),
                Text("Live Preview of Objective Statement:", style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12.0),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withAlpha((0.5 * 255).round()),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: SelectableText(
                    _previewStatement,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.done_all_outlined),
              label: const Text("Done with Parameters for this Objective"),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          )
        ],
      ),
    );
  }
}