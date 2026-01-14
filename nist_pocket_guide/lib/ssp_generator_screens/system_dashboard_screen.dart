// lib/screens/system_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/provider/project_data_manager.dart';
import 'package:nist_pocket_guide/services/oscal_service.dart';
import 'package:nist_pocket_guide/ssp_generator_screens/dataio/project_form_screen.dart';
import 'package:nist_pocket_guide/ssp_generator_screens/control_parameter_list_screen.dart';
import 'package:nist_pocket_guide/ssp_generator_screens/control_implementation_list_screen.dart'; // To implement controls
import 'package:nist_pocket_guide/ssp_generator_screens/dataio/oscal_export_screen.dart';
import 'package:nist_pocket_guide/app_data_manager.dart';

import 'package:provider/provider.dart';

class SystemDashboardScreen extends StatelessWidget {
  final String systemId;

  const SystemDashboardScreen({super.key, required this.systemId});

  Widget _buildDashboardTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(
          icon,
          size: 36,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch for changes to the system object
    final system = Provider.of<ProjectDataManager>(
      context,
    ).getSystemById(systemId);

    if (system == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('System Not Found')),
        body: const Center(
          child: Text(
            'The selected system could not be found or has been deleted.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              system.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "System Dashboard",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest
                  .withAlpha((255 * 0.5).round()),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ID: ${system.id}",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "ATO Status: ${system.atoStatus}",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Selected Baseline: ${system.selectedBaselineId ?? 'Not Set'}",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Company/Agency: ${system.companyAgencyName?.isNotEmpty == true ? system.companyAgencyName : 'Not Set'}",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildDashboardTile(
              context,
              icon: Icons.edit_note_outlined,
              title: 'System Details',
              subtitle:
                  'Update name, description, ATO status, baseline, company name.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ProjectFormScreen(systemToEdit: system),
                  ),
                );
              },
            ),
            _buildDashboardTile(
              context,
              icon: Icons.tune_outlined,
              title: 'Control Objective Parameters',
              subtitle:
                  'Set values for reusable statement blocks (e.g., tool names, roles).',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            SspGeneratorControlListScreen(system: system),
                  ),
                );
              },
            ),
            _buildDashboardTile(
              context,
              icon: Icons.checklist_rtl_outlined,
              title: 'Control Implementation Statements',
              subtitle:
                  'Manage control implementation status and build SSP statements.',
              onTap: () {
                if (system.selectedBaselineId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please select a baseline for this system first (Edit System Details).',
                      ),
                    ),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // This will list controls for SSP work, leading to ControlSspWorkspaceScreen
                    builder:
                        (context) => SspViewControlListScreen(system: system),
                  ),
                );
              },
            ),
            // Optional: Full SSP Export Button
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.download_for_offline_outlined),
              label: const Text("Export Full System SSP (OSCAL)"),
              onPressed: () {
                // SSP export logic implementation
                final appDataManager = AppDataManager.instance;
                final selectedBaselineId = system.selectedBaselineId;
                if (selectedBaselineId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Cannot export: No baseline selected for this system.",
                      ),
                    ),
                  );
                  return;
                }
                final profile = OscalService.getSelectedProfile(
                  appDataManager,
                  selectedBaselineId,
                );
                if (profile != null) {
                  final controlsToExport =
                      appDataManager.catalog.controls
                          .where(
                            (c) =>
                                profile.selectedControlIds.contains(
                                  c.id.toLowerCase(),
                                ) ||
                                c.enhancements.any(
                                  (e) => profile.selectedControlIds.contains(
                                    e.id.toLowerCase(),
                                  ),
                                ),
                          )
                          .toList();
                  final oscalString = OscalService.generateOscalJson(
                    system,
                    controlsToExport,
                    appDataManager,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              OscalExportScreen(oscalData: oscalString),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Cannot export: Baseline profile not found.",
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
