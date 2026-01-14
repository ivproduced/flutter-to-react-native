// lib/models/oscal_models.dart

// Helper classes first
import 'package:flutter/foundation.dart';

class Prop {
  final String name;
  final String value;
  final String? ns;
  final String? clazz; // 'class' in JSON

  Prop({
    required this.name,
    required this.value,
    this.ns,
    this.clazz,
  });

  factory Prop.fromJson(Map<String, dynamic> json) {
    return Prop(
      name: json['name'] as String? ?? '',
      value: json['value'] as String? ?? '',
      ns: json['ns'] as String?,
      clazz: json['class'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      if (ns != null) 'ns': ns,
      if (clazz != null) 'class': clazz,
    };
  }
}

class Select {
  final String? howMany;
  final List<String> choice;

  Select({
    this.howMany,
    this.choice = const [],
  });

  factory Select.fromJson(Map<String, dynamic> json) {
    return Select(
      howMany: json['how-many'] as String?,
      choice: (json['choice'] as List<dynamic>?)
              ?.map((c) => c.toString())
              .toList() ??
          [],
    );
  }
}

class Link {
  final String href;
  final String? rel;

  Link({required this.href, this.rel});

  factory Link.fromJson(Map<String, dynamic> json) {
    return Link(
      href: json['href'] as String? ?? '',
      rel: json['rel'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'href': href,
      if (rel != null) 'rel': rel,
    };
  }
}

class Parameter {
  final String id;
  final List<Prop> props;
  final String? label;
  final List<String> values;
  final Select? select;
  // final List<Guideline>? guidelines; // Example

  Parameter({
    required this.id,
    this.props = const [],
    this.label,
    this.values = const [],
    this.select,
    // this.guidelines,
  });

  factory Parameter.fromJson(Map<String, dynamic> json) {
    return Parameter(
      id: json['id'] as String? ?? 'unknown-param-id',
      props: (json['props'] as List<dynamic>?)
              ?.map((p) => Prop.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      label: json['label'] as String?,
      values: (json['values'] as List<dynamic>?)
              ?.map((v) => v.toString())
              .toList() ??
          [],
      select: json['select'] != null
          ? Select.fromJson(json['select'] as Map<String, dynamic>)
          : null,
    );
  }
}



class Part {
  final String? id;
  final String name;
  final String? title;
  final String? prose; // Nullable
  final List<Part> subparts; // Maps to "parts" in JSON
  final List<Prop> props;

  Part({
    this.id,
    required this.name,
    this.title,
    this.prose, // Nullable
    this.subparts = const [],
    this.props = const [],
  });

