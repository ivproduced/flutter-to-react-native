// lib/app_data_manager.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
// 📌 Ensure this path correctly locates your llm_objective_data.dart file.
// If it's in lib/models/, the path should be '../models/llm_objective_data.dart' (if app_data_manager.dart is in lib/)
// or a direct package import if lib is not the direct parent.
// Assuming AppDataManager is in lib/ and llm_objective_data.dart is in lib/ssp_generator_screens/
import 'package:nist_pocket_guide/models/llm_objective_data.dart';
import 'package:nist_pocket_guide/models/oscal_models.dart';
import 'package:nist_pocket_guide/models/reusable_placeholder_model.dart';
import 'package:nist_pocket_guide/services/baseline_loader.dart';
import 'package:nist_pocket_guide/models/baseline_profile.dart';
import 'package:nist_pocket_guide/services/oscal_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/ai_rmf_playbook_entry.dart';
import '../services/ai_rmf_playbook_loader.dart';
import '../models/system_parameter_block.dart';
import '../models/csf_models.dart';
import '../models/sp800_171_models.dart';
import '../models/ssdf_models.dart';


class AppDataManager with ChangeNotifier {
  static final AppDataManager _instance = AppDataManager._internal();


  AppDataManager._internal();

  factory AppDataManager() => _instance;

  static AppDataManager get instance => _instance;

  late Catalog catalog;
  late BaselineProfile lowBaseline;
  late BaselineProfile moderateBaseline;
  late BaselineProfile highBaseline;
  late BaselineProfile privacyBaseline;

  bool isInitialized = false;

  // Property for LLM data (already in your code)
  Map<String, LlmControlObjectiveData> llmControlData = {};

  late List<Control> _allControls;
  List<Control> get allControls => _allControls;
  
  List<SystemParameterBlock> systemParameterBlocks = [];
  Set<String> favorites = {};
  Map<String, String> notesPerControl = {};
  List<String> recentControlIds = [];
  Map<String, dynamic> userSettings = {};
  Map<String, List<String>> customBaselines = {};
  final List<BaselineProfile> _userBaselines = [];
  List<BaselineProfile> get userBaselines => _userBaselines;
  late List<AiRmfPlaybookEntry> aiRmfPlaybookEntries;

  // CSF 2.0 Catalog
  CsfCatalog? _csfCatalog;
  CsfCatalog? get csfCatalog => _csfCatalog;

  // SP 800-171 Rev 3 Catalog
  Sp800171Catalog? _sp800171Catalog;
  Sp800171Catalog? get sp800171Catalog => _sp800171Catalog;

  // SSDF SP 800-218 Catalog
  SsdfCatalog? _ssdfCatalog;
  SsdfCatalog? get ssdfCatalog => _ssdfCatalog;

  static const String _userSavedPlaceholderValuesKey = 'userSavedPlaceholderValues';
  List<ReusablePlaceholderValue> _userSavedPlaceholderValues = [];

 // Getter for the UI
  List<ReusablePlaceholderValue> get userSavedPlaceholderValues => List.unmodifiable(_userSavedPlaceholderValues);

  ThemeMode _themeMode = ThemeMode.system; // Default theme setting

  // This is the public getter your main.dart will use
  ThemeMode get currentThemeMode => _themeMode;

