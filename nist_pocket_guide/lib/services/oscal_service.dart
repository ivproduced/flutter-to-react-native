// lib/services/oscal_service.dart
import 'dart:convert';
import 'package:flutter/material.dart'; // Keep for TextStyle if needed by substituteBlockValuesAndStyle
import 'package:intl/intl.dart';
import 'package:nist_pocket_guide/app_data_manager.dart';
import 'package:nist_pocket_guide/models/baseline_profile.dart';
import 'package:nist_pocket_guide/models/information_system.dart';
import 'package:nist_pocket_guide/models/llm_objective_data.dart';
import 'package:nist_pocket_guide/models/oscal_models.dart';
// Import specific functions needed and LlmControlObjectiveData if passed or fetched
import 'package:nist_pocket_guide/ssp_generator_screens/ssp_statement_template_utils.dart' 
    show substituteBlockValuesAndStyle; // Or just what's needed
import 'package:uuid/uuid.dart';


// We'll need _replacePlaceholdersPlainText. It's currently private in ssp_statement_templates.
// For now, let's assume we can make it public or replicate its logic here if necessary.
// OR, we pass all data to getFinalStatementForControl and use its output.
// For this iteration, let's focus on modifying the objective part directly.
// We need access to LlmControlObjectiveData and LlmObjectiveStatement models.
// Helper function to replace placeholders in a template string with given values.
// This is similar to _replacePlaceholdersPlainText from ssp_statement_templates.dart
// It expects keys in 'values' to be WITHOUT brackets.


String _fillLlmTemplate(String template, Map<String, String> filledValues) {
  if (template.isEmpty) return "";
  StringBuffer sb = StringBuffer();
  RegExp placeholderRegExp = RegExp(r"\[([^\]]+)\]"); // Matches "[PlaceholderKey]"
  int currentIndex = 0;

  for (Match match in placeholderRegExp.allMatches(template)) {
    sb.write(template.substring(currentIndex, match.start)); // Text before placeholder
    
    String placeholderKey = match.group(1)!; // Key inside brackets (e.g., "AssignedRole")
    String value = filledValues[placeholderKey]?.trim() ?? ""; // Look up by key *without* brackets
    
    if (value.isNotEmpty) {
      sb.write(value);
    } else {
      // If value is empty or not found, show the original placeholder with an indicator
      sb.write("${match.group(0)!} (Needs Input)"); 
    }
    currentIndex = match.end;
  }
  sb.write(template.substring(currentIndex)); // Remaining text
  return sb.toString();
}


class OscalService {

  // This helper is fine as is, assuming substituteBlockValuesAndStyle returns List<TextSpan>
  static String _spansToPlainText(List<InlineSpan> spans) {
    StringBuffer buffer = StringBuffer();
    for (var span in spans) {
      if (span is TextSpan) {
        buffer.write(span.text);
        // Recursively handle children if TextSpan can have nested TextSpan children
        if (span.children != null) {
          for (var childSpan in span.children!) {
            if (childSpan is TextSpan) { // Check type again
              buffer.write(childSpan.text);
            }
            // If childSpan could be other InlineSpan types, handle them or use a recursive call
          }
        }
      }
      // Handle other InlineSpan types like WidgetSpan if necessary
    }
    return buffer.toString();
  }

  static String generateOscalJson(
    InformationSystem system,
    List<Control> baselineControlsAndSelectedEnhancements,
    AppDataManager appDataManager, // Pass AppDataManager to access LLM data
  ) {
    String getCurrentTimestamp() => DateFormat("yyyy-MM-dd'T'HH:mm:ssXXX").format(DateTime.now().toUtc());
    const uuidGen = Uuid();
    final String companyName = system.companyAgencyName?.isNotEmpty == true ? system.companyAgencyName! : "The organization";

    // Dummy TextStyles for substituteBlockValuesAndStyle (if it's still used for mainImpl)
    const TextStyle dummyNormalStyle = TextStyle();
    const TextStyle dummySubstitutedStyle = TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic);

    List<Map<String, dynamic>> implementedRequirements = [];

    for (var control in baselineControlsAndSelectedEnhancements) {
      final mainImpl = system.controlImplementations[control.id] ?? ControlImplementation(status: 'Not Implemented');
      final objectiveResponses = system.assessmentObjectiveResponses[control.id] ?? [];
      
      // Get LLM data for this control
      final LlmControlObjectiveData? llmControlData = appDataManager.getLlmObjectiveDataForControl(control.id);
      
      List<Map<String, dynamic>> controlStatements = [];

      // Main implementation detail
      // Assuming mainImpl.implementationDetails might use [placeholders] filled by systemParameterBlockValues
      if (mainImpl.implementationDetails.trim().isNotEmpty) {

        
        // If mainImpl.implementationDetails uses the same [placeholder] style as LLM statements,
        // AND its placeholders are defined in system.systemParameterBlockValues, then this is fine.
        // The keys in system.systemParameterBlockValues must be *without* brackets for substituteBlockValuesAndStyle.
        List<InlineSpan> mainImplSpans = substituteBlockValuesAndStyle(
            mainImpl.implementationDetails.trim(),
            system.systemParameterBlockValues, // These are global system-wide key-value pairs
            companyName,
            dummyNormalStyle,
            dummySubstitutedStyle);
        controlStatements.add({
          'uuid': uuidGen.v4(),
          'statement-id': '${control.id}_stmt_main-implementation', // Unique ID for this statement
          'description': _spansToPlainText(mainImplSpans),
        });
      }

      // Assessment objective responses
      for (var objResp in objectiveResponses) {
        String objectiveStatementDescriptionPlainText;
        if (objResp.isMet) {
          // NEW LOGIC: Use LLM generated statements
          String llmTemplate = "This objective (${objResp.objectiveKey}) is met. Details derived from primary control documentation."; // Default fallback
          
          if (llmControlData != null) {
            final matchingLlmStatement = llmControlData.llmGeneratedObjectiveStatements.firstWhere(
                (stmt) => stmt.objectiveId == objResp.objectiveKey, // Match by objectiveKey
                orElse: () => LlmObjectiveStatement(objectiveId: '', objectiveProseOriginal: '', llmGeneratedStatement: '', llmGeneratedQuestion: '', placeholders: []) // Dummy
            );

            if (matchingLlmStatement.objectiveId.isNotEmpty) {
              llmTemplate = matchingLlmStatement.llmGeneratedStatement; // Get the template

              // Get user-filled values for this specific LLM objective
              // llmObjectivePlaceholderValues stores keys WITH brackets, e.g., "[AssignedRole]"
              final Map<String, String> userFilledValuesWithBrackets = 
                  mainImpl.llmObjectivePlaceholderValues[objResp.objectiveKey] ?? {};
              
              // Transform keys to be WITHOUT brackets for _fillLlmTemplate helper
              Map<String, String> userFilledValuesWithoutBrackets = {};
              userFilledValuesWithBrackets.forEach((keyWithBrackets, value) {
                  userFilledValuesWithoutBrackets[keyWithBrackets.replaceAll('[','').replaceAll(']','')] = value;
              });

              objectiveStatementDescriptionPlainText = _fillLlmTemplate(llmTemplate, userFilledValuesWithoutBrackets);
            } else {
              // No specific LLM template found for this objectiveKey, use a generic statement
              objectiveStatementDescriptionPlainText = 
                  "Objective ${objResp.objectiveKey} is met based on overall control implementation.";
            }
          } else {
            // No LLM data for the entire control, use generic statement
            objectiveStatementDescriptionPlainText = 
                "Objective ${objResp.objectiveKey} is met. LLM data not available for this control.";
          }
          
          if (objResp.userNotes != null && objResp.userNotes!.trim().isNotEmpty) {
            objectiveStatementDescriptionPlainText += "\n  ADDITIONAL NOTES/DEVIATIONS: ${objResp.userNotes!.trim()}";
          }
        } else { // Objective is NOT met
          String proseSnippet = objResp.objectiveProse;
          if (proseSnippet.length > 70) proseSnippet = "${proseSnippet.substring(0, 67)}...";
          proseSnippet = proseSnippet.replaceAll('\n', ' ').replaceAll(RegExp(r'\\s+'), ' ');
          objectiveStatementDescriptionPlainText = "This objective \"$proseSnippet\" (${objResp.objectiveKey}) is currently NOT MET.";
           if (objResp.userNotes != null && objResp.userNotes!.trim().isNotEmpty) {
            objectiveStatementDescriptionPlainText += "\n  REASON/NOTES: ${objResp.userNotes!.trim()}";
          }
        }
        controlStatements.add({
          'uuid': uuidGen.v4(),
          'statement-id': objResp.objectiveKey, // This is the Part.id for the objective
          'description': objectiveStatementDescriptionPlainText,
          'props': [ // Retaining your original props structure for objectives
            {'name': 'objective-key', 'value': objResp.objectiveKey},
            // 'objective-prose-snapshot' might be redundant if description covers it, but kept for now
            {'name': 'objective-prose-snapshot', 'value': objResp.objectiveProse}, 
            {'name': 'objective-is-met', 'value': objResp.isMet.toString()},
          ]
        });
      }
      
      implementedRequirements.add({
        'uuid': uuidGen.v4(),
        'control-id': control.id,
        'description': 'Implementation for control ${control.id} in system ${system.name}.',
        'props': [{'name': 'status', 'value': mainImpl.status}],
        'links': mainImpl.evidence
            .map((e) => {'href': e, 'rel': 'evidence'})
            .where((link) => (link['href'] as String).isNotEmpty)
            .toList(),
        // Only add 'statements' array if it's not empty
        'statements': controlStatements.isNotEmpty ? controlStatements : null, 
      });

      // --- Enhancement Processing (Simplified for brevity, apply similar LLM logic if needed) ---
      final appDataManagerForEnh = AppDataManager.instance; // Or pass if already available
      BaselineProfile? selectedProfile;
      if(system.selectedBaselineId != null) {
        selectedProfile = _getSelectedProfile(appDataManagerForEnh, system.selectedBaselineId!);
      }
      if (selectedProfile != null) {
        for (var enhControl in control.enhancements) {
          final normEnhId = enhControl.id.toLowerCase(); // Your OSCAL model stores ID as lowercase
          // Assuming selectedControlIds in BaselineProfile are also stored/compared as lowercase
          if (selectedProfile.selectedControlIds.map((id) => id.toLowerCase()).contains(normEnhId)) {
            final enhImpl = system.controlImplementations[enhControl.id] ??
                ControlImplementation(status: 'Not Implemented');
            final enhObjectiveResponses = system.assessmentObjectiveResponses[enhControl.id] ?? [];
            List<Map<String, dynamic>> enhancementControlStatements = [];

            // Main implementation for enhancement
            if (enhImpl.implementationDetails.trim().isNotEmpty) {
                List<InlineSpan> enhMainSpans = substituteBlockValuesAndStyle(
                    enhImpl.implementationDetails.trim(),
                    system.systemParameterBlockValues,
                    companyName,
                    dummyNormalStyle,
                    dummySubstitutedStyle);
                enhancementControlStatements.add({
                    'uuid': uuidGen.v4(),
                    'statement-id': '${enhControl.id}_stmt_main-implementation',
                    'description': _spansToPlainText(enhMainSpans),
                });
            }
            
            // Objective statements for enhancement (NEEDS LLM LOGIC similar to main control)
            final LlmControlObjectiveData? enhLlmControlData = appDataManager.getLlmObjectiveDataForControl(enhControl.id);
            for (var enhObjResp in enhObjectiveResponses) {
                String enhObjDescPlainText;
                if (enhObjResp.isMet) {
                    String enhLlmTemplate = "Enhancement objective ${enhObjResp.objectiveKey} met."; // Fallback
                    if (enhLlmControlData != null) {
                        final matchingEnhLlmStmt = enhLlmControlData.llmGeneratedObjectiveStatements.firstWhere(
                            (s) => s.objectiveId == enhObjResp.objectiveKey, orElse: () => LlmObjectiveStatement(objectiveId: '', objectiveProseOriginal: '', llmGeneratedStatement: '', llmGeneratedQuestion: '', placeholders: []));
                        if (matchingEnhLlmStmt.objectiveId.isNotEmpty) {
                            enhLlmTemplate = matchingEnhLlmStmt.llmGeneratedStatement;
                            final enhUserFilledValsWB = enhImpl.llmObjectivePlaceholderValues[enhObjResp.objectiveKey] ?? {};
                            Map<String, String> enhUserFilledValsWOB = {};
                            enhUserFilledValsWB.forEach((k,v) => enhUserFilledValsWOB[k.replaceAll('[','').replaceAll(']','')] = v);
                            enhObjDescPlainText = _fillLlmTemplate(enhLlmTemplate, enhUserFilledValsWOB);
                        } else {
                             enhObjDescPlainText = "Enhancement objective ${enhObjResp.objectiveKey} is met based on overall control implementation.";
                        }
                    } else {
                        enhObjDescPlainText = "Enhancement objective ${enhObjResp.objectiveKey} is met. LLM data not available for this enhancement.";
                    }
                     if (enhObjResp.userNotes != null && enhObjResp.userNotes!.trim().isNotEmpty) {
                        enhObjDescPlainText += "\n  ADDITIONAL NOTES/DEVIATIONS: ${enhObjResp.userNotes!.trim()}";
                    }
                } else {
                    enhObjDescPlainText = "Enhancement objective ${enhObjResp.objectiveKey} NOT MET. Notes: ${enhObjResp.userNotes ?? ''}";
                }
                enhancementControlStatements.add({
                    'uuid': uuidGen.v4(),
                    'statement-id': enhObjResp.objectiveKey,
                    'description': enhObjDescPlainText,
                    'props': [ /* ... props for enh objResp ... */ ]
                });
            }

            if (enhancementControlStatements.isNotEmpty) { // Or check enhImpl.implementationDetails as well
              implementedRequirements.add({
                'uuid': uuidGen.v4(),
                'control-id': enhControl.id,
                'description': 'Implementation for enhancement ${enhControl.id}.',
                'props': [{'name': 'status', 'value': enhImpl.status}],
                'statements': enhancementControlStatements,
              });
            }
          }
        }
      }
    }
    // Clean up any implemented-requirement if its 'statements' array ended up being null or empty
    for (var req in implementedRequirements) {
        if (req['statements'] == null || (req['statements'] is List && (req['statements'] as List).isEmpty)) {
            req.remove('statements');
        }
    }
    // --- END of Implemented Requirements logic ---


