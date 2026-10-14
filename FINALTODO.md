# Masjid App — Master Requirements Checklist (FINALTODO.md)

> **Instructions**: This is the master requirements checklist and source of truth across all coding sessions.
> Status legend:
> `[ ]` Not started
> `[~]` In progress
> `[x]` Implemented AND verified (must meet all criteria: implementation exists, correct data flow, backend/security exists, UI exists, tested, no known regression)
> `[!]` Blocked

---

## SESSION 1 — FOUNDATION, AUTH, MASJID, ROLES, SECURITY

### 1. User hierarchy
- [~] Level 1 (Normal user / guest capabilities & restrictions)
- [~] Level 2 (Email-verified app user can ask questions)
- [~] Level 3 (Verified Muqtaddi request & imam approval workflow)
- [~] Level 4 (Imam role verification, masjid linkage, and management permissions)
- [~] Level 5 (Ultimate Admin verification and administrative functions enforced by backend security)

### 2. User Login / Authentication
- [~] Investigate and fix login & masjid registration flow issues (Imam login & new masjid registration)
- [~] Test normal user login, email verified user, Imam login, logout, account switching, and account registration

### 3. App User Email
- [x] Keep app user email separate from optional Imam contact email

### 4. Masjid Credentials
- [~] Secure masjid authentication/credentials mechanism compatible with Firebase (No plaintext passwords in Firestore)
- [~] Restrict masjid management strictly to authorized managers

### 5. Masjid Registration
- [~] Implement/fix masjid registration (name, credential, location, Jamia toggle, optional Imam info, creator relationship)

### 6. Masjid Verification
- [~] Persisted verification-request workflow (statuses: pending, approved, rejected)

### 7. Muqtaddi Verification
- [~] Muqtaddi requests verification for selected masjid; Imam accepts/rejects; permissions update; Firestore rules prevent self-promotion

### 8. Firestore Security
- [~] Audit and enforce comprehensive Firestore rules (`firestore.rules`) preventing self-promotion, self-verification, role tampering, and unauthorized management

### 9. Masjid Name Bugs
- [x] Fix long masjid names wrapping/truncating correctly across light and dark modes
- [x] Fix stale data / caching issues when masjid name changes

### 10. Masjid List Dark Mode
- [x] Ensure masjid containers/cards have darker backgrounds, readable white/light text, and clear selected state in dark mode

### 11. Cache Management
- [~] Optimize cache management to avoid unnecessary reads, stale data, and ensure sensitive user data/state is cleared on logout/account switch

---

## SESSION 2 — PRAYER, EVENTS, COMMUNITY, QUESTIONS

### 12. Namaz Notifications
- [~] Optional local Android reminders implemented: default 15 minutes, presets including 20, custom 1–60 minutes, persisted opt-in, permission handling, Friday Jummah, timetable/masjid refresh, cancellation, and a one-minute test. Calendar/provider/storage and English/Urdu controls pass local tests. Delivery with the app closed, reboot, denied/revoked permissions, OEM battery behavior, and signed Android acceptance remain pending; see scripts/qa/PRAYER_REMINDERS.md.

### 13. Prayer Page
- [x] Normal user view with prayer times, sunrise, sunset, countdown ("X hours remaining"), and localized prayer names

### 14. Urdu Prayer Names
- [x] Implement dynamic localization for prayer names in Urdu without hardcoded English/Urdu pairs in widgets

### 15. Prayer Editing for Imam
- [x] Contextual edit button on prayer interface opening prayer edit page for authorized Imams

### 16. Event Page
- [x] Rename navigation semantics: Community page -> Events, Questions page -> Community
  - The bottom navigation now presents the actual event/community split: Events and Community, with the events feed gated to approved items and the community Q&A flow separate.

### 17. Event Creation & Approval
- [~] Allow eligible users to propose events, requiring Imam/admin approval (accept/reject workflow)

### 18. Event Categories
- [x] Unified canonical event category definition across creation and filtering; rename "Tablighi Jammat" to "Jammat"

### 19. Event Management for Imam
- [~] Imam event interface with management controls and pending event requests review bar

### 20. Event Registration
- [ ] Source inspection found no attendance registration UI or persistence. Deferred for this MVP; old completion claim removed.

### 21. Community Page
- [~] Community posts are text-only; media inputs and previews removed from both posting screens. Existing attachments are not deleted from production.

### 22. Question Posting & Comments
- [~] Text posts (up to 4,000 characters) and comments (up to 1,000 characters) implemented. Comments load on demand, newest 30 first with older pagination and delete controls. Local emulator/Playwright persistence is verified; production rule deployment and Android acceptance remain pending.

### 23. Community Permissions
- [~] Post author UID and text-only schema validated by local rules. Comment authors and server timestamps validated. 31 local rule tests pass, including role denial, text limits, and deletion races. Production migration/deployment and device acceptance remain launch gates (launchplan.md).

