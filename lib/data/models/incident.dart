import 'package:cloud_firestore/cloud_firestore.dart';

import 'incident_category.dart';
import 'incident_status.dart';
import 'status_change.dart';

/// An incident report stored at `incidents/{id}`.
class Incident {
  const Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.status,
    required this.reporterId,
    required this.reporterName,
    required this.createdAt,
    required this.updatedAt,
    this.photoUrl,
    this.photoPath,
    this.history = const [],
  });

  final String id;
  final String title;
  final String description;
  final IncidentCategory category;
  final String location;
  final IncidentStatus status;
  final String reporterId;
  final String reporterName;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Public URL of the photo in Supabase Storage, if one was attached.
  final String? photoUrl;

  /// Object path inside the storage bucket, used to delete the photo.
  final String? photoPath;

  /// Every status the incident has been in, oldest first.
  final List<StatusChange> history;

  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  /// When the incident entered [s], or null if it hasn't yet.
  DateTime? reachedAt(IncidentStatus s) {
    for (final change in history) {
      if (change.status == s) return change.changedAt;
    }
    return null;
  }

  /// Case-insensitive match against the title, description and location.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return title.toLowerCase().contains(q) ||
        description.toLowerCase().contains(q) ||
        location.toLowerCase().contains(q) ||
        category.label.toLowerCase().contains(q);
  }

  factory Incident.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Incident.fromMap(doc.id, doc.data() ?? const {});

  /// Tolerates missing or wrongly typed fields, so one malformed document
  /// can never break a whole list of reports.
  factory Incident.fromMap(String id, Map<String, dynamic> map) {
    final created = _date(map['createdAt']) ?? DateTime.now();
    return Incident(
      id: id,
      title: _string(map['title']) ?? '',
      description: _string(map['description']) ?? '',
      category: IncidentCategory.fromName(_string(map['category'])),
      location: _string(map['location']) ?? '',
      status: IncidentStatus.fromName(_string(map['status'])),
      reporterId: _string(map['reporterId']) ?? '',
      reporterName: _string(map['reporterName']) ?? '',
      createdAt: created,
      updatedAt: _date(map['updatedAt']) ?? created,
      photoUrl: _string(map['photoUrl']),
      photoPath: _string(map['photoPath']),
      history: [
        if (map['history'] case final List<dynamic> entries)
          for (final entry in entries)
            if (entry is Map)
              StatusChange.fromMap(Map<String, dynamic>.from(entry)),
      ],
    );
  }

  static String? _string(Object? value) => value is String ? value : null;

  static DateTime? _date(Object? value) =>
      value is Timestamp ? value.toDate() : null;

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'category': category.name,
    'location': location,
    'status': status.name,
    'reporterId': reporterId,
    'reporterName': reporterName,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'photoUrl': photoUrl,
    'photoPath': photoPath,
    'history': history.map((h) => h.toMap()).toList(),
  };
}
