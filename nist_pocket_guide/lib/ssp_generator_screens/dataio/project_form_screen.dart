// lib/screens/project_form_screen.dart
import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/app_data_manager.dart';
import 'package:nist_pocket_guide/models/baseline_profile.dart';
import 'package:nist_pocket_guide/provider/project_data_manager.dart';
// import 'package:nist_pocket_guide/ssp_generator_screens/project_form_screen.dart';
// Ensure correct path
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/information_system.dart';

class ProjectFormScreen extends StatefulWidget {
  final InformationSystem? systemToEdit;

  const ProjectFormScreen({super.key, this.systemToEdit});

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;
  late TextEditingController _companyNameController;

  String _selectedAtoStatus = atoStatusOptions.first;
  String? _selectedBaselineId;

  final List<BaselineProfile> _availableBaselines = []; // Make final if not re-assigned
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final system = widget.systemToEdit;
    _nameController = TextEditingController(text: system?.name ?? '');
    _descriptionController = TextEditingController(text: system?.description ?? '');
    _notesController = TextEditingController(text: system?.notes ?? '');
    _companyNameController = TextEditingController(text: system?.companyAgencyName ?? '');
    _selectedAtoStatus = system?.atoStatus ?? atoStatusOptions.first;
    _selectedBaselineId = system?.selectedBaselineId;

    final appDataManager = AppDataManager.instance;
    if (appDataManager.isInitialized) {
      _availableBaselines.clear();
      _availableBaselines.add(appDataManager.lowBaseline);
      _availableBaselines.add(appDataManager.moderateBaseline);
      _availableBaselines.add(appDataManager.highBaseline);
      _availableBaselines.add(appDataManager.privacyBaseline);
      _availableBaselines.addAll(appDataManager.userBaselines);
    }

    if (_selectedBaselineId != null &&
        !_availableBaselines.any((b) => b.id == _selectedBaselineId)) {
      _selectedBaselineId = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) { // Return if form is not valid
      return;
    }
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final projectManager = Provider.of<ProjectDataManager>(context, listen: false);
    final isUpdating = widget.systemToEdit != null;

    final systemData = InformationSystem(
      id: widget.systemToEdit?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      atoStatus: _selectedAtoStatus,
      selectedBaselineId: _selectedBaselineId,
      controlImplementations: widget.systemToEdit?.controlImplementations ?? {},
      assessmentObjectiveResponses: widget.systemToEdit?.assessmentObjectiveResponses ?? {},
      notes: _notesController.text.trim(),
      companyAgencyName: _companyNameController.text.trim(),
      systemParameterBlockValues: widget.systemToEdit?.systemParameterBlockValues ?? {},
    );

    bool success;
    if (isUpdating) {
      success = await projectManager.updateSystem(systemData);
    } else {
      success = await projectManager.addSystem(systemData);
    }

    // Guard uses of BuildContext across async gaps
    if (!mounted) return; // Check if widget is still in the tree

    setState(() => _isSaving = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('System ${isUpdating ? "updated" : "created"} successfully!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${projectManager.errorMessage ?? "Could not save system."}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.systemToEdit != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit System Details' : 'Create New System'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: 'System Name *',
                    hintText: 'e.g., HR Management Portal',
                    border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a system name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16), // Corrected: const SizedBox
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                    labelText: 'Description *',
                    hintText: 'Brief overview of the system and its purpose.',
                    border: OutlineInputBorder()),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16), // Corrected: const SizedBox
              DropdownButtonFormField<String>(
                value: _selectedAtoStatus,
                decoration: const InputDecoration(
                    labelText: 'ATO Status *', border: OutlineInputBorder()),
                items: atoStatusOptions.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedAtoStatus = newValue;
                    });
                  }
                },
                validator: (value) =>
                    value == null ? 'Please select an ATO status.' : null,
              ),
              const SizedBox(height: 16), // Corrected: const SizedBox
              DropdownButtonFormField<String?>(
                value: _selectedBaselineId,
                decoration: const InputDecoration(
                    labelText: 'Select Baseline (Optional)',
                    border: OutlineInputBorder()),
                hint: const Text('None (No Baseline Selected)'),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('None (No Baseline Selected)', style: TextStyle(fontStyle: FontStyle.italic)),
                  ),
                  ..._availableBaselines.map((BaselineProfile baseline) {
                    return DropdownMenuItem<String?>(
                      value: baseline.id,
                      child: Text(baseline.title),
                    );
                  }), // Removed .toList() here, spread works directly
                ],
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedBaselineId = newValue;
                  });
                },
              ),
              const SizedBox(height: 16), // Corrected: const SizedBox
              TextFormField(
                controller: _companyNameController,
                decoration: const InputDecoration(
                    labelText: 'Company/Agency Name (for "[The enterprise]")',
                    hintText: 'e.g., ACME Corporation',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16), // Corrected: const SizedBox
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                    labelText: 'General System Notes',
                    hintText: 'Any additional notes about this system.',
                    border: OutlineInputBorder()),
                maxLines: 5,
              ),
              const SizedBox(height: 24), // Corrected: const SizedBox
               if (isEditing) ...[
                const SizedBox(height: 16),
              ],
              Center(
                child: ElevatedButton.icon( // Corrected: ElevatedButton.icon
                  // Corrected: icon parameter
                  icon: _isSaving ? const SizedBox(width:18, height:18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save System'),
                  onPressed: _isSaving ? null : _submitForm,
                  style: ElevatedButton.styleFrom( // Corrected: ElevatedButton.styleFrom
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} // This is the correct end of the _ProjectFormScreenState class