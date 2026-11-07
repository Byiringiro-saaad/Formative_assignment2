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

  factory StatusChange.fromMap(Map<String, dynamic> map) => StatusChange(
    status: IncidentStatus.fromName(map['status'] as String?),
    changedAt: (map['changedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    changedBy: map['changedBy'] as String? ?? '',
    changedByName: map['changedByName'] as String? ?? '',
    note: map['note'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    'status': status.name,
    'changedAt': Timestamp.fromDate(changedAt),
    'changedBy': changedBy,
    'changedByName': changedByName,
    'note': note,
  };
}
