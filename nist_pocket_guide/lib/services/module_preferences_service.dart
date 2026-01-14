// lib/services/module_preferences_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nist_pocket_guide/models/app_module.dart';

class ModulePreferencesService extends ChangeNotifier {
  static const String _nist80053ModuleKey = 'show_nist_800_53_module';
  static const String _aiRmfModuleKey = 'show_ai_rmf_module';
  static const String _sspGeneratorModuleKey = 'show_ssp_generator_module';
  static const String _nistBotModuleKey = 'show_nist_bot_module';
  static const String _enhancedNistBotModuleKey =
      'show_enhanced_nist_bot_module';
  static const String _csf20ModuleKey = 'show_csf_2_0_module';
  static const String _sp800171ModuleKey = 'show_sp_800_171_module';
  static const String _ssdfModuleKey = 'show_ssdf_module';

  final SharedPreferences _prefs;

  ModulePreferencesService(this._prefs);

  // Getter methods for module visibility
  bool get showNist80053Module => _prefs.getBool(_nist80053ModuleKey) ?? true;
  bool get showAiRmfModule => _prefs.getBool(_aiRmfModuleKey) ?? true;
  bool get showSspGeneratorModule =>
      _prefs.getBool(_sspGeneratorModuleKey) ?? true;
  bool get showNistBotModule => _prefs.getBool(_nistBotModuleKey) ?? false;
  bool get showEnhancedNistBotModule =>
      _prefs.getBool(_enhancedNistBotModuleKey) ?? true;
  bool get showSp800171Module => _prefs.getBool(_sp800171ModuleKey) ?? true;
  bool get showCsf20Module => _prefs.getBool(_csf20ModuleKey) ?? true;
  bool get showSsdfModule => _prefs.getBool(_ssdfModuleKey) ?? true;

  // Dynamic getter for any module by preference key
  bool getModuleVisibility(String preferenceKey) {
    // Find the module to get its default visibility
    final module = AppModules.getModuleByPreferenceKey(preferenceKey);
    final defaultValue = module?.defaultVisible ?? true;
    return _prefs.getBool(preferenceKey) ?? defaultValue;
  }

  // Dynamic setter for any module by preference key
  Future<void> setModuleVisibility(String preferenceKey, bool visible) async {
    await _prefs.setBool(preferenceKey, visible);
    notifyListeners();
  }

  // Setter methods for module visibility (kept for backward compatibility)
  Future<void> setNist80053ModuleVisibility(bool visible) async {
    await setModuleVisibility(_nist80053ModuleKey, visible);
  }

  Future<void> setAiRmfModuleVisibility(bool visible) async {
    await setModuleVisibility(_aiRmfModuleKey, visible);
  }

  Future<void> setSspGeneratorModuleVisibility(bool visible) async {
    await setModuleVisibility(_sspGeneratorModuleKey, visible);
  }

  Future<void> setNistBotModuleVisibility(bool visible) async {
    await setModuleVisibility(_nistBotModuleKey, visible);
  }

  Future<void> setEnhancedNistBotModuleVisibility(bool visible) async {
    await setModuleVisibility(_enhancedNistBotModuleKey, visible);
  }

  // Helper method to reset all available modules to their default values
  Future<void> resetAllModulesToDefaults() async {
    final availableModules = AppModules.getAvailableModules();
    await Future.wait([
      for (final module in availableModules)
        setModuleVisibility(module.preferenceKey, module.defaultVisible),
    ]);
  }

  // Legacy method name for backward compatibility
  @Deprecated('Use resetAllModulesToDefaults() instead')
  Future<void> resetAllModulesToVisible() async {
    await resetAllModulesToDefaults();
  }
}
