// --- widgets/control/notes_section.dart ---

import 'package:flutter/material.dart';
import '../../../services/purchase_service.dart';
import '../../../app_data_manager.dart';
import '../../../services/utils/upgrade_dialog.dart';

class NotesSection extends StatefulWidget {
  final String controlId;
  final PurchaseService purchaseService;

  const NotesSection({
    super.key,
    required this.controlId,
    required this.purchaseService,
  });

  @override
  State<NotesSection> createState() => _NotesSectionState();
}

class _NotesSectionState extends State<NotesSection> {
  late TextEditingController _notesController;
  final FocusNode _notesFocusNode = FocusNode();
  String _initialNoteValue = ''; // To track if the note has actually changed

  bool get isPro => widget.purchaseService.isPro;

  @override
  void initState() {
    super.initState();
    _initialNoteValue = AppDataManager.instance.getNoteForControl(widget.controlId) ?? '';
    _notesController = TextEditingController(text: _initialNoteValue);
    _notesFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    // Save when the text field loses focus, only if the content has changed
    if (!_notesFocusNode.hasFocus && _notesController.text != _initialNoteValue) {
      _saveNote(shouldNotify: true); // Notify when saving due to focus change
      _initialNoteValue = _notesController.text; // Update initial value after save
    }
  }

  void _saveNote({bool shouldNotify = true}) { // Added shouldNotify parameter
    final currentNote = _notesController.text;
    // Optionally, only save if the note has actually changed from its last saved state
    // This check is more robust if _initialNoteValue is updated after every save.
    // if (currentNote != _initialNoteValue) { // Or compare with AppDataManager().getNoteForControl(widget.controlId)
    AppDataManager.instance.addOrUpdateNote(widget.controlId, currentNote, shouldNotify: shouldNotify);
    // }
  }

  @override
  void dispose() {
    _notesFocusNode.removeListener(_onFocusChange);
    _notesFocusNode.dispose();

    // Save one last time if content changed, but do NOT broadly notify during dispose
    // as it can cause issues with widget tree being locked during navigation.
    if (_notesController.text != _initialNoteValue) {
      _saveNote(shouldNotify: false);
    }
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Notes",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        isPro
            ? TextField(
                controller: _notesController,
                focusNode: _notesFocusNode, // Assign the focus node
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Add your notes here...',
                  border: OutlineInputBorder(),
                ),
                // REMOVED: onChanged: (_) => _saveNote(),
                // Save when editing is complete (e.g., user presses "done" or unfocuses)
                onEditingComplete: () {
                  _saveNote(shouldNotify: true); // Notify on explicit completion
                  _notesFocusNode.unfocus(); // Remove focus
                },
              )
            : GestureDetector(
                onTap: () => showUpgradeDialog(context, widget.purchaseService),
                child: AbsorbPointer(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Upgrade to Pro to unlock notes',
                      border: OutlineInputBorder(),
                      enabled: false, // Make it look disabled
                    ),
                    maxLines: 4,
                    style: TextStyle(color: Theme.of(context).disabledColor),
                  ),
                ),
              ),
      ],
    );
  }
}