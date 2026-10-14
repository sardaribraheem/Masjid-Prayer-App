# MVP launch plan

Target: 15 October 2026 (Asia/Karachi). Launch platform: **Android only**, confirmed by the owner. Final Android application ID remains pending. Launch depends on passing the gates below, not reaching the date. This file tracks implementation and evidence; MVP_REVIEW.md records the original findings. Preserve unrelated work already in the checkout.

Status: **in progress** = work underway; **local verified** = code and local checks pass; **release verified** = staging/device checks also pass. No phase is release verified yet.

**Current decision: hold public launch.** A read-only production audit on 14 October confirms Firestore still serves the old email-based rules (release updated 16 September), incompatible with current comments, approval, and cleanup workflows. Final Android identity/signing and device acceptance also remain pending. See [production audit](scripts/qa/PRODUCTION_AUDIT.md). Local source improvements do not repair production until the reviewed migration/deployment is completed.

## Scope decisions

- Community posts/comments are text-only. Use existing Firebase Auth + Firestore; do not introduce Storage or a paid backend for the MVP.
- New imam accounts start as ordinary members and submit approval requests. A trusted super-admin grants management access.
- Super-admin access comes from a server-issued `superAdmin` custom claim, never an email string or editable user field.
- A manager must have an imam/admin user role, a matching masjid association, and membership in that masjid's protected `authorizedImamUids` list.
- Existing anonymous posting hides the display name only; do not promise that other readers cannot discover the author UID.
- Defer attendance registration for this MVP; source inspection found no persistence or registration UI despite checklist claims. Revisit it after the launch-critical flows work.
- The owner requested optional prayer reminders on 14 October. Implement the local Android scheduler and user-selected lead time; include it in release only after device delivery/permissions/reboot acceptance. Attendance remains deferred.
- Do not promise automated archival. Define actual deletion/retention behavior and update privacy text.

## Phase 1 — Authorization and imam onboarding (8–9 October)

**Status: local verified; staging/migration pending.** Addresses review blocker 1 and imam-onboarding parts of 3.

- [x] Reject self-created imam/admin roles, approved verification, and elevated event permission.
- [x] Prevent users from changing manager associations or granting management via masjid edits.
- [x] Replace email-only super-admin authorization with a trusted custom claim; provide an explicit bootstrap/migration procedure.
- [x] Register imam applicants as members with a pending new-masjid request, atomically.
- [x] Approve requests in a transaction that creates/links the masjid, assigns the user, and marks the request reviewed. Reject repeated approval and missing applicants/masjids.
- [x] Wire claim provider, dashboard navigation, and reliable role hydration into the app.
- [x] Run rules emulator tests for authorized and denied operations, Flutter checks, and formatting/diff checks.

**Gate:** a member cannot become imam, move a manager grant, edit a different masjid, impersonate a claimant, or obtain super-admin access by email. An approved applicant can manage only the assigned masjid. Approval failures do not leave partial role assignments.

**Production prerequisite:** use a trusted Admin SDK environment to grant the known administrator UID `superAdmin: true`. Review existing elevated users and masjid lists before deployment: old rules allowed unauthorized creation. Never bulk-trust every existing role. Test the migration on staging, refresh the administrator's token, then deploy reviewed rules with the compatible app.

## Phase 2 — Account lifecycle and member workflows (9–10 October)

**Status: core implementation and rules locally verified; client/device acceptance and legacy data migration pending.** Addresses blockers 2 and 3 and account-switching risks.

- [x] Implement a retryable Spark-compatible cleanup: freeze contributions with a deletion marker; remove UID-attributed posts and child comments, authored comments/events, claims, and profile in batches; delete Auth only after cleanup succeeds. Legacy content without creator UIDs requires reviewed migration. Attendance registration is deferred.
- [x] Require recent authentication before cleanup; support email/password and configured Google sign-in. Surface failed cleanup without a false success message.
- [x] Handle manager-owned masjids explicitly: revoke access safely or require transfer before account deletion. Do not orphan community administration.
- [x] Prevent deleted-user records or asynchronous role loads from restoring an old session.
- [x] Allow a member to request verification for an existing selected masjid without self-approving.
- [x] Add scoped manager review UI with approve/reject actions; lock protected roles and association fields.
- [x] Allow eligible verified members to propose pending events; publication requires manager approval unless explicit full permission was granted.
- [x] Fix event document IDs. Attendance registration is absent; explicitly defer it and remove completion claims. Pending event reads now require author/manager access; approved-event queries are public.
- [x] Test cleanup ownership/retry, recent-auth restrictions, verification transitions, and pending-event visibility against the emulator.
- [ ] Run the actual client cleanup with interruption/Auth failures on staging; verify email/password and configured Google reauthentication on Android.
- [ ] Validate account switching/revocation and profile changes on-device; ensure no private review screen remains visible after logout.

**Gate:** deletion fails visibly and remains retryable until cleanup is complete; verification and event proposals persist with rules enforcing the same permissions as the UI. No privileged account survives an association switch.

## Phase 3 — Community reliability, cost, and truthful behavior (10–12 October)

**Status: implemented with local QA; broader device and staging acceptance remains open.** Addresses the remaining feed/privacy findings.

- [x] Align guest UI and read rules; approved events and community reading must behave as advertised, while private/pending content stays protected.
- [x] Add bounded post/event queries and pagination without hiding the manager's pending queue.
- [x] Remove duplicate fetch/listen requests; correctly cancel/resubscribe on user and masjid changes and display stream errors/retries.
- [x] Add older-comment pagination, author/manager delete controls, and parent-deletion handling. Firestore does not recursively remove subcollections; explicitly handle orphan comments.
- [x] Community, comment, event, and answer forms disable duplicate submissions and close only after successful saves; failures retain their drafts.
- [ ] Complete failure/recovery acceptance for profile, imam onboarding, and claims on Android and staging.
- [x] Make Upcoming/Nearby/All filters change the actual results; remove controls that have no meaningful MVP behavior.
- [x] Update privacy policy, English/Urdu strings, notification UI, README, and FINALTODO to match tested capabilities.
- [x] Check browser light/dark, English/Urdu RTL, text-only community controls, and narrow layouts.
- [ ] Complete actual Android keyboard, long input, restart, offline/reconnect, and accessibility acceptance across every form.

**Gate:** no unbounded feed reads, no duplicate listeners after navigation, no inaccessible error states, no orphaned comment promises, and no UI or policy claims for absent features.

## Phase 4 — Release configuration (12–13 October)

**Status: debug build verified; final identity, signing, and device acceptance pending.** Addresses blocker 4 and native configuration.

- [x] Confirm Android-only launch scope.
- [ ] Confirm the final application ID before changing Firebase registrations.
- [x] Remove debug signing fallback and require ignored owner-controlled release signing configuration.
- [ ] Supply and verify the owner's release keystore and final identity in the reviewed release environment.
- [x] Android initializes from native Firebase configuration; omit Google sign-in UI by default. Build the current source as an ARM64 debug APK.
- [ ] Verify signed startup, Firebase authentication, password recovery delivery, and persistence on Android. Missing-config startup recovery remains to be accepted.
- [ ] Build release APK/AAB, verify installed behavior on target Android devices, version/build number, permissions, icons, and store metadata.
- [x] Document Android-only launch, browser QA scope, and placeholder native platforms.

**Gate:** a reproducible release build uses the intended Firebase app and release signing; real-device authentication and data operations pass. Application identity/signing choices require the owner's concrete values.

## Phase 5 — Release acceptance and deployment (13–15 October)

**Status: pending.** Addresses missing end-to-end evidence.

- [ ] Run the security suite and Flutter checks with final rules/indexes.
- [ ] Use staging accounts: guest, member A, member B, verified member, imam, super-admin. Test denied operations directly as well as normal UI flows.
- [ ] Exercise registration, verification, claims, prayers, proposals/approval, posts/comments, logout/switching, deletion/retry, offline/reconnect, and persistence after restart.
- [ ] Run light/dark, English/Urdu RTL, small-screen keyboard, long-name/text, and empty-state checks on target devices.
- [ ] Complete [Android prayer reminder acceptance](scripts/qa/PRAYER_REMINDERS.md): 15/20/custom lead, opt-in/denial/revocation, app closed, Friday, mosque/time changes, reboot, and signed installation.
- [ ] Review production role migration, Firestore indexes, usage limits, support contact, privacy/deletion policy, rollback plan, and database backup/export options available to the project.
- [ ] Record evidence and unresolved failures here. Deploy only after the reviewed rules/app migration is ready and deployment is authorized.

**Launch decision:** all security/data-loss blockers fixed; acceptance checks pass; remaining limitations are explicitly documented. Hold launch if any privilege escalation or unreliable deletion remains.

## Implementation log

### 14 October — configurable prayer reminders and production audit

