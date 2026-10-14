import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {before, after, beforeEach, test} from 'node:test';
import {assertFails, assertSucceeds, initializeTestEnvironment} from '@firebase/rules-unit-testing';
import {doc, setDoc, updateDoc, getDoc, serverTimestamp, runTransaction, arrayUnion, collection, query, where, orderBy, getDocs, setLogLevel, deleteDoc, collectionGroup, writeBatch, limit} from 'firebase/firestore';

setLogLevel('silent');
let env;
const member = (extra = {}) => ({username: 'Member', email: 'member@example.com', role: 'muqtaddi', verificationStatus: 'none', eventPermission: 'none', masjidId: 'a', masjidName: 'Masjid A', ...extra});
const user = (uid = 'member', claims = {}) => env.authenticatedContext(uid, {email: `${uid}@example.com`, auth_time: Math.floor(Date.now()/1000), ...claims}).firestore();
const admin = () => user('reviewer', {superAdmin: true});
const claim = (extra = {}) => ({masjidId: 'a', imamUid: 'member', imamName: 'Member', imamEmail: 'member@example.com', status: 'pending', createdAt: serverTimestamp(), ...extra});
const post = (extra = {}) => ({id: 'p', userName: 'Member', questionText: 'A question', answer: null, masjidId: 'a', timestamp: new Date().toISOString(), isAnswered: false, isAnonymous: false, createdByUid: 'member', ...extra});
before(async () => {
  env = await initializeTestEnvironment({projectId: 'demo-masjid-rules', firestore: {rules: readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8')}});
});
after(async () => {await env?.cleanup();});
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    await Promise.all([
      setDoc(doc(db, 'masjids/a'), {name: 'Masjid A', authorizedImamUids: ['imam'], isVerified: true}),
      setDoc(doc(db, 'masjids/b'), {name: 'Masjid B', authorizedImamUids: ['other-imam']}),
      setDoc(doc(db, 'users/imam'), member({email: 'imam@example.com', role: 'imam', verificationStatus: 'approved', eventPermission: 'full'})),
      setDoc(doc(db, 'users/member'), member()),
      setDoc(doc(db, 'users/forged'), member({email: 'forged@example.com', role: 'imam', verificationStatus: 'approved', eventPermission: 'full'})),
      setDoc(doc(db, 'masjids/a/questions/p'), post()),
    ]);
  });
});

