// lib/screens/system_list_screen.dart (or your renamed ProjectManagementScreen.dart)
import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/provider/project_data_manager.dart';
import 'package:provider/provider.dart';
import 'dataio/project_form_screen.dart';
// --- NEW IMPORT ---
import 'system_dashboard_screen.dart';
// Keep ControlImplementationScreen import if you want a direct link to it,
// but the primary flow will now be via SystemDashboardScreen.
// import 'control_implementation_screen.dart';

class SystemListScreen extends StatelessWidget {
  const SystemListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final projectManager = Provider.of<ProjectDataManager>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Project/System Management')),
      body: SafeArea(
        child:
            projectManager.isLoading
                ? const Center(child: CircularProgressIndicator())
                : projectManager.systems.isEmpty
                ? const Center(/* ... No systems message ... */)
                : ListView.builder(
                  itemCount: projectManager.systems.length,
                  itemBuilder: (context, index) {
                    final system = projectManager.systems[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.dns_outlined,
                        ), // Icon for a system
                        title: Text(
                          system.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          'Status: ${system.atoStatus} | Baseline: ${system.selectedBaselineId ?? "Not Set"}',
                        ),
                        // isThreeLine: true, // Only if needed
                        trailing: IconButton(
                          // Quick edit for metadata
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          tooltip: 'Edit System Details',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        ProjectFormScreen(systemToEdit: system),
                              ),
                            );
                          },
                        ),
                        onTap: () {
                          // --- NAVIGATE TO SystemDashboardScreen ---
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => SystemDashboardScreen(
                                    systemId: system.id,
                                  ),
                            ),
                          );
                        },
                        onLongPress: () async {
                          // For delete
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder:
                                (ctx) => AlertDialog(
                                  title: const Text('Confirm Delete'),
                                  content: Text(
                                    'Are you sure you want to delete "${system.name}"? This action cannot be undone.',
                                  ),
                                  actions: [
                                    TextButton(
                                      child: const Text('Cancel'),
                                      onPressed:
                                          () => Navigator.of(ctx).pop(false),
                                    ),
                                    TextButton(
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      onPressed:
                                          () => Navigator.of(ctx).pop(true),
                                    ),
                                  ],
                                ),
                          );
                          if (confirm == true) {
                            bool success = await projectManager.deleteSystem(
                              system.id,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? '${system.name} deleted.'
                                        : 'Failed to delete ${system.name}.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New System'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProjectFormScreen()),
          );
        },
      ),
    );
  }
}