- Added opt-in local Android reminders, default 15 minutes, presets including 20, and custom whole minutes from 1–60. Saved preferences, permission recovery, weekly exact scheduling, Friday Jummah, midnight/DST handling, native receivers, schedule replacement on mosque/timetable/locale changes, and a one-minute test are implemented. Browser platforms show the Android-only state; no paid server or Storage uploads are added.
- Added 28 reminder calendar/provider/storage/widget tests. Final Flutter analysis is clean and all 38 Flutter tests pass. English/Urdu lead controls, 20/custom 17, invalid 61 and reload persistence were checked through Playwright; the Urdu picker was inspected at 320px. These checks cannot establish native notification delivery.
- Hardened post metadata/ISO-date/ID validation and event metadata on create/update; blocked posts/events under missing/deleted mosques. All 35 local rules tests pass. Existing legacy schemas require migration review; ISO strings remain unchanged for feed ordering compatibility.
- Retrieved the actual deployed Firestore rules read-only: they differ from local rules and retain email-based administration. Current comments, verification/approval and cleanup workflows are incompatible. [PRODUCTION_AUDIT.md](scripts/qa/PRODUCTION_AUDIT.md) records evidence and the required migration/deployment sequence. No production write, rule/index deployment, administrator grant or release publication occurred.
- Android delivery/reboot/revocation acceptance remains open; follow [PRAYER_REMINDERS.md](scripts/qa/PRAYER_REMINDERS.md). Final application ID, signing and staging/production acceptance remain launch gates.
- Native build attempts hit workstation disk exhaustion during dependency downloads. The final attempt after clearing generated caches is pending; the earlier debug APK predates reminders. Do not confuse the earlier APK evidence with a successful build of this feature.

### 8 October — starting Phase 1

Plan created. Initial review found claim approval changed only request status, imam registration bypassed approval, the claim provider was not registered in main.dart, and the dashboard had no settings entry. These must be repaired together with the authorization rules.

### 8 October — Phases 1 and 2 implementation

- Rules reject privilege escalation and manager reassignment; managers also need a protected masjid grant. Super-admin uses `superAdmin: true` from a trusted ID token.
- Imam registration commits a member profile and pending request together. Approval creates/links the masjid, assigns the applicant, and reviews the request atomically. The dashboard/provider/settings navigation are wired. A trusted administrator bootstrap tool defaults to a read-only preview; it was not executed against Firebase.
- Role hydration cancels listeners and rejects stale account loads; profile edits now update Firestore as well as Auth. Management/review screens check the current session.
- Deletion requests reauthenticate, freeze new content, remove owned data in batches, and surface failures. Completed batches remain deleted after interruption; the UI explains retries. The profile is removed after content and before Auth. If Auth deletion then fails, retry remains available; final deletion is not a cross-service transaction. Manager transfer and unidentified legacy content require reviewed admin operations.
- Members can request verification; scoped managers approve/reject. Verified members can submit events with backend-enforced approval/full permission. Events preserve real document IDs and author metadata. Pending events are private; guests read approved events and community text.
- Validation: `flutter analyze` clean; 6 Flutter model tests passed; 27 Firestore emulator cases passed using `demo-masjid-rules`; JavaScript syntax checks passed. These rule tests do not establish client UI behavior or production deployment.
- No production rules/indexes/claims/data changed. Deploy the new indexes together with reviewed rules and the compatible app after migration and staging checks. Remaining work starts at Phase 3; Phase 2 client acceptance also remains open.


### 14 October — UI, reliability, and local acceptance

- Redesigned prayer times, masjid selection, public feeds, and settings around a shared emerald/cream Material theme. Dark mode uses readable theme colors; fonts and six Streamline Nova icons are bundled. English/Urdu changes update visible screens immediately, and Urdu masjid names are searchable.
- Location is optional and requested explicitly. Timetable parsing/countdowns handle unset times, sunrise, ordering, midnight, and Friday Jummah safely. Notification scheduling and attendance remain excluded.
- Post/event/comment reads are bounded and paginated. Removed duplicate initial reads, added refresh/error recovery, kept older pages stable, and queried manager pending events separately. Explicit post cleanup blocks new replies and removes descendants before the parent.
- Event categories now agree between creation and filtering. Upcoming filters dates/end times; the ineffective Nearby control was removed. Event/answer dialogs preserve failed drafts, and answer cards update after saves. Password recovery and accessible password controls are available in login; signup returns to the signed-in app and passes a 320×400 browser check.
- Privacy and README now describe public text, name hiding, optional location, real retention, retryable deletion, and release limits. QA fixtures use only hardcoded localhost demo endpoints.
- Evidence: 31 Firestore emulator tests, 10 Flutter tests, clean analysis, an ARM64 Android debug APK, and 29 repeatable Playwright assertions against local Auth/Firestore. See [UI_QA.md](scripts/qa/UI_QA.md) for the tested flows and exact limitations. No Android device was connected; no signed release or production deployment was performed.
- Remaining gates: final application ID, owner signing, reviewed grants/legacy migration, trusted super-admin bootstrap, production indexes/rules, staging interruption/restart failures, actual Android keyboard/offline/restart/deletion acceptance, and store metadata. Local success is not a launch certification.


### 14 October — restrained prayer-page follow-up

The owner requested a small undo of the prayer redesign. Restored individual timetable cards, separated name/time columns, and familiar Material time-of-day icons; reduced next-prayer typography and omitted the zero-hour countdown segment. Verified clean analysis, 10 Flutter tests, and Playwright screenshots at 390×844 English/light and 320×640 Urdu/dark. The scheduling and Firestore behavior remain intact. Device and release gates remain pending.
