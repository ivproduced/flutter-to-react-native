import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/app_data_manager.dart';
import 'package:nist_pocket_guide/services/purchase_service.dart';
import 'package:nist_pocket_guide/800-53_screens/widgets/control/control_tile.dart'; // 👈 Make sure this is imported

class NotesScreen extends StatelessWidget {
  final PurchaseService purchaseService;

  const NotesScreen({super.key, required this.purchaseService});

  @override
  Widget build(BuildContext context) {
    final notes = AppDataManager()
        .notesPerControl
        .entries
        .where((entry) => entry.value.trim().isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: notes.isEmpty
          ? const Center(child: Text('No notes added yet.'))
          : ListView(
              children: notes.map((entry) {
                 final control = AppDataManager.instance.getControlById(entry.key);

                if (control == null) return const SizedBox.shrink(); // skip invalid
                return NoteControlTile(
                  control: control,
                  purchaseService: purchaseService,
                );
              }).toList(),
            ),
    );
  }
}
