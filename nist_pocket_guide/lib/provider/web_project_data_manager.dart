import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/information_system.dart';
import 'project_data_manager.dart'; // Import base class

/// A web-only ProjectDataManager implementation using SharedPreferences.
class WebProjectDataManager extends ProjectDataManager {
  static const _storageKey = 'web_systems';
  List<InformationSystem> _systems = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  List<InformationSystem> get systems => List.unmodifiable(_systems);
  @override
  bool get isLoading => _isLoading;
  @override
  String? get errorMessage => _errorMessage;

  WebProjectDataManager() : super();

  void _clearError() {
    _errorMessage = null;
  }

  @override
  Future<bool> loadSystems() async {
    _isLoading = true;
    _clearError();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_storageKey) ?? [];
      _systems = jsonList.map((e) {
        final map = jsonDecode(e) as Map<String, dynamic>;
        return InformationSystem.fromMap(map);
      }).toList();
      _systems.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to load systems: $e';
      _systems = [];
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  Future<bool> addSystem(InformationSystem system) async {
    _isLoading = true;
    _clearError();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_storageKey) ?? [];
      jsonList.add(jsonEncode(system.toMap()));
      await prefs.setStringList(_storageKey, jsonList);
      await loadSystems();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add system: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  Future<bool> updateSystem(InformationSystem system) async {
    _isLoading = true;
    _clearError();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_storageKey) ?? [];
      final updatedList = jsonList.map((e) {
        final map = jsonDecode(e) as Map<String, dynamic>;
        if (map['id'] == system.id) {
          return jsonEncode(system.toMap());
        }
        return e;
      }).toList();
      await prefs.setStringList(_storageKey, updatedList);
      await loadSystems();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update system: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  Future<bool> deleteSystem(String id) async {
    _isLoading = true;
    _clearError();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_storageKey) ?? [];
      final filtered = jsonList.where((e) {
        final map = jsonDecode(e) as Map<String, dynamic>;
        return map['id'] != id;
      }).toList();
      await prefs.setStringList(_storageKey, filtered);
      await loadSystems();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete system: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  InformationSystem? getSystemById(String id) {
    try {
      return _systems.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }
}