  // Method to load the saved theme preference
  Future<void> _loadThemeModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString('themeMode'); // Key used for saving
    if (themeModeString != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.toString() == themeModeString,
        orElse: () => ThemeMode.system, // Fallback if the saved string is invalid
      );
    }
    // No notifyListeners() needed here if called only during app initialization
    // before the UI that depends on it is built.
  }

  // Method to change the current theme and save the preference
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return; // No change, no need to save or notify

    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.toString()); // Save with the same key
    notifyListeners(); // Notify listeners (like MyApp in main.dart) to rebuild
  }


  Control? getControlById(String id) {
    if (!isInitialized) {
      return null;
    }
    final normalizedId = id.toLowerCase();
    try {
      return catalog.controls.firstWhere(
        (control) => control.id == normalizedId,
      );
    } catch (e) {
      return null; 
    }
  }

  LlmControlObjectiveData? getLlmObjectiveDataForControl(String controlId) {
    final normalizedKey = controlId.toUpperCase();
    return llmControlData[normalizedKey];
  }



  Future<void> _loadLlmDataInternal() async {
    try {
      final jsonString = await rootBundle.loadString('assets/llm_enhanced_assessment_objectives.json');

      final List<dynamic> jsonData = json.decode(jsonString);

      Map<String, LlmControlObjectiveData> tempMap = {};

      for (var item in jsonData) {
        if (item is Map<String, dynamic> && item.containsKey('control_id')) {
          String controlIdFromJson = item['control_id'] as String;
          String mapKey = controlIdFromJson.toUpperCase();

          try {
            final llmDataForItem = LlmControlObjectiveData.fromJson(item);
            tempMap[mapKey] = llmDataForItem;
          } catch (e) {
            // Ignore malformed or invalid LLM data entries
          }
        } 
      }
      llmControlData = tempMap;
    } catch (e) {
      llmControlData = {};
    }
  }


