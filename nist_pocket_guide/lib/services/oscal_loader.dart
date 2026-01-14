// oscal_loader.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/oscal_models.dart';
import '../models/baseline_profile.dart';

class OSCALLoader {
  static Future<Catalog> loadCatalogAndTagBaselines({
    required BaselineProfile lowBaseline,
    required BaselineProfile moderateBaseline,
    required BaselineProfile highBaseline,
    required BaselineProfile privacyBaseline,
  }) async {
    final catalogString = await rootBundle.loadString('assets/NIST_SP-800-53_rev5_catalog.json');
    final catalogJson = jsonDecode(catalogString);
    final catalog = Catalog.fromJson(catalogJson);

    for (final control in catalog.controls) {
      final id = control.id.toLowerCase();

      // Tag control baseline membership
      control.baselines = {
        'LOW': lowBaseline.selectedControlIds.contains(id),
        'MODERATE': moderateBaseline.selectedControlIds.contains(id),
        'HIGH': highBaseline.selectedControlIds.contains(id),
        'PRIVACY': privacyBaseline.selectedControlIds.contains(id),
      };

      // Tag enhancement baseline membership
      for (final enhancement in control.enhancements) {
        final normId = enhancement.id.toLowerCase().replaceAll('(', '.').replaceAll(')', '');

        enhancement.baselines = {
          'LOW': lowBaseline.selectedControlIds.contains(normId),
          'MODERATE': moderateBaseline.selectedControlIds.contains(normId),
          'HIGH': highBaseline.selectedControlIds.contains(normId),
          'PRIVACY': privacyBaseline.selectedControlIds.contains(normId),
        };
      }
    }

    return catalog;
  }
}
