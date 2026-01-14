import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/app_data_manager.dart';
import 'package:nist_pocket_guide/models/llm_objective_data.dart';
import 'package:nist_pocket_guide/models/reusable_placeholder_model.dart';

class ParameterManagementScreen extends StatefulWidget {
  const ParameterManagementScreen({super.key});

  @override
  State<ParameterManagementScreen> createState() =>
      _ParameterManagementScreenState();
}

class _ParameterManagementScreenState extends State<ParameterManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late Map<String, List<LlmPlaceholderDefinition>> _semanticGroups;
  late Map<String, List<String>> _llmExamplesByGroup;
  late Map<String, List<ReusablePlaceholderValue>> _userValuesByGroup;
  bool _isLoading = true;

  // --- Caching for performance ---
  Map<String, Map<String, Map<String, List<LlmPlaceholderDefinition>>>>?
  _cachedFamilyControlGroupMap;
  String? _lastSearchQuery;
  List<String>? _cachedFilteredFamilies;

  @override
  void initState() {
    super.initState();
    // Ensure AppDataManager is initialized before building groups
    Future(() async {
      if (!AppDataManager.instance.isInitialized) {
        await AppDataManager.instance.initialize();
      }
      _buildSemanticGroups();
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _buildSemanticGroups() {
    setState(() {
      _isLoading = true;
    });
    final llmData = AppDataManager.instance.llmControlData;
    final userValues = AppDataManager.instance.userSavedPlaceholderValues;
    _semanticGroups = {};
    _llmExamplesByGroup = {};
    _userValuesByGroup = {};
    for (final control in llmData.values) {
      for (final placeholder in control.placeholders) {
        final group = placeholder.semanticGroupKey;
        if (group.isEmpty) continue;
        _semanticGroups.putIfAbsent(group, () => []).add(placeholder);
        _llmExamplesByGroup
            .putIfAbsent(group, () => [])
            .addAll(placeholder.examples);
      }
    }
    for (final userVal in userValues) {
      final group = userVal.associatedPlaceholderLabel ?? '';
      if (group.isEmpty) continue;
      _userValuesByGroup.putIfAbsent(group, () => []).add(userVal);
    }
    _llmExamplesByGroup.updateAll((k, v) => v.toSet().toList());
    setState(() {
      _isLoading = false;
    });
  }

  void _cacheFamilyControlGroupMap() {
    final llmData = AppDataManager.instance.llmControlData;
    final Map<String, Map<String, Map<String, List<LlmPlaceholderDefinition>>>>
    result = {};
    for (final control in llmData.values) {
      final family = control.controlId.split('-').first;
      final controlId = control.controlId;
      for (final placeholder in control.placeholders) {
        final group = placeholder.semanticGroupKey;
        if (group.isEmpty) continue;
        result.putIfAbsent(family, () => {});
        result[family]!.putIfAbsent(controlId, () => {});
        result[family]![controlId]!.putIfAbsent(group, () => []);
        result[family]![controlId]![group]!.add(placeholder);
      }
    }
    _cachedFamilyControlGroupMap = result;
    _lastSearchQuery = null;
    _cachedFilteredFamilies = null;
  }

  List<String> _getFilteredFamilies(String searchQuery) {
    if (_cachedFamilyControlGroupMap == null) _cacheFamilyControlGroupMap();
    if (_lastSearchQuery == searchQuery && _cachedFilteredFamilies != null) {
      return _cachedFilteredFamilies!;
    }
    final families =
        _cachedFamilyControlGroupMap!.keys
            .where(
              (fam) => fam.toLowerCase().contains(searchQuery.toLowerCase()),
            )
            .toList();
    _lastSearchQuery = searchQuery;
    _cachedFilteredFamilies = families;
    return families;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit System Parameter Definitions')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_cachedFamilyControlGroupMap == null) _cacheFamilyControlGroupMap();
    final familyControlGroupMap = _cachedFamilyControlGroupMap!;
    final filteredFamilies = _getFilteredFamilies(_searchQuery);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit System Parameter Definitions')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search by family, control, or group',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filteredFamilies.length,
                itemBuilder: (context, famIdx) {
                  final family = filteredFamilies[famIdx];
                  final controls = familyControlGroupMap[family]!;
                  final filteredControls =
                      controls.keys
                          .where(
                            (ctrl) =>
                                ctrl.toLowerCase().contains(
                                  _searchQuery.toLowerCase(),
                                ) ||
                                family.toLowerCase().contains(
                                  _searchQuery.toLowerCase(),
                                ),
                          )
                          .toList();
                  return ExpansionTile(
                    title: Text(
                      'Family: $family',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    children:
                        filteredControls.map((controlId) {
                          final groupMap = controls[controlId]!;
                          final filteredGroups =
                              groupMap.keys
                                  .where(
                                    (g) =>
                                        g.toLowerCase().contains(
                                          _searchQuery.toLowerCase(),
                                        ) ||
                                        controlId.toLowerCase().contains(
                                          _searchQuery.toLowerCase(),
                                        ) ||
                                        family.toLowerCase().contains(
                                          _searchQuery.toLowerCase(),
                                        ),
                                  )
                                  .toList();
                          return ExpansionTile(
                            title: Text(
                              'Control: $controlId',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            children:
                                filteredGroups.map((group) {
                                  final placeholders = groupMap[group]!;
                                  final llmExamples =
                                      _llmExamplesByGroup[group] ?? [];
                                  final userValues =
                                      _userValuesByGroup[group] ?? [];
                                  final allValues =
                                      <dynamic>{
                                        ...llmExamples,
                                        ...userValues.map((e) => e.value),
                                      }.toList();
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    child: ExpansionTile(
                                      title: Text(group),
                                      subtitle: Text(
                                        'Placeholders: ${placeholders.map((p) => p.label).join(", ")}',
                                      ),
                                      children: [
                                        Wrap(
                                          spacing: 8,
                                          children:
                                              allValues
                                                  .map(
                                                    (val) => Chip(
                                                      label: Text(val),
                                                      onDeleted:
                                                          userValues.any(
                                                                (u) =>
                                                                    u.value ==
                                                                    val,
                                                              )
                                                              ? () async {
                                                                final toRemove =
                                                                    userValues.firstWhere(
                                                                      (u) =>
                                                                          u.value ==
                                                                          val,
                                                                    );
                                                                await AppDataManager
                                                                    .instance
                                                                    .removeUserSavedPlaceholderValue(
                                                                      toRemove
                                                                          .id,
                                                                    );
                                                                _buildSemanticGroups();
                                                              }
                                                              : null,
                                                    ),
                                                  )
                                                  .toList(),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: TextField(
                                                  decoration:
                                                      const InputDecoration(
                                                        hintText:
                                                            'Add new value',
                                                      ),
                                                  onSubmitted: (val) async {
                                                    if (val.trim().isEmpty) {
                                                      return;
                                                    }
                                                    await AppDataManager
                                                        .instance
                                                        .addUserSavedPlaceholderValue(
                                                          val.trim(),
                                                          associatedPlaceholderLabel:
                                                              group,
                                                        );
                                                    _buildSemanticGroups();
                                                  },
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.add),
                                                onPressed: () async {
                                                  final val =
                                                      _searchController.text
                                                          .trim();
                                                  if (val.isEmpty) return;
                                                  await AppDataManager.instance
                                                      .addUserSavedPlaceholderValue(
                                                        val,
                                                        associatedPlaceholderLabel:
                                                            group,
                                                      );
                                                  _buildSemanticGroups();
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                          );
                        }).toList(),
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

extension _LlmPlaceholderDefSemanticGroup on LlmPlaceholderDefinition {
  String get semanticGroupKey {
    try {
      final dynamic self = this;
      if (self.semantic_group != null &&
          (self.semantic_group as String).isNotEmpty) {
        return self.semantic_group as String;
      }
    } catch (_) {}
    return label;
  }
}