Future<void> initialize() async {
    if (isInitialized && llmControlData.isNotEmpty) {
        return;
    }

    // Load System Parameter Blocks
    try {
      final String blocksJsonString = await rootBundle.loadString('assets/system_parameter_blocks.json');
      final List<dynamic> blocksJsonList = jsonDecode(blocksJsonString);
      systemParameterBlocks = blocksJsonList.map((json) => SystemParameterBlock.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      systemParameterBlocks = [];
    }

    await _loadLlmDataInternal();
    await _loadThemeModePreference();
    await _loadUserSavedPlaceholderValues();

    // Load baseline profiles (existing logic)
    lowBaseline = await BaselineLoader.loadLowBaseline();
    moderateBaseline = await BaselineLoader.loadModerateBaseline();
    highBaseline = await BaselineLoader.loadHighBaseline();
    privacyBaseline = await BaselineLoader.loadPrivacyBaseline();

    // Load catalog and tag (existing logic)
    catalog = await OSCALLoader.loadCatalogAndTagBaselines(
      lowBaseline: lowBaseline,
      moderateBaseline: moderateBaseline,
      highBaseline: highBaseline,
      privacyBaseline: privacyBaseline,
    );

    // Filter catalog for AC control family when running on web
    if (kIsWeb) {
      catalog = Catalog(
        controls: catalog.controls.where((c) => c.id.toLowerCase().startsWith('ac-')).toList(),
        // Include AC family groups (e.g., 'AC') as well as specific controls
        groups: catalog.groups.where((g) {
          final id = g.id.toLowerCase();
          return id == 'ac' || id.startsWith('ac-') || id.startsWith('ac');
        }).toList(),
      );
    }

    _allControls = catalog.controls
        .expand((c) => [c, ...c.enhancements])
        .toList();

    aiRmfPlaybookEntries = await AiRmfPlaybookLoader.loadPlaybook();

    // Load CSF 2.0 catalog
    await _loadCsfCatalog();

    // Load SP 800-171 Rev 3 catalog
    await _loadSp800171Catalog();

    // Load SSDF SP 800-218 catalog
    await _loadSsdfCatalog();

    // Load user preferences (existing logic)
    final prefs = await SharedPreferences.getInstance();
    // await prefs.reload(); // This might not be strictly necessary unless making external changes
    final keys = prefs.getKeys();
    _userBaselines.clear(); 
    for (final key in keys) {
      if (key.startsWith('custom_baseline_')) {
        // ... (rest of your custom baseline loading logic) ...
         final jsonString = prefs.getString(key);
        if (jsonString != null) {
          try {
            final Map<String, dynamic> map = jsonDecode(jsonString);
            final profile = BaselineProfile.fromJson(map);
            _userBaselines.add(profile);

            final selectedIds = profile.selectedControlIds.map((e) => e.toLowerCase()).toSet();
            for (final control in catalog.controls) {
              final id = control.id.toLowerCase();
              control.baselines[profile.id.toUpperCase()] = selectedIds.contains(id);
              for (final enhancement in control.enhancements) {
                final normId = enhancement.id
                    .toLowerCase()
                    .replaceAll('(', '.')
                    .replaceAll(')', '');
                enhancement.baselines[profile.id.toUpperCase()] =
                    selectedIds.contains(normId);
              }
            }
          } catch (e) {
            // Ignore errors during custom baseline loading
          }
        }
      }
    }
    _userBaselines.sort((a,b) => a.title.compareTo(b.title));


    isInitialized = true;
    notifyListeners();
  }


  // ... (rest of your AppDataManager methods: retagControlsWithUserBaselines, reset, toggleFavorite, etc.) ...
  // (Make sure to include your _saveUserPreferences method or similar persistence logic if you have it)
  Future<void> _saveUserPreferences() async { 
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', favoriteIds.value.toList()); 
    await prefs.setString('notesPerControl', jsonEncode(notesPerControl));
    await prefs.setStringList('recentControlIds', recentControlIds);
  }

  final ValueNotifier<Set<String>> favoriteIds = ValueNotifier(<String>{});

  void toggleFavorite(String controlId) {
    final currentFavorites = Set<String>.from(favoriteIds.value);
    if (currentFavorites.contains(controlId)) {
      currentFavorites.remove(controlId);
    } else {
      currentFavorites.add(controlId);
    }
    favoriteIds.value = currentFavorites;
    _saveUserPreferences();
  }

  bool isFavorite(String controlId) => favoriteIds.value.contains(controlId);

void addOrUpdateNote(String controlId, String note, {bool shouldNotify = true}) { // Added shouldNotify
  // Optional: Only proceed if the note actually changed to avoid unnecessary saves/notifications
  // if (notesPerControl[controlId] == note) return;

  notesPerControl[controlId] = note;
  _saveUserPreferences(); // Assumes _saveUserPreferences saves notesPerControl

  if (shouldNotify) { // Only notify if requested
    notifyListeners();
  }
}

  // Load CSF 2.0 catalog
  // Note: Control mappings are now loaded via const maps in csf_crosswalk_mappings.dart
  // and populated automatically in CsfSubcategory.fromJson()
  Future<void> _loadCsfCatalog() async {
    try {
      final jsonString = await rootBundle.loadString('assets/NIST_CSF_v2.0_catalog.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      _csfCatalog = CsfCatalog.fromJson(jsonData);
      debugPrint('✅ Loaded CSF 2.0 catalog with control mappings');
    } catch (e) {
      debugPrint('❌ Error loading CSF catalog: $e');
      _csfCatalog = null;
    }
  }

  // Get CSF function by ID
  CsfFunction? getCsfFunctionById(String id) {
    if (_csfCatalog == null) return null;
    try {
      return _csfCatalog!.functions.firstWhere((f) => f.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get CSF category by ID
  CsfCategory? getCsfCategoryById(String id) {
    if (_csfCatalog == null) return null;
    for (final function in _csfCatalog!.functions) {
      try {
        return function.categories.firstWhere((c) => c.id == id);
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  // Search CSF subcategories
  List<CsfSubcategory> searchCsfSubcategories(String query) {
    if (_csfCatalog == null || query.trim().isEmpty) return [];
    
    final lowercaseQuery = query.toLowerCase();
    final List<CsfSubcategory> results = [];

    for (final function in _csfCatalog!.functions) {
      for (final category in function.categories) {
        for (final subcategory in category.subcategories) {
          if (subcategory.id.toLowerCase().contains(lowercaseQuery) ||
              subcategory.title.toLowerCase().contains(lowercaseQuery) ||
              subcategory.statement.toLowerCase().contains(lowercaseQuery)) {
            results.add(subcategory);
          }
        }
      }
    }

    return results;
  }

  // Load SP 800-171 Rev 3 catalog
  Future<void> _loadSp800171Catalog() async {
    try {
      final jsonString = await rootBundle.loadString('assets/NIST_SP800-171_rev3_catalog.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      _sp800171Catalog = Sp800171Catalog.fromJson(jsonData);
    } catch (e) {
      debugPrint('❌ Error loading SP 800-171 catalog: $e');
      _sp800171Catalog = null;
    }
  }

  // Get SP 800-171 family by ID
  Sp800171Family? getSp800171FamilyById(String id) {
    if (_sp800171Catalog == null) return null;
    try {
      return _sp800171Catalog!.families.firstWhere((f) => f.id == id || f.familyId == id);
    } catch (e) {
      return null;
    }
  }

  // Get SP 800-171 requirement by ID
  Sp800171Requirement? getSp800171RequirementById(String id) {
    if (_sp800171Catalog == null) return null;
    for (final family in _sp800171Catalog!.families) {
      try {
        return family.requirements.firstWhere((r) => r.id == id || r.requirementId == id);
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  // Search SP 800-171 requirements
  List<Sp800171Requirement> searchSp800171Requirements(String query) {
    if (_sp800171Catalog == null || query.trim().isEmpty) return [];
    
    final lowercaseQuery = query.toLowerCase();
    final List<Sp800171Requirement> results = [];

    for (final family in _sp800171Catalog!.families) {
      for (final requirement in family.requirements) {
        if (requirement.requirementId.toLowerCase().contains(lowercaseQuery) ||
            requirement.title.toLowerCase().contains(lowercaseQuery) ||
            requirement.fullStatement.toLowerCase().contains(lowercaseQuery) ||
            requirement.guidance.toLowerCase().contains(lowercaseQuery)) {
          results.add(requirement);
        }
      }
    }

    return results;
  }

  // Load SSDF SP 800-218 catalog
  Future<void> _loadSsdfCatalog() async {
    try {
      final jsonString = await rootBundle.loadString('assets/NIST_SP800-218_ver1_catalog.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      _ssdfCatalog = SsdfCatalog.fromJson(jsonData);
    } catch (e) {
      debugPrint('❌ Error loading SSDF catalog: $e');
      _ssdfCatalog = null;
    }
  }

  // Get SSDF practice group by ID
  SsdfPracticeGroup? getSsdfPracticeGroupById(String id) {
    if (_ssdfCatalog == null) return null;
    try {
      return _ssdfCatalog!.practiceGroups.firstWhere((g) => g.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get SSDF practice by ID
  SsdfPractice? getSsdfPracticeById(String id) {
    if (_ssdfCatalog == null) return null;
    for (final group in _ssdfCatalog!.practiceGroups) {
      try {
        return group.practices.firstWhere((p) => p.id == id);
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  // Get SSDF task by ID
  SsdfTask? getSsdfTaskById(String id) {
    if (_ssdfCatalog == null) return null;
    for (final group in _ssdfCatalog!.practiceGroups) {
      for (final practice in group.practices) {
        try {
          return practice.tasks.firstWhere((t) => t.id == id);
        } catch (e) {
          continue;
        }
      }
    }
    return null;
  }

  // Search SSDF tasks
  List<SsdfTask> searchSsdfTasks(String query) {
    if (_ssdfCatalog == null || query.trim().isEmpty) return [];
    
    final lowercaseQuery = query.toLowerCase();
    final List<SsdfTask> results = [];

    for (final group in _ssdfCatalog!.practiceGroups) {
      for (final practice in group.practices) {
        for (final task in practice.tasks) {
          if (task.id.toLowerCase().contains(lowercaseQuery) ||
              task.statement.toLowerCase().contains(lowercaseQuery) ||
              task.examples.any((e) => e.toLowerCase().contains(lowercaseQuery))) {
            results.add(task);
          }
        }
      }
    }

    return results;
  }

  String? getNoteForControl(String controlId) {
    return notesPerControl[controlId];
  }

  void addRecentControl(String controlId) {
    recentControlIds.remove(controlId); 
    recentControlIds.insert(0, controlId);
    if (recentControlIds.length > 50) {
      recentControlIds = recentControlIds.sublist(0, 50); 
    }
    _saveUserPreferences(); 
    notifyListeners();
  }

  List<String> getRecentControls() {
    return List.unmodifiable(recentControlIds);
  }
  
  Future<void> retagControlsWithUserBaselines() async {
    if (!isInitialized) await initialize(); 

    for (final control in catalog.controls) {
      for (final profile in _userBaselines) {
        final id = control.id.toLowerCase();
        control.baselines[profile.id.toUpperCase()] =
            profile.selectedControlIds.map((e) => e.toLowerCase()).contains(id);

        for (final enhancement in control.enhancements) {
          final normId = enhancement.id.toLowerCase().replaceAll('(', '.').replaceAll(')', ''); 
          enhancement.baselines[profile.id.toUpperCase()] =
              profile.selectedControlIds.map((e) => e.toLowerCase()).contains(normId);
        }
      }
    }
    notifyListeners();
  }
 // Make sure to call this during your AppDataManager.initialize() or a similar setup method
  Future<void> _loadUserSavedPlaceholderValues() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_userSavedPlaceholderValuesKey);
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString) as List;
        _userSavedPlaceholderValues = jsonList
            .map((jsonItem) => ReusablePlaceholderValue.fromJson(jsonItem as Map<String, dynamic>))
            .toList();
        // Optional: Sort them, e.g., by creation date or alphabetically
        _userSavedPlaceholderValues.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first
      } catch (e) {
        _userSavedPlaceholderValues = []; // Reset if decoding fails
      }
    } else {
      _userSavedPlaceholderValues = [];
    }
    // No need to notifyListeners here if this is part of initial load,
    // but if called separately later, you might want to.
  }
  Future<void> _saveUserSavedPlaceholderValuesToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(_userSavedPlaceholderValues.map((item) => item.toJson()).toList());
    await prefs.setString(_userSavedPlaceholderValuesKey, jsonString);
  }

  Future<void> addUserSavedPlaceholderValue(String value, {String? associatedPlaceholderLabel}) async {
    if (value.trim().isEmpty) return;

    if (_userSavedPlaceholderValues.any((rpv) => rpv.value == value && rpv.associatedPlaceholderLabel == associatedPlaceholderLabel)) {
        final existing = _userSavedPlaceholderValues.firstWhere((rpv) => rpv.value == value && rpv.associatedPlaceholderLabel == associatedPlaceholderLabel);
        _userSavedPlaceholderValues.remove(existing);
        _userSavedPlaceholderValues.insert(0, existing);
        await _saveUserSavedPlaceholderValuesToPrefs();
        notifyListeners();
        return;
    }

    final newValue = ReusablePlaceholderValue(
      value: value.trim(),
      associatedPlaceholderLabel: associatedPlaceholderLabel,
    );
    _userSavedPlaceholderValues.insert(0, newValue);
    await _saveUserSavedPlaceholderValuesToPrefs();
    notifyListeners();
  }

  Future<void> removeUserSavedPlaceholderValue(String id) async {
    _userSavedPlaceholderValues.removeWhere((item) => item.id == id);
    await _saveUserSavedPlaceholderValuesToPrefs();
    notifyListeners();
  }
  void reset() {
    isInitialized = false;
    _allControls = [];
    favorites.clear();
    favoriteIds.value = {};
    notesPerControl.clear();
    recentControlIds.clear();
    userSettings.clear();
    customBaselines.clear();
    aiRmfPlaybookEntries = [];
    _userBaselines.clear();
    llmControlData.clear();
    systemParameterBlocks.clear();
    _csfCatalog = null;
    _sp800171Catalog = null;

    _saveUserPreferences();

    _themeMode = ThemeMode.system;
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('themeMode');
    });

    notifyListeners();
  }
}