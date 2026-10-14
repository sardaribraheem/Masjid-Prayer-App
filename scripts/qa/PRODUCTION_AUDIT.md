# Production backend audit — 14 October 2026

**Public launch is blocked.** A read-only Firebase Rules API check using the installed Firebase CLI account retrieved the project's active Firestore source. No production rules, indexes, claims, users, or documents were changed. This was a rules inspection, not a production penetration test or load test.

- Project: `masjid-prayer-app-49f50`.
- Active Firestore release update: `2026-09-16T09:08:44.495731Z`.
- Deployed source SHA-256: `287ef838b77e0007e8962097cdc17434e8adc962bcd24bdc5d9135b1e3f8d47e`.
- The deployed source does **not** match the repository's reviewed rules.

## Confirmed deployed-rule gaps

| Finding | Consequence |
| --- | --- |
| `isAdmin` trusts Auth email matching the public masjid `username` or the hardcoded super-admin email; there is no email-verification/custom-claim check | Client role controls cannot protect administration. Replace this with the reviewed claims/grant policy. |
| Any signed-in user may create a mosque whose `username` matches their email | New imam registration bypasses the intended approval boundary at the API level. |
| Question creation checks only sign-in and matching masjid ID | Spoofed authors, malformed metadata, oversized content and media fields are not rejected. |
| Questions/events require sign-in to read; pending events are readable to any signed-in user | Guest UX conflicts with production permissions, and proposals lack intended privacy. |
| There is no comments rule or user-document delete permission | Current comment writes and account cleanup cannot complete against these rules. |
| Member verification transitions, scoped manager review, collection-group cleanup and reviewed claim transactions are absent | Current workflows will encounter permission failures even though local QA passes. |

## Local corrections and evidence

The repository uses the server-issued `superAdmin` claim and protected per-mosque manager UID grants, ordinary-member onboarding, immutable role permissions, private pending events, text-only posts/comments, bounded input and recent-auth cleanup. This pass also validates post metadata/ISO dates/document IDs and event metadata on create/update, and rejects contributions beneath missing/deleted mosques. **35 Firestore emulator tests pass** against these local rules. They do not establish deployed behavior.

Keep existing ISO-string post/event ordering until a reviewed migration; silently mixing Firestore timestamp types would change query order. Existing malformed/legacy documents still require review. The public mosque directory remains an unbounded read suitable only for a small initial directory. Post ordering still uses client-provided ISO time, and spam/rate controls and production usage monitoring require follow-up. No production performance or concurrency benchmark was run.

## Required release sequence

1. Review existing privileged users, mosque ownership/grants and unattributed or malformed legacy data. Never bulk-trust existing email/role fields. Follow [the trusted bootstrap/migration procedure](../admin/README.md).
2. Test that migration and the compatible client in staging. Refresh trusted administrator claims and verify denied operations, comments, proposal privacy and interrupted account cleanup there.
3. Review [firestore.rules](../../firestore.rules) and [firestore.indexes.json](../../firestore.indexes.json) as a coordinated deployment with the migrated grants and app. Obtain explicit deployment authorization; this review does not deploy them.
4. Retrieve deployed rules again, compare the reviewed source, verify indexes and actual staging/production acceptance, monitor Spark usage, and record evidence in [launchplan.md](../../launchplan.md).

The UI has scoped local usability evidence, and one controlled Android debug background reminder delivered. A real-user pilot still requires compatible backend activation and the correctness/moderation gates in [launchplan.md](../../launchplan.md). Public release additionally requires final Android identity/signing, remaining native/reminder acceptance and store readiness.