test('normal registration succeeds; self-promotion and foreign identity fail', async () => {
  const db = user('new');
  await assertSucceeds(setDoc(doc(db, 'users/new'), member({email: 'new@example.com'})));
  await assertFails(setDoc(doc(db, 'users/other'), member({email: 'new@example.com'})));
  for (const extra of [{role: 'imam'}, {role: 'admin'}, {verificationStatus: 'approved'}, {eventPermission: 'full'}, {superAdmin: true}]) {
    await assertFails(setDoc(doc(user('attacker'), 'users/attacker'), member({email: 'attacker@example.com', ...extra})));
  }
});
test('users cannot elevate themselves by updates', async () => {
  for (const data of [{role: 'imam'}, {verificationStatus: 'approved'}, {eventPermission: 'full'}, {authorizedImamUids: ['member']}]) {
    await assertFails(updateDoc(doc(user(), 'users/member'), data));
  }
});
test('only an ordinary unverified member may change their own association', async () => {
  await assertSucceeds(updateDoc(doc(user(), 'users/member'), {masjidId: 'b', masjidName: 'Masjid B'}));
  await assertFails(updateDoc(doc(user('imam'), 'users/imam'), {masjidId: 'b'}));
});
test('manager role alone does not authorize masjid access', async () => {
  await assertFails(updateDoc(doc(user('forged'), 'masjids/a'), {name: 'Taken over'}));
  await assertFails(updateDoc(doc(user('member'), 'masjids/a'), {prayerTimes: []}));
});
test('assigned imam edits only community fields on their own masjid', async () => {
  const db = user('imam');
  await assertSucceeds(updateDoc(doc(db, 'masjids/a'), {prayerTimes: [], jummah: '1:00 PM'}));
  await assertFails(updateDoc(doc(db, 'masjids/b'), {prayerTimes: []}));
  for (const data of [{authorizedImamUids: ['member']}, {creatorUid: 'imam'}, {isVerified: false}, {verifiedImamId: 'member'}]) {
    await assertFails(updateDoc(doc(db, 'masjids/a'), data));
  }
});
test('the former super-admin email provides no authority', async () => {
  const db = user('attacker', {email: 'superadmin@masjid-app.com', email_verified: true});
  await assertFails(updateDoc(doc(db, 'users/member'), {role: 'imam'}));
  await assertFails(setDoc(doc(db, 'masjids/new'), {name: 'New'}));
});
test('trusted super-admin claim authorizes approval operations', async () => {
  await assertSucceeds(updateDoc(doc(admin(), 'users/member'), {role: 'imam'}));
  await assertSucceeds(setDoc(doc(admin(), 'masjids/new'), {name: 'New'}));
});
test('claim requests validate claimant, pending status, and server timestamp', async () => {
  const db = user();
  await assertSucceeds(setDoc(doc(db, 'claimRequests/valid'), claim()));
  for (const extra of [{imamUid: 'imam'}, {imamEmail: 'imam@example.com'}, {status: 'approved'}, {createdAt: 'yesterday'}, {role: 'imam'}, {masjidId: 'missing'}]) {
    await assertFails(setDoc(doc(db, 'claimRequests/invalid'), claim(extra)));
  }
});
test('new masjid request permits a bounded description but no immediate grant', async () => {
  await assertSucceeds(setDoc(doc(user(), 'claimRequests/new'), claim({masjidId: null, type: 'new_masjid', masjidName: 'New masjid', masjidLocation: 'Karachi'})));
  await assertFails(setDoc(doc(user(), 'masjids/new'), {name: 'New masjid', creatorUid: 'member', authorizedImamUids: ['member']}));
  await assertFails(setDoc(doc(user(), 'claimRequests/invalid'), claim({masjidId: null, type: 'new_masjid', masjidName: '', masjidLocation: 'Karachi'})));
});
test('claimants read their requests but cannot approve or see others', async () => {
  await setDoc(doc(user(), 'claimRequests/valid'), claim());
  await assertSucceeds(getDoc(doc(user(), 'claimRequests/valid')));
  await assertFails(getDoc(doc(user('other'), 'claimRequests/valid')));
  await assertFails(updateDoc(doc(user(), 'claimRequests/valid'), {status: 'approved'}));
  await assertSucceeds(getDocs(query(collection(admin(), 'claimRequests'), where('status', '==', 'pending'), orderBy('createdAt', 'desc'))));
});
test('trusted approval transaction assigns access and cannot be reviewed twice', async () => {
  await setDoc(doc(user(), 'claimRequests/valid'), claim());
  const db = admin();
  await assertSucceeds(runTransaction(db, async tx => {
    await tx.get(doc(db, 'claimRequests/valid'));
    await tx.get(doc(db, 'users/member'));
    await tx.get(doc(db, 'masjids/a'));
    tx.update(doc(db, 'masjids/a'), {authorizedImamUids: arrayUnion('member')});
    tx.update(doc(db, 'users/member'), {role: 'imam', verificationStatus: 'approved', eventPermission: 'full'});
    tx.update(doc(db, 'claimRequests/valid'), {status: 'approved', approvedMasjidId: 'a', reviewedByUid: 'reviewer', reviewedAt: serverTimestamp()});
  }));
  await assertSucceeds(updateDoc(doc(user(), 'masjids/a'), {prayerTimes: []}));
  await assertFails(updateDoc(doc(user(), 'masjids/b'), {prayerTimes: []}));
  await assertFails(updateDoc(doc(db, 'claimRequests/valid'), {status: 'rejected', reviewedByUid: 'reviewer', reviewedAt: serverTimestamp()}));
});
test('failed approval rolls back other writes', async () => {
  await setDoc(doc(user(), 'claimRequests/valid'), claim());
  const db = admin();
  await assert.rejects(runTransaction(db, async tx => {
    await tx.get(doc(db, 'claimRequests/valid'));
    tx.update(doc(db, 'users/missing'), {role: 'imam'});
    tx.update(doc(db, 'masjids/a'), {authorizedImamUids: arrayUnion('missing')});
    tx.update(doc(db, 'claimRequests/valid'), {status: 'approved', reviewedByUid: 'reviewer', reviewedAt: serverTimestamp()});
  }), error => error.code === 'not-found');
  const result = await getDoc(doc(db, 'masjids/a'));
  if (result.data().authorizedImamUids.includes('missing')) throw Error('Partial grant');
});
test('community posts are text-only and cannot impersonate an author or supply an answer', async () => {
  await assertSucceeds(setDoc(doc(user(), 'masjids/a/questions/new'), post({id: 'new'})));
  for (const extra of [{mediaUrl: 'https://example.com/a.jpg'}, {mediaType: 'video'}, {createdByUid: 'imam'}, {answer: 'Pretend imam answer'}, {isAnswered: true}, {questionText: ''}, {questionText: 'x'.repeat(4001)}]) {
    await assertFails(setDoc(doc(user(), 'masjids/a/questions/invalid'), post({id: 'invalid', ...extra})));
  }
});
test('post metadata rejects malformed feed types, dates, and mismatched IDs', async () => {
  for (const extra of [{id: 'wrong'}, {userName: 12}, {userName: ''}, {userName: 'x'.repeat(101)}, {isAnonymous: 'yes'}, {timestamp: 'yesterday'}, {timestamp: new Date()}, {timestamp: '2026-10-14T25:00:00.000'}, {timestamp: '2026-13-14T12:00:00.000'}]) {
    await assertFails(setDoc(doc(user(), 'masjids/a/questions/invalid'), post({id: 'invalid', ...extra})));
  }
  await assertSucceeds(setDoc(doc(user(), 'masjids/a/questions/local'), post({id: 'local', timestamp: '2026-10-14T12:00:00.123456'})));
  await assertSucceeds(setDoc(doc(user(), 'masjids/a/questions/utc'), post({id: 'utc', timestamp: '2026-10-14T12:00:00.000Z'})));
});
test('posts cannot be created below missing or deleted masjids', async () => {
  await assertFails(setDoc(doc(user(), 'masjids/missing/questions/new'), post({id: 'new', masjidId: 'missing'})));
  await deleteDoc(doc(admin(), 'masjids/a'));
  await assertFails(setDoc(doc(user(), 'masjids/a/questions/new'), post({id: 'new'})));
});
test('only assigned managers can answer posts', async () => {
  await assertSucceeds(updateDoc(doc(user('imam'), 'masjids/a/questions/p'), {answer: 'Answer', isAnswered: true}));
  await assertFails(updateDoc(doc(user(), 'masjids/a/questions/p'), {answer: 'Answer', isAnswered: true}));
  await assertFails(updateDoc(doc(user('forged'), 'masjids/a/questions/p'), {answer: 'Answer', isAnswered: true}));
});
test('manager answers reject empty, oversized, or non-text input', async () => {
  for (const answer of ['', 'x'.repeat(4001), null, 123]) {
    await assertFails(updateDoc(doc(user('imam'), 'masjids/a/questions/p'), {answer, isAnswered: true}));
  }
});
test('comments enforce author, existing parent, timestamp, and text length', async () => {
  const comment = {text: 'Comment', createdByUid: 'member', userName: 'Member', timestamp: serverTimestamp()};
  await assertSucceeds(setDoc(doc(user(), 'masjids/a/questions/p/comments/valid'), comment));
  for (const extra of [{createdByUid: 'imam'}, {mediaUrl: 'https://example.com/a.jpg'}, {text: ''}, {text: 'x'.repeat(1001)}, {timestamp: 'yesterday'}]) {
    await assertFails(setDoc(doc(user(), 'masjids/a/questions/p/comments/invalid'), {...comment, ...extra}));
  }
  await assertFails(setDoc(doc(user(), 'masjids/a/questions/missing/comments/c'), comment));
  await assertFails(setDoc(doc(env.unauthenticatedContext().firestore(), 'masjids/a/questions/p/comments/guest'), comment));
});

