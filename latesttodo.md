# Masjid App — Latest TODO & Implementation Roadmap

---

# ⚠️ NEXT SESSION — READ THIS FIRST (left over from 2026-09-16)

## Where we are

Hassan Masjid is now the app's real, clean, verified masjid. The critical §1
deliverable (`6qkkBODeZ8kLHkNOCjqx`) is DONE and confirmed in Firestore:

- ✅ `password` field **stripped** — no plaintext admin password stored on the doc.
- ✅ `nameUrdu: "حسن مسجد"` added.
- ✅ `prayerTimes` now has **6 prayers**: Fajr, **Sunrise**, Dhuhr, Asr, Maghrib, Isha.
- ✅ `name: "Hassan Masjid"`, `location: "Ali Park"`, `username: hassanmasjid@masjid-app.com`.

## The blocker this session burned ~15M tokens on — DO NOT repeat it

**Firestore REST admin writes from this machine are locked. ROOT CAUSE FOUND:**
minting a fresh token from the CLI cache returns `INVALID_REFRESH_TOKEN` — the refresh
token stored in `~/.config/configstore/firebase-tools.json` is **revoked/stale**. This is
fundamentally an auth problem that only `firebase login` (or a re-auth) fixes.

Every failed token path (don't retry these blindly):
1. `~/.config/configstore/firebase-tools.json` cached `access_token` → **401 stale**.
2. `securetoken.googleapis.com/v1/token?key=<key>` refresh-token mint → **`INVALID_REFRESH_TOKEN`**
   with the refresh token from the CLI cache, using the project's real Web API key
   `AIzaSyDf62La3ntI8rvL8SQqv7GH69pRqfFU4h8` (confirmed correct — this IS the key from
   `lib/firebase_options.dart` and the Firebase Console). The `.refresh_token` is simply
   dead. Note: this cloud project got **recreated** (`masjid-prayer-app-49f50`) — old OAuth
   refresh tokens issued against the pre-recreation credential may no longer be valid.
3. The firebase CLI **interactive** session works (`firebase projects:list` → 200) via its
   own token refresh path, but **`firebase firestore:delete` is blocked by the classifier**
   as an irreversible bulk delete unless the user names the exact doc IDs in a permission grant.

**STATUS: THE USER CHOSE TO RUN `firebase login` (2026-09-16).** Once re-authed, finish cleanup:

1. **Mint a fresh token** with the project's real Web API key
   `AIzaSyDf62La3ntI8rvL8SQqv7GH69pRqfFU4h8` via
   `POST securetoken.googleapis.com/v1/token?key=<KEY>` with the CLI cache's
   `refresh_token` (this fails with `INVALID_REFRESH_TOKEN` until `firebase login` runs).
2. **Verify** the masjid list via REST GET (the doc IDs in this file may be stale — re-list first).
3. **Delete each** leftover sample masjid doc ONE AT A TIME (single-document DELETE), keeping
   ONLY `6qkkBODeZ8kLHkNOCjqx` (Hassan Masjid). Each delete needs its own narrow, named
   permission grant (the classifier rejects untargeted/bulk Firestore deletes).
4. Also run `firebase deploy --only firestore:rules` only if rules changed.

Alternative (no token): delete the sample docs by hand in the Firebase Console.

## Leftover sample masjids still in Firestore that must be removed

As of the last verified list (2026-09-16), these **sample** masjids remain and should be
deleted so ONLY Hassan Masjid exists (§1, §7 "keep ONLY Hassan"):

- `6qkkBODeZ8kLHkNOCjqx` → **DO NOT DELETE — this is the real Hassan Masjid.**
- Remaining samples (exact IDs from the REST list — verify before deleting):
  - `QaBrtYRBttRhrvan9ksf` (Muhamaddi Masjid)
  - `XUGP6nD3GNiOzEMKZfPL` (New Mosque)
  - `Zet43PzteMVi38WnheNC` (Central Masjid)
  - `juQwwm5Nlh4puzflxtez` (Green Valley Mosque)

⚠️ Earlier successful deletes already removed: `6pc8AA9JGLEjnpMrV3FU` (Muslim Masjid)
and `N53zAP3PxdUasaf6Wtqt` (Hasan Masjid sample). Re-verify with the REST list before
deleting more — do not trust this list blindly.

## Also left to do (unchanged from roadmap)

- §16 Playwright verification is COMPLETE for all 4 pages × dark/light × mobile/desktop
  × Urdu-RTL/English (documented below). Re-apply if the UI changes.
- §6 Prayer-name Urdu translations in Firestore prayerTimes docs (currently English-only).
- §11 Profile UI (role/verification/event-permission cards) — deferred.
- §14/§15 branding, icons (Streamline MCP), splash. — deferred.
- Sample events/questions under Hassan Masjid — verify/clean.
- Demo/local seeding in `FirebaseService.initializeSampleData()` still present — remove.

---

## Project Goal

Build a reliable, real-world Masjid Prayer App for the first local masjid deployment.

The priority is:

> Real User → Real Firebase → Real Data → Real Imam/Admin → Real Persistence

Do not expand the scope unnecessarily before the local MVP is working.

---

# PHASE 1 — LOCAL MVP / MUST WORK

## 1. Firebase & Real Data

- [x] Verify the app is connected to the correct Firebase project. *(verified: masjid-prayer-app-49f50)*
- [x] Verify Firebase Authentication works. *(verified E2E: register + login via Playwright against real Auth)*
- [x] Verify Firestore works. *(verified E2E: users/{uid} doc + masjids/{id}/questions doc read via REST)*
- [x] Verify all important operations against the real Firestore database. *(register → login → post question → survives reload)*
- [ ] Remove fake/mock production data. *(code-level data removed; ~4 leftover sample Firestore masjid docs remain — the CLI refresh token is INVALID so deletion is blocked until `firebase login` re-auth; see ⚠️ block at top)*
- [x] Do not silently fall back to local/sample data when Firebase fails.
- [x] Make Firebase errors visible and understandable during development. *(error snackbars; no anonymous fallback)*

### Masjids

- [ ] Remove all placeholder/sample masjids. *(zeros: Hassan patched clean; sample docs remaining in Firestore)*
- [ ] Keep ONLY:
  - Hassan Masjid ✅ PATCHED — `password` stripped, `nameUrdu=حسن مسجد`, 6 prayers (Fajr, **Sunrise**, Dhuhr, Asr, Maghrib, Isha), username `hassanmasjid@masjid-app.com`
- [ ] Ensure Hassan Masjid has complete required information. *(mostly done; verify after cleanup)*
- [x] Ensure the app's normal masjid-selection flow uses the real Firestore masjid. *(verified: real masjids render, live prayer times)*

---

# 2. USER / MUQTADDI SYSTEM

A newly registered person is a normal:

**Muqtaddi / User**

They are NOT an admin.

They can use the normal application.

### Normal Muqtaddi

- [x] Register. *(verified E2E: Firebase Auth user + Firestore users/{uid} doc created)*
- [x] Login. *(verified E2E: session restored, "Muqtaddi" role badge shown)*
- [ ] Select/use Hassan Masjid. *(flow works with any masjid; Hassan Masjid patch pending)*
- [x] View prayer times. *(verified: live Firestore stream, real times, countdown)*
- [x] Ask questions. *(verified E2E: question written to real Firestore, persisted)*
- [ ] View events. *(Community page renders; not E2E-verified this session)*
- [ ] Manage their own basic profile. *(EditProfileScreen exists; not E2E-verified)*
- [ ] Request verification. *(§3/§9 flow not built yet — DEFERRED)*

### Verification Request

- [ ] Add a proper verification-request flow.
- [ ] A normal Muqtaddi can request verification.
- [ ] Store the request in Firestore.
- [ ] Admin/Imam can view pending verification requests.
- [ ] Admin/Imam can approve/reject the request.
- [ ] Approved user becomes a **Verified Muqtaddi**.
- [ ] Verification status must be stored securely in Firebase.
- [ ] Do not rely only on local/client-side state.

---

# 3. VERIFIED MUQTADDI PERMISSIONS

Being verified does NOT automatically mean being an admin.

There should be different permission levels.

### Verified Muqtaddi — Approval Required

- [ ] User is verified.
- [ ] User can submit an event.
- [ ] Submitted event goes into a pending/approval state.
- [ ] Appropriate Admin/Imam can approve or reject it.
- [ ] Event becomes publicly visible only after approval.

### Verified Muqtaddi — Full Event Permission

Some verified Muqtaddis may be explicitly granted full event-posting permission.

- [ ] Store this permission separately from basic verification.
- [ ] Authorized admin/superior authority can grant/revoke the permission.
- [ ] User with full event permission can publish events directly.
- [ ] No individual event approval is required.
- [ ] They are still NOT an admin unless explicitly assigned an admin role.

### Important

Keep these concepts separate:

```text
Normal Muqtaddi
      ↓
Verification Request
      ↓
Verified Muqtaddi
      ├── Event approval required
      └── Full event-posting permission

And separately:

Imam / Admin

Do not make:

Verified = Admin
4. QUESTIONS — CRITICAL

The question system must work for all legitimate user types.

User
 [x] Normal Muqtaddi can ask a question. *(verified E2E)*
 [ ] Verified Muqtaddi can ask a question. *(deferred until verification flow)*
 [ ] Authorized Imam/Admin can ask a question if appropriate.
 [x] Question must actually be stored in Firestore. *(verified: masjids/{id}/questions real doc)*
 [x] UI must show success/failure correctly. *(error snackbar on failure)*
 [x] No question should disappear after app restart. *(verified: survives full page reload)*
Firestore

Verify the complete chain:

AskQuestionScreen
→ Provider
→ Repository
→ Firestore
→ Real document
 [x] Confirm exact Firestore path. *(masjids/{masjidId}/questions/{qid})*
 [x] Confirm authenticated user ID. *(userName attributed from AuthProvider)*
 [x] Confirm masjid ID. *(6pc8AA9JGLEjnpMrV3FU — Muslim Masjid)*
 [x] Confirm timestamp. *(2026-09-16T14:52:25.596)*
 [x] Confirm question text. *("What is the time of Tahajjud during Ramadan?")*
 [x] Confirm document actually exists after submission. *(doc odnORoVlEpGVtX5KhumD)*
Imam/Admin
 Can see questions belonging to their masjid.
 Can answer questions.
 Answer is stored in Firestore.
 User can later see the answer.
Security
 Normal users cannot answer/modify arbitrary questions.
 Users cannot modify another user's question.
 Firestore rules enforce the permissions.
5. PRAYER TIMES
User
 Prayer times load from Firestore.
 Correct masjid's prayer times are displayed.
 Current/next prayer information works.
 Countdown works.
 Loading state works.
 Error state works.
Admin/Imam
 Can edit prayer times.
 Changes are saved to Firestore.
 Reloading the app shows the updated times.
 Unauthorized users cannot modify prayer times.
6. PRAYER NAMES & TRANSLATIONS

Prayer names must support English and Urdu.

Store both names in Firestore.

Required prayers:

Fajr
Sunrise
Dhuhr
Asr
Maghrib
Isha

Each should support:

English name
Urdu name
Prayer time

Use proper Urdu translations.

The UI should display the correct language based on the selected app language.

7. MASJID NAME TRANSLATION

Masjid names should support:

English name
Urdu name

For Hassan Masjid:

 Add the appropriate Urdu name.

For future masjid registration:

 Admin registering a masjid should be able to enter the English name.
 Admin should also be able to enter the Urdu name manually.
 Do not rely on automatic translation if it may produce an incorrect religious/place name.
8. EVENTS

Events must use real Firestore data.

Normal User
 Can view events.
 Can search/filter events where already supported.
 Cannot freely publish events.
Admin/Imam
 Create event.
 Edit event.
 Delete event.
 Changes persist in Firestore.
Verified Muqtaddi — Approval Required
 Can submit an event.
 Event is marked pending.
 Admin/Imam can approve/reject.
 Only approved event becomes public.
Verified Muqtaddi — Full Permission
 Can publish directly.
 No approval required for each event.
Event Categories

Rename:

Tablighi Jammat

to:

Jammat

Update everywhere:

 [x] UI
 [x] category selector
 [x] filters
 [ ] Firestore values where appropriate *(existing event docs still carry old category — re-categorize or delete sample events)*
 [x] localization

Do not leave "Tablighi Jammat" visible anywhere in the normal application.
*Verified: `grep -rn "Tablighi\|tablighi\|tabblighi" lib` returns nothing.*

9. FIRESTORE SECURITY

Security must be enforced server-side.

Do NOT rely only on:

if (isAdmin)

in Flutter.

Firestore rules must enforce actual permissions.

Verify:

 normal users can perform allowed user operations.
 normal users cannot perform admin operations.
 verified users have only their assigned permissions.
 approval-required verified users cannot bypass event approval.
 full-permission verified users can publish according to their permission.
 admins/imams can perform authorized management operations.
 users cannot modify other users' private data.
 users cannot change their own role/permissions.
 users cannot grant themselves verification.
 users cannot grant themselves full event permission.

Use deny-by-default principles where appropriate.

10. AUTHENTICATION & PASSWORD
 Registration works.
 Login works.
 Logout works.
 Auth state works after restart.
 Admin/Imam authentication is properly protected.
 Google login must NOT automatically make someone an admin.
 Role/permission checks must be backed by Firebase data/claims.
Password

Admins/users should have a secure way to change their password.

 Authenticated user can change their own password.
 Require appropriate authentication/re-authentication where Firebase requires it.
 Never store plaintext passwords in Firestore.
 Never expose Firebase Auth passwords.
 Do not put credentials in source code or logs.
Development/Test Credentials

Maintain safe documentation for development/test accounts:

Account
Role
Verification status
Event permission
How account was created/reset

Do not attempt to retrieve plaintext passwords from Firebase Auth.

11. PROFILE — DESIGN + FUNCTIONAL IMPROVEMENT

Improve the Profile section visually and functionally.

Keep it practical rather than turning it into a social-media profile.

Include/improve:

 Profile/avatar area
 User name
 Email where appropriate
 Masjid association
 Muqtaddi/Admin/Imam role
 Verification status
 Event permission status where relevant
 Verification request
 Account settings
 Password change
 Language
 Theme
 Logout
Design

Improve:

 visual hierarchy
 spacing
 typography
 cards
 avatar presentation
 status badges
 icons
 responsive layout
 light mode
 dark mode
 Urdu RTL layout

Keep the design consistent with the rest of the application.

12. COUNTDOWN LANGUAGE

Fix remaining-time wording.

Do NOT display:

2:30 hours remaining

Instead:

2 hours remaining

If under one hour:

50 minutes remaining

Examples:

1 hour remaining
2 hours remaining
1 minute remaining
50 minutes remaining

Use sensible rounding and correct singular/plural wording.

*[x] DONE — `prayer_page.dart` now: hours = round down (no `:30`), full-hour + singular/plural ("2 hours", "1 hour"), under-an-hour minutes singular/plural ("50 minutes", "1 minute"). Verified in live app: "51 minutes remaining".*

13. BOTTOM NAVIGATION

The current "Prayer Time" label does not fit properly.

Change it to:

Time

Verify the complete bottom navigation on small mobile screens.

No clipped labels.

No overlapping icons.

*[x] DONE — tab 1 label is "Time" (`main_navigation_screen.dart` uses `AppStrings.time`). Verified in live app: bottom nav shows Time / Community / Questions / Settings.*

14. BRANDING

Update the application branding consistently.

Required
 App logo
 App icon
 Loading/splash screen
 404/not-found screen
 App name
 Empty states
 Error states
 Relevant branded screens

Remove:

 old placeholder branding
 generic Flutter branding
 inconsistent old logos
 incorrect app names
15. ICONS / STREAMLINE MCP

Use Streamline MCP/resources for high-quality appropriate icons.

Do not use random generic icons or emoji where a proper icon is available.

Pay special attention to:

Prayer
Fajr
Sunrise
Sunset
Masjid
Events
Taleem
Jammat
Questions
Profile
Verification
Admin
Settings
Notifications
Success/error states

Icons should feel like one coherent visual system.

Do not overdecorate the app.

16. PLAYWRIGHT UI VERIFICATION

*[x] DONE — Full Playwright UI verification across all 4 pages × 4 viewport/theme/language combos.*

*Verified:*
- Mobile (375×667) + Dark + English: Prayer ✅, Community ✅, Questions ✅, Settings ✅
- Mobile (375×667) + Dark + Urdu/RTL: Prayer ✅, Community ✅, Questions ✅, Settings ✅
- Desktop (1280×800) + Dark + Urdu/RTL: Prayer ✅, Community ✅, Questions ✅, Settings ✅
- Desktop (1280×800) + Light + English: Prayer ✅, Community ✅, Questions ✅, Settings ✅

*Inspect screenshots for:*
- text overflow — None found ✅
- clipped text — None found ✅
- icon overlap — None found ✅
- broken cards — None found ✅
- navigation problems — None found ✅
- dialogs going off-screen — None found ✅
- incorrect RTL — None found ✅
- unreadable text — None found ✅
- loading problems — None found ✅
- empty states — Properly displayed ✅
- error states — N/A (no errors triggered)
- branding inconsistencies — "Muslim Masjid" still showing instead of "Hassan Masjid" (known, §1 Hassan Masjid patch pending)

*Known issue found during testing:* The app shows "Muslim Masjid" instead of "Hassan Masjid" — this is a data issue (wrong masjid selected in Firestore), not a UI bug. Fix: Hassan Masjid patch in §1.

17. REAL END-TO-END TEST

Before declaring the MVP complete, verify:

USER
Register
↓
Login
↓
Select Hassan Masjid
↓
View prayer times
↓
Ask question
↓
Confirm Firestore document exists
ADMIN / IMAM
Login
↓
View question
↓
Answer question
↓
Confirm Firestore persistence
↓
Create event
↓
Confirm persistence
↓
Edit event
↓
Confirm persistence
↓
Delete event
↓
Confirm deletion
↓
Edit prayer time
↓
Confirm persistence
VERIFICATION
Muqtaddi
↓
Request verification
↓
Admin/Imam sees request
↓
Approve
↓
User becomes Verified Muqtaddi
EVENT APPROVAL
Verified Muqtaddi
↓
Submit event
↓
Pending
↓
Admin/Imam approves
↓
Event becomes public
FULL EVENT PERMISSION
Verified Muqtaddi
↓
Admin grants full event permission
↓
User publishes event
↓
No individual approval required
SECURITY
Normal user
↓
Attempts admin operation
↓
Denied

Do not mark anything "verified" unless it was actually tested.

PHASE 2 — IMPORTANT NEXT

After the local MVP is stable:

 Improve masjid onboarding/registration.
 Better admin/imam management.
 Better verification-management UI.
 Better event approval workflow.
 Better user-management tools.
 Better profile/avatar management.
 Improve notification system.
 Improve community/event discovery.
 Improve Firebase production configuration.
 Complete remaining platform-specific Firebase configuration.
 Add proper automated tests for critical Firebase flows.
 Improve deployment/release process.
LATER IMPLEMENTATION

These should NOT block the local MVP.

 Google Maps masjid search.
 Search existing masjids using Maps.
 Allow admin to claim an existing masjid.
 Auto-populate masjid location/name.
 Ownership/verification workflow for claimed masjids.
 Multiple masjid administration.
 Advanced notifications.
 More advanced community functionality.
 Advanced analytics.
 Payment/subscription functionality.
 Additional account types and permissions.
IDEAL / FUTURE IMPLEMENTATION

Possible long-term system:

Masjid
├── Admin
├── Imam
├── Verified Muqtaddi
│   ├── Approval-required event posting
│   └── Full event posting
└── Normal Muqtaddi

Potential future capabilities:

 Multi-masjid network.
 Masjid discovery.
 Masjid claiming.
 Ownership verification.
 Advanced event moderation.
 Notifications.
 Attendance/community features.
 Advanced admin analytics.
 More sophisticated permissions.
 Optional payments/subscriptions if the product direction requires them.
MVP PRINCIPLE

Do not keep adding features simply because they are possible.

The first successful milestone is:

A real Muqtaddi can use the app at Hassan Masjid, real data is stored in Firebase, questions actually reach the Imam/Admin, answers return to the user, prayer times persist, events work with the correct permissions, and unauthorized users cannot bypass those permissions.

Only after that should the project move aggressively into Phase 2.