// lib/screens/system_parameters_input_screen.dart
import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/app_data_manager.dart';
import 'package:nist_pocket_guide/models/information_system.dart';
import 'package:nist_pocket_guide/models/system_parameter_block.dart';
import 'package:nist_pocket_guide/provider/project_data_manager.dart';
import 'package:provider/provider.dart';

class SystemParametersInputScreen extends StatefulWidget {
  final String systemId;

  const SystemParametersInputScreen({super.key, required this.systemId});

  @override
  State<SystemParametersInputScreen> createState() =>
      _SystemParametersInputScreenState();
}

class _SystemParametersInputScreenState
    extends State<SystemParametersInputScreen> {
  InformationSystem? _system;
  List<SystemParameterBlock> _definedParameterBlocks = [];
  final Map<String, TextEditingController> _valueControllers = {};
  // To manage dropdown states if we convert some TextFormFields to DropdownButtonFormFields
  final Map<String, String?> _dropdownSelectedValues = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadDataAndInitializeControllers();
  }

  Future<void> _loadDataAndInitializeControllers() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final projectManager = Provider.of<ProjectDataManager>(
      context,
      listen: false,
    );
    _system = projectManager.getSystemById(widget.systemId);

    if (AppDataManager.instance.isInitialized) {
      _definedParameterBlocks = AppDataManager.instance.systemParameterBlocks;
    } else {
      // if (kDebugMode) {
      //     print("WARN: AppDataManager not initialized in SystemParametersInputScreen. Attempting init.");
      //   }
      await AppDataManager.instance.initialize();
      _definedParameterBlocks = AppDataManager.instance.systemParameterBlocks;
    }

    if (_system != null) {
      _valueControllers.clear();
      _dropdownSelectedValues.clear();
      for (var blockDef in _definedParameterBlocks) {
        String existingValue =
            _system!.systemParameterBlockValues[blockDef.id] ?? '';
        _valueControllers[blockDef.id] = TextEditingController(
          text: existingValue,
        );
        // If we use dropdowns, pre-select if the value is in examples
        if (blockDef.examples.isNotEmpty &&
            blockDef.examples.contains(existingValue)) {
          _dropdownSelectedValues[blockDef.id] = existingValue;
        } else {
          _dropdownSelectedValues[blockDef.id] =
              null; // Or set to an empty string if that's your "none" value
        }
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _valueControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _saveSystemParameters() async {
    if (_system == null || _isSaving || !mounted) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final Map<String, String> newBlockValues = {};
    _valueControllers.forEach((blockId, controller) {
      newBlockValues[blockId] = controller.text.trim();
    });
    // if (kDebugMode) {
    //   print("SystemParametersInputScreen - _saveParameters - newValues being set: $newBlockValues");
    // }

    InformationSystem systemToUpdate = InformationSystem.fromMap(
      _system!.toMap(),
    );
    systemToUpdate.systemParameterBlockValues = newBlockValues;

    // --- Debug print removed ---

    final projectManager = Provider.of<ProjectDataManager>(
      context,
      listen: false,
    );
    bool success = await projectManager.updateSystem(systemToUpdate);

    if (mounted) {
      setState(() {
        _isSaving = false;
        if (success) _system = systemToUpdate;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'System parameters saved!'
                : 'Error saving parameters: ${projectManager.errorMessage ?? "Unknown error."}',
          ),
        ),
      );
      if (success) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Parameters for ${_system?.name ?? "System"}'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_system == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('System not found.')),
      );
    }

    if (_definedParameterBlocks.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Parameters for ${_system!.name}')),
        body: const Center(/* ... No blocks defined message ... */),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${_system?.name ?? 'System'} - Parameter Input'),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
          itemCount: _definedParameterBlocks.length,
          itemBuilder: (context, index) {
            final block = _definedParameterBlocks[index];
            final controller = _valueControllers[block.id];

            if (controller == null) {
              return Card(/* ... Error controller missing ... */);
            }

            Widget inputField;
            // Condition for using Dropdown: has 2 to 7 examples (arbitrary limits)
            bool useDropdown =
                block.examples.length >= 2 && block.examples.length <= 7;

            if (useDropdown) {
              // Use the _dropdownSelectedValues map for the dropdown's value
              // Ensure the controller's text is updated when dropdown changes
              inputField = DropdownButtonFormField<String>(
                value:
                    _dropdownSelectedValues[block
                        .id], // This should be one of the example strings or null
                hint: Text('Select or type for "${block.title}"'),
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: [
                  DropdownMenuItem<String>(
                    value:
                        null, // Represents clearing to type custom or no selection
                    child: Text(
                      "- Select an option -",
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                  ...block.examples.map(
                    (ex) => DropdownMenuItem(value: ex, child: Text(ex)),
                  ),
                ],
                onChanged: (String? newValue) {
                  setState(() {
                    controller.text = newValue ?? ''; // Update controller text
                    _dropdownSelectedValues[block.id] =
                        newValue; // Update dropdown state
                  });
                },
                // To allow typing a custom value even with dropdown, would need a more complex widget
                // or instruct users to clear selection to type. For now, this forces selection from list OR empty.
              );
            } else {
              inputField = TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Your Value',
                  hintText:
                      block.examples.isNotEmpty
                          ? 'e.g., ${block.examples.first}'
                          : 'Enter value here',
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines:
                    block.summary.length > 100 || block.title.length > 50
                        ? 2
                        : 1,
                onChanged: (value) {
                  // If it was a dropdown, changing text field might deselect dropdown
                  if (useDropdown) {
                    setState(() {
                      _dropdownSelectedValues[block.id] = null;
                    });
                  }
                },
              );
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      block.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (block.summary.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        block.summary,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(height: 1.4),
                      ),
                    ],
                    const SizedBox(height: 12),
                    inputField,
                    if (block.examples.isNotEmpty && !useDropdown) ...[
                      const SizedBox(height: 10),
                      Text(
                        "Examples:",
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6.0,
                        runSpacing: 0.0,
                        children:
                            block.examples
                                .map(
                                  (ex) => Chip(
                                    label: Text(ex),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 0,
                                    ),
                                    labelStyle:
                                        Theme.of(context).textTheme.bodySmall,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                )
                                .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveSystemParameters,
        label: const Text('Save All Parameters'),
        icon:
            _isSaving
                ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : const Icon(Icons.save),
      ),
    );
  }
}