test('new applicant onboarding commits member and pending request atomically', async () => {
  const db = user('new');
  const {writeBatch} = await import('firebase/firestore');
  const batch = writeBatch(db);
  batch.set(doc(db, 'users/new'), member({email: 'new@example.com', masjidId: null, masjidName: null}));
  batch.set(doc(db, 'claimRequests/new'), claim({imamUid: 'new', imamEmail: 'new@example.com', masjidId: null, type: 'new_masjid', masjidName: 'New masjid', masjidLocation: 'Karachi'}));
  await assertSucceeds(batch.commit());
  const account = await getDoc(doc(db, 'users/new'));
  assert.equal(account.data().role, 'muqtaddi');
  await assertFails(setDoc(doc(db, 'masjids/new'), {authorizedImamUids: ['new']}));
});
test('super-admin creates a masjid and grants its applicant access in one transaction', async () => {
  await setDoc(doc(user(), 'claimRequests/new'), claim({masjidId: null, type: 'new_masjid', masjidName: 'New masjid', masjidLocation: 'Karachi'}));
  const db = admin();
  await assertSucceeds(runTransaction(db, async tx => {
    await tx.get(doc(db, 'claimRequests/new'));
    await tx.get(doc(db, 'users/member'));
    await tx.get(doc(db, 'masjids/new'));
    tx.set(doc(db, 'masjids/new'), {name: 'New masjid', creatorUid: 'member', authorizedImamUids: ['member'], isVerified: true});
    tx.update(doc(db, 'users/member'), {role: 'imam', masjidId: 'new', masjidName: 'New masjid', verificationStatus: 'approved', eventPermission: 'full'});
    tx.update(doc(db, 'claimRequests/new'), {status: 'approved', approvedMasjidId: 'new', reviewedByUid: 'reviewer', reviewedAt: serverTimestamp()});
  }));
  await assertSucceeds(updateDoc(doc(user(), 'masjids/new'), {prayerTimes: []}));
  await assertFails(updateDoc(doc(user(), 'masjids/a'), {prayerTimes: []}));
});

