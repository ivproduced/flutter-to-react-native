import 'package:nist_pocket_guide/models/oscal_models.dart';

// Helper to get display label (should be consistent with other screens)
String getObjectiveDisplayLabel(Part objectivePart) {
  try {
    final labelProp = objectivePart.props.firstWhere((prop) => prop.name.toLowerCase() == 'label');
    return labelProp.value;
  } catch (e) {
    return objectivePart.id ?? objectivePart.name;
  }
}

String getObjectiveKey(Part objectivePart) {
    if (objectivePart.id != null && objectivePart.id!.isNotEmpty) {
      return objectivePart.id!;
    }
    return "ac-2_proseHash_${(objectivePart.prose ?? '').hashCode}"; // Assuming a default control ID
  }