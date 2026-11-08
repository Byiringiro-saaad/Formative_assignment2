# Demo video script (7–10 minutes)

The brief asks the video to show authentication, submitting a report, browsing and filtering, and a staff member updating a status. The rubric also asks you to show the Firebase Console records and to explain your design decisions. This script covers all of that in about 9½ minutes.

## Before recording

1. Load the demo data (needs the Firebase service-account key):
   ```bash
   cd tool && npm install
   GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json node seed_demo.mjs
   ```
2. Demo accounts (password `Campus2026`):
   - Student: `demo.amina@alustudent.com`
   - Student: `demo.brian@alustudent.com`
   - Staff: `demo.grace@alueducation.com`
3. For the sign-up scene you need a real ALU inbox you can open on camera, because the app sends a real verification email. Use your own `@alustudent.com` address. If you've already signed up with it, delete that account under **Authentication → Users** in the Firebase Console first.
4. Have a photo of a campus problem ready on the phone or simulator (for example a broken chair or leaking tap).
5. Open the Firebase Console in a browser tab: **Authentication → Users** and **Firestore Database → incidents**.
6. Start the app signed out.

## Script

| Time | Scene | What to show and say |
|---|---|---|
| 0:00 | Intro | Name, course, and one sentence: "Campus Incidents lets students report campus problems and staff track them to resolution." Mention Flutter, Riverpod, Firebase Auth, Firestore and Supabase Storage. |
| 0:30 | Sign up | Tap **Sign up**. Submit the empty form to show validation. Enter a Gmail address to show "Use your ALU email". Then sign up with your ALU email. Point out that everyone signs up as a student. |
| 1:15 | Verify email | The app stops on **Verify your email**. Tap **I've Verified My Email** first to show it refuses. Open the email, tap the link, come back and tap the button again: the app opens. In the Firebase Console, show the new user under **Authentication → Users** and their profile under **Firestore → users**. Explain that the security rules also refuse unverified and non-ALU accounts, so skipping the screen in a modified app gains nothing. |
| 2:00 | Sign out and sign in | Sign out from Profile (confirm dialog). Sign in as Amina with a wrong password to show the error message, then the correct one. |
| 2:15 | Home | Greeting, the summary tiles (tap **In Progress** to show it opens the filtered list), recent reports. |
| 3:00 | Submit a report | Tap the centre **Report** button. Tap **Submit Report** empty to show validation. Pick **Furniture**, enter a title and description, choose **Block C**, attach a photo from the gallery, submit. The app opens the new report: Submitted on the timeline, photo attached. Show the new document in **Firestore → incidents** and explain its fields and the embedded `history`. |
| 4:00 | Anonymous report | Open the form again and point out **Hide my name from other students**. Explain why: safety or harassment reports are easier to make when other students can't see your name, but staff still need to follow up. Open **Main gate light not working** (an anonymous demo report): it says "Reported anonymously". |
| 4:15 | Browse and filter | Go to **Reports**. Search "light". Clear it. Tap **Submitted**, then **Electricity**. Switch between **All campus** and **My reports**. Show the empty state and **Clear filters**. |
| 5:15 | Details | Open **Broken classroom projector**: header, timeline, staff note, description. Open a report with a photo and pinch to zoom. |
| 5:45 | Staff sign in | Sign out, sign in as Grace (staff). Point out the Staff badge, "Campus Summary" and "Review Reports". Open the anonymous gate report: staff see who filed it. |
| 6:15 | Update status | Tap **Review Reports**. Open the report Amina just submitted. Tap **Mark as In Progress**, add a note ("Replacement chair ordered"), confirm. The timeline updates live. Then **Mark as Resolved** with a note. |
| 7:15 | Student sees it | Sign back in as Amina. The bell shows an unread dot; open **Updates** to see both changes and notes. Open the report: timeline complete. |
| 7:45 | Security | Briefly show `firestore.rules` and the rules tests passing (`npm test` in `test_rules`): only verified ALU accounts get in, students can't change status or make themselves staff, and anonymous reports can't carry the real name. |
| 8:30 | Code tour | Show the folders (`core`, `data`, `features`, `shared`), one provider (`allIncidentsProvider`), one controller (`SubmitReportController`) and the redirect function in `app_router.dart`. Explain why Riverpod. |
| 9:15 | Wrap up | Recap the four workflows, mention the tests, and show the GitHub repository. |

## Tips

- Record at 1080p. Keep the simulator at 100% zoom.
- Use the same demo photo every take so the result is predictable.
- If something fails on camera, keep going. The app shows a clear error, which is worth showing.
