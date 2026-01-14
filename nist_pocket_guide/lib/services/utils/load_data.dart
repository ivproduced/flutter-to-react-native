// lib/utils/load_data.dart
/*
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
// Use relative path to import control.dart (assuming it's directly in lib)
import '../control.dart';

// Central function to load and parse the JSON data from the asset file
Future<List<Control>> loadControlData() async {
  try {
    // Ensure the correct asset path is used here!
    final String jsonString = await rootBundle.loadString('assets/controls.json');
    final List<dynamic> jsonList = jsonDecode(jsonString);
    List<Control> controls = jsonList.map((jsonItem) => Control.fromJson(jsonItem as Map<String, dynamic>)).toList();
    return controls;
  } catch (e) {
    // Handle potential errors during loading/parsing
    print("Error loading control data in utility function: $e");
    // Return an empty list or rethrow the error depending on desired handling
    return [];
  }
} */