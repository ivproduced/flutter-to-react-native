// lib/models/system_parameter_block.dart
// Not strictly needed in this file if only using toJson/fromJson for maps
import 'package:flutter/foundation.dart'; // For kDebugMode
// No need for 'package:flutter/services.dart'; unless loadSystemParameterBlocks is also in this file
// If loadSystemParameterBlocks is here, then 'flutter/services.dart' is needed.

class SystemParameterBlock {
  final String id;
  final String title;
  final String summary;
  final List<String> examples;

  SystemParameterBlock({
    required this.id,
    required this.title,
    required this.summary,
    this.examples = const [],
  });

  factory SystemParameterBlock.fromJson(Map<String, dynamic> json) {
    String idValue = json['id'] as String? ?? '';
    if (idValue.isEmpty && json['title'] is String) {
      idValue = (json['title'] as String).toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
    }
    if (idValue.isEmpty) {
      idValue = 'generated_id_${DateTime.now().millisecondsSinceEpoch}';
      if (kDebugMode) {
        print("Warning: SystemParameterBlock created with a generated ID for title: ${json['title']}");
      }
    }

    return SystemParameterBlock(
      id: idValue,
      title: json['title'] as String? ?? 'Untitled Parameter',
      summary: json['summary'] as String? ?? '',
      examples: (json['examples'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  // --- THIS IS THE METHOD YOU NEED TO ADD or ENSURE IS PRESENT ---
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'examples': examples,
    };
  }
  // --- END OF toJson() method ---
}