    // --- Build the OSCAL SSP Document (Structure seems fine) ---
    final List<Map<String, dynamic>> parties = [
      {
        'uuid': uuidGen.v4(),
        'type': 'organization',
        'name': companyName
      }
    ];
    final String firstPartyUuid = parties.first['uuid'];

    Map<String, dynamic> oscalSsp = {
      'system-security-plan': {
        'uuid': system.id, // Use system's actual ID if it's a UUID, otherwise generate one.
        'metadata': {
          'title': 'System Security Plan for ${system.name}',
          'last-modified': getCurrentTimestamp(),
          'version': '1.0.0', // Consider making this dynamic or configurable
          'oscal-version': '1.1.2', // Or your target OSCAL version
          'parties': parties,
          'responsible-parties': [
            {
              'role-id': 'system-owner', 
              'party-uuids': [firstPartyUuid] 
            }
            // Add other responsible parties as needed
          ],
          'roles': [ 
            {'id': 'system-owner', 'title': 'System Owner'},
            // Define other roles here
          ],
        },
        'import-profile': {
          'href': system.selectedBaselineId != null
              ? 'urn:uuid:${BaselineProfile.generateUuidFromName(system.selectedBaselineId!)}' // Example URN
              : 'urn:uri:profile-not-specified', // Fallback URN
          'remarks': system.selectedBaselineId != null
              ? 'System implements controls from the ${system.selectedBaselineId} baseline profile.'
              : 'No specific baseline profile specified.',
        },
        'system-characteristics': {
          'system-ids': [{'identifier-type': 'local-system-id', 'id': system.id}],
          'system-name': system.name,
          'description': system.description,
          'status': {'state': system.atoStatus.toLowerCase().replaceAll(' ', '-')},
          // Only add props if notes are not empty
          if (system.notes.trim().isNotEmpty) 'props': [{'name': 'general-system-notes', 'value': system.notes.trim()}],
        },
        'system-implementation': {
          'description': 'Describes how security controls are implemented for ${system.name}.',
          'components': [ // Define at least one component
            {
              'uuid': uuidGen.v4(), // UUID for this component
              'type': 'this-system', // Standard OSCAL component type
              'title': system.name,
              'description': 'The primary logical component representing the ${system.name}.',
              'status': {'state': 'operational'}, // Or another appropriate status
              // Add responsible-roles if applicable
            }
          ],
          // Only add implemented-requirements if it's not empty
          if (implementedRequirements.isNotEmpty) 'implemented-requirements': implementedRequirements,
        },
      }
    };
    
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(oscalSsp);
  }

  // _getSelectedProfile seems fine, assuming BaselineProfile has a static method for UUID generation if needed
  static BaselineProfile? _getSelectedProfile(AppDataManager adm, String baselineId) {
    // Normalize comparison if IDs might have case differences
    final String targetIdLower = baselineId.toLowerCase();

    if (adm.lowBaseline.id.toLowerCase() == targetIdLower) return adm.lowBaseline;
    if (adm.moderateBaseline.id.toLowerCase() == targetIdLower) return adm.moderateBaseline;
    if (adm.highBaseline.id.toLowerCase() == targetIdLower) return adm.highBaseline;
    if (adm.privacyBaseline.id.toLowerCase() == targetIdLower) return adm.privacyBaseline;
    try {
      return adm.userBaselines.firstWhere((b) => b.id.toLowerCase() == targetIdLower);
    } catch (e) {
      return null;
    }
  }

  static BaselineProfile? getSelectedProfile(AppDataManager adm, String baselineId) {
    return _getSelectedProfile(adm, baselineId);
  }
}