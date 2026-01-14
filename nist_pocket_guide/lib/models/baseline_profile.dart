// baseline_profile.dart
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart'; // Add this import at the top

class BaselineProfile {
  final String id;
  final String title;
  final List<String> selectedControlIds;

  BaselineProfile({
    required this.id,
    required this.title,
    required this.selectedControlIds,
  });

static String generateUuidFromName(String name) {
    // Using a predefined namespace ensures that for the same name, 
    // you always get the same UUID (UUID v5).
    // IMPORTANT: Replace YOUR_APP_NAMESPACE_UUID with a real UUID v4 that you generate once.
    // You can generate one at websites like https://www.uuidgenerator.net/
    const String yourAppNamespaceUuid = '33a5939a-876f-41f6-a862-aac8536fdb1d'; // 👈 REPLACE THIS
    if (yourAppNamespaceUuid == 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6' && kDebugMode) {
        // This specific UUID is the example from RFC 4122 for DNS namespace. 
        // It's better to use your own unique one.
        if (kDebugMode) {
          print("WARNING: Using a generic example namespace UUID for BaselineProfile.generateUuidFromName. " "/nPlease generate and use a unique v4 UUID for your application's namespace for consistency.");
        }
    }
    return const Uuid().v5(yourAppNamespaceUuid, name.toLowerCase()); // Ensure name is consistent for hashing
  }


  factory BaselineProfile.fromJson(Map<String, dynamic> json) {
  // 🔁 If this is a custom baseline, just pull the list directly
  if (json.containsKey('selectedControlIds')) {
    return BaselineProfile(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      selectedControlIds: List<String>.from(json['selectedControlIds'] ?? []),
    );
  }

  // 🔁 Otherwise fall back to parsing OSCAL official profile format
  final modifySection = json['modify'] ?? {};
  final includeControls = modifySection['include-controls'] as List<dynamic>? ?? [];
  final selectedControlIds = <String>[];

  for (var include in includeControls) {
    final controls = include['control-selections'] as List<dynamic>? ?? [];
    for (var control in controls) {
      if (control is Map<String, dynamic> && control['control-id'] != null) {
        selectedControlIds.add(control['control-id']);
      }
    }
  }

  return BaselineProfile(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    selectedControlIds: selectedControlIds,
  );
}


  Map<String, dynamic> toJson() {
  return {
    'id': id,
    'title': title,
    'selectedControlIds': selectedControlIds,
  };
}
}
