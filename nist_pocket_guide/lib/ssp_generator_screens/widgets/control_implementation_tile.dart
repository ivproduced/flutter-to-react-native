// lib/widgets/control_implementation_tile.dart
import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/app_data_manager.dart';
import 'package:nist_pocket_guide/models/baseline_profile.dart';
import 'package:nist_pocket_guide/models/information_system.dart';
import 'package:nist_pocket_guide/models/oscal_models.dart'; // This should define Control and Enhancement
import 'package:nist_pocket_guide/provider/project_data_manager.dart';
import 'package:nist_pocket_guide/services/utils/ui_helpers.dart';
import 'package:provider/provider.dart'; // Ensure this import works after pub get


class ControlImplementationTile extends StatefulWidget {
  final String systemId;
  final Control control;
  final String? selectedBaselineId;
  final VoidCallback onChanged;

  const ControlImplementationTile({
    super.key,
    required this.systemId,
    required this.control,
    required this.selectedBaselineId,
    required this.onChanged,
  });

  @override
  State<ControlImplementationTile> createState() =>
      _ControlImplementationTileState();
}

class _ControlImplementationTileState extends State<ControlImplementationTile> {
  late InformationSystem? _system;

  late ControlImplementation _currentMainImplementation;
  late TextEditingController _mainDetailsController;
  late TextEditingController _mainNotesController;
  late TextEditingController _mainNewEvidenceController;

  // MODIFIED: Make these final as they are initialized in initState and not reassigned
  final Map<String, ControlImplementation> _currentEnhancementImplementations = {};
  final Map<String, TextEditingController> _enhancementDetailsControllers = {};
  final Map<String, TextEditingController> _enhancementNotesControllers = {};
  final Map<String, TextEditingController> _enhancementNewEvidenceControllers = {};
  final Map<String, List<String>> _enhancementEvidenceLists = {};
  List<Control> _selectedEnhancements = []; // This can change if data reloads, so not final

  @override
  void initState() {
    super.initState();
    // Ensure Provider.of is called correctly for ProjectDataManager
    // It's better to get this once rather than in every build method if not listening directly.
    // However, for initState, listen:false is appropriate.
    final projectManager = Provider.of<ProjectDataManager>(context, listen: false);
    _system = projectManager.getSystemById(widget.systemId);

    _currentMainImplementation = _system?.controlImplementations[widget.control.id] ??
        ControlImplementation(status: controlStatusOptions.first);
    _mainDetailsController = TextEditingController(text: _currentMainImplementation.implementationDetails);
    _mainNotesController = TextEditingController(text: _currentMainImplementation.notes);
    _mainNewEvidenceController = TextEditingController();

    if (_system != null && widget.selectedBaselineId != null) {
      final appDataManager = AppDataManager.instance;
      // Ensure AppDataManager is initialized before accessing baselines
      if (appDataManager.isInitialized) {
         BaselineProfile? selectedProfile = _getSelectedProfile(appDataManager, widget.selectedBaselineId!);

        if (selectedProfile != null) {
          _selectedEnhancements = widget.control.enhancements.where((enh) {
            final normEnhancementId = enh.id.toLowerCase().replaceAll('(', '.').replaceAll(')', '');
            return selectedProfile.selectedControlIds.contains(normEnhancementId);
          }).toList(); // .toList() is fine here as where returns an Iterable

          for (var enh in _selectedEnhancements) { // enh here is correctly typed as Enhancement
            _currentEnhancementImplementations[enh.id] =
                _system?.controlImplementations[enh.id] ??
                    ControlImplementation(status: controlStatusOptions.first);
            _enhancementDetailsControllers[enh.id] = TextEditingController(
                text: _currentEnhancementImplementations[enh.id]?.implementationDetails ?? ''); // Null check
            _enhancementNotesControllers[enh.id] = TextEditingController(
                text: _currentEnhancementImplementations[enh.id]?.notes ?? ''); // Null check
            _enhancementNewEvidenceControllers[enh.id] = TextEditingController();
            _enhancementEvidenceLists[enh.id] =
                List<String>.from(_currentEnhancementImplementations[enh.id]?.evidence ?? []); // Null check
          }
        }
      } else {
         // Handle case where AppDataManager might not be initialized yet, though it should be.
        // if (kDebugMode) {
        //   print("WARN: AppDataManager not initialized in ControlImplementationTile initState");
        // }
      }
    }
  }

