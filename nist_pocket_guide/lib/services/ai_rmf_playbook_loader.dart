// lib/services/ai_rmf_playbook_loader.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/ai_rmf_playbook_entry.dart';

class AiRmfPlaybookLoader {
  static Future<List<AiRmfPlaybookEntry>> loadPlaybook() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/nist_ai_rmf_playbook.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => AiRmfPlaybookEntry.fromJson(json))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print("Error loading AI RMF Playbook: $e");
      }
      return []; // Return empty list on error
    }
  }
}