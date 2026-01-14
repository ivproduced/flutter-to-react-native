import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/provider/project_data_manager.dart';
import 'package:nist_pocket_guide/ssp_generator_screens/ssp_bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'control_parameter_list_screen.dart'; // Next screen

class SspGeneratorProjectListScreen extends StatelessWidget {
  const SspGeneratorProjectListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final projectManager = Provider.of<ProjectDataManager>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SSP Generator - Select System/Project'),
      ),
      body: SafeArea(
        child:
            projectManager.isLoading
                ? const Center(child: CircularProgressIndicator())
                : projectManager.systems.isEmpty
                ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No projects/systems found. Please create a system in "Project/System Management" first.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
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
                        leading: const Icon(Icons.folder_copy_outlined),
                        title: Text(system.name),
                        subtitle: Text(
                          'Baseline: ${system.selectedBaselineId ?? "Not Set"}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          if (system.selectedBaselineId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'This system has no baseline selected. Please edit it first.',
                                ),
                              ),
                            );
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => SspGeneratorControlListScreen(
                                    system: system,
                                  ), // Pass the whole system
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      ),
      bottomNavigationBar: const SspGeneratorBottomNavBar(),
    );
  }
}
