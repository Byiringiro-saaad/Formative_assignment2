// Creates demo accounts and sample reports so the app has realistic data for
// the demonstration video. Safe to run more than once: accounts are reused and
// the sample reports are replaced.
//
//   GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json node seed_demo.mjs
//   GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json node seed_demo.mjs --clear
//
// Demo accounts (password for all: Campus2026). They are created already
// verified, because the app only admits verified ALU email addresses:
//   demo.amina@alustudent.com    student
//   demo.brian@alustudent.com    student
//   demo.grace@alueducation.com  staff
import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { Timestamp, getFirestore } from 'firebase-admin/firestore';

const PASSWORD = 'Campus2026';
// Earlier demo accounts that the ALU-only rules no longer admit.
const RETIRED = ['amina.student@campus.demo', 'brian.student@campus.demo', 'grace.staff@campus.demo'];
const SEED_PREFIX = 'demo-';

const people = [
  { key: 'amina', email: 'demo.amina@alustudent.com', name: 'Amina Hassan', role: 'student', department: 'Computer Science', campus: 'Kigali, Rwanda' },
  { key: 'brian', email: 'demo.brian@alustudent.com', name: 'Brian Kamau', role: 'student', department: 'Software Engineering', campus: 'Kigali, Rwanda' },
  { key: 'grace', email: 'demo.grace@alueducation.com', name: 'Grace Uwase', role: 'staff', department: 'Facilities Office', campus: 'Kigali, Rwanda' },
];

// hoursAgo: when it was reported. steps: later status changes by staff.
const reports = [
  { id: 'water-residence', by: 'amina', category: 'water', title: 'Water shortage', location: 'Student Residence', hoursAgo: 2,
    description: 'There has been no water supply in the student residence since this morning. This is affecting many students on the 2nd floor. Kindly check and fix the issue.' },
  { id: 'projector-b', by: 'amina', category: 'facilities', title: 'Broken classroom projector', location: 'Block B', hoursAgo: 26,
    description: 'The projector in Block B, Room 204 does not turn on. Lecturers have had to cancel slides for two classes today.',
    steps: [{ status: 'inProgress', hoursAgo: 20, note: 'A technician has been assigned and will check the power supply.' }] },
  { id: 'bin-cafeteria', by: 'amina', category: 'sanitation', title: 'Overflowing bin', location: 'Cafeteria', hoursAgo: 72,
    description: 'The large bin next to the cafeteria entrance is overflowing and attracting flies.',
    steps: [
      { status: 'inProgress', hoursAgo: 70, note: 'Cleaning team notified.' },
      { status: 'resolved', hoursAgo: 66, note: 'Bin emptied and collection moved to twice a day.' },
    ] },
  { id: 'lights-library', by: 'brian', category: 'electricity', title: 'Flickering lights in the library', location: 'Library', hoursAgo: 5,
    description: 'Several ceiling lights on the second floor of the library keep flickering, which makes it hard to read.' },
  { id: 'chair-c', by: 'brian', category: 'furniture', title: 'Broken chairs in lecture hall', location: 'Block C', hoursAgo: 30,
    description: 'Four chairs in the front row of the Block C lecture hall have cracked legs and are unsafe to sit on.',
    steps: [{ status: 'inProgress', hoursAgo: 8, note: 'Replacement chairs ordered, arriving Thursday.' }] },
  { id: 'gate-light', by: 'brian', category: 'safety', title: 'Main gate light not working', location: 'Main Gate', hoursAgo: 50,
    description: 'The security light at the main gate has been off for two nights. The path is very dark after 7pm.' },
  { id: 'socket-a', by: 'amina', category: 'electricity', title: 'Sparking power socket', location: 'Block A', hoursAgo: 100,
    description: 'The power socket next to the window in Block A, Room 101 sparks when a charger is plugged in.',
    steps: [
      { status: 'inProgress', hoursAgo: 99, note: 'Socket switched off at the breaker as a precaution.' },
      { status: 'resolved', hoursAgo: 90, note: 'Socket replaced by the electrician.' },
    ] },
  { id: 'leak-sports', by: 'brian', category: 'water', title: 'Leaking roof in the gym', location: 'Sports Complex', hoursAgo: 12,
    description: 'Rainwater is dripping from the gym roof onto the basketball court, making the floor slippery.' },
];

initializeApp({ credential: applicationDefault() });
const auth = getAuth();
const db = getFirestore();
const ago = (h) => Timestamp.fromMillis(Date.now() - h * 3600 * 1000);

async function upsertUser(p) {
  let user;
  try {
    user = await auth.getUserByEmail(p.email);
    await auth.updateUser(user.uid, { password: PASSWORD, displayName: p.name, emailVerified: true });
  } catch (e) {
    if (e.code !== 'auth/user-not-found') throw e;
    user = await auth.createUser({ email: p.email, password: PASSWORD, displayName: p.name, emailVerified: true });
  }
  await db.doc(`users/${user.uid}`).set({
    name: p.name, email: p.email, role: p.role, department: p.department, campus: p.campus,
    createdAt: ago(24 * 14),
  });
  return user.uid;
}

const existing = await db.collection('incidents').get();
await Promise.all(existing.docs.filter((d) => d.id.startsWith(SEED_PREFIX)).map((d) => d.ref.delete()));

for (const email of RETIRED) {
  try {
    const old = await auth.getUserByEmail(email);
    await db.doc(`users/${old.uid}`).delete();
    await auth.deleteUser(old.uid);
    console.log(`Removed retired demo account ${email}.`);
  } catch (e) {
    if (e.code !== 'auth/user-not-found') throw e;
  }
}

if (process.argv.includes('--clear')) {
  console.log('Removed sample reports.');
  process.exit(0);
}

const uids = {};
for (const p of people) uids[p.key] = await upsertUser(p);
const byKey = Object.fromEntries(people.map((p) => [p.key, p]));
const staff = byKey.grace;

for (const r of reports) {
  const reporter = byKey[r.by];
  const history = [{ status: 'submitted', changedAt: ago(r.hoursAgo), changedBy: uids[r.by], changedByName: reporter.name, note: '' }];
  for (const s of r.steps ?? []) {
    history.push({ status: s.status, changedAt: ago(s.hoursAgo), changedBy: uids.grace, changedByName: staff.name, note: s.note });
  }
  const last = history[history.length - 1];
  await db.doc(`incidents/${SEED_PREFIX}${r.id}`).set({
    title: r.title, description: r.description, category: r.category, location: r.location,
    status: last.status, reporterId: uids[r.by], reporterName: reporter.name,
    createdAt: ago(r.hoursAgo), updatedAt: last.changedAt, photoUrl: null, photoPath: null, history,
  });
}

console.log(`Seeded ${people.length} accounts and ${reports.length} reports.`);
for (const p of people) console.log(`  ${p.role.padEnd(7)} ${p.email}  /  ${PASSWORD}`);
