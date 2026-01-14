import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/app_data_manager.dart';
import 'package:nist_pocket_guide/models/oscal_models.dart';
import 'package:nist_pocket_guide/provider/project_data_manager.dart';
import 'package:nist_pocket_guide/services/utils/ui_helpers.dart';
import 'package:nist_pocket_guide/ssp_generator_screens/widgets/control_implementation_tile.dart';
import 'package:provider/provider.dart';
import '../models/information_system.dart';
import '../models/baseline_profile.dart'; // For BaselineProfile

class ControlImplementationScreen extends StatefulWidget {
  final String systemId;

  const ControlImplementationScreen({super.key, required this.systemId});

  @override
  State<ControlImplementationScreen> createState() =>
      _ControlImplementationScreenState();
}

class _ControlImplementationScreenState
    extends State<ControlImplementationScreen> {
  InformationSystem? _system;
  List<Control> _baselineControlsAndSelectedEnhancements = [];
  final Map<String, int> _statusSummary = {};
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
    _loadData();
    _searchController.addListener(() {
      if (mounted) {
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

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final projectManager = Provider.of<ProjectDataManager>(
      context,
      listen: false,
    );
    final appDataManager = AppDataManager.instance;

    // _system is set here and becomes the screen's source of truth for this data
    _system = projectManager.getSystemById(widget.systemId);

    if (_system != null &&
        _system!.selectedBaselineId != null &&
        appDataManager.isInitialized) {
      final baselineId = _system!.selectedBaselineId!;
      BaselineProfile? selectedProfile = _getSelectedProfile(
        appDataManager,
        baselineId,
      );

      if (selectedProfile != null) {
        List<Control> tempControls = [];
        for (var control in appDataManager.catalog.controls) {
          bool controlItselfInBaseline = selectedProfile.selectedControlIds
              .contains(control.id.toLowerCase());
          bool anyEnhancementInBaseline = false;
          if (control.enhancements.isNotEmpty) {
            anyEnhancementInBaseline = control.enhancements.any((enh) {
              final normalizedEnhId = _normalizeEnhancementId(enh.id);
              return selectedProfile.selectedControlIds.contains(
                normalizedEnhId,
              );
            });
          }
          if (controlItselfInBaseline || anyEnhancementInBaseline) {
            tempControls.add(control);
          }
        }
        _baselineControlsAndSelectedEnhancements = tempControls;
        _baselineControlsAndSelectedEnhancements.sort(
          (a, b) => _sortControls(a.id, b.id),
        );
      } else {
        _baselineControlsAndSelectedEnhancements = [];
      }
    } else {
      _baselineControlsAndSelectedEnhancements = [];
    }
    _updateStatusSummary();
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
      return null; // Baseline not found
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
      // For enhancements like ac-2(1), ac-2(2) or ac-2.a, ac-2.b
      // This part of suffix comparison might need refinement based on exact enhancement ID structure
      // if they are not already handled by the main numeric sort.
      // The current suffixA.compareTo(suffixB) might be sufficient for many cases.
      return suffixA.compareTo(suffixB);
    }
    return a.compareTo(b); // Fallback for non-standard IDs
  }

  void _updateStatusSummary() {
    if (_system == null || _system!.selectedBaselineId == null) {
      _statusSummary.clear();
      if (mounted) setState(() {});
      return;
    }
    _statusSummary.clear();

    final appDataManager = AppDataManager.instance;
    BaselineProfile? selectedProfile = _getSelectedProfile(
      appDataManager,
      _system!.selectedBaselineId!,
    );

    if (selectedProfile == null) {
      if (mounted) setState(() {});
      return;
    }

    for (var control in _baselineControlsAndSelectedEnhancements) {
      // Summarize main control only if it's in the selected baseline
      if (selectedProfile.selectedControlIds.contains(
        control.id.toLowerCase(),
      )) {
        final impl =
            _system!.controlImplementations[control.id] ??
            ControlImplementation(status: 'Not Implemented'); // Default status
        _statusSummary[impl.status] = (_statusSummary[impl.status] ?? 0) + 1;
      }

      // Summarize selected enhancements for this control
      for (var enhancement in control.enhancements) {
        // Apply normalization for matching
        final normalizedEnhId = _normalizeEnhancementId(enhancement.id);
        if (selectedProfile.selectedControlIds.contains(normalizedEnhId)) {
          final enhImpl =
              _system!.controlImplementations[enhancement
                  .id] ?? // Use original enhancement.id for map lookup
              ControlImplementation(
                status: 'Not Implemented',
              ); // Default status
          _statusSummary[enhImpl.status] =
              (_statusSummary[enhImpl.status] ?? 0) + 1;
        }
      }
    }
    if (mounted) {
      setState(() {}); // Update the UI with the new summary
    }
  }

  void _onImplementationChanged() {
    // This callback is triggered by ControlImplementationTile when a save occurs
    // It's important to reload system data if ProjectDataManager was updated by the tile,
    // or ensure _updateStatusSummary can work with potentially stale _system data
    // if only ControlImplementation within _system.controlImplementations map was changed.
    // For simplicity, a full _updateStatusSummary() is called.
    // If _system object instance itself changes in ProjectDataManager, Provider.of in build() will get it.
    _updateStatusSummary();
  }

  List<Control> get _filteredDisplayControls {
    if (_searchQuery.isEmpty) {
      return _baselineControlsAndSelectedEnhancements;
    }
    return _baselineControlsAndSelectedEnhancements.where((control) {
      final controlIdLower = control.id.toLowerCase();
      final controlTitleLower = control.title.toLowerCase();

      if (controlIdLower.contains(_searchQuery) ||
          controlTitleLower.contains(_searchQuery)) {
        return true;
      }

      // Also search within selected enhancements' titles for this control
      if (_system?.selectedBaselineId != null) {
        final appDataManager = AppDataManager.instance;
        BaselineProfile? selectedProfile = _getSelectedProfile(
          appDataManager,
          _system!.selectedBaselineId!,
        );
        if (selectedProfile != null) {
          for (var enh in control.enhancements) {
            // Apply normalization for matching against selectedControlIds
            final normalizedEnhId = _normalizeEnhancementId(enh.id);
            if (selectedProfile.selectedControlIds.contains(normalizedEnhId)) {
              final enhIdLower =
                  enh.id.toLowerCase(); // Search uses original ID format
              final enhTitleLower = enh.title.toLowerCase();
              if (enhIdLower.contains(_searchQuery) ||
                  enhTitleLower.contains(_searchQuery)) {
                return true;
              }
            }
          }
        }
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Re-fetch system from Provider to ensure it's the latest version,
    // especially if other screens (like ProjectFormScreen) could have modified it.

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(_system?.name ?? 'System Controls')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_system == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(
          child: Text('System not found or has been deleted.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _system!.name.isNotEmpty ? _system!.name : "Unnamed System",
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.summarize_outlined),
            tooltip: 'Export OSCAL SSP Component for this System',
            onPressed:
                _baselineControlsAndSelectedEnhancements.isEmpty ||
                        _system?.selectedBaselineId == null
                    ? null // Disable if no controls or baseline
                    : () {
                      final appDataManager = AppDataManager.instance;
                      List<Control> allRelevantControlsForOscal = [];
                      BaselineProfile? selectedProfile = _getSelectedProfile(
                        appDataManager,
                        _system!.selectedBaselineId!,
                      );

                      if (selectedProfile != null) {
                        // Get all controls (parents and standalone enhancements) that are in the baseline
                        allRelevantControlsForOscal =
                            appDataManager.catalog.controls.where((control) {
                              if (selectedProfile.selectedControlIds.contains(
                                control.id.toLowerCase(),
                              )) {
                                return true;
                              }
                              // Also include parent controls if any of their enhancements are selected.
                              // The OscalService.generateOscalJson will then correctly include
                              // only the selected enhancements for that parent.
                              for (var enh in control.enhancements) {
                                // Apply normalization for matching
                                final normalizedEnhId = _normalizeEnhancementId(
                                  enh.id,
                                );
                                if (selectedProfile.selectedControlIds.contains(
                                  normalizedEnhId,
                                )) {
                                  return true; // Include the parent control
                                }
                              }
                              return false;
                            }).toList();
                      }

                      if (allRelevantControlsForOscal.isNotEmpty) {
                        try {
                          // ...existing code...
                        } catch (e) {
                          // ...existing code...
                        }
                      }
                    },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search Controls & Enhancements',
                  hintText: 'Enter ID or title keyword...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  filled: true,
                  // fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                ),
              ),
            ),
            if (_system!.selectedBaselineId != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
                child: Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Implementation Status Summary',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (_statusSummary.isEmpty &&
                            _baselineControlsAndSelectedEnhancements.isNotEmpty)
                          const Text(
                            'No statuses recorded yet for baseline controls.',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        if (_statusSummary.isEmpty &&
                            _baselineControlsAndSelectedEnhancements.isEmpty &&
                            _system!.selectedBaselineId != null)
                          const Text(
                            'No controls in the selected baseline to summarize.',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        if (_statusSummary.isNotEmpty)
                          Wrap(
                            spacing: 8.0, // Horizontal space between chips
                            runSpacing:
                                4.0, // Vertical space between lines of chips
                            children:
                                _statusSummary.entries.map((entry) {
                                  return Chip(
                                    label: Text('${entry.key}: ${entry.value}'),
                                    backgroundColor: getStatusColor(
                                      entry.key,
                                      context,
                                    ).withAlpha((0.15 * 255).round()),
                                    labelStyle: TextStyle(
                                      color: getStatusColor(entry.key, context),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  );
                                }).toList(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_system!.selectedBaselineId == null)
              const Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No baseline selected for this system. Please go to "Project/System Management", edit this system, and select a baseline to view and implement controls.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            if (_baselineControlsAndSelectedEnhancements.isEmpty &&
                _system!.selectedBaselineId != null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No controls found for the selected baseline: "${_system!.selectedBaselineId}". Ensure the baseline profile exists and has controls selected, or check catalog data.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            if (_filteredDisplayControls.isEmpty &&
                _searchQuery.isNotEmpty &&
                _baselineControlsAndSelectedEnhancements.isNotEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'No controls or enhancements match the search query.',
                  ),
                ),
              ),
            if (_system!.selectedBaselineId != null &&
                _baselineControlsAndSelectedEnhancements.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredDisplayControls.length,
                  itemBuilder: (context, index) {
                    final control = _filteredDisplayControls[index];
                    return ControlImplementationTile(
                      key: ValueKey(control.id + widget.systemId), // Unique key
                      systemId: widget.systemId,
                      control: control,
                      selectedBaselineId:
                          _system!
                              .selectedBaselineId, // Pass this for the tile to know context
                      onChanged: _onImplementationChanged,
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