  factory Part.fromJson(Map<String, dynamic> json) {
    return Part(
      id: json['id'] as String?,
      name: json['name'] as String? ?? 'unknown-part-name',
      title: json['title'] as String?,
      prose: json['prose'] as String?, // Assigns null if json['prose'] is null/missing
      subparts: (json['parts'] as List<dynamic>?)
              ?.map((p) => Part.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      props: (json['props'] as List<dynamic>?)
              ?.map((p) => Prop.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (title != null) 'title': title,
      if (prose != null) 'prose': prose, // Only include in JSON if not null
      if (subparts.isNotEmpty) 'parts': subparts.map((p) => p.toJson()).toList(),
      if (props.isNotEmpty) 'props': props.map((p) => p.toJson()).toList(),
    };
  }

  // Getters for part types
  bool get isStatement => name.toLowerCase() == 'statement';
  bool get isGuidance => name.toLowerCase() == 'guidance';
  bool get isAssessmentObjectiveContainer => name.toLowerCase() == 'assessment-objective'; // For the parent part
  // Add more as needed:
  // bool get isAssessmentMethod => name.toLowerCase() == 'assessment-method';
  // bool get isEvidence => name.toLowerCase() == 'assessment-objects';
}

class Control {
  final String id;
  final String title;
  final String controlClass;
  final List<Prop> props;
  final List<Link> links;
  final List<Parameter> params;
  final List<Part> parts; // Direct child parts of this control
  final List<Control> enhancements; // Nested controls (enhancements)

  Map<String, bool> baselines = {
    'LOW': false,
    'MODERATE': false,
    'HIGH': false,
    'PRIVACY': false,
  };
  bool inCustomBaseline = false;

  Control({
    required this.id,
    required this.title,
    required this.controlClass,
    this.props = const [],
    this.links = const [],
    this.params = const [],
    this.parts = const [],
    this.enhancements = const [],
  });

  factory Control.fromJson(Map<String, dynamic> json) {
    return Control(
      id: (json['id'] as String? ?? '').toLowerCase(),
      title: json['title'] as String? ?? 'Untitled Control',
      controlClass: json['class'] as String? ?? '',
      props: (json['props'] as List<dynamic>?)
              ?.map((p) => Prop.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      links: (json['links'] as List<dynamic>?)
              ?.map((l) => Link.fromJson(l as Map<String, dynamic>))
              .toList() ??
          [],
      params: (json['params'] as List<dynamic>?)
              ?.map((p) => Parameter.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      parts: (json['parts'] as List<dynamic>?)
              ?.map((p) => Part.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      enhancements: (json['controls'] as List<dynamic>?) // OSCAL enhancements are nested controls
              ?.map((e) => Control.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  // Getter for the container of assessment objectives
  List<Part> get assessmentObjectives {
    try {
      final assessmentObjectiveParentPart = parts.firstWhere(
        (p) => p.name.toLowerCase() == 'assessment-objective',
      );
      return assessmentObjectiveParentPart.subparts;
    } catch (e) {
      return [];
    }
  }

  // Getter for flattened, actionable assessment objectives (those with prose)
  // lib/models/oscal_models.dart
// ... (inside the Control class) ...

// lib/models/oscal_models.dart
// ... (inside the Control class) ...

List<Part> get flatAssessmentObjectives {
  List<Part> objectives = [];
  if (kDebugMode) {
    // This is the initial log for the CORRECT getter
    print("DEBUG: Control $id: Entered flatAssessmentObjectives (Aggressive Search V2). Searching for 'assessment-objective' parts with prose.");
  }

  void findRecursiveObjectivesWithProse(Part currentPart, int depth) {
    if (depth > 15) { 
      if (kDebugMode) print("DEBUG: Control $id: Max recursion depth for part ${currentPart.id ?? 'N/A'}");
      return;
    }

    String currentPartNameLower = currentPart.name.toLowerCase();
    // Optional: More verbose logging during traversal if needed
    // if (kDebugMode && depth < 5) { 
    //     print("DEBUG: Control $id (depth $depth): Processing part id='${currentPart.id ?? "N/A"}', name='$currentPartNameLower'. Has ${currentPart.subparts.length} subparts. Has prose: ${currentPart.prose != null && currentPart.prose!.trim().isNotEmpty}");
    // }

    // Condition to add: name is 'assessment-objective' AND it has non-empty prose
    if (currentPartNameLower == 'assessment-objective') {
      if (currentPart.id != null && currentPart.id!.isNotEmpty &&
          currentPart.prose != null && currentPart.prose!.trim().isNotEmpty) {
        
        objectives.add(currentPart);
        if (kDebugMode) {
           print("DEBUG: Control $id: ADDED part id='${currentPart.id}', name='$currentPartNameLower' because it's an 'assessment-objective' with prose.");
        }
        // Once an 'assessment-objective' with prose is added, we generally consider it a "leaf" objective
        // for the purpose of this flat list. So, we don't recurse into its children to find more.
        return; 
      }
    }

    // If the current part itself wasn't added as a final objective (e.g., it's a container,
    // or an 'assessment-objective' without prose like 'ac-2_obj' or 'ac-2_obj.a'),
    // then recurse into its subparts.
    if (currentPart.subparts.isNotEmpty) {
      for (var sub in currentPart.subparts) {
        findRecursiveObjectivesWithProse(sub, depth + 1);
      }
    }
  }

  // Start recursion from all direct child parts of the Control object.
  // This allows finding objectives even if the main container isn't named "objective".
  for (var topLevelPart in parts) { 
    findRecursiveObjectivesWithProse(topLevelPart, 0);
  }

  // Remove duplicates by ID (important if traversal could hit the same part via different paths)
  if (objectives.isNotEmpty) {
    final ids = <String>{};
    objectives.retainWhere((x) => x.id != null && ids.add(x.id!)); 
  }

  if (kDebugMode) {
     if (objectives.isEmpty) {
        print("DEBUG: Control $id: flatAssessmentObjectives (Aggressive Search V2) is EMPTY. No 'assessment-objective' parts with prose found. Check OSCAL structure and part names/prose content.");
     } else {
        print("DEBUG: Control $id: Found objectives (Aggressive Search V2): ${objectives.map((o) => "{id:${o.id}, name:${o.name}}").join(', ')}");
     }
  }
  return objectives;
}
}
// Helper extension if not already available on List:

extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E element) test) {
    for (E element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

class Group {
  final String id;
  final String title;
  final List<Control> controls;

  Group({required this.id, required this.title, required this.controls});

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String? ?? 'unknown-group-id',
      title: json['title'] as String? ?? 'Unknown Group Title',
      controls: (json['controls'] as List<dynamic>?)
              ?.map((c) => Control.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}


class Catalog {
  final List<Control> controls; // All unique controls in the catalog
  final List<Group> groups;   // Top-level groups

  Catalog({required this.controls, required this.groups});

  factory Catalog.fromJson(Map<String, dynamic> json) {
    final catalogData = json['catalog'];
    if (catalogData == null || catalogData is! Map<String, dynamic>) {
      if (kDebugMode) {
        print("Error: 'catalog' key missing or not a map in JSON source for Catalog.");
      }
      return Catalog(controls: [], groups: []);
    }

    final List<Group> parsedGroups = (catalogData['groups'] as List<dynamic>?)
            ?.map((g) => Group.fromJson(g as Map<String, dynamic>))
            .toList() ??
        [];

    // Collect all unique controls:
    // 1. Controls directly under catalog.controls (if any - some OSCAL versions might have this)
    // 2. Controls nested under groups (and recursively under sub-groups if your Group model supported that)
    // 3. Controls nested under other controls (enhancements) - these are handled within Control.fromJson

    final Set<String> controlIds = {};
    final List<Control> allUniqueControls = [];

    // Function to recursively add controls and their enhancements
    void addControlAndEnhancements(Control control) {
      if (controlIds.add(control.id.toLowerCase())) { // Ensure ID is normalized for uniqueness check
        allUniqueControls.add(control);
      }
      for (var enhancement in control.enhancements) {
        addControlAndEnhancements(enhancement); // Recursively add enhancements
      }
    }

    // Add controls from top-level groups
    for (var group in parsedGroups) {
      for (var control in group.controls) {
        addControlAndEnhancements(control);
      }
    }

    // Add controls directly under catalog (if your OSCAL JSON has them there)
    if (catalogData['controls'] is List) {
      final List<Control> directControls = (catalogData['controls'] as List<dynamic>)
          .map((c) => Control.fromJson(c as Map<String, dynamic>))
          .toList();
      for (var control in directControls) {
        addControlAndEnhancements(control);
      }
    }

    allUniqueControls.sort((a, b) => _compareControlIds(a.id, b.id));

    return Catalog(
      controls: allUniqueControls, // This list now contains all unique controls and enhancements
      groups: parsedGroups,
    );
  }
}

// Helper function for sorting controls (can be top-level or static in a utility class)
int _compareControlIds(String a, String b) {
  RegExp pattern = RegExp(r"([A-Za-z]+)-(\d+)(.*)");
  Match? matchA = pattern.firstMatch(a.toLowerCase()); // Normalize for comparison
  Match? matchB = pattern.firstMatch(b.toLowerCase());

  if (matchA != null && matchB != null) {
    String prefixA = matchA.group(1)!;
    String prefixB = matchB.group(1)!;
    int numA = int.parse(matchA.group(2)!);
    int numB = int.parse(matchB.group(2)!);
    String suffixA = matchA.group(3)!; // Includes enhancement part like ".1"
    String suffixB = matchB.group(3)!;

    if (prefixA.compareTo(prefixB) != 0) {
      return prefixA.compareTo(prefixB);
    }
    if (numA != numB) {
      return numA.compareTo(numB);
    }
    // Now compare suffix, which handles enhancements correctly
    // e.g. ".1" vs ".2", or "" vs ".1"
    return _compareSuffixes(suffixA, suffixB);
  }
  return a.toLowerCase().compareTo(b.toLowerCase());
}

int _compareSuffixes(String suffixA, String suffixB) {
  // Handle empty suffixes (base controls)
  if (suffixA.isEmpty && suffixB.isNotEmpty) return -1; // Base control comes before enhancement
  if (suffixA.isNotEmpty && suffixB.isEmpty) return 1;  // Enhancement comes after base control
  if (suffixA.isEmpty && suffixB.isEmpty) return 0;

  // Try to parse numbers after '.' for enhancements like ".1", ".10"
  RegExp enhPattern = RegExp(r"\.(\d+)(.*)");
  Match? matchEnhA = enhPattern.firstMatch(suffixA);
  Match? matchEnhB = enhPattern.firstMatch(suffixB);

  if (matchEnhA != null && matchEnhB != null) {
    int numEnhA = int.parse(matchEnhA.group(1)!);
    int numEnhB = int.parse(matchEnhB.group(1)!);
    String subSuffixA = matchEnhA.group(2)!;
    String subSuffixB = matchEnhB.group(2)!;

    if (numEnhA != numEnhB) {
      return numEnhA.compareTo(numEnhB);
    }
    return subSuffixA.compareTo(subSuffixB); // Further sort by any sub-suffixes
  }
  return suffixA.compareTo(suffixB); // Fallback to string comparison
}


// Extensions
extension ControlComputed on Control {
  String get statement {
    try {
      final statementPart = parts.firstWhere(
        (p) => p.name.toLowerCase() == 'statement',
      );
      return statementPart.prose ?? '';
    } catch (e) {
      return '';
    }
  }

  String get discussion {
    try {
      final guidancePart = parts.firstWhere(
        (p) => p.name.toLowerCase() == 'guidance',
      );
      return guidancePart.prose ?? '';
    } catch (e) {
      return '';
    }
  }

  bool get isEnhancement {
    // A more robust check might be if its ID pattern matches an enhancement
    // or if it's found within another control's 'enhancements' list during parsing.
    // For now, relying on ID structure.
    return id.contains('.') || RegExp(r"-\d+\(\d+\)").hasMatch(id);
  }

  String get family {
    return id.split('-').first.toUpperCase();
  }
}

extension ControlBaselineExtensions on Control {
  bool get baselineLow => baselines['LOW'] ?? false;
  bool get baselineModerate => baselines['MODERATE'] ?? false;
  bool get baselineHigh => baselines['HIGH'] ?? false;
  bool get baselinePrivacy => baselines['PRIVACY'] ?? false;
}