# Campus Incidents

A Flutter app for reporting campus issues: broken facilities, water shortages, power outages, damaged furniture, sanitation problems and safety concerns. Students submit reports with an optional photo and track them until they're resolved. Authorised staff review the reports and update their status.

## Tech stack

| Concern | Choice |
|---|---|
| UI | Flutter (Material 3), bundled Plus Jakarta Sans font |
| State management | Riverpod |
| Navigation | go_router |
| Authentication | Firebase Authentication (email and password) |
| Database | Cloud Firestore |
| Photo storage | Supabase Storage (see below) |

### Why Supabase for photos

Firebase Storage now requires the paid Blaze plan for new projects. With the facilitator's agreement, photos are stored in a Supabase Storage bucket on Supabase's free plan instead. Supabase is configured to trust Firebase ID tokens (third-party auth), so users still sign in only once. The storage policies in [`supabase/storage.sql`](supabase/storage.sql) only accept uploads from a valid Firebase user of this project, and only into that user's own folder.

## Project structure

```
lib/
  core/        configuration, theme, shared utilities
  data/        models and repositories (Firebase and Supabase access)
  features/    one folder per feature (auth, home, reports, ...)
  shared/      reusable widgets
supabase/      storage bucket and access policies
test/          unit and widget tests
```

## Running the app

```bash
flutter pub get
flutter run
```

The Firebase configuration (`lib/firebase_options.dart`, `android/app/google-services.json`) and the Supabase publishable key are client-side values. They're meant to be shipped in the app and are protected by the Firestore security rules and the Supabase storage policies.

## Tests

```bash
flutter analyze
flutter test
```
