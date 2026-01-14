import '../models/oscal_models.dart';

class ControlSearchService {
  static List<Control> searchControls(
    String query,
    List<Control> baseControls,
  ) {
    if (query.isEmpty) return [];
    final lowerQuery = query.toLowerCase();
    final Set<Control> uniqueResults = {};
    for (final baseControl in baseControls) {
      if (_matchesControl(baseControl, lowerQuery)) {
        uniqueResults.add(baseControl);
      }
      for (final enhancement in baseControl.enhancements) {
        if (_matchesControl(enhancement, lowerQuery)) {
          uniqueResults.add(enhancement);
        }
      }
    }
    final List<Control> results = uniqueResults.toList();
    results.sort((a, b) => compareControlIds(a.id, b.id));
    return results;
  }

  static bool _matchesControl(Control control, String query) {
    return control.id.toLowerCase().contains(query) ||
        control.title.toLowerCase().contains(query) ||
        control.statement.toLowerCase().contains(query) ||
        control.discussion.toLowerCase().contains(query);
  }

  static int compareControlIds(String a, String b) {
    RegExp pattern = RegExp(r"([A-Za-z]+)-(\d+)(.*)");
    Match? matchA = pattern.firstMatch(a);
    Match? matchB = pattern.firstMatch(b);
    if (matchA != null && matchB != null) {
      String prefixA = matchA.group(1)!;
      String prefixB = matchB.group(1)!;
      int numA = int.parse(matchA.group(2)!);
      int numB = int.parse(matchB.group(2)!);
      String suffixA = matchA.group(3)!;
      String suffixB = matchB.group(3)!;
      if (prefixA.compareTo(prefixB) != 0) {
        return prefixA.compareTo(prefixB);
      }
      if (numA != numB) {
        return numA.compareTo(numB);
      }
      return suffixA.compareTo(suffixB);
    }
    return a.compareTo(b);
  }
}
