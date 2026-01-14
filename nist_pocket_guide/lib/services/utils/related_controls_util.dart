import '../../models/oscal_models.dart'; // Adjust path if needed

List<String> getRelatedClontrolIds(Control control) {
  return control.links
      .where((link) => link.rel?.toLowerCase() == 'related')
      .map((link) => link.href.replaceFirst('#', '').toLowerCase())
      .toList();
}