### 24. Imam Question Management
- [~] Imam/admin question management is supported through the live Q&A flow and answer storage in Firestore.

### 25. Community Content Lifecycle & Custom Expiry
- [~] The app supports the core approval and answer lifecycle for events and questions, but the broader social-media expiry/history model is still not implemented as a custom content-retention feature.

---

## SESSION 3 — PROFILE, SETTINGS, PRIVACY, QA

### 26. Profile
- [x] Simple profile showing user name, verification badge/status, role, and app-account email

### 27. Settings
- [~] Settings page including Privacy Policy, Help & Support, Logout (at bottom), and Delete Account

### 28. Help & Support
- [x] Help & Support opens `mailto:sardaribraheem277@gmail.com` via mail client intent

### 29. Privacy Policy
- [~] English/Urdu privacy describes actual account data, public text/approved events, optional location, retention, and retryable deletion. Attendance registration is explicitly absent; release review remains pending.

### 30. Delete Account
- [~] Real Firebase Auth account deletion flow with proper data cleanup and logout

### 31. Keyboard UI Bug
- [~] Prevent keyboard from corrupting layouts, covering fields, or pushing buttons off-screen across all key forms

### 32. Streamline Icons
- [~] Streamline Nova icons cover navigation and the community header. Prayer rows now use familiar Material time-of-day icons; categories and management also use Material. Do not claim every control uses Streamline.

### 33. Fake / Sample Data
- [x] Remove production reliance on `FirebaseService.initializeSampleData()`

### 34. Firebase Runtime Verification
- [~] Rigorous runtime verification of real Firestore-backed data persistence across all core features

### 35. Playwright / UI QA
- [~] Comprehensive UI QA testing via Playwright across light/dark modes, Urdu, RTL, long names, login, events, questions, settings, and forms

### 36. FinalTODO Completion Rule
- [~] Update FINALTODO.md honestly at the end of every session with verifiable evidence

## 2026-10-08 MVP review
Prior completion claims are not release evidence. See MVP_REVIEW.md for source-confirmed blockers and pending verification.

## Launch implementation tracker
[launchplan.md](launchplan.md) tracks current phases and evidence. Phase 1 and the core Phase 2 code/rules pass local checks; production migration, client acceptance, and Android device QA remain open. Earlier checks do not certify the current build.

## 2026-10-14 reminders and deployed security audit

Optional configurable Android reminders are implemented and pass 28 new local logic/UI tests (38 Flutter tests total), with clean analysis. Playwright checked lead selection, custom validation, persistence and Urdu layout. Native delivery/reboot and signed device acceptance remain pending. Post/event metadata rules and orphan-parent checks pass 35 local rule tests.

The current reminder source builds as an ARM64 debug APK after clearing generated caches to resolve workstation disk exhaustion. This establishes compilation, not actual notification delivery or release readiness.

The read-only production audit confirmed the old deployed email-based rules from 16 September, missing current comment/approval/cleanup permissions. Public launch remains blocked until the reviewed migration, trusted grants, coordinated rules/index deployment and staging/device acceptance pass. See scripts/qa/PRODUCTION_AUDIT.md; no production changes were made.

## 2026-10-14 connected Android phone

The current APK installs on the owner's Android 14 device with existing data preserved. Native startup, English/dark prayer/settings UI, saved custom 33 minutes, 35 weekly alarms, Friday Jummah metadata and off-state cancellation were observed. The real one-minute test notification posted at 17:47:58.065 PKT with the app in the background; see scripts/qa/ANDROID_DEVICE_QA.md. This verifies one device/debug delivery scenario, not reboot, all permission/revocation cases, daily/Friday delivery, tap navigation, signed-release behavior or the deployed backend. Item 12 remains in progress.


## 2026-10-14 UI and launch-readiness pass

Shared Material theme, bundled Poppins/Streamline assets, optional location, prayer countdown edge cases, bounded feeds/comments, post cleanup, canonical event categories, real Upcoming/All filtering, refreshed settings/privacy, and login password recovery are implemented. See [UI_QA.md](scripts/qa/UI_QA.md) for browser and emulator evidence.

Analysis, 10 Flutter tests, and 31 rule tests pass; an ARM64 debug APK builds. 29 repeatable Playwright assertions verify local demo flows, including denied-save recovery and full account cleanup, not production. No Android device was available; actual keyboard behavior, signed release configuration, staging/production migration, deployed indexes/rules, and failure/restart acceptance remain open. Broad checklist items remain in progress until that evidence exists.


## 2026-10-14 prayer-page adjustment

At the owner's request, restored individual prayer cards with names and times aligned at opposite edges, distinct dawn/day/afternoon/night icons, and a slightly smaller next-prayer card. English/Urdu RTL and light/dark browser previews pass; analysis is clean and all 10 Flutter tests pass. No other screen behavior, authorization rules, or release gates changed.
