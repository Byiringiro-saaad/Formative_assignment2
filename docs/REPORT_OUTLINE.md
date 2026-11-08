# Technical report outline

A section-by-section outline for the technical report, matching what the brief asks for. Each section lists the points to make and where to find the evidence in this repository. Citations use IEEE style; the reference list is at the end.

**Cover page:** title, your name, course, date, **GitHub link**, **demo video link**.

## 1. Introduction (½ page)
- The problem: campus issues are reported informally (word of mouth, emails) and nobody can see whether they're being handled.
- The solution: one app where students report issues with a category, location and photo, and staff move each report from Submitted → In Progress → Resolved.
- Scope: two roles, four main workflows (authentication, reporting, browsing and filtering, status updates).

## 2. Requirements (½ page)
- Functional requirements from the brief, mapped to features. Use a table: requirement → screen → test that covers it.
- Non-functional: security (role-based access), responsiveness (live updates), usability (validation, empty states), cost (free tiers only).

## 3. Application architecture (1–1½ pages)
- Layered architecture diagram: copy section 1 of `docs/ARCHITECTURE.md`.
- Folder structure and why features are grouped by folder.
- Navigation: `go_router`, the redirect function, and the tab shell (section 3).
- Justify: separating the data layer makes the backend swappable. This is exactly what made it easy to replace Firebase Storage with Supabase.

## 4. Firebase data structure (1 page)
- ER diagram and field table: section 4 of `docs/ARCHITECTURE.md`.
- Decisions to justify:
  - Status history embedded in the incident document (one read, atomic update) rather than a subcollection.
  - `reporterName` denormalised so students never need to read other profiles [1].
  - Composite index for "my reports".
  - Searching on the device instead of in Firestore queries, and why that's fine at campus scale.

## 5. Photo storage decision (½ page)
- Firebase Storage requires the Blaze plan for new projects [2]; the facilitator approved an alternative.
- Supabase Storage with third-party auth trusting Firebase ID tokens [3]: one login, real access control.
- Storage policies (`supabase/storage.sql`): uploads only into your own folder, images only, 5 MB limit.
- Sequence diagram: section 5 of `docs/ARCHITECTURE.md`.

## 6. State management (1 page)
- Why Riverpod [4] over Provider, BLoC and Cubit: compile-safe providers, `AsyncValue` for loading and error states, easy test overrides.
- Provider table: section 2 of `docs/ARCHITECTURE.md`.
- Walk through one flow end to end: tapping **Submit Report** → `SubmitReportController` → `PhotoRepository.upload` → `IncidentRepository.create` → Firestore → `allIncidentsProvider` stream → list updates.

## 7. User roles and access control (1 page)
- Role table: section 6 of `docs/ARCHITECTURE.md`.
- Show the key parts of `firestore.rules`: `isStaff()`, the forward-only status rule, the self-promotion block [5].
- Explain why hiding buttons in the UI isn't enough and the rules are the real enforcement.
- How staff accounts are created (`tool/make_staff.mjs`).

## 8. UI/UX decisions (1 page + screenshots)
- Followed the provided mockups: colour palette, cards, status colours, bottom navigation with the centre Report button.
- Additions and why:
  - Validation messages next to each field; the form keeps its input if submission fails.
  - Photos resized on the device before upload, with replace and remove buttons.
  - Loading, empty and error states on every list.
  - Summary tiles open the list already filtered.
  - Staff notes shown on the timeline; Updates feed with an unread dot.
  - Confirmation dialogs for sign out, withdrawing and status changes.
- Accessibility: semantic labels on icon buttons and category tiles, text that wraps on small screens, colour plus text for status (not colour alone).
- Screenshots: login, home, report form, reports with filters, details timeline, staff update sheet.

## 9. Testing strategy (1 page)
- Testing pyramid table: section 7 of `docs/ARCHITECTURE.md`.
- Numbers: 78 Dart unit and widget tests, 36 security-rule tests (check the final `flutter test` and `npm test` output before submitting).
- Examples worth quoting: "a student cannot promote themselves to staff", "a failed upload keeps the form and shows the error".
- Manual testing on a device.

## 10. Challenges and solutions (½–1 page)
- Firebase Storage needing a paid plan → Supabase Storage with Firebase token trust.
- Supabase normally expects a `role: authenticated` claim, which needs Cloud Functions (also paid) → storage policies that check the Firebase token's issuer, audience and uid directly.
- The Supabase project was first linked to the wrong Firebase project ID (Firebase added a suffix) → found during end-to-end testing.
- Text overflowing on narrow screens, caught by widget tests → wrapping layouts.
- The report form used a lazy `ListView`, so `Form.validate()` skipped fields scrolled off screen and an empty title could be submitted. A widget test caught it; the form now builds every field up front.
- An independent code review found that the create rule didn't check timestamps or the reporter's name: one malformed write could break the list for every user, and reports could be backdated or filed under a fake name. Fixed with stricter rules, server timestamps and defensive parsing, plus a test for each attack.
- The same review found a race between sign-up and the "repair a missing profile" logic that could lose the user's name. Fixed by doing both writes in Firestore transactions.
- Both tabs keep their report cards alive, so a Hero animation found two heroes with the same tag when a report was opened. Caught while generating screenshots; the animation was removed and a regression test added.
- Keeping the photo and the report consistent → upload first, delete the photo if saving the report fails.

## 11. Lessons learned and future work (½ page)
- Security rules and their tests are as important as the UI.
- Designing the data layer behind interfaces paid off when the storage provider changed.
- Future work: push notifications (Firebase Cloud Messaging), assigning reports to specific staff, analytics for administrators, offline drafts.

## 12. Conclusion (short)

## References (IEEE)
[1] Google, "Choose a data structure," *Firebase Documentation*. [Online]. Available: https://firebase.google.com/docs/firestore/manage-data/structure-data

[2] Google, "Firebase pricing plans," *Firebase Documentation*. [Online]. Available: https://firebase.google.com/pricing

[3] Supabase, "Firebase Auth (third-party auth)," *Supabase Docs*. [Online]. Available: https://supabase.com/docs/guides/auth/third-party/firebase-auth

[4] R. Rousselet, "Riverpod documentation." [Online]. Available: https://riverpod.dev

[5] Google, "Get started with Cloud Firestore Security Rules," *Firebase Documentation*. [Online]. Available: https://firebase.google.com/docs/firestore/security/get-started

[6] Flutter team, "go_router package." [Online]. Available: https://pub.dev/packages/go_router

[7] Flutter team, "Testing Flutter apps," *Flutter Documentation*. [Online]. Available: https://docs.flutter.dev/testing/overview

Add the date you accessed each page ("Accessed: Nov. 7, 2026.") as IEEE requires for online sources.
