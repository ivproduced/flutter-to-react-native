import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/models/baseline_profile.dart';
import 'package:nist_pocket_guide/models/oscal_models.dart';
import 'package:nist_pocket_guide/app_data_manager.dart';
import 'package:nist_pocket_guide/services/baseline_mananger.dart';

class CustomBaselineBuilderScreen extends StatefulWidget {
  final BaselineProfile? existingBaseline; // nullable for create mode

  const CustomBaselineBuilderScreen({super.key, this.existingBaseline});

  @override
  State<CustomBaselineBuilderScreen> createState() => _CustomBaselineBuilderScreenState();
}

class _CustomBaselineBuilderScreenState extends State<CustomBaselineBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final Set<String> _selectedControlIds = {};

  late final List<Control> _allControls;

  @override
  void initState() {
    super.initState();
    _allControls = AppDataManager.instance.catalog.controls
        .expand((c) => [c, ...c.enhancements])
        .toList();

    if (widget.existingBaseline != null) {
      _nameController.text = widget.existingBaseline!.id;
      _descController.text = widget.existingBaseline!.title;
      _selectedControlIds.addAll(widget.existingBaseline!.selectedControlIds);
    }
  }

  void _toggleControl(String id) {
    setState(() {
      if (_selectedControlIds.contains(id)) {
        _selectedControlIds.remove(id);
      } else {
        _selectedControlIds.add(id);
      }
    });
  }

  Future<void> _saveBaseline() async {
    if (_formKey.currentState?.validate() != true) return;

    final id = widget.existingBaseline?.id ?? _nameController.text.trim().toLowerCase();
    final title = _descController.text.trim();

    final profile = BaselineProfile(
      id: id,
      title: title,
      selectedControlIds: _selectedControlIds.map((e) => e.toLowerCase()).toList(),
    );

    await BaselineManager.saveUserBaseline(profile);
    await AppDataManager.instance.retagControlsWithUserBaselines();

    if (!mounted) return;

    // Use post-frame callback to pop the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pop(context, true); // pass `true` to trigger rebuild
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Custom Baseline'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveBaseline,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Baseline ID (e.g., custom-1)'),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'ID required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'Description required' : null,
                  ),
                ],
              ),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Select Controls', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _allControls.length,
                itemBuilder: (context, index) {
                  final control = _allControls[index];
                  final isSelected = _selectedControlIds.contains(control.id);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (_) => _toggleControl(control.id),
                    title: Text('${control.id.toUpperCase()} — ${control.title}'),
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
