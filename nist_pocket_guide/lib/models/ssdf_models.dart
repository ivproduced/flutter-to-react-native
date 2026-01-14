// SSDF (Secure Software Development Framework) SP 800-218 Data Models
// Follows OSCAL catalog structure for NIST SP 800-218 Ver 1.1

class SsdfCatalog {
  final String uuid;
  final SsdfMetadata metadata;
  final List<SsdfPracticeGroup> practiceGroups;

  SsdfCatalog({
    required this.uuid,
    required this.metadata,
    required this.practiceGroups,
  });

  factory SsdfCatalog.fromJson(Map<String, dynamic> json) {
    final catalog = json['catalog'] as Map<String, dynamic>;
    final groups = catalog['groups'] as List<dynamic>;

    return SsdfCatalog(
      uuid: catalog['uuid'] as String,
      metadata: SsdfMetadata.fromJson(catalog['metadata'] as Map<String, dynamic>),
      practiceGroups: groups.map((g) => SsdfPracticeGroup.fromJson(g as Map<String, dynamic>)).toList(),
    );
  }
}

class SsdfMetadata {
  final String title;
  final String version;
  final String lastModified;

  SsdfMetadata({
    required this.title,
    required this.version,
    required this.lastModified,
  });

  factory SsdfMetadata.fromJson(Map<String, dynamic> json) {
    return SsdfMetadata(
      title: json['title'] as String,
      version: json['version'] as String,
      lastModified: json['last-modified'] as String,
    );
  }
}

class SsdfPracticeGroup {
  final String id;
  final String title;
  final String overview;
  final List<SsdfPractice> practices;

  SsdfPracticeGroup({
    required this.id,
    required this.title,
    required this.overview,
    required this.practices,
  });

  factory SsdfPracticeGroup.fromJson(Map<String, dynamic> json) {
    final parts = json['parts'] as List<dynamic>? ?? [];
    String overview = '';
    
    for (var part in parts) {
      final partMap = part as Map<String, dynamic>;
      if (partMap['name'] == 'overview') {
        overview = partMap['prose'] as String? ?? '';
        break;
      }
    }

    final controls = json['controls'] as List<dynamic>? ?? [];

    return SsdfPracticeGroup(
      id: json['id'] as String,
      title: json['title'] as String,
      overview: overview,
      practices: controls.map((c) => SsdfPractice.fromJson(c as Map<String, dynamic>)).toList(),
    );
  }

  String get description {
    switch (id) {
      case 'PO':
        return 'Prepare the Organization';
      case 'PS':
        return 'Protect the Software';
      case 'PW':
        return 'Produce Well-Secured Software';
      case 'RV':
        return 'Respond to Vulnerabilities';
      default:
        return title;
    }
  }

  String get icon {
    switch (id) {
      case 'PO':
        return '🏢';
      case 'PS':
        return '🛡️';
      case 'PW':
        return '⚙️';
      case 'RV':
        return '🚨';
      default:
        return '📋';
    }
  }
}

class SsdfPractice {
  final String id;
  final String title;
  final String statement;
  final List<SsdfTask> tasks;

  SsdfPractice({
    required this.id,
    required this.title,
    required this.statement,
    required this.tasks,
  });

  factory SsdfPractice.fromJson(Map<String, dynamic> json) {
    final parts = json['parts'] as List<dynamic>? ?? [];
    String statement = '';
    
    for (var part in parts) {
      final partMap = part as Map<String, dynamic>;
      if (partMap['name'] == 'statement') {
        statement = partMap['prose'] as String? ?? '';
        break;
      }
    }

    final controls = json['controls'] as List<dynamic>? ?? [];

    return SsdfPractice(
      id: json['id'] as String,
      title: json['title'] as String,
      statement: statement,
      tasks: controls.map((c) => SsdfTask.fromJson(c as Map<String, dynamic>)).toList(),
    );
  }

  String get practiceGroupId => id.split('.').first;
}

class SsdfTask {
  final String id;
  final String title;
  final String statement;
  final List<String> examples;
  final List<SsdfReference> references;

  SsdfTask({
    required this.id,
    required this.title,
    required this.statement,
    required this.examples,
    required this.references,
  });

  factory SsdfTask.fromJson(Map<String, dynamic> json) {
    final parts = json['parts'] as List<dynamic>? ?? [];
    String statement = '';
    List<String> examples = [];

    for (var part in parts) {
      final partMap = part as Map<String, dynamic>;
      if (partMap['name'] == 'statement') {
        statement = partMap['prose'] as String? ?? '';
      } else if (partMap['name'] == 'example') {
        final prose = partMap['prose'] as String? ?? '';
        if (prose.isNotEmpty) {
          examples.add(prose);
        }
      }
    }

    final links = json['links'] as List<dynamic>? ?? [];
    final references = links
        .map((l) => SsdfReference.fromJson(l as Map<String, dynamic>))
        .toList();

    return SsdfTask(
      id: json['id'] as String,
      title: json['title'] as String? ?? json['id'] as String,
      statement: statement,
      examples: examples,
      references: references,
    );
  }

  String get practiceId {
    // PO.1.1 -> PO.1
    final parts = id.split('.');
    if (parts.length >= 2) {
      return '${parts[0]}.${parts[1]}';
    }
    return id;
  }

  String get practiceGroupId => id.split('.').first;

  // Map task to SDLC phase
  String get sdlcPhase {
    final groupId = practiceGroupId;
    switch (groupId) {
      case 'PO':
        return 'Planning';
      case 'PS':
        return 'Design & Development';
      case 'PW':
        return 'Implementation & Testing';
      case 'RV':
        return 'Operations & Maintenance';
      default:
        return 'General';
    }
  }
}

class SsdfReference {
  final String href;
  final String rel;
  final String text;

  SsdfReference({
    required this.href,
    required this.rel,
    required this.text,
  });

  factory SsdfReference.fromJson(Map<String, dynamic> json) {
    return SsdfReference(
      href: json['href'] as String? ?? '',
      rel: json['rel'] as String? ?? '',
      text: json['text'] as String? ?? '',
    );
  }

  bool get isExternalReference => rel == 'external_reference';
}

// DevSecOps tool recommendations for SSDF practices
class SsdfToolRecommendation {
  final String practiceId;
  final String toolName;
  final String category;
  final String description;
  final String? url;

  SsdfToolRecommendation({
    required this.practiceId,
    required this.toolName,
    required this.category,
    required this.description,
    this.url,
  });
}

// SSDF Maturity Level assessment
enum SsdfMaturityLevel {
  notStarted,
  initial,
  managed,
  defined,
  quantitativelyManaged,
  optimizing,
}

class SsdfMaturityAssessment {
  final String practiceId;
  final SsdfMaturityLevel level;
  final String notes;
  final DateTime assessmentDate;

  SsdfMaturityAssessment({
    required this.practiceId,
    required this.level,
    required this.notes,
    required this.assessmentDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'practiceId': practiceId,
      'level': level.toString().split('.').last,
      'notes': notes,
      'assessmentDate': assessmentDate.toIso8601String(),
    };
  }

  factory SsdfMaturityAssessment.fromJson(Map<String, dynamic> json) {
    return SsdfMaturityAssessment(
      practiceId: json['practiceId'] as String,
      level: SsdfMaturityLevel.values.firstWhere(
        (e) => e.toString().split('.').last == json['level'],
        orElse: () => SsdfMaturityLevel.notStarted,
      ),
      notes: json['notes'] as String,
      assessmentDate: DateTime.parse(json['assessmentDate'] as String),
    );
  }
}
