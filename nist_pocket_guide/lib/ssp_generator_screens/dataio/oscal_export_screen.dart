// lib/screens/oscal_export_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for Clipboard

class OscalExportScreen extends StatelessWidget {
  final String oscalData; // The generated OSCAL JSON string
  final String format;    // To display "JSON" or "XML" in the title

  const OscalExportScreen({
    super.key,
    required this.oscalData,
    this.format = "JSON", // Default to JSON
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OSCAL Export ($format)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all_outlined),
            tooltip: 'Copy to Clipboard',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: oscalData));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('OSCAL $format data copied to clipboard!')),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0), // Add some padding around the ScrollView
        child: SingleChildScrollView( // Makes the content scrollable
          child: Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800] // Darker background for dark theme
                  : Colors.grey[200], // Lighter background for light theme
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: SelectableText(
              oscalData.isEmpty ? "No OSCAL data generated." : oscalData,
              style: TextStyle(
                fontFamily: 'monospace', // Good for structured data like JSON/XML
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyLarge?.color, // Respect theme text color
              ),
            ),
          ),
        ),
      ),
    );
  }
}