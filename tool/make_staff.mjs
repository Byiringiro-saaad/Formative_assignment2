// Grants or removes the staff role for an existing account.
//
// Usage (needs a Firebase service-account key, never committed):
//   GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json node make_staff.mjs staff@example.com
//   GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json node make_staff.mjs staff@example.com --revoke
//
// The Firestore rules stop users from changing their own role, so staff
// accounts can only be created through this admin script.
import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

const [email, flag] = process.argv.slice(2);
if (!email) {
  console.error('Usage: node make_staff.mjs <email> [--revoke]');
  process.exit(1);
}
const role = flag === '--revoke' ? 'student' : 'staff';

initializeApp({ credential: applicationDefault() });
const user = await getAuth().getUserByEmail(email);
const ref = getFirestore().doc(`users/${user.uid}`);
const snap = await ref.get();
if (!snap.exists) {
  console.error(`${email} has no profile yet. Sign up in the app first.`);
  process.exit(1);
}
await ref.update({ role });
console.log(`${email} (${user.uid}) is now ${role}.`);
