// lib/provider/project_data_manager.dart

import 'package:flutter/foundation.dart';
import 'package:nist_pocket_guide/models/user_input_model.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // Not used if DatabaseService handles persistence
import '../models/information_system.dart'; // 📌 Assumes this file has the updated ControlImplementation
import '../models/assessment_objective_response.dart';
import '../services/database_service.dart'; // Using DatabaseService
 // For generating IDs

class ProjectDataManager with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService.instance;
  List<InformationSystem> _systems = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<InformationSystem> get systems => List.unmodifiable(_systems);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ProjectDataManager() {
    loadSystems();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      // notifyListeners(); // Only notify if UI specifically reacts to error clearing
    }
  }

  // --- System Management (using DatabaseService) ---
  Future<bool> loadSystems() async {
    _isLoading = true;
    _clearError();
    notifyListeners();
    try {
      _systems = await _dbService.getAllInformationSystems();
      _systems.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      _errorMessage = "Failed to load systems.";
      if (kDebugMode) {
        print("ProjectDataManager - Error loading systems: $e");
        debugPrintStack(stackTrace: stackTrace, label: "LoadSystems Error");
      }
      _isLoading = false;
      _systems = [];
      notifyListeners();
      return false;
    }
  }

  Future<bool> addSystem(InformationSystem system) async {
    _isLoading = true;
    _clearError();
    notifyListeners(); 

    try {
      if (system.id.isEmpty) {
        // Ensure system.id is assigned if your DatabaseService doesn't auto-generate it
        // or if InformationSystem constructor doesn't.
        // My previous example for InformationSystem model had `id: map['id'] as String,`
        // implying ID is usually present. If creating a new one, it needs an ID.
        // system.id = const Uuid().v4(); // Example: Assign UUID if empty.
      }
      // Your current code uses _dbService.createInformationSystem(system);
      // My older suggested template used _dbService.insertInformationSystem(system);
      // I will use your current method name.
      await _dbService.createInformationSystem(system); 
      await loadSystems(); 
      return true;
    } catch (e, stackTrace) {
      _errorMessage = "Failed to add system '${system.name}'.";
      if (kDebugMode) {
        print("ProjectDataManager - Error adding system: $e");
        debugPrintStack(stackTrace: stackTrace, label: "AddSystem Error");
      }
      _isLoading = false; 
      notifyListeners(); 
      return false;
    }
  }

  Future<bool> updateSystem(InformationSystem system) async {
    _isLoading = true;
    _clearError();
    notifyListeners();

    try {
      await _dbService.updateInformationSystem(system);
      final index = _systems.indexWhere((s) => s.id == system.id);
      if (index != -1) {
        _systems[index] = system;
        _systems.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      } else {
        // If system not in list, it implies an issue with state or it's a new system.
        // For an update, it should typically be in the list. Reloading might be safer.
        await loadSystems(); // Reload to ensure consistency
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      _errorMessage = "Failed to update system '${system.name}'.";
      if (kDebugMode) {
        print("ProjectDataManager - Error updating system: $e");
        debugPrintStack(stackTrace: stackTrace, label: "UpdateSystem Error");
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSystem(String id) async {
    _isLoading = true;
    _clearError();
    notifyListeners();
    InformationSystem? systemToDelete = getSystemById(id);
    String systemName = systemToDelete?.name ?? "the system";

    try {
      await _dbService.deleteInformationSystem(id);
      _systems.removeWhere((s) => s.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      _errorMessage = "Failed to delete $systemName.";
      if (kDebugMode) {
        print("ProjectDataManager - Error deleting system: $e");
        debugPrintStack(stackTrace: stackTrace, label: "DeleteSystem Error");
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  InformationSystem? getSystemById(String id) {
    try {
      return _systems.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  // --- Control Implementation Management ---
  ControlImplementation? getControlImplementation({
    required String systemId,
    required String controlId,
  }) {
    final system = getSystemById(systemId);
    // The '?? ControlImplementation(status: 'Not Implemented')' might be risky here
    // if the caller expects null when it doesn't exist.
    // It's better to return null if controlImpl doesn't exist for the controlId.
    return system?.controlImplementations[controlId];
  }
  
  // This method seems more aligned with how you'd save the entire ControlImplementation object.
  // Your current file has 'updateControlImplementation'. I'll keep that name.
  Future<bool> updateControlImplementation({
    required String systemId,
    required String controlId,
    required ControlImplementation implementation,
  }) async {
    _clearError();
    final system = getSystemById(systemId);
    if (system != null) {
      system.controlImplementations[controlId] = implementation;
      return await updateSystem(system);
    }
    _errorMessage = "System not found for updating control implementation.";
    notifyListeners();
    return false;
  }

  // ✨ --- NEW: LLM OBJECTIVE PLACEHOLDER VALUES MANAGEMENT --- ✨
  Map<String, String> getLlmObjectivePlaceholderValues({
    required String systemId,
    required String controlId,
    required String objectiveId,
  }) {
    final controlImpl = getControlImplementation(systemId: systemId, controlId: controlId);
    // 📌 Assumes ControlImplementation has 'llmObjectivePlaceholderValues'
    //    which is Map<String, Map<String, String>>
    // This returns the inner map (placeholder_label -> value) for a specific objective.
    return Map<String, String>.from(controlImpl?.llmObjectivePlaceholderValues[objectiveId] ?? {});
  }

  Future<bool> saveLlmObjectivePlaceholderValues({
    required String systemId,
    required String controlId,
    required String objectiveId,
    required Map<String, String> placeholderValues, // These are {placeholder_label: value}
  }) async {
    _clearError();
    final system = getSystemById(systemId);
    if (system != null) {
      // Ensure ControlImplementation object exists for this controlId
      system.controlImplementations[controlId] ??= ControlImplementation(
        status: controlStatusOptions.first, // Or your default status
        // Ensure llmObjectivePlaceholderValues is initialized if ControlImplementation is new
        llmObjectivePlaceholderValues: {}, 
      );
      
      // Ensure the llmObjectivePlaceholderValues map itself (the outer map) exists
      // The constructor of ControlImplementation should initialize llmObjectivePlaceholderValues to {}
      // So, system.controlImplementations[controlId]!.llmObjectivePlaceholderValues should not be null.

      // Update the specific objective's placeholder values (the inner map)
      system.controlImplementations[controlId]!
          .llmObjectivePlaceholderValues[objectiveId] = placeholderValues;
      
      final success = await updateSystem(system); // Persists the entire InformationSystem
      if (success) {
        notifyListeners(); 
      }
      return success;
    }
    _errorMessage = "System not found for saving LLM objective placeholder values.";
    notifyListeners();
    return false;
  }
  // ✨ --- END OF LLM MANAGEMENT --- ✨


  // --- User Parameter Value Management ---
  // (Your existing methods seem fine, assuming ControlImplementation has userParameterValues list)
  Future<bool> saveUserParameterValue(String systemId, UserParameterValue paramValue) async {
    _clearError();
    final system = getSystemById(systemId);
    if (system == null) {
      _errorMessage = "System not found: $systemId";
      if (kDebugMode) print(_errorMessage);
      notifyListeners();
      return false;
    }

    ControlImplementation controlImpl = system.controlImplementations[paramValue.controlId] ??
        ControlImplementation(status: controlStatusOptions.first);

    List<UserParameterValue> mutableParamValues = List.from(controlImpl.userParameterValues);
    final index = mutableParamValues.indexWhere((pv) =>
        pv.paramId == paramValue.paramId &&
        pv.statementPartId == paramValue.statementPartId);

    if (index != -1) {
      mutableParamValues[index] = paramValue;
    } else {
      mutableParamValues.add(paramValue);
    }
    controlImpl.userParameterValues = mutableParamValues;
    system.controlImplementations[paramValue.controlId] = controlImpl;

    return await updateSystem(system);
  }

  List<UserParameterValue> getControlParameterValues(String systemId, String controlId) {
    final controlImpl = getControlImplementation(systemId: systemId, controlId: controlId);
    return List.unmodifiable(controlImpl?.userParameterValues ?? []);
  }

  // --- User Implementation Narrative Management ---
  Future<bool> saveUserImplementationNarrative(String systemId, UserImplementationNarrative narrative) async {
    _clearError();
    final system = getSystemById(systemId);
    if (system == null) {
      _errorMessage = "System not found: $systemId";
      if (kDebugMode) print(_errorMessage);
      notifyListeners();
      return false;
    }

    ControlImplementation controlImpl = system.controlImplementations[narrative.controlId] ??
        ControlImplementation(status: controlStatusOptions.first);
    
    List<UserImplementationNarrative> mutableNarratives = List.from(controlImpl.userStatementPartNarratives);
    final index = mutableNarratives.indexWhere((n) => n.statementPartId == narrative.statementPartId);

    if (index != -1) {
      mutableNarratives[index] = narrative;
    } else {
      mutableNarratives.add(narrative);
    }
    controlImpl.userStatementPartNarratives = mutableNarratives;
    system.controlImplementations[narrative.controlId] = controlImpl;

    return await updateSystem(system);
  }

  List<UserImplementationNarrative> getControlNarratives(String systemId, String controlId) {
    final controlImpl = getControlImplementation(systemId: systemId, controlId: controlId);
    return List.unmodifiable(controlImpl?.userStatementPartNarratives ?? []);
  }

  // --- Assessment Objective Response Management ---
  Future<bool> saveAssessmentObjectiveResponses({
    required String systemId,
    required String controlId,
    required List<AssessmentObjectiveResponse> responses,
  }) async {
    _clearError();
    final system = getSystemById(systemId);
    if (system != null) {
      system.assessmentObjectiveResponses[controlId] = responses;
      final success = await updateSystem(system);
       if (success) { // Added from your suggested code
        notifyListeners();
      }
      return success;
    }
    _errorMessage = "System not found for saving assessment responses.";
    notifyListeners();
    return false;
  }

  List<AssessmentObjectiveResponse> getAssessmentObjectiveResponses({
    required String systemId,
    required String controlId,
  }) {
    final system = getSystemById(systemId);
    return List<AssessmentObjectiveResponse>.from(
        system?.assessmentObjectiveResponses[controlId] ?? []);
  }
  
  // --- System Parameter Block Values Management ---
  // (This was in your suggested code, adding it here if it's part of your scope)
  Map<String, String> getSystemParameterBlockValues({required String systemId}) {
    final system = getSystemById(systemId);
    // Assumes InformationSystem has 'systemParameterBlockValues'
    return Map<String, String>.from(system?.systemParameterBlockValues ?? {});
  }

  Future<bool> saveSystemParameterBlockValues({
    required String systemId,
    required Map<String, String> values,
  }) async {
    _clearError();
    final system = getSystemById(systemId);
    if (system != null) {
      // Assumes InformationSystem has 'systemParameterBlockValues'
      system.systemParameterBlockValues = values;
      final success = await updateSystem(system);
      if (success) {
        notifyListeners();
      }
      return success;
    }
    _errorMessage = "System not found for saving system parameter block values.";
    notifyListeners();
    return false;
  }


  Future<void> refreshData() async {
    await loadSystems();
  }
}