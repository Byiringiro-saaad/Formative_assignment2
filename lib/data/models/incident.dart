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

  factory Incident.fromMap(String id, Map<String, dynamic> map) {
    final created =
        (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    return Incident(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: IncidentCategory.fromName(map['category'] as String?),
      location: map['location'] as String? ?? '',
      status: IncidentStatus.fromName(map['status'] as String?),
      reporterId: map['reporterId'] as String? ?? '',
      reporterName: map['reporterName'] as String? ?? '',
      createdAt: created,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? created,
      photoUrl: map['photoUrl'] as String?,
      photoPath: map['photoPath'] as String?,
      history: ((map['history'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(StatusChange.fromMap)
          .toList(),
    );
  }

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