test('a member requests verification without granting privileges', async () => {
  await assertSucceeds(updateDoc(doc(user(), 'users/member'), {verificationStatus: 'pending'}));
  await assertFails(updateDoc(doc(user(), 'users/member'), {verificationStatus: 'approved', role: 'verified_muqtaddi', eventPermission: 'full'}));
  await assertFails(updateDoc(doc(user(), 'users/member'), {masjidId: 'b'}));
});
test('assigned managers review only their own masjid members', async () => {
  await updateDoc(doc(user(), 'users/member'), {verificationStatus: 'pending'});
  const db = user('imam');
  await assertSucceeds(getDocs(query(collection(db, 'users'), where('masjidId', '==', 'a'), where('verificationStatus', '==', 'pending'), limit(50))));
  await assertSucceeds(updateDoc(doc(db, 'users/member'), {role: 'verified_muqtaddi', verificationStatus: 'approved', eventPermission: 'approval_required'}));
  await assertFails(updateDoc(doc(db, 'users/member'), {role: 'imam'}));
  await assertFails(updateDoc(doc(user(), 'users/member'), {masjidId: 'b'}));
  await assertFails(getDocs(query(collection(db, 'users'), where('masjidId', '==', 'b'))));
});
const event = (extra = {}) => ({id: 'event', title: 'Class', description: 'A community class', masjidId: 'a', createdByUid: 'member', createdByName: 'Member', eventDate: new Date().toISOString(), startTime: '5:00 PM', endTime: '6:00 PM', status: 'pending', ...extra});
test('event metadata is bounded and typed for members and manager edits', async () => {
  await updateDoc(doc(admin(), 'users/member'), {role: 'verified_muqtaddi', verificationStatus: 'approved', eventPermission: 'full'});
  const malformed = [{title: ''}, {title: 'x'.repeat(201)}, {description: 42}, {description: 'x'.repeat(4001)}, {eventDate: 'bad-date'}, {startTime: []}, {endTime: 42}, {location: 'x'.repeat(501)}, {category: true}, {createdByName: 42}, {masjidName: []}, {mediaUrl: []}, {mediaType: 'invalid'}];
  for (const extra of malformed) {
    await assertFails(setDoc(doc(user(), 'masjids/a/events/invalid'), event(extra)));
  }
  await assertSucceeds(setDoc(doc(user(), 'masjids/a/events/event'), event()));
  for (const extra of malformed) {
    await assertFails(updateDoc(doc(user('imam'), 'masjids/a/events/event'), extra));
  }
  await assertSucceeds(updateDoc(doc(user('imam'), 'masjids/a/events/event'), {status: 'approved', title: 'Updated class'}));
});
test('full event permission does not authorize orphan events after masjid deletion', async () => {
  await updateDoc(doc(admin(), 'users/member'), {role: 'verified_muqtaddi', verificationStatus: 'approved', eventPermission: 'full'});
  await deleteDoc(doc(admin(), 'masjids/a'));
  await assertFails(setDoc(doc(user(), 'masjids/a/events/event'), event({status: 'approved'})));
});
test('verified members propose pending events but cannot approve them', async () => {
  await assertFails(setDoc(doc(user(), 'masjids/a/events/event'), event()));
  await updateDoc(doc(admin(), 'users/member'), {role: 'verified_muqtaddi', verificationStatus: 'approved', eventPermission: 'approval_required'});
  await assertSucceeds(setDoc(doc(user(), 'masjids/a/events/event'), event()));
  await assertFails(setDoc(doc(user(), 'masjids/a/events/direct'), event({status: 'approved'})));
  await assertFails(setDoc(doc(user(), 'masjids/b/events/foreign'), event({masjidId: 'b'})));
  await assertFails(updateDoc(doc(user(), 'masjids/a/events/event'), {status: 'approved'}));
  await assertSucceeds(updateDoc(doc(user('imam'), 'masjids/a/events/event'), {status: 'approved'}));
});
test('full event permission allows publication only for the assigned masjid', async () => {
  await updateDoc(doc(admin(), 'users/member'), {role: 'verified_muqtaddi', verificationStatus: 'approved', eventPermission: 'full'});
  await assertSucceeds(setDoc(doc(user(), 'masjids/a/events/direct'), event({status: 'approved'})));
  await assertFails(setDoc(doc(user(), 'masjids/b/events/foreign'), event({masjidId: 'b', status: 'approved'})));
  await assertFails(setDoc(doc(user(), 'masjids/a/events/forged'), event({createdByUid: 'imam'})));
});
test('deletion requires recent authentication and prevents manager self-deletion', async () => {
  await assertFails(updateDoc(doc(user('member', {auth_time: Math.floor(Date.now()/1000)-600}), 'users/member'), {deletionRequestedAt: serverTimestamp()}));
  await assertFails(updateDoc(doc(user('imam'), 'users/imam'), {deletionRequestedAt: serverTimestamp()}));
  await assertFails(deleteDoc(doc(user(), 'users/member')));
  await assertSucceeds(updateDoc(doc(user(), 'users/member'), {deletionRequestedAt: serverTimestamp()}));
});
test('deletion marker freezes contributions and cannot be removed', async () => {
  await updateDoc(doc(user(), 'users/member'), {deletionRequestedAt: serverTimestamp()});
  await assertFails(setDoc(doc(user(), 'masjids/a/questions/new'), post({id: 'new'})));
  await assertFails(setDoc(doc(user(), 'claimRequests/new'), claim()));
  await assertFails(setDoc(doc(user(), 'masjids/a/questions/p/comments/new'), {text: 'No', userName: 'Member', createdByUid: 'member', timestamp: serverTimestamp()}));
  await assertFails(updateDoc(doc(user(), 'users/member'), {deletionRequestedAt: null}));
  await assertFails(updateDoc(doc(user(), 'users/member'), {username: 'Changed'}));
  await env.withSecurityRulesDisabled(async context => setDoc(doc(context.firestore(), 'users/other'), member({email: 'other@example.com'})));
  await assertFails(setDoc(doc(user('other'), 'masjids/a/questions/p/comments/race'), {text: 'Late comment', userName: 'Other', createdByUid: 'other', timestamp: serverTimestamp()}));
});
test('cleanup enumerates only owned contributions across masjids', async () => {
  await env.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    await setDoc(doc(db, 'masjids/b/questions/q'), post({id: 'q', masjidId: 'b'}));
    await setDoc(doc(db, 'masjids/b/questions/other'), post({id: 'other', masjidId: 'b', createdByUid: 'other'}));
  });
  const owned = await assertSucceeds(getDocs(query(collectionGroup(user(), 'questions'), where('createdByUid', '==', 'member'), limit(100))));
  assert.equal(owned.size, 2);
  await assertFails(getDocs(collectionGroup(user(), 'questions')));
});
test('cleanup removes child comments before posts and supports retries', async () => {
  await env.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    await setDoc(doc(db, 'masjids/a/questions/p/comments/other'), {text: 'Reply', userName: 'Other', createdByUid: 'other', timestamp: serverTimestamp()});
    await setDoc(doc(db, 'masjids/a/events/event'), event({status: 'approved'}));
  });
  await setDoc(doc(user(), 'claimRequests/valid'), claim());
  await updateDoc(doc(user(), 'users/member'), {deletionRequestedAt: serverTimestamp()});
  const db = user();
  await assertSucceeds(deleteDoc(doc(db, 'masjids/a/questions/p/comments/other')));
  await assertSucceeds(deleteDoc(doc(db, 'masjids/a/questions/p')));
  await assertSucceeds(deleteDoc(doc(db, 'masjids/a/events/event')));
  await assertSucceeds(deleteDoc(doc(db, 'claimRequests/valid')));
  // Simulate an interrupted cleanup by querying its already-removed data again.
  const remaining = await getDocs(query(collectionGroup(db, 'questions'), where('createdByUid', '==', 'member')));
  assert.equal(remaining.size, 0);
  await assertSucceeds(deleteDoc(doc(db, 'users/member')));
  await assertFails(setDoc(doc(db, 'masjids/a/questions/new'), post({id: 'new'})));
});
test('cleanup cannot delete another member profile or contribution', async () => {
  await assertFails(deleteDoc(doc(user('other'), 'masjids/a/questions/p')));
  await assertFails(deleteDoc(doc(user('other'), 'users/member')));
});

