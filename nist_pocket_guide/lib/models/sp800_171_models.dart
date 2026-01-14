// SP 800-171 Rev 3 Data Models
// Protecting Controlled Unclassified Information (CUI) in Nonfederal Systems

class Sp800171Catalog {
  final String uuid;
  final Sp800171Metadata metadata;
  final List<Sp800171Family> families;

  Sp800171Catalog({
    required this.uuid,
    required this.metadata,
    required this.families,
  });

  factory Sp800171Catalog.fromJson(Map<String, dynamic> json) {
    final catalog = json['catalog'] ?? json;
    final groups = catalog['groups'] as List<dynamic>? ?? [];

    return Sp800171Catalog(
      uuid: catalog['uuid'] as String,
      metadata: Sp800171Metadata.fromJson(
        catalog['metadata'] as Map<String, dynamic>,
      ),
      families: groups
          .map((g) => Sp800171Family.fromJson(g as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Sp800171Metadata {
  final String title;
  final String version;
  final String lastModified;
  final String published;

  Sp800171Metadata({
    required this.title,
    required this.version,
    required this.lastModified,
    required this.published,
  });

  factory Sp800171Metadata.fromJson(Map<String, dynamic> json) {
    return Sp800171Metadata(
      title: json['title'] as String,
      version: json['version'] as String,
      lastModified: json['last-modified'] as String,
      published: json['published'] as String? ?? '',
    );
  }
}

class Sp800171Family {
  final String id;
  final String title;
  final String familyId;
  final List<Sp800171Requirement> requirements;

  Sp800171Family({
    required this.id,
    required this.title,
    required this.familyId,
    required this.requirements,
  });

  factory Sp800171Family.fromJson(Map<String, dynamic> json) {
    final controls = json['controls'] as List<dynamic>? ?? [];
    final id = json['id'] as String;
    
    // Extract family ID from id (e.g., "SP_800_171_03.01" -> "03.01")
    final familyId = id.replaceAll('SP_800_171_', '');

    return Sp800171Family(
      id: id,
      title: json['title'] as String,
      familyId: familyId,
      requirements: controls
          .map((c) => Sp800171Requirement.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  // Get color based on family for consistent UI theming
  String get colorCode {
    switch (familyId) {
      case '03.01': return 'blue'; // Access Control
      case '03.02': return 'green'; // Awareness and Training
      case '03.03': return 'orange'; // Audit and Accountability
      case '03.04': return 'purple'; // Configuration Management
      case '03.05': return 'red'; // Identification and Authentication
      case '03.06': return 'teal'; // Incident Response
      case '03.07': return 'indigo'; // Maintenance
      case '03.08': return 'pink'; // Media Protection
      case '03.09': return 'amber'; // Personnel Security
      case '03.10': return 'cyan'; // Physical Protection
      case '03.11': return 'lime'; // Risk Assessment
      case '03.12': return 'deepOrange'; // Security Assessment
      case '03.13': return 'lightBlue'; // System and Communications Protection
      case '03.14': return 'deepPurple'; // System and Information Integrity
      default: return 'grey';
    }
  }
}

class Sp800171Requirement {
  final String id;
  final String title;
  final String requirementId;
  final String familyId;
  final List<Sp800171StatementPart> statementParts;
  final String guidance;
  final List<Sp800171AssessmentObjective> assessmentObjectives;
  final List<Sp800171Parameter> parameters;

  Sp800171Requirement({
    required this.id,
    required this.title,
    required this.requirementId,
    required this.familyId,
    required this.statementParts,
    required this.guidance,
    required this.assessmentObjectives,
    required this.parameters,
  });

  factory Sp800171Requirement.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    
    // Extract requirement ID (e.g., "SP_800_171_03.01.01" -> "03.01.01")
    final requirementId = id.replaceAll('SP_800_171_', '');
    
    // Extract family ID (e.g., "03.01.01" -> "03.01")
    final parts = requirementId.split('.');
    final familyId = parts.length >= 2 ? '${parts[0]}.${parts[1]}' : requirementId;

    final allParts = json['parts'] as List<dynamic>? ?? [];
    
    // Extract statement parts
    final statementPart = allParts.firstWhere(
      (p) => (p as Map<String, dynamic>)['name'] == 'statement',
      orElse: () => <String, dynamic>{},
    ) as Map<String, dynamic>;
    
    final statementSubParts = statementPart['parts'] as List<dynamic>? ?? [];
    final statements = statementSubParts
        .map((p) => Sp800171StatementPart.fromJson(p as Map<String, dynamic>))
        .toList();

    // Extract guidance
    final guidancePart = allParts.firstWhere(
      (p) => (p as Map<String, dynamic>)['name'] == 'guidance',
      orElse: () => <String, dynamic>{},
    ) as Map<String, dynamic>;
    final guidance = guidancePart['prose'] as String? ?? '';

    // Extract assessment objectives
    final assessmentObjectives = allParts
        .where((p) => (p as Map<String, dynamic>)['name'] == 'assessment-objective')
        .map((p) => Sp800171AssessmentObjective.fromJson(p as Map<String, dynamic>))
        .toList();

    // Extract parameters
    final params = json['params'] as List<dynamic>? ?? [];
    final parameters = params
        .map((p) => Sp800171Parameter.fromJson(p as Map<String, dynamic>))
        .toList();

    return Sp800171Requirement(
      id: id,
      title: json['title'] as String,
      requirementId: requirementId,
      familyId: familyId,
      statementParts: statements,
      guidance: guidance,
      assessmentObjectives: assessmentObjectives,
      parameters: parameters,
    );
  }

  // Get full statement text (combining all parts)
  String get fullStatement {
    return statementParts.map((p) => p.getFullText()).join('\n\n');
  }

  // Get short preview of the statement
  String get statementPreview {
    if (statementParts.isEmpty) return '';
    final firstPart = statementParts.first.prose;
    return firstPart.length > 150 
        ? '${firstPart.substring(0, 150)}...' 
        : firstPart;
  }
}

class Sp800171StatementPart {
  final String id;
  final String label;
  final String prose;
  final List<Sp800171StatementPart> subParts;

  Sp800171StatementPart({
    required this.id,
    required this.label,
    required this.prose,
    required this.subParts,
  });

  factory Sp800171StatementPart.fromJson(Map<String, dynamic> json) {
    final props = json['props'] as List<dynamic>? ?? [];
    String label = '';
    
    if (props.isNotEmpty) {
      final labelProp = props.firstWhere(
        (p) => (p as Map<String, dynamic>)['name'] == 'label',
        orElse: () => <String, dynamic>{},
      ) as Map<String, dynamic>;
      label = labelProp['value'] as String? ?? '';
    }

    final parts = json['parts'] as List<dynamic>? ?? [];
    final subParts = parts
        .map((p) => Sp800171StatementPart.fromJson(p as Map<String, dynamic>))
        .toList();

    return Sp800171StatementPart(
      id: json['id'] as String? ?? '',
      label: label,
      prose: json['prose'] as String? ?? '',
      subParts: subParts,
    );
  }

  // Recursively get full text with proper indentation
  String getFullText({int level = 0}) {
    final indent = '  ' * level;
    final buffer = StringBuffer();
    
    if (prose.isNotEmpty) {
      if (label.isNotEmpty) {
        buffer.write('$indent$label. $prose');
      } else {
        buffer.write('$indent$prose');
      }
    }
    
    if (subParts.isNotEmpty) {
      for (final sub in subParts) {
        if (buffer.isNotEmpty) buffer.write('\n');
        buffer.write(sub.getFullText(level: level + 1));
      }
    }
    
    return buffer.toString();
  }
}

class Sp800171AssessmentObjective {
  final String id;
  final String prose;

  Sp800171AssessmentObjective({
    required this.id,
    required this.prose,
  });

  factory Sp800171AssessmentObjective.fromJson(Map<String, dynamic> json) {
    return Sp800171AssessmentObjective(
      id: json['id'] as String? ?? '',
      prose: json['prose'] as String? ?? '',
    );
  }
}

class Sp800171Parameter {
  final String id;
  final String label;
  final String usage;
  final String guideline;

  Sp800171Parameter({
    required this.id,
    required this.label,
    required this.usage,
    required this.guideline,
  });

  factory Sp800171Parameter.fromJson(Map<String, dynamic> json) {
    final props = json['props'] as List<dynamic>? ?? [];
    String label = '';
    
    if (props.isNotEmpty) {
      final labelProp = props.firstWhere(
        (p) => (p as Map<String, dynamic>)['name'] == 'label',
        orElse: () => <String, dynamic>{},
      ) as Map<String, dynamic>;
      label = labelProp['value'] as String? ?? '';
    }

    final guidelines = json['guidelines'] as List<dynamic>? ?? [];
    String guideline = '';
    if (guidelines.isNotEmpty) {
      final guidelineData = guidelines.first as Map<String, dynamic>;
      guideline = guidelineData['prose'] as String? ?? '';
    }

    return Sp800171Parameter(
      id: json['id'] as String? ?? '',
      label: label,
      usage: json['usage'] as String? ?? '',
      guideline: guideline,
    );
  }
}
