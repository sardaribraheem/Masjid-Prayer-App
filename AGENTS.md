# Working on Masjid App

Read CLAUDE.md, FINALTODO.md, and launchplan.md before changes. Inspect files relevant to the current task; preserve existing uncommitted work. This is a Flutter/Dart app using Firebase Authentication, Firestore, Provider, and English/Urdu localization.

- Community is the QuestionsPage tab; CommunityPage is the events feed.
- Community posts and comments are text-only. Do not introduce media attachments or uploads.
- Enforce permissions and input constraints in Firestore rules as well as the UI.
- Never trust client role checks as authorization, store plaintext passwords, or seed sample production data.
- Preserve English/Urdu and RTL support.
- Run flutter analyze and flutter test for relevant changes. Report verification limits honestly; local tests do not establish deployed Firebase behavior.
- Do not mark checklist items verified without evidence. See MVP_REVIEW.md for known launch blockers.
- Do not deploy rules or release builds implicitly during code review.

- Super-admin authorization uses the server-issued `superAdmin` claim; email strings confer no privileges. Do not bypass the reviewed bootstrap/migration process.
- Optional local Android prayer reminders are implemented at the owner's request. Keep device delivery, reboot, and permission-revocation acceptance pending until tested; do not mark them release verified. Event attendance registration remains deferred.
