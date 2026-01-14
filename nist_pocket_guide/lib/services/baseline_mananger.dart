// --- baseline_manager.dart ---
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nist_pocket_guide/models/baseline_profile.dart';
import 'package:nist_pocket_guide/models/oscal_models.dart';
import 'package:nist_pocket_guide/app_data_manager.dart';

class BaselineManager {
  static const String _customBaselinePrefix = 'custom_baseline_';

  static final List<BaselineProfile> _userBaselines = [];

  static List<BaselineProfile> get userBaselines => _userBaselines;

  /// Loads user-created baselines from local storage
  Future<void> loadUserBaselines() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    _userBaselines.clear(); // Reset list

    for (final key in keys) {
      if (key.startsWith(_customBaselinePrefix)) {
        final jsonString = prefs.getString(key);
        if (jsonString != null) {
          final Map<String, dynamic> map = jsonDecode(jsonString);
          final profile = BaselineProfile.fromJson(map);
          _userBaselines.add(profile);
        }
      }
    }
  }

  /// Saves a new user-created baseline
 static Future<void> saveUserBaseline(BaselineProfile profile) async {
  final prefs = await SharedPreferences.getInstance();
  final jsonString = jsonEncode(profile.toJson());
  await prefs.setString('$_customBaselinePrefix${profile.id}', jsonString);

  // 🔥 This ensures the saved baseline is added to memory right away
  final manager = AppDataManager.instance;
  final existingIndex = manager.userBaselines.indexWhere((b) => b.id == profile.id);
  if (existingIndex != -1) {
    manager.userBaselines[existingIndex] = profile;
  } else {
    manager.userBaselines.add(profile);
  }
}

  /// Deletes a user-created baseline
  static Future<void> deleteUserBaseline(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_customBaselinePrefix$id');

    _userBaselines.removeWhere((profile) => profile.id == id);
    AppDataManager.instance.userBaselines.removeWhere((profile) => profile.id == id);

  }

  /// Tags controls with all user-created baselines
  void tagControlsWithUserBaselines(List<Control> controls) {
    for (final baseline in _userBaselines) {
      for (final control in controls) {
        final id = control.id.toLowerCase();
        control.baselines[baseline.id.toUpperCase()] = baseline.selectedControlIds.contains(id);
      }
    }
  }
}
