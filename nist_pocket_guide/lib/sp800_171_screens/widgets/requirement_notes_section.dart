// lib/sp800_171_screens/widgets/requirement_notes_section.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/purchase_service.dart';
import '../../app_data_manager.dart';
import '../../services/utils/upgrade_dialog.dart';

class RequirementNotesSection extends StatefulWidget {
  final String requirementId;

  const RequirementNotesSection({
    super.key,
    required this.requirementId,
  });

  @override
  State<RequirementNotesSection> createState() => _RequirementNotesSectionState();
}

class _RequirementNotesSectionState extends State<RequirementNotesSection> {
  late TextEditingController _notesController;
  final FocusNode _notesFocusNode = FocusNode();
  String _initialNoteValue = '';

  @override
  void initState() {
    super.initState();
    _initialNoteValue = AppDataManager.instance.getNoteForControl(widget.requirementId) ?? '';
    _notesController = TextEditingController(text: _initialNoteValue);
    _notesFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_notesFocusNode.hasFocus && _notesController.text != _initialNoteValue) {
      _saveNote(shouldNotify: true);
      _initialNoteValue = _notesController.text;
    }
  }

  void _saveNote({bool shouldNotify = true}) {
    final currentNote = _notesController.text;
    AppDataManager.instance.addOrUpdateNote(
      widget.requirementId,
      currentNote,
      shouldNotify: shouldNotify,
    );
  }

  @override
  void dispose() {
    _notesFocusNode.removeListener(_onFocusChange);
    _notesFocusNode.dispose();

    if (_notesController.text != _initialNoteValue) {
      _saveNote(shouldNotify: false);
    }
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purchaseService = Provider.of<PurchaseService>(context, listen: false);
    final bool isPro = purchaseService.isPro;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.note_outlined, size: 20),
              const SizedBox(width: 8),
              Text(
                "Notes",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          isPro
              ? TextField(
                  controller: _notesController,
                  focusNode: _notesFocusNode,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Add your notes here...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  onChanged: (_) => setState(() {}),
                )
              : GestureDetector(
                  onTap: () => showUpgradeDialog(context, purchaseService),
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[100],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 32,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Upgrade to Pro to add notes',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          if (isPro && _notesController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: Colors.green[700],
                ),
                const SizedBox(width: 4),
                Text(
                  'Note saved',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
