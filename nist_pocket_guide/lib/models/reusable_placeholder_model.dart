// lib/models/reusable_placeholder_value.dart
import 'package:uuid/uuid.dart';

var _uuid = Uuid();

class ReusablePlaceholderValue {
  final String id;
  final String value; // The actual text value saved by the user
  final String? associatedPlaceholderLabel; // Optional: To know which placeholder label this was saved from (e.g., "[Assigner]")
  final DateTime createdAt;

  ReusablePlaceholderValue({
    String? id,
    required this.value,
    this.associatedPlaceholderLabel,
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  // For saving to SharedPreferences (or other storage)
  Map<String, dynamic> toJson() => {
        'id': id,
        'value': value,
        'associatedPlaceholderLabel': associatedPlaceholderLabel,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ReusablePlaceholderValue.fromJson(Map<String, dynamic> json) =>
      ReusablePlaceholderValue(
        id: json['id'] as String,
        value: json['value'] as String,
        associatedPlaceholderLabel: json['associatedPlaceholderLabel'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReusablePlaceholderValue &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => value; // For easy display in Dropdown items
}