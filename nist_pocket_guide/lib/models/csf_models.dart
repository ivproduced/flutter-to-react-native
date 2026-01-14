// CSF (Cybersecurity Framework) v2.0 Data Models
// Follows OSCAL catalog structure for NIST CSF 2.0

import 'package:flutter/material.dart';
import 'csf_crosswalk_mappings.dart';

/// Framework types for cross-reference display
enum FrameworkType {
  sp80053('800-53', 'NIST SP 800-53 Rev 5', Icons.shield_outlined, Color(0xFF1976D2), Color(0xFFE3F2FD)),
  sp800171('800-171', 'NIST SP 800-171 Rev 3', Icons.lock_outlined, Color(0xFF00796B), Color(0xFFE0F2F1));
  
  final String shortName;
  final String fullName;
  final IconData icon;
  final Color primaryColor;
  final Color lightColor;
  
  const FrameworkType(this.shortName, this.fullName, this.icon, this.primaryColor, this.lightColor);
}

class CsfCatalog {
  final String uuid;
  final CsfMetadata metadata;
  final List<CsfFunction> functions;

  CsfCatalog({
    required this.uuid,
    required this.metadata,
    required this.functions,
  });

  factory CsfCatalog.fromJson(Map<String, dynamic> json) {
    final catalog = json['catalog'] as Map<String, dynamic>;
    final groups = catalog['groups'] as List<dynamic>;

    return CsfCatalog(
      uuid: catalog['uuid'] as String,
      metadata: CsfMetadata.fromJson(catalog['metadata'] as Map<String, dynamic>),
      functions: groups.map((g) => CsfFunction.fromJson(g as Map<String, dynamic>)).toList(),
    );
  }
}

class CsfMetadata {
  final String title;
  final String version;
  final String lastModified;

  CsfMetadata({
    required this.title,
    required this.version,
    required this.lastModified,
  });

  factory CsfMetadata.fromJson(Map<String, dynamic> json) {
    return CsfMetadata(
      title: json['title'] as String,
      version: json['version'] as String,
      lastModified: json['last-modified'] as String,
    );
  }
}

class CsfFunction {
  final String id;
  final String title;
  final List<CsfCategory> categories;

  CsfFunction({
    required this.id,
    required this.title,
    required this.categories,
  });

  factory CsfFunction.fromJson(Map<String, dynamic> json) {
    final controls = json['controls'] as List<dynamic>? ?? [];
    
    return CsfFunction(
      id: json['id'] as String,
      title: json['title'] as String,
      categories: controls.map((c) => CsfCategory.fromJson(c as Map<String, dynamic>)).toList(),
    );
  }

  String get description {
    switch (id) {
      case 'GV':
        return 'Establish and monitor organizational cybersecurity governance, risk management strategy, and program';
      case 'ID':
        return 'Develop organizational understanding to manage cybersecurity risk';
      case 'PR':
        return 'Implement safeguards to ensure delivery of critical services';
      case 'DE':
        return 'Implement activities to identify cybersecurity events';
      case 'RS':
        return 'Implement activities to take action regarding detected cybersecurity incidents';
      case 'RC':
        return 'Implement activities to restore capabilities and services impaired by cybersecurity incidents';
      default:
        return '';
    }
  }
}

class CsfCategory {
  final String id;
  final String title;
  final String statement;
  final List<CsfSubcategory> subcategories;

  CsfCategory({
    required this.id,
    required this.title,
    required this.statement,
    required this.subcategories,
  });

  factory CsfCategory.fromJson(Map<String, dynamic> json) {
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

    return CsfCategory(
      id: json['id'] as String,
      title: json['title'] as String,
      statement: statement,
      subcategories: controls.map((c) => CsfSubcategory.fromJson(c as Map<String, dynamic>)).toList(),
    );
  }

  String get functionId => id.split('.').first;
  
  String get categoryId => id;
}

class CsfSubcategory {
  final String id;
  final String title;
  final String statement;
  final List<String> examples;
  final List<String> related80053Controls;
  final List<String> related800171Controls;

  CsfSubcategory({
    required this.id,
    required this.title,
    required this.statement,
    required this.examples,
    this.related80053Controls = const [],
    this.related800171Controls = const [],
  });

  factory CsfSubcategory.fromJson(Map<String, dynamic> json) {
    final parts = json['parts'] as List<dynamic>? ?? [];
    String statement = '';
    List<String> examples = [];

    for (var part in parts) {
      final partMap = part as Map<String, dynamic>;
      if (partMap['name'] == 'statement') {
        statement = partMap['prose'] as String? ?? '';
      } else if (partMap['name'] == 'example') {
        examples.add(partMap['prose'] as String? ?? '');
      }
    }

    final subcategoryId = json['id'] as String;
    
    final related80053 = csfTo80053Mappings[subcategoryId] ?? const [];
    final related800171 = csfTo800171Mappings[subcategoryId] ?? const [];
    
    // Debug output for mapping lookup
    if (related80053.isNotEmpty || related800171.isNotEmpty) {
      debugPrint('📊 Loading CSF $subcategoryId: 800-53=${related80053.length}, 800-171=${related800171.length}');
    }
    
    return CsfSubcategory(
      id: subcategoryId,
      title: json['title'] as String,
      statement: statement,
      examples: examples,
      related80053Controls: related80053,
      related800171Controls: related800171,
    );
  }

  String get categoryId {
    // GV.OC-01 -> GV.OC
    final parts = id.split('-');
    if (parts.length >= 2) {
      return parts[0];
    }
    return id;
  }

  String get functionId => id.split('.').first;
  
  String get subcategoryId => id;
}
