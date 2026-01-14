// baseline_loader.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/baseline_profile.dart';
import '../models/oscal_models.dart';

class BaselineLoader {
  static Future<BaselineProfile> loadLowBaseline() async {
    return _loadBaseline(
      profilePath: 'assets/NIST_SP-800-53_rev5_LOW-baseline_profile.json',
      catalogPath: 'assets/NIST_SP-800-53_rev5_catalog.json',
      id: 'low',
      title: 'NIST SP 800-53 Rev5 Low Baseline',
    );
  }

  static Future<BaselineProfile> loadModerateBaseline() async {
    return _loadBaseline(
      profilePath: 'assets/NIST_SP-800-53_rev5_MODERATE-baseline_profile.json',
      catalogPath: 'assets/NIST_SP-800-53_rev5_catalog.json',
      id: 'moderate',
      title: 'NIST SP 800-53 Rev5 Moderate Baseline',
    );
  }

  static Future<BaselineProfile> loadHighBaseline() async {
    return _loadBaseline(
      profilePath: 'assets/NIST_SP-800-53_rev5_HIGH-baseline_profile.json',
      catalogPath: 'assets/NIST_SP-800-53_rev5_catalog.json',
      id: 'high',
      title: 'NIST SP 800-53 Rev5 High Baseline',
    );
  }

  static Future<BaselineProfile> loadPrivacyBaseline() async {
    return _loadBaseline(
      profilePath: 'assets/NIST_SP-800-53_rev5_PRIVACY-baseline_profile.json',
      catalogPath: 'assets/NIST_SP-800-53_rev5_catalog.json',
      id: 'privacy',
      title: 'NIST SP 800-53 Rev5 Privacy Baseline',
    );
  }

  static Future<BaselineProfile> _loadBaseline({
    required String profilePath,
    required String catalogPath,
    required String id,
    required String title,
  }) async {
    // Load profile
    final profileString = await rootBundle.loadString(profilePath);
    final profileJson = jsonDecode(profileString);

    // Load imported catalog
    final catalogString = await rootBundle.loadString(catalogPath);
    final catalogJson = jsonDecode(catalogString);
    final catalog = Catalog.fromJson(catalogJson);

    // Build control lookup map
    final controlMap = {
    for (final control in catalog.controls) ...{
    control.id.toLowerCase(): control,
    for (final enhancement in control.enhancements)
      enhancement.id.toLowerCase(): enhancement,
  },
    for (final group in catalog.groups) ...{
    for (final control in group.controls) ...{
      control.id.toLowerCase(): control,
      for (final enhancement in control.enhancements)
        enhancement.id.toLowerCase(): enhancement,
    }
  }
};


    // Correctly navigate through profile → imports → include-controls → with-ids
    final imports = (profileJson['profile']?['imports'] as List<dynamic>?) ?? [];

    final includedControlIds = imports
        .expand((import) => (import['include-controls'] as List<dynamic>? ?? []))
        .expand((include) => (include['with-ids'] as List<dynamic>? ?? []))
        .map((id) => id.toString().toLowerCase())
        .toSet();

    // Resolve selected controls from catalog
    final selectedControls = includedControlIds.map((id) => controlMap[id]).whereType<Control>().toList();

    return BaselineProfile(
      id: id,
      title: title,
      selectedControlIds: selectedControls.map((c) => c.id.toLowerCase()).toList(),
    );
  }
  void tagControlsWithBaselines({
  required List<Control> controls,
  required BaselineProfile low,
  required BaselineProfile moderate,
  required BaselineProfile high,
  required BaselineProfile privacy,
}) 
{

  for (final control in controls) {
    final id = control.id.toLowerCase();

    control.baselines['LOW'] = low.selectedControlIds.contains(id);
    control.baselines['MODERATE'] = moderate.selectedControlIds.contains(id);
    control.baselines['HIGH'] = high.selectedControlIds.contains(id);
    control.baselines['PRIVACY'] = privacy.selectedControlIds.contains(id);
  

     // 🔥 VERY IMPORTANT: Also tag each enhancement
    for (final enhancement in control.enhancements) {
      final enhancementId = enhancement.id.toLowerCase();
      final normalizedEnhancementId = enhancementId.replaceAll('(', '.').replaceAll(')', '');
    enhancement.baselines = {
      'LOW': true,
      'MODERATE': moderate.selectedControlIds.contains(normalizedEnhancementId),
      'HIGH': high.selectedControlIds.contains(normalizedEnhancementId),
      'PRIVACY': privacy.selectedControlIds.contains(normalizedEnhancementId),
    };
    
  }
  
  }
  
}
}