  BaselineProfile? _getSelectedProfile(AppDataManager adm, String baselineId) {
    if (baselineId == adm.lowBaseline.id) return adm.lowBaseline;
    if (baselineId == adm.moderateBaseline.id) return adm.moderateBaseline;
    if (baselineId == adm.highBaseline.id) return adm.highBaseline;
    if (baselineId == adm.privacyBaseline.id) return adm.privacyBaseline;
    try {
      return adm.userBaselines.firstWhere((b) => b.id == baselineId);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _mainDetailsController.dispose();
    _mainNotesController.dispose();
    _mainNewEvidenceController.dispose();
    _enhancementDetailsControllers.forEach((_, controller) => controller.dispose());
    _enhancementNotesControllers.forEach((_, controller) => controller.dispose());
    _enhancementNewEvidenceControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _saveImplementation(String controlOrEnhancementId, ControlImplementation impl) async {
    // Ensure Provider.of is used correctly here if needed, or pass projectManager
    final projectManager = Provider.of<ProjectDataManager>(context, listen: false);
    bool success = await projectManager.updateControlImplementation(
      systemId: widget.systemId,
      controlId: controlOrEnhancementId,
      implementation: impl,
    );
    widget.onChanged();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '$controlOrEnhancementId implementation saved.'
                : 'Failed to save $controlOrEnhancementId.',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Widget _buildImplementationForm(
    String title, // Not used directly anymore if title is part of header
    ControlImplementation currentImplementation,
    TextEditingController detailsController,
    TextEditingController notesController,
    TextEditingController newEvidenceController,
    List<String> currentEvidenceList,
    Function(ControlImplementation) onSave,
    {bool isEnhancement = false}
  ) {
    // Using a StatefulWidget for the form itself can help manage local status without rebuilding the whole tile
    // For now, keeping it simple.
    String localStatus = currentImplementation.status;

    return Padding(
      padding: EdgeInsets.only(left: isEnhancement ? 16.0 : 0, top: 8.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: localStatus,
            decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
            items: controlStatusOptions.map((String status) {
              return DropdownMenuItem<String>(value: status, child: Text(status));
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() { // This setState is for the _ControlImplementationTileState
                  localStatus = newValue; // Update local copy for dropdown
                  currentImplementation.status = newValue; // Update the model
                });
                onSave(currentImplementation); // Save on change
              }
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: detailsController,
            decoration: InputDecoration(
                labelText: '${isEnhancement ? "Enh. " : ""}Implementation Details',
                border: const OutlineInputBorder()),
            maxLines: 3,
            onChanged: (value) {
              currentImplementation.implementationDetails = value;
            },
            onEditingComplete: () => onSave(currentImplementation..implementationDetails = detailsController.text),
            onTapOutside: (_) {
              if (detailsController.text.trim() != currentImplementation.implementationDetails.trim()) {
                 onSave(currentImplementation..implementationDetails = detailsController.text.trim());
              }
            }
          ),
          const SizedBox(height: 12),
          Text('Evidence:', style: Theme.of(context).textTheme.titleSmall),
          if (currentEvidenceList.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4.0),
              child: Text("No evidence added.", style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13))
            ),
          ...currentEvidenceList.asMap().entries.map((entry) { // Removed .toList() here, spread handles it
            int idx = entry.key;
            String evidence = entry.value;
            return ListTile(
              dense: true,
              leading: const Icon(Icons.link_outlined, size: 18),
              title: Text(evidence, style: const TextStyle(fontSize: 13)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                onPressed: () {
                  setState(() {
                    currentEvidenceList.removeAt(idx);
                    currentImplementation.evidence = List.from(currentEvidenceList); // Update model
                  });
                  onSave(currentImplementation); // Save on change
                },
              ),
            );
          }),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: newEvidenceController,
                  decoration: const InputDecoration(
                      hintText: 'Add evidence link/description',
                      border: UnderlineInputBorder()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                onPressed: () {
                  if (newEvidenceController.text.trim().isNotEmpty) {
                    setState(() {
                      currentEvidenceList.add(newEvidenceController.text.trim());
                      currentImplementation.evidence = List.from(currentEvidenceList); // Update model
                      newEvidenceController.clear();
                    });
                    onSave(currentImplementation); // Save on change
                  }
                },
              )
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: notesController,
            decoration:
                InputDecoration(labelText: '${isEnhancement ? "Enh. " : ""}Control Notes', border: const OutlineInputBorder()),
            maxLines: 2,
            onChanged: (value) => currentImplementation.notes = value,
            onEditingComplete: () => onSave(currentImplementation..notes = notesController.text),
            onTapOutside: (_) {
              if (notesController.text.trim() != currentImplementation.notes.trim()) {
                 onSave(currentImplementation..notes = notesController.text.trim());
              }
            }
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // It's generally better to get the system instance once in initState or via a Consumer/Selector
    // For simplicity and to ensure reactivity if the system object itself is replaced in ProjectDataManager:
    _system = Provider.of<ProjectDataManager>(context, listen: true).getSystemById(widget.systemId);


    if (_system == null) return const SizedBox.shrink(); // System might have been deleted

    // Refresh local implementation objects if the system's data has changed
    // This is important if ProjectDataManager reloads systems or if another part of the app modifies it.
    _currentMainImplementation = _system!.controlImplementations[widget.control.id] ??
        ControlImplementation(status: controlStatusOptions.first);
    // Update controllers if their text doesn't match the model (prevents cursor jump)
    if (_mainDetailsController.text != _currentMainImplementation.implementationDetails) {
      _mainDetailsController.text = _currentMainImplementation.implementationDetails;
    }
    if (_mainNotesController.text != _currentMainImplementation.notes) {
      _mainNotesController.text = _currentMainImplementation.notes;
    }


    // Similar refresh for enhancements if _selectedEnhancements might change or their implementations might
    // This part can get complex if _selectedEnhancements itself is reactive.
    // For now, assuming _selectedEnhancements is stable after initState.
     for (var enh in _selectedEnhancements) {
      _currentEnhancementImplementations[enh.id] =
          _system!.controlImplementations[enh.id] ??
              ControlImplementation(status: controlStatusOptions.first);
      if (_enhancementDetailsControllers[enh.id]?.text != _currentEnhancementImplementations[enh.id]?.implementationDetails) {
        _enhancementDetailsControllers[enh.id]?.text = _currentEnhancementImplementations[enh.id]?.implementationDetails ?? '';
      }
      if (_enhancementNotesControllers[enh.id]?.text != _currentEnhancementImplementations[enh.id]?.notes) {
        _enhancementNotesControllers[enh.id]?.text = _currentEnhancementImplementations[enh.id]?.notes ?? '';
      }
      _enhancementEvidenceLists[enh.id] = List<String>.from(_currentEnhancementImplementations[enh.id]?.evidence ?? []);
    }


    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ExpansionTile(
        key: PageStorageKey(widget.control.id),
        leading: Icon(Icons.security_outlined, color: getStatusColor(_currentMainImplementation.status, context)),
        title: Text(
          '${widget.control.id}: ${widget.control.title}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Status: ${_currentMainImplementation.status}',
          style: TextStyle(
              color: getStatusColor(_currentMainImplementation.status, context),
              fontStyle: FontStyle.italic),
        ),
        childrenPadding: const EdgeInsets.all(16).copyWith(top: 0),
        children: [
          _buildImplementationForm(
            'Main Control Implementation', // Title for context, not displayed directly by form
            _currentMainImplementation,
            _mainDetailsController,
            _mainNotesController,
            _mainNewEvidenceController,
            _currentMainImplementation.evidence, // Pass the live list from the model
            (impl) => _saveImplementation(widget.control.id, impl),
          ),
          if (_selectedEnhancements.isNotEmpty)
            const Divider(height: 20, thickness: 1, indent: 16, endIndent: 16),
          ..._selectedEnhancements.map((Control enh) { // Explicitly type enh
            // Null checks for safety, though they should be initialized in initState
            final currentEnhImpl = _currentEnhancementImplementations[enh.id] ?? ControlImplementation(status: controlStatusOptions.first);
            final enhDetailsCtrl = _enhancementDetailsControllers[enh.id] ?? TextEditingController();
            final enhNotesCtrl = _enhancementNotesControllers[enh.id] ?? TextEditingController();
            final enhNewEvidenceCtrl = _enhancementNewEvidenceControllers[enh.id] ?? TextEditingController();
            final enhEvidenceList = _enhancementEvidenceLists[enh.id] ?? [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 12.0, bottom: 4.0),
                  child: Text(
                    'Enhancement ${enh.id}: ${enh.title}', // enh.id and enh.title are now safe
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                  child: Text(
                    'Status: ${currentEnhImpl.status}',
                    style: TextStyle(
                        color: getStatusColor(currentEnhImpl.status, context),
                        fontStyle: FontStyle.italic,
                        fontSize: 12),
                  ),
                ),
                _buildImplementationForm(
                  '${enh.id}: ${enh.title}', // enh.id and enh.title are now safe
                  currentEnhImpl,
                  enhDetailsCtrl,
                  enhNotesCtrl,
                  enhNewEvidenceCtrl,
                  enhEvidenceList, // Pass the live list
                  (impl) => _saveImplementation(enh.id, impl), // enh.id is now safe
                  isEnhancement: true,
                ),
                if (enh != _selectedEnhancements.last)
                  const Divider(height: 16, thickness: 0.5, indent: 16, endIndent: 16),
              ],
            );
          }), // Removed .toList() here, spread handles it
        ],
      ),
    );
  }
  // getStatusColor is now in ui_helpers.dart
}