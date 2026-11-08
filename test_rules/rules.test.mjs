// Security-rule tests for firestore.rules, run against the Firestore emulator.
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp, arrayUnion, deleteDoc, doc, getDoc, serverTimestamp, setDoc, updateDoc,
} from 'firebase/firestore';

let env;
const now = Timestamp.now();
const longAgo = Timestamp.fromDate(new Date('2020-01-01T00:00:00Z'));
const BASE = 'https://wkjdfzafkuwigelkxiir.supabase.co/storage/v1/object/public/incident-photos/';
const photo = (path) => ({ photoPath: path, photoUrl: BASE + path });

const as = (uid, email, verified = true) =>
  env.authenticatedContext(uid, { email, email_verified: verified }).firestore();
const student = () => as('amina', 'amina@alustudent.com');
const other = () => as('brian', 'brian@alustudent.com');
const staff = () => as('staff1', 'staff@alueducation.com');
const anon = () => env.unauthenticatedContext().firestore();

const newIncident = (overrides = {}) => ({
  title: 'Water shortage',
  description: 'No water in the residence since this morning.',
  category: 'water',
  location: 'Student Residence',
  status: 'submitted',
  reporterId: 'amina',
  reporterName: 'Amina Hassan',
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  photoUrl: null,
  photoPath: null,
  history: [{ status: 'submitted', changedAt: now, changedBy: 'amina', changedByName: 'Amina Hassan', note: '' }],
  ...overrides,
});

const change = (status, by = 'staff1', name = 'Campus Staff') => ({ status, changedAt: now, changedBy: by, changedByName: name, note: '' });

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-campus',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8'), host: '127.0.0.1', port: 8080 },
  });
});

after(() => env.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users/staff1'), { name: 'Campus Staff', email: 'staff@alueducation.com', role: 'staff', department: 'Facilities', campus: 'Kigali', createdAt: now });
    await setDoc(doc(db, 'users/amina'), { name: 'Amina Hassan', email: 'amina@alustudent.com', role: 'student', department: 'CS', campus: 'Kigali', createdAt: now });
    await setDoc(doc(db, 'users/brian'), { name: 'Brian Kamau', email: 'brian@alustudent.com', role: 'student', department: '', campus: '', createdAt: now });
    await setDoc(doc(db, 'incidents/existing'), { ...newIncident(), createdAt: now, updatedAt: now });
  });
});

describe('ALU accounts only', () => {
  test('a non-ALU account cannot create a profile', async () => {
    const outsider = as('eve', 'eve@gmail.com');
    await assertFails(setDoc(doc(outsider, 'users/eve'), {
      name: 'Eve', email: 'eve@gmail.com', role: 'student', department: '', campus: '', createdAt: now,
    }));
  });
  test('a non-ALU account cannot read or file reports', async () => {
    const outsider = as('eve', 'eve@gmail.com');
    await assertFails(getDoc(doc(outsider, 'incidents/existing')));
    await assertFails(setDoc(doc(outsider, 'incidents/n1'), newIncident({ reporterId: 'eve' })));
  });
  test('an unverified ALU account cannot read or file reports', async () => {
    const unverified = as('amina', 'amina@alustudent.com', false);
    await assertFails(getDoc(doc(unverified, 'incidents/existing')));
    await assertFails(setDoc(doc(unverified, 'incidents/n1'), newIncident()));
  });
  test('an unverified staff account cannot change a status', async () => {
    const unverified = as('staff1', 'staff@alueducation.com', false);
    await assertFails(updateDoc(doc(unverified, 'incidents/existing'), {
      status: 'inProgress', updatedAt: serverTimestamp(), history: arrayUnion(change('inProgress')),
    }));
  });
});

describe('users', () => {
  const profile = (role = 'student') => ({ name: 'Brian K', email: 'brian@alustudent.com', role, department: '', campus: '', createdAt: now });

  test('a user can create their own student profile', async () => {
    const fresh = as('carol', 'brian@alustudent.com', false);
    await assertSucceeds(setDoc(doc(fresh, 'users/carol'), profile()));
  });
  test('a user cannot sign themselves up as staff', async () => {
    const fresh = as('carol', 'brian@alustudent.com', false);
    await assertFails(setDoc(doc(fresh, 'users/carol'), profile('staff')));
  });
  test('a user cannot create a profile for someone else', async () => {
    await assertFails(setDoc(doc(other(), 'users/amina2'), profile()));
  });
  test('a student cannot promote themselves to staff', async () => {
    await assertFails(updateDoc(doc(student(), 'users/amina'), { role: 'staff' }));
  });
  test('a student can edit their name and department', async () => {
    await assertSucceeds(updateDoc(doc(student(), 'users/amina'), { name: 'Amina H.', department: 'SE' }));
  });
  test('students read only their own profile; staff read any', async () => {
    await assertSucceeds(getDoc(doc(student(), 'users/amina')));
    await assertFails(getDoc(doc(student(), 'users/staff1')));
    await assertSucceeds(getDoc(doc(staff(), 'users/amina')));
  });
});

