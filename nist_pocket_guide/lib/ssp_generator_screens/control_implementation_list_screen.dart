// lib/screens/ssp_generator_control_list_screen.dart
import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/app_data_manager.dart';
import 'package:nist_pocket_guide/models/information_system.dart';
import 'package:nist_pocket_guide/models/oscal_models.dart';
import 'package:nist_pocket_guide/models/baseline_profile.dart'; // For BaselineProfile
import 'package:nist_pocket_guide/ssp_generator_screens/ssp_statement_view_screen.dart';
// Next screen

class SspViewControlListScreen extends StatefulWidget {
  final InformationSystem system;

  const SspViewControlListScreen({super.key, required this.system});

  @override
  State<SspViewControlListScreen> createState() =>
      _SspViewControlListScreenState();
}

class _SspViewControlListScreenState extends State<SspViewControlListScreen> {
  List<Control> _baselineControls = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBaselineControls();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBaselineControls() async {
    setState(() => _isLoading = true);
    final appDataManager = AppDataManager.instance;

    if (widget.system.selectedBaselineId != null &&
        appDataManager.isInitialized) {
      final baselineId = widget.system.selectedBaselineId!;
      BaselineProfile? selectedProfile = _getSelectedProfile(
        appDataManager,
        baselineId,
      );

      if (selectedProfile != null) {
        _baselineControls =
            appDataManager.catalog.controls.where((control) {
              if (selectedProfile.selectedControlIds.contains(
                control.id.toLowerCase(),
              )) {
                return true;
              }
              // Include parent control if any of its enhancements are in the baseline
              for (var enhancement in control.enhancements) {
                if (selectedProfile.selectedControlIds.contains(
                  enhancement.id
                      .toLowerCase()
                      .replaceAll('(', '.')
                      .replaceAll(')', ''),
                )) {
                  return true;
                }
              }
              return false;
            }).toList();
        _baselineControls.sort((a, b) => _sortControls(a.id, b.id));
      }
    }
    setState(() => _isLoading = false);
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
            const Text('SSP Generator - Select Control'),
            Text(
              widget.system.name,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child:
            _isLoading
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
                          // fillColor: Theme.of(context).canvasColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child:
                          _baselineControls.isEmpty
                              ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    'No controls found for baseline "${widget.system.selectedBaselineId}" or baseline not set for system "${widget.system.name}".',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                              : _filteredControls.isEmpty
                              ? Center(
                                child: Text(
                                  'No controls match "$_searchQuery"',
                                ),
                              )
                              : ListView.builder(
                                itemCount: _filteredControls.length,
                                itemBuilder: (context, index) {
                                  final control = _filteredControls[index];
                                  final hasObjectives =
                                      control.assessmentObjectives.isNotEmpty;
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.gpp_good_outlined,
                                        color:
                                            hasObjectives
                                                ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                                : Colors.grey,
                                      ),
                                      title: Text(
                                        '${control.id}: ${control.title}',
                                      ),
                                      subtitle:
                                          hasObjectives
                                              ? Text(
                                                '${control.assessmentObjectives.length} assessment objectives',
                                              )
                                              : const Text(
                                                'No assessment objectives defined in OSCAL',
                                                style: TextStyle(
                                                  color: Colors.orange,
                                                ),
                                              ),
                                      trailing:
                                          hasObjectives
                                              ? const Icon(Icons.chevron_right)
                                              : null,
                                      onTap:
                                          hasObjectives
                                              ? () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) =>
                                                            SspStatementDisplayScreen(
                                                              systemId:
                                                                  widget
                                                                      .system
                                                                      .id,
                                                              controlId:
                                                                  control.id,
                                                            ),
                                                  ),
                                                );
                                              }
                                              : null, // Disable tap if no objectives
                                    ),
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
