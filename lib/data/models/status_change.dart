import 'package:cloud_firestore/cloud_firestore.dart';

import 'incident_status.dart';

/// One step on an incident's status timeline.
class StatusChange {
  const StatusChange({
    required this.status,
    required this.changedAt,
    required this.changedBy,
    required this.changedByName,
    this.note = '',
  });

  final IncidentStatus status;
  final DateTime changedAt;
  final String changedBy;
  final String changedByName;
  final String note;

  /// Tolerates missing or wrongly typed fields.
  factory StatusChange.fromMap(Map<String, dynamic> map) => StatusChange(
    status: IncidentStatus.fromName(_string(map['status'])),
    changedAt: switch (map['changedAt']) {
      final Timestamp t => t.toDate(),
      _ => DateTime.now(),
    },
    changedBy: _string(map['changedBy']) ?? '',
    changedByName: _string(map['changedByName']) ?? '',
    note: _string(map['note']) ?? '',
  );

  Map<String, dynamic> toMap() => {
    'status': status.name,
    'changedAt': Timestamp.fromDate(changedAt),
    'changedBy': changedBy,
    'changedByName': changedByName,
    'note': note,
  };

  static String? _string(Object? value) => value is String ? value : null;
}
