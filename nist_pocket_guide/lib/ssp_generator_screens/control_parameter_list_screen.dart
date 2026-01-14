import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/app_data_manager.dart';
import 'package:nist_pocket_guide/models/information_system.dart';
import 'package:nist_pocket_guide/models/oscal_models.dart';
import 'package:nist_pocket_guide/models/baseline_profile.dart'; // For BaselineProfile
// import 'package:nist_pocket_guide/ssp_generator_screens/system_ssp_input_screen.dart'; // Old target
import 'package:nist_pocket_guide/ssp_generator_screens/control_workspace_screen.dart'; // New target

class SspGeneratorControlListScreen extends StatefulWidget {
  final InformationSystem system;

  const SspGeneratorControlListScreen({super.key, required this.system});

  @override
  State<SspGeneratorControlListScreen> createState() =>
      _SspGeneratorControlListScreenState();
}

class _SspGeneratorControlListScreenState
    extends State<SspGeneratorControlListScreen> {
  List<Control> _baselineControls = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Helper to normalize enhancement IDs for consistent matching
  String _normalizeEnhancementId(String id) {
    return id.toLowerCase().replaceAll('(', '.').replaceAll(')', '');
  }

  @override
  void initState() {
    super.initState();
    _loadBaselineControls();
    _searchController.addListener(() {
      if (mounted) { // Added mounted check
        setState(() {
          _searchQuery = _searchController.text.toLowerCase();
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBaselineControls() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final appDataManager = AppDataManager.instance;

    if (widget.system.selectedBaselineId != null &&
        appDataManager.isInitialized) {
      final baselineId = widget.system.selectedBaselineId!;
      BaselineProfile? selectedProfile =
          _getSelectedProfile(appDataManager, baselineId);

      if (selectedProfile != null) {
        _baselineControls = appDataManager.catalog.controls.where((control) {
          if (selectedProfile.selectedControlIds
              .contains(control.id.toLowerCase())) {
            return true;
          }
          // Include parent control if any of its enhancements are in the baseline
          for (var enhancement in control.enhancements) {
            // Use the consistent normalization for matching
            final normalizedEnhId = _normalizeEnhancementId(enhancement.id);
            if (selectedProfile.selectedControlIds.contains(normalizedEnhId)) {
              return true;
            }
          }
          return false;
        }).toList();
        _baselineControls.sort((a, b) => _sortControls(a.id, b.id));
      } else {
        _baselineControls = []; // Baseline profile not found
      }
    } else {
      _baselineControls = []; // No baseline selected or AppDataManager not ready
    }
    if (mounted) {
      setState(() => _isLoading = false);
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

  int _sortControls(String a, String b) {
    RegExp pattern = RegExp(r"([A-Za-z]+)-(\d+)(.*)");
    Match? matchA = pattern.firstMatch(a);
    Match? matchB = pattern.firstMatch(b);

    if (matchA != null && matchB != null) {
      String prefixA = matchA.group(1)!;
      String prefixB = matchB.group(1)!;
      int numA = int.parse(matchA.group(2)!);
      int numB = int.parse(matchB.group(2)!);
      String suffixA = matchA.group(3)!;
      String suffixB = matchB.group(3)!;

      if (prefixA.compareTo(prefixB) != 0) {
        return prefixA.compareTo(prefixB);
      }
      if (numA != numB) {
        return numA.compareTo(numB);
      }
      return suffixA.compareTo(suffixB);
    }
    return a.compareTo(b);
  }

  List<Control> get _filteredControls {
    if (_searchQuery.isEmpty) {
      return _baselineControls;
    }
    // Current search only filters top-level controls by ID and title.
    // Enhancements within these controls are not individually filtered out here,
    // they are shown as part of their parent control in the target screen.
    return _baselineControls.where((control) {
      final controlId = control.id.toLowerCase();
      final controlTitle = control.title.toLowerCase();
      return controlId.contains(_searchQuery) ||
          controlTitle.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Control'), // Updated title
            Text(
              widget.system.name,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search Controls (e.g., AC-2)',
                      hintText: 'Enter control ID or title',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      filled: true,
                      // fillColor: Theme.of(context).canvasColor, // Consider theme-based fill
                    ),
                  ),
                ),
                Expanded(
                  child: _baselineControls.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              widget.system.selectedBaselineId == null
                                  ? 'No baseline is selected for system "${widget.system.name}". Please select one in System Management.'
                                  : 'No controls found for baseline "${widget.system.selectedBaselineId}" for system "${widget.system.name}". Ensure the baseline profile is correctly configured and has controls.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : _filteredControls.isEmpty
                          ? Center(
                              child: Text(
                                  'No controls match "$_searchQuery"'))
                          : ListView.builder(
                              itemCount: _filteredControls.length,
                              itemBuilder: (context, index) {
                                final control = _filteredControls[index];
                                // Check if the control itself or any of its *selected* enhancements have objectives.
                                // This is a more nuanced check. For simplicity, we can check flatAssessmentObjectives.
                                final bool hasDefinedObjectives = control.flatAssessmentObjectives.isNotEmpty;

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.tune_outlined, // Changed icon to suit workspace concept
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    title: Text('${control.id.toUpperCase()}: ${control.title}'),
                                    subtitle: Text(
                                      hasDefinedObjectives
                                        ? '${control.flatAssessmentObjectives.length} assessment objective(s) defined'
                                        : 'No specific assessment objectives defined in catalog',
                                      style: TextStyle(
                                        color: hasDefinedObjectives ? null : Colors.orange[700],
                                        fontStyle: hasDefinedObjectives ? FontStyle.normal : FontStyle.italic
                                      )
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () { // onTap is no longer conditional based on hasObjectives
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ControlSspWorkspaceScreen(
                                            systemId: widget.system.id,
                                            controlId: control.id, // Pass controlId
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }
}