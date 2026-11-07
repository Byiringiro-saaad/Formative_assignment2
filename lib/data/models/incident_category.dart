import 'package:flutter/material.dart';

/// The kinds of campus issue a student can report.
enum IncidentCategory {
  facilities('Facilities', Icons.apartment_rounded),
  water('Water', Icons.water_drop_outlined),
  electricity('Electricity', Icons.bolt_rounded),
  safety('Safety', Icons.shield_outlined),
  sanitation('Sanitation', Icons.delete_outline_rounded),
  furniture('Furniture', Icons.chair_outlined);

  const IncidentCategory(this.label, this.icon);

  final String label;
  final IconData icon;

  /// Parses the value stored in Firestore. Unknown values become
  /// [facilities] so an old or corrupted document never crashes the UI.
  static IncidentCategory fromName(String? name) =>
      IncidentCategory.values.firstWhere(
        (c) => c.name == name,
        orElse: () => IncidentCategory.facilities,
      );
}
