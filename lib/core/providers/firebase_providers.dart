import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/incident_repository.dart';
import '../../data/repositories/photo_repository.dart';
import '../../data/repositories/user_repository.dart';

// Backend clients. Tests override these with fakes, so nothing below talks
// to a real service unless the app is running for real.
final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

// Repositories: the only layer that knows about Firebase and Supabase.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(firebaseAuthProvider)),
);

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(ref.watch(firestoreProvider)),
);

final incidentRepositoryProvider = Provider<IncidentRepository>(
  (ref) => IncidentRepository(ref.watch(firestoreProvider)),
);

final photoRepositoryProvider = Provider<PhotoRepository>(
  (ref) => SupabasePhotoRepository(Supabase.instance.client),
);
