// lib/models/ai_rmf_playbook_entry.dart
// For TapGestureRecognizer

class AiRmfPlaybookEntry {
  final String type;
  final String title;
  final String category;
  final String description;
  final String sectionAbout;
  final String sectionActions;
  final String sectionDoc;
  final String sectionRef;
  final List<String> aiActors;
  final List<String> topic;

  AiRmfPlaybookEntry({
    required this.type,
    required this.title,
    required this.category,
    required this.description,
    required this.sectionAbout,
    required this.sectionActions,
    required this.sectionDoc,
    required this.sectionRef,
    required this.aiActors,
    required this.topic,
  });

  factory AiRmfPlaybookEntry.fromJson(Map<String, dynamic> json) {
    return AiRmfPlaybookEntry(
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      sectionAbout: json['section_about'] as String? ?? '',
      sectionActions: json['section_actions'] as String? ?? '',
      sectionDoc: json['section_doc'] as String? ?? '',
      sectionRef: json['section_ref'] as String? ?? '',
      aiActors: (json['AI Actors'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      topic: (json['Topic'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  // Helper for search functionality
  String get searchableContent {
    return '$title $description $category $sectionAbout ${aiActors.join(" ")} ${topic.join(" ")}'.toLowerCase();
  }
}