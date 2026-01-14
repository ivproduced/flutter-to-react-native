// lib/models/app_module.dart
import 'package:flutter/material.dart';

/// Defines the available modules in the NIST Pocket Guide app.
///
/// This model ensures that the settings screen module visibility list
/// stays in sync with what's actually implemented in the app.
///
/// To add a new module:
/// 1. Add it to the allModules list below
/// 2. Implement the module in main.dart with appropriate visibility checks
/// 3. Add the preference key to ModulePreferencesService if needed
class AppModule {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final String preferenceKey;
  final bool defaultVisible;
  final bool Function()? isAvailable; // Optional check for module availability

  const AppModule({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.preferenceKey,
    this.defaultVisible = true,
    this.isAvailable,
  });
}

class AppModules {
  static const List<AppModule> allModules = [
    AppModule(
      id: 'nist_800_53',
      title: '800-53 Pocket Guide',
      description: 'Show NIST 800-53 controls and guidance module',
      icon: Icons.menu_book_outlined,
      preferenceKey: 'show_nist_800_53_module',
    ),
    AppModule(
      id: 'ai_rmf',
      title: 'AI RMF Playbook',
      description: 'Show NIST AI Risk Management Framework module',
      icon: Icons.psychology_alt_outlined,
      preferenceKey: 'show_ai_rmf_module',
    ),
    AppModule(
      id: 'ssp_generator',
      title: 'Systems & SSPs',
      description: 'Show system management and SSP generation module',
      icon: Icons.folder_shared_outlined,
      preferenceKey: 'show_ssp_generator_module',
    ),
    AppModule(
      id: 'nist_bot',
      title: 'NISTBot Chat',
      description: 'Show NISTBot chat module',
      icon: Icons.smart_toy_outlined,
      preferenceKey: 'show_nist_bot_module',
      defaultVisible: false,
    ),
    AppModule(
      id: 'csf_2_0',
      title: 'CSF 2.0',
      description: 'Show NIST Cybersecurity Framework 2.0 module',
      icon: Icons.security_outlined,
      preferenceKey: 'show_csf_2_0_module',
    ),
    AppModule(
      id: 'sp_800_171',
      title: 'SP 800-171 Rev 3',
      description: 'Show NIST SP 800-171 (Protecting CUI) module',
      icon: Icons.shield_outlined,
      preferenceKey: 'show_sp_800_171_module',
    ),
    // Enhanced NISTBot is currently disabled in the main app
    // AppModule(
    //   id: 'enhanced_nist_bot',
    //   title: 'Enhanced NISTBot',
    //   description: 'Show enhanced NISTBot chat module',
    //   icon: Icons.auto_awesome,
    //   preferenceKey: 'show_enhanced_nist_bot_module',
    //   isAvailable: () => false, // Currently disabled
    // ),
  ];

  /// Get modules that are actually implemented in the app
  static List<AppModule> getAvailableModules() {
    return allModules.where((module) {
      // Only include modules that don't have an availability check or pass the check
      return module.isAvailable?.call() ?? true;
    }).toList();
  }

  /// Get module by preference key
  static AppModule? getModuleByPreferenceKey(String preferenceKey) {
    try {
      return allModules.firstWhere(
        (module) => module.preferenceKey == preferenceKey,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get module by ID
  static AppModule? getModuleById(String id) {
    try {
      return allModules.firstWhere((module) => module.id == id);
    } catch (e) {
      return null;
    }
  }
}
