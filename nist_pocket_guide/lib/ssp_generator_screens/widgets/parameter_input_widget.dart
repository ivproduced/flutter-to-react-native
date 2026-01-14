import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/models/information_system.dart';
import 'package:nist_pocket_guide/models/system_parameter_block.dart';
import 'package:nist_pocket_guide/provider/project_data_manager.dart';
import 'package:provider/provider.dart';

class ParameterInputWidget extends StatefulWidget {
  final InformationSystem system;
  final SystemParameterBlock block;
  final VoidCallback onChanged;

  const ParameterInputWidget({
    super.key,
    required this.system,
    required this.block,
    required this.onChanged,
  });

  @override
  State<ParameterInputWidget> createState() => _ParameterInputWidgetState();
}

class _ParameterInputWidgetState extends State<ParameterInputWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.system.systemParameterBlockValues[widget.block.id] ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _updateParameter(String newValue) async {
    final projectManager = Provider.of<ProjectDataManager>(
      context,
      listen: false,
    );
    final updatedSystem = InformationSystem.fromMap(widget.system.toMap());
    updatedSystem.systemParameterBlockValues[widget.block.id] = newValue;
    await projectManager.updateSystem(updatedSystem);
    widget.onChanged(); // Notify parent to refresh
  }

  @override
  Widget build(BuildContext context) {
    // Always use text field for input, with ActionChips for quick selection
    Widget inputField = TextFormField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: 'Your Value',
        hintText:
            widget.block.examples.isNotEmpty
                ? 'e.g., ${widget.block.examples.first}'
                : 'Enter value here',
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      onChanged: (value) => _updateParameter(value),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.block.title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (widget.block.summary.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              widget.block.summary,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(height: 1.4),
            ),
          ],
          const SizedBox(height: 12),
          inputField,
          if (widget.block.examples.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text("Examples:", style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6.0,
              children:
                  widget.block.examples
                      .map(
                        (ex) => ActionChip(
                          label: Text(ex),
                          onPressed: () {
                            setState(() {
                              _controller.text = ex;
                            });
                            _updateParameter(ex);
                          },
                        ),
                      )
                      .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