describe('incidents: create and read', () => {
  test('signed-in users can read reports; signed-out users cannot', async () => {
    await assertSucceeds(getDoc(doc(other(), 'incidents/existing')));
    await assertFails(getDoc(doc(anon(), 'incidents/existing')));
  });
  test('a student can submit a valid report, with or without a photo', async () => {
    await assertSucceeds(setDoc(doc(student(), 'incidents/a'), newIncident()));
    await assertSucceeds(setDoc(doc(student(), 'incidents/b'), newIncident(photo('amina/b/3f2a-9c.jpg'))));
  });
  test('a report cannot be filed in someone else\'s name', async () => {
    await assertFails(setDoc(doc(other(), 'incidents/c'), newIncident()));
  });
  test('a new report must start as submitted', async () => {
    await assertFails(setDoc(doc(student(), 'incidents/d'), newIncident({ status: 'resolved' })));
  });
  test('title, description and category are validated', async () => {
    await assertFails(setDoc(doc(student(), 'incidents/e'), newIncident({ title: 'x' })));
    await assertFails(setDoc(doc(student(), 'incidents/f'), newIncident({ description: 'short' })));
    await assertFails(setDoc(doc(student(), 'incidents/g'), newIncident({ category: 'parking' })));
  });
  test('photos must come from the app\'s storage bucket', async () => {
    await assertFails(setDoc(doc(student(), 'incidents/h'), newIncident({ photoUrl: 'https://evil.example/x.jpg', photoPath: 'amina/h/x.jpg' })));
  });
  test('a report cannot reuse another user\'s photo', async () => {
    await assertFails(setDoc(doc(student(), 'incidents/h2'), newIncident(photo('brian/other/abc.jpg'))));
    await assertFails(setDoc(doc(student(), 'incidents/h3'), newIncident(photo('amina/another-incident/abc.jpg'))));
  });
  test('timestamps must be server time, so reports cannot be backdated or malformed', async () => {
    await assertFails(setDoc(doc(student(), 'incidents/t1'), newIncident({ createdAt: longAgo })));
    await assertFails(setDoc(doc(student(), 'incidents/t2'), newIncident({ createdAt: 'x' })));
    await assertFails(setDoc(doc(student(), 'incidents/t3'), newIncident({
      history: [{ status: 'submitted', changedAt: longAgo, changedBy: 'amina', changedByName: 'Amina Hassan', note: '' }],
    })));
  });
  test('the reporter name must be the reporter\'s real profile name', async () => {
    await assertFails(setDoc(doc(student(), 'incidents/n1'), newIncident({ reporterName: 'Campus Security' })));
  });
  test('history entries cannot carry extra fields', async () => {
    await assertFails(setDoc(doc(student(), 'incidents/x1'), newIncident({
      history: [{ status: 'submitted', changedAt: now, changedBy: 'amina', changedByName: 'Amina Hassan', note: '', admin: true }],
    })));
  });
  test('unknown fields are rejected', async () => {
    await assertFails(setDoc(doc(student(), 'incidents/i'), newIncident({ priority: 'urgent' })));
  });
});

