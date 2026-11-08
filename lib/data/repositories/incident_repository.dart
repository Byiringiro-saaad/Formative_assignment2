import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/incident.dart';
import '../models/incident_category.dart';
import '../models/incident_status.dart';
import '../models/status_change.dart';

/// All Firestore access for incident reports.
class IncidentRepository {
  IncidentRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _incidents =>
      _db.collection('incidents');

  /// Generates an id up front so a photo can be uploaded under it first.
  String newId() => _incidents.doc().id;

  /// Every incident, newest first. Students and staff can both browse these.
  Stream<List<Incident>> watchAll() => _incidents
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Incident.fromDoc).toList());

  /// Incidents reported by [uid], newest first.
  Stream<List<Incident>> watchByReporter(String uid) => _incidents
      .where('reporterId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Incident.fromDoc).toList());

  /// A single incident, or null once it has been deleted.
  Stream<Incident?> watchById(String id) => _incidents
      .doc(id)
      .snapshots()
      .map((doc) => doc.exists ? Incident.fromDoc(doc) : null);

  /// Saves a new report with status [IncidentStatus.submitted].
  Future<Incident> create({
    required String id,
    required AppUser reporter,
    required String title,
    required String description,
    required IncidentCategory category,
    required String location,
    String? photoUrl,
    String? photoPath,
    bool anonymous = false,
    DateTime? now,
  }) async {
    final at = now ?? DateTime.now();
    // Anonymous reports never store the name, so no student can read it.
    final name = anonymous ? Incident.anonymousName : reporter.name;
    final incident = Incident(
      id: id,
      title: title.trim(),
      description: description.trim(),
      category: category,
      location: location.trim(),
      status: IncidentStatus.submitted,
      reporterId: reporter.uid,
      reporterName: name,
      createdAt: at,
      updatedAt: at,
      photoUrl: photoUrl,
      photoPath: photoPath,
      history: [
        StatusChange(
          status: IncidentStatus.submitted,
          changedAt: at,
          changedBy: reporter.uid,
          changedByName: name,
        ),
      ],
      anonymous: anonymous,
    );
    // createdAt/updatedAt use server time: the security rules require it,
    // so nobody can backdate a report.
    await _incidents.doc(id).set({
      ...incident.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return incident;
  }

  /// Moves an incident to [status] and appends the change to its timeline.
  /// Only staff are allowed to do this by the security rules.
  Future<void> updateStatus({
    required Incident incident,
    required IncidentStatus status,
    required AppUser staff,
    String note = '',
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    final change = StatusChange(
      status: status,
      changedAt: at,
      changedBy: staff.uid,
      changedByName: staff.name,
      note: note.trim(),
    );
    return _incidents.doc(incident.id).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'history': FieldValue.arrayUnion([change.toMap()]),
    });
  }

  /// Reporters may withdraw a report while it is still `submitted`.
  Future<void> delete(String id) => _incidents.doc(id).delete();
}
