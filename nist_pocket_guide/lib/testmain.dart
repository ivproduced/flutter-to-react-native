// Flutter app (Web/Mobile/Desktop) to load and display AC-2 parsed data using the OSCAL models
/*
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'models/oscal_models.dart';

void printControlDetails(Control control, StringBuffer buffer) {
  buffer.writeln('--- ${control.id}: ${control.title} ---');

  // Props
  if (control.props.isNotEmpty) {
    buffer.writeln('Props:');
    for (final prop in control.props) {
      buffer.writeln('- ${prop.name}: ${prop.value}');
    }
  }

  // Links
  if (control.links.isNotEmpty) {
    buffer.writeln('Related Controls:');
    for (final link in control.links) {
      buffer.writeln('- ${link.rel}: ${link.href}');
    }
  }

  // Parameters
  if (control.params.isNotEmpty) {
    buffer.writeln('Parameters:');
    for (final param in control.params) {
      buffer.writeln('- ID: ${param.id}');
      if (param.label != null) buffer.writeln('  Label: ${param.label}');
      if (param.usage != null) buffer.writeln('  Usage: ${param.usage}');
    }
  }

  // Statement
  buffer.writeln('Statement:');
  for (final part in control.parts.where((p) => p.isStatement)) {
    printPartProse(buffer, part);
  }

  // Guidance
  buffer.writeln('Guidance:');
  for (final part in control.parts.where((p) => p.isGuidance)) {
    printPartProse(buffer, part);
  }

  // Assessment Objectives
  buffer.writeln('Assessment Objectives:');
  for (final part in control.parts.where((p) => p.isAssessmentObjective)) {
    printPartProse(buffer, part);
  }

  // Assessment Methods
  buffer.writeln('Assessment Methods:');
  for (final method in control.parts.where((p) => p.isAssessmentMethod)) {
    printPartProse(buffer, method);
  }

  // Evidence Expectations
  buffer.writeln('Evidence Expectations:');
  for (final method in control.parts.where((p) => p.isAssessmentMethod)) {
    for (final evidence in method.subparts.where((sp) => sp.isEvidence)) {
      printPartProse(buffer, evidence);
    }
  }

  // Enhancements
  if (control.enhancements.isNotEmpty) {
    buffer.writeln('--- Enhancements ---');
    for (final enhancement in control.enhancements) {
      buffer.writeln('> Enhancement: ${enhancement.id} - ${enhancement.title}');
      printControlDetails(enhancement, buffer); // Recursive call!
    }
  }
}

// Corrected printPartProse() function that handles labels from props

void printPartProse(StringBuffer buffer, Part part, [String indent = '']) {
  String? label;

  // Check if part has a label in its props
  for (final prop in part.props) {
    if (prop.name == 'label') {
      label = prop.value;
      break;
    }
  }

  if (part.prose != null) {
    if (label != null) {
      buffer.writeln('$indent$label ${part.prose}');
    } else {
      buffer.writeln('$indent- ${part.prose}');
    }
  }

  // Recursively print subparts
  for (final sub in part.subparts) {
    printPartProse(buffer, sub, '$indent  ');
  }
}



void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('AC-2 Control Viewer')),
        body: const Center(
          child: AC2Display(),
        ),
      ),
    );
  }
}

class AC2Display extends StatefulWidget {
  const AC2Display({super.key});

  @override
  State<AC2Display> createState() => _AC2DisplayState();
}

class _AC2DisplayState extends State<AC2Display> {
  String output = 'Loading...';

  @override
  void initState() {
    super.initState();
    loadAC2();
  }
Control? findControl(Catalog catalog, String id) {
  for (final control in catalog.controls) {
    if (control.id.toLowerCase() == id.toLowerCase()) return control;
  }
  for (final group in catalog.groups) {
    for (final control in group.controls) {
      if (control.id.toLowerCase() == id.toLowerCase()) return control;
    }
  }
  return null;
}

  Future<void> loadAC2() async {
  try {
    final jsonString = await rootBundle.loadString('assets/NIST_SP-800-53_rev5_catalog.json');
    final catalogJson = jsonDecode(jsonString);
    final catalog = Catalog.fromJson(catalogJson);

    final Control? ac2 = findControl(catalog, 'ac-2');
    if (ac2 == null) {
      setState(() {
        output = 'AC-2 not found.';
      });
      return;
    }

    final buffer = StringBuffer();
    printControlDetails(ac2, buffer); // <--- use corrected logic!

    setState(() {
      output = buffer.toString();
    });
  } catch (e) {
    setState(() {
      output = 'Error loading AC-2: $e';
    });
  }
}
 @override
Widget build(BuildContext context) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Text(output),
  );
}

}
*/
