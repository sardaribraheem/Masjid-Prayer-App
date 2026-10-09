// Run only in a trusted environment with Application Default Credentials.
// Defaults to read-only. Preserves unrelated claims on the selected account.
import {initializeApp, applicationDefault} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';

const args = process.argv.slice(2);
function option(name) {
  const index = args.indexOf(name);
  return index < 0 ? undefined : args[index + 1];
}
const uid = option('--uid');
const projectId = option('--project');
if (!uid || !projectId || uid.startsWith('--') || projectId.startsWith('--')) {
  console.error('Usage: node scripts/admin/grant-super-admin.mjs --project PROJECT_ID --uid REVIEWED_ADMIN_UID [--apply]');
  process.exit(1);
}
if (process.env.FIREBASE_AUTH_EMULATOR_HOST && !projectId.startsWith('demo-')) {
  throw Error('Refusing an emulator/production project mismatch.');
}
initializeApp({credential: applicationDefault(), projectId});
const auth = getAuth();
const account = await auth.getUser(uid);
if (account.disabled || !account.emailVerified) {
  throw Error('The administrator account must be enabled with a verified email.');
}
console.log(JSON.stringify({projectId, uid, email: account.email, action: 'grant superAdmin custom claim', apply: args.includes('--apply')}, null, 2));
if (args.includes('--apply')) {
  await auth.setCustomUserClaims(uid, {...account.customClaims, superAdmin: true});
  console.log('Claim granted. Sign out and sign in again to refresh the token.');
} else {
  console.log('Read-only preview. Check the account identity before running with --apply.');
}