describe('incidents: anonymous reports', () => {
  const anonymous = (overrides = {}) => newIncident({
    anonymous: true,
    reporterName: 'Anonymous',
    history: [{ status: 'submitted', changedAt: now, changedBy: 'amina', changedByName: 'Anonymous', note: '' }],
    ...overrides,
  });

  test('a student can file a report without showing their name', async () => {
    await assertSucceeds(setDoc(doc(student(), 'incidents/n1'), anonymous()));
  });
  test('an anonymous report cannot carry the real name anywhere', async () => {
    await assertFails(setDoc(doc(student(), 'incidents/n1'), anonymous({ reporterName: 'Amina Hassan' })));
    await assertFails(setDoc(doc(student(), 'incidents/n2'), anonymous({
      history: [{ status: 'submitted', changedAt: now, changedBy: 'amina', changedByName: 'Amina Hassan', note: '' }],
    })));
  });
  test('a named report cannot pretend to be anonymous', async () => {
    await assertFails(setDoc(doc(student(), 'incidents/n1'), anonymous({ anonymous: false })));
    await assertFails(setDoc(doc(student(), 'incidents/n2'), anonymous({ anonymous: 'yes' })));
  });
  test('only staff can look up who filed an anonymous report', async () => {
    await assertFails(getDoc(doc(other(), 'users/amina')));
    await assertSucceeds(getDoc(doc(staff(), 'users/amina')));
  });
  test('staff can still update an anonymous report', async () => {
    await env.withSecurityRulesDisabled((ctx) =>
      setDoc(doc(ctx.firestore(), 'incidents/anon'), { ...anonymous(), createdAt: now, updatedAt: now }));
    await assertSucceeds(updateDoc(doc(staff(), 'incidents/anon'), {
      status: 'inProgress', updatedAt: serverTimestamp(), history: arrayUnion(change('inProgress')),
    }));
  });
});

describe('incidents: status updates', () => {
  test('staff can move a report forward and add to the timeline', async () => {
    await assertSucceeds(updateDoc(doc(staff(), 'incidents/existing'), {
      status: 'inProgress', updatedAt: serverTimestamp(), history: arrayUnion(change('inProgress')),
    }));
  });
  test('staff cannot rewrite earlier history entries', async () => {
    let original;
    await env.withSecurityRulesDisabled(async (ctx) => {
      original = (await getDoc(doc(ctx.firestore(), 'incidents/existing'))).data();
    });
    const forged = [{ ...original.history[0], changedByName: 'Someone else' }, change('inProgress')];
    await assertFails(updateDoc(doc(staff(), 'incidents/existing'), {
      status: 'inProgress', updatedAt: serverTimestamp(), history: forged,
    }));
  });
  test('staff must sign the change with their own name and the current time', async () => {
    await assertFails(updateDoc(doc(staff(), 'incidents/existing'), {
      status: 'inProgress', updatedAt: serverTimestamp(), history: arrayUnion(change('inProgress', 'staff1', 'The Dean')),
    }));
    await assertFails(updateDoc(doc(staff(), 'incidents/existing'), {
      status: 'inProgress', updatedAt: serverTimestamp(),
      history: arrayUnion({ ...change('inProgress'), changedAt: longAgo }),
    }));
  });
  test('students cannot change status, even on their own report', async () => {
    await assertFails(updateDoc(doc(student(), 'incidents/existing'), {
      status: 'resolved', updatedAt: serverTimestamp(), history: arrayUnion(change('resolved', 'amina', 'Amina Hassan')),
    }));
  });
  test('staff cannot move a report backwards', async () => {
    await env.withSecurityRulesDisabled((ctx) => updateDoc(doc(ctx.firestore(), 'incidents/existing'), {
      status: 'resolved', history: arrayUnion(change('resolved')),
    }));
    await assertFails(updateDoc(doc(staff(), 'incidents/existing'), {
      status: 'inProgress', updatedAt: serverTimestamp(), history: arrayUnion(change('inProgress')),
    }));
  });
  test('staff cannot edit the report text', async () => {
    await assertFails(updateDoc(doc(staff(), 'incidents/existing'), { title: 'Edited' }));
  });
  test('a status change must be recorded in the history', async () => {
    await assertFails(updateDoc(doc(staff(), 'incidents/existing'), { status: 'inProgress', updatedAt: serverTimestamp() }));
  });
});

describe('incidents: delete', () => {
  test('the reporter can withdraw a submitted report', async () => {
    await assertSucceeds(deleteDoc(doc(student(), 'incidents/existing')));
  });
  test('other users cannot delete it', async () => {
    await assertFails(deleteDoc(doc(other(), 'incidents/existing')));
  });
  test('it cannot be withdrawn once work has started', async () => {
    await env.withSecurityRulesDisabled((ctx) => updateDoc(doc(ctx.firestore(), 'incidents/existing'), { status: 'inProgress' }));
    await assertFails(deleteDoc(doc(student(), 'incidents/existing')));
  });
});