test('guests read community text and approved events, but cannot read pending proposals', async () => {
  await env.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    await setDoc(doc(db, 'masjids/a/events/pending'), event());
    await setDoc(doc(db, 'masjids/a/events/approved'), event({status: 'approved'}));
  });
  const guest = env.unauthenticatedContext().firestore();
  await assertSucceeds(getDoc(doc(guest, 'masjids/a/questions/p')));
  await assertSucceeds(getDocs(query(collection(guest, 'masjids/a/events'), where('status', '==', 'approved'), orderBy('eventDate', 'asc'))));
  await assertFails(getDoc(doc(guest, 'masjids/a/events/pending')));
  await assertFails(getDocs(collection(guest, 'masjids/a/events')));
  await assertFails(getDoc(doc(user('other'), 'masjids/a/events/pending')));
  await assertSucceeds(getDoc(doc(user(), 'masjids/a/events/pending')));
  await assertSucceeds(getDocs(collection(user('imam'), 'masjids/a/events')));
});

test('post deletion freezes replies without allowing authors to forge an answer', async () => {
  await assertSucceeds(updateDoc(doc(user(), 'masjids/a/questions/p'), {isDeleting: true}));
  await assertFails(updateDoc(doc(user(), 'masjids/a/questions/p'), {isDeleting: false}));
  await assertFails(updateDoc(doc(user(), 'masjids/a/questions/p'), {answer: 'Forged', isAnswered: true}));
  await assertFails(setDoc(doc(user('imam'), 'masjids/a/questions/p/comments/late'), {
    text:'Late reply',createdByUid:'imam',userName:'Imam',timestamp:serverTimestamp()}));
  await assertFails(updateDoc(doc(user('other'), 'masjids/a/questions/p'), {isDeleting: true}));
});
test('bounded question pagination handles equal timestamps without skipping posts', async () => {
  await env.withSecurityRulesDisabled(async context => {
    const db=context.firestore(); const batch=writeBatch(db);
    for(let i=0;i<35;i++) batch.set(doc(db,`masjids/a/questions/page-${String(i).padStart(2,'0')}`),
      post({timestamp:'2026-10-13T10:00:00.000',id:`page-${String(i).padStart(2,'0')}`}));
    await batch.commit();
  });
  const base=query(collection(user(),'masjids/a/questions'),orderBy('timestamp','desc'),orderBy('__name__','desc'));
  const {startAfter}=await import('firebase/firestore');
  const first=await getDocs(query(base,limit(31)));
  assert.equal(first.size,31);
  const cursor=first.docs[29];
  const second=await getDocs(query(base,startAfter(cursor.data().timestamp,cursor.id),limit(31)));
  const ids=new Set([...first.docs.slice(0,30),...second.docs].map(d=>d.id));
  assert.equal(ids.size,36); // 35 equal-time posts plus the pre-seeded post.
  assert.equal(second.docs[0].id,first.docs[30].id);
});


test('bounded manager pending queue is queried independently of approved history', async () => {
  await env.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    const batch = writeBatch(db);
    for(let i=0;i<35;i++) batch.set(doc(db, `masjids/a/events/history-${i}`), {status:'approved',eventDate:'2026-01-01',createdByUid:'imam'});
    batch.set(doc(db,'masjids/a/events/proposal'),{status:'pending',eventDate:'2026-12-01',createdByUid:'member'});
    await batch.commit();
  });
  const pending = await assertSucceeds(getDocs(query(collection(user('imam'),'masjids/a/events'),where('status','==','pending'),orderBy('eventDate'),limit(31))));
  assert.deepEqual(pending.docs.map(doc=>doc.id),['proposal']);
  await assertFails(getDocs(query(collection(env.unauthenticatedContext().firestore(),'masjids/a/events'),where('status','==','pending'),orderBy('eventDate'),limit(31))));
});
