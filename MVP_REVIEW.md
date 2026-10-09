# MVP review — 8 October 2026

**Live work tracker:** [launchplan.md](launchplan.md). The findings below describe the initial baseline; implementation status is recorded there.

Initial source review, not a complete security audit or production verification. Existing uncommitted changes were preserved. Target launch: 15 October 2026 if “in a week” remains the plan.

## Launch blockers

1. **Critical: self-assigned imam and arbitrary masjid access.** `firestore.rules` allows creating one's user document with role `imam`, approved verification, and full event permission. Self-updates also allow changing `masjidId`. Together these let an attacker become a manager of an existing masjid. Replace this with trusted approval/assignment and lock manager associations. Super-admin authorization relies on an email string without checking email verification; migrate to trusted claims or an immutable server-managed grant. Resolve registration compatibility before deploying a role-policy fix.
2. **Account deletion leaves personal data.** `AuthProvider.deleteAccount` swallows Firestore deletion failures, and the rules have no user-document delete permission. Auth deletion can succeed while the user document remains; posts and event participation are not cleaned up. Build a reliable deletion/anonymization workflow including reauthentication and partial-failure recovery.
3. **Verification and event proposals conflict with rules.** User updates cannot change verification status, managers cannot read other user documents, and events can only be created by managers. Checklist claims for member verification and member proposals are not established by these rules.
4. **Android release setup unfinished.** `android/app/build.gradle.kts` uses `com.example.masjid_app` and debug signing for release. Decide the final application ID and configure release signing before store delivery.
5. **Notification feature absent.** Settings persist a boolean; no notification scheduling package or scheduling implementation is present. Remove the promise/toggle or implement and device-test it. FINALTODO item 12's completion claim is unsupported.

## Other findings

- Guests are told they can read community content, but question/event read rules require authentication. Align the promised behavior and rules.
- QuestionProvider and the repository load the complete post history; comments are capped but posts still need pagination. Initial screens also do a one-shot fetch plus a listener.
- Comment display currently shows only the newest 30; older-comment pagination and moderation/delete controls need a follow-up. Deleting a post does not recursively delete its comment subcollection.
- Publicly readable post documents include author UIDs even for anonymous posts. Anonymity is a display choice, not backend identity secrecy.
- Privacy policy claims automatic content archival/removal, but FINALTODO says retention is incomplete. Correct the policy to match implementation.
- Events' Upcoming/Nearby/All buttons change selected state but do not affect filtering in CommunityPage.
- Native Firebase setup and release builds need target-device verification. README describes platform placeholders; documentation and checklists disagree about completion.
- Existing test coverage is a small set of model tests, not security-rule or end-to-end coverage.

## Changes in this review

- Added AGENTS.md project guidance for future sessions.
- Removed community image/video URL entry and previews. New question serialization excludes media fields; legacy attachments are hidden, not destroyed. Separate event media behavior remains unchanged.
- Added text comments under `masjids/{id}/questions/{id}/comments`, loaded only when opened. Requires signed-in posting, a server timestamp, and bounded text via local rules.
- Fixed post document IDs in repository reads and writes so answers/comments target actual documents.
- Removed subscription creation from QuestionsPage.build; added stream error handling. Failed posts retain their draft and posting is disabled during submission.
- Added post length validation and creator UID/schema enforcement in local rules.

## Before release

Prioritize role authorization and deletion, then verify registration/verification/event workflows against Firebase emulators and staging. Test two users plus imam/admin and denied operations. Test community posting, comments, empty/long text, retries, keyboard layout, Urdu/RTL, account switching, and masjid switching on the target devices. Configure release identity/signing, run a release build, and make documentation/privacy claims accurate. Deploy reviewed rules only after verification.

No production data was deleted and no rules were deployed during this review. Current production rules were not retrieved; findings refer to repository rules.

## Local validation

`flutter analyze`: no issues. `flutter test`: all 6 tests passed. `git diff --check`: passed. No Firebase emulator, production round-trip, or device UI testing was performed in this pass.

## Follow-up implementation — 8 October

Phase 1 authorization and approval workflows are implemented locally. Phase 2 now includes reauthentication, retryable Firestore cleanup, member review UI, verified event proposals, real event IDs, and private pending-event rules. All 27 emulator rule tests and 6 Flutter model tests pass; Flutter analysis is clean. These are local checks, not staging or device acceptance.

Deletion cleans the currently implemented collections: UID-attributed questions and their comments, authored comments/events, masjid requests, and the profile, followed by Auth deletion. Incoming comments on a deleting author's posts are blocked to avoid a cleanup race. Managers and super-admins require a reviewed transfer/revocation first. Legacy content without creator UIDs cannot be safely attributed automatically; production migration must review it. Event attendance registration is absent and deferred for this MVP. No rules, indexes, administrator claims, or production data were changed remotely.
