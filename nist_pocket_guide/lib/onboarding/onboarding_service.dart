import 'package:shared_preferences/shared_preferences.dart';
import '../services/module_preferences_service.dart';

class OnboardingService {
  static const _completedKey = 'onboarding_completed_v2';
  static const _welcomeSeenKey = 'welcome_screen_seen';
  static const _roleKey = 'user_role';
  static const _timestampKey = 'onboarding_completed_timestamp';
  static const _startTimeKey = 'onboarding_start_timestamp';
  static const _stepTimesKey = 'onboarding_step_times';
  static const _skippedKey = 'onboarding_skipped';
  static const _version = 2; // bump when changing structure

  Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey) ?? false;
  }

  Future<bool> hasSeenWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_welcomeSeenKey) ?? false;
  }

  Future<void> setWelcomeSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_welcomeSeenKey, true);
  }

  Future<bool> wasSkipped() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_skippedKey) ?? false;
  }

  Future<void> setCompleted({
    required String role,
    List<int>? stepDurations,
    bool skipped = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;

    await prefs.setBool(_completedKey, true);
    await prefs.setString(_roleKey, role);
    await prefs.setInt('onboarding_version', _version);
    await prefs.setInt(_timestampKey, now);
    await prefs.setBool(_skippedKey, skipped);

    if (stepDurations != null) {
      await prefs.setStringList(
        _stepTimesKey,
        stepDurations.map((d) => d.toString()).toList(),
      );
    }
  }

  Future<void> trackStart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_startTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_completedKey);
    await prefs.remove(_welcomeSeenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_timestampKey);
    await prefs.remove(_startTimeKey);
    await prefs.remove(_stepTimesKey);
    await prefs.remove(_skippedKey);
  }

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  Future<DateTime?> getCompletionTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_timestampKey);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  Future<OnboardingAnalytics?> getAnalytics() async {
    final prefs = await SharedPreferences.getInstance();
    final startTime = prefs.getInt(_startTimeKey);
    final endTime = prefs.getInt(_timestampKey);
    final stepTimes = prefs.getStringList(_stepTimesKey);
    final role = prefs.getString(_roleKey);
    final skipped = prefs.getBool(_skippedKey) ?? false;

    if (startTime == null || endTime == null) return null;

    return OnboardingAnalytics(
      totalDurationMs: endTime - startTime,
      stepDurations: stepTimes?.map(int.parse).toList() ?? [],
      role: role,
      skipped: skipped,
      completedAt: DateTime.fromMillisecondsSinceEpoch(endTime),
    );
  }

  /// Apply role-based defaults for modules
  static Future<void> applyRoleDefaults(
    String role,
    ModulePreferencesService modulePrefs,
  ) async {
    final defaults = _getRoleDefaults(role);
    for (final entry in defaults.entries) {
      await modulePrefs.setModuleVisibility(entry.key, entry.value);
    }
  }

  /// Get role-based defaults for modules
  static Map<String, bool> getRoleDefaults(String role) {
    return _getRoleDefaults(role);
  }

  static Map<String, bool> _getRoleDefaults(String role) {
    switch (role) {
      case 'Security Assessor':
        return {
          'nist_800_53': true,
          'assessment_objectives': true,
          'ssp_tools': true,
          'ai_assistant': true,
        };
      case 'Implementer / Engineer':
        return {
          'nist_800_53': true,
          'assessment_objectives': false,
          'ssp_tools': true,
          'ai_assistant': true,
        };
      case 'Compliance Manager':
        return {
          'nist_800_53': true,
          'assessment_objectives': true,
          'ssp_tools': true,
          'ai_assistant': false,
        };
      case 'Executive / Sponsor':
        return {
          'nist_800_53': false,
          'assessment_objectives': false,
          'ssp_tools': true,
          'ai_assistant': false,
        };
      case 'Learner / Student':
        return {
          'nist_800_53': true,
          'assessment_objectives': true,
          'ssp_tools': false,
          'ai_assistant': true,
        };
      default:
        return {
          'nist_800_53': true,
          'assessment_objectives': true,
          'ssp_tools': true,
          'ai_assistant': true,
        };
    }
  }
}

class OnboardingAnalytics {
  final int totalDurationMs;
  final List<int> stepDurations;
  final String? role;
  final bool skipped;
  final DateTime completedAt;

  OnboardingAnalytics({
    required this.totalDurationMs,
    required this.stepDurations,
    required this.role,
    required this.skipped,
    required this.completedAt,
  });

  Duration get totalDuration => Duration(milliseconds: totalDurationMs);

  Map<String, dynamic> toJson() => {
    'totalDurationMs': totalDurationMs,
    'stepDurations': stepDurations,
    'role': role,
    'skipped': skipped,
    'completedAt': completedAt.toIso8601String(),
  };
}
