# Masjid App — Latest TODO & Implementation Roadmap

## Project Goal

Build a reliable, real-world Masjid Prayer App for the first local masjid deployment.

The priority is:

> Real User → Real Firebase → Real Data → Real Imam/Admin → Real Persistence

Do not expand the scope unnecessarily before the local MVP is working.

---

# PHASE 1 — LOCAL MVP / MUST WORK

## 1. Firebase & Real Data

- [ ] Verify the app is connected to the correct Firebase project.
- [ ] Verify Firebase Authentication works.
- [ ] Verify Firestore works.
- [ ] Verify all important operations against the real Firestore database.
- [ ] Remove fake/mock production data.
- [ ] Do not silently fall back to local/sample data when Firebase fails.
- [ ] Make Firebase errors visible and understandable during development.

### Masjids

- [ ] Remove all placeholder/sample masjids.
- [ ] Keep ONLY:
  - Hassan Masjid
- [ ] Ensure Hassan Masjid has complete required information.
- [ ] Ensure the app's normal masjid-selection flow uses the real Firestore masjid.

---

# 2. USER / MUQTADDI SYSTEM

A newly registered person is a normal:

**Muqtaddi / User**

They are NOT an admin.

They can use the normal application.

### Normal Muqtaddi

- [ ] Register.
- [ ] Login.
- [ ] Select/use Hassan Masjid.
- [ ] View prayer times.
- [ ] Ask questions.
- [ ] View events.
- [ ] Manage their own basic profile.
- [ ] Request verification.

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
 Normal Muqtaddi can ask a question.
 Verified Muqtaddi can ask a question.
 Authorized Imam/Admin can ask a question if appropriate.
 Question must actually be stored in Firestore.
 UI must show success/failure correctly.
 No question should disappear after app restart.
Firestore

Verify the complete chain:

AskQuestionScreen
→ Provider
→ Repository
→ Firestore
→ Real document
 Confirm exact Firestore path.
 Confirm authenticated user ID.
 Confirm masjid ID.
 Confirm timestamp.
 Confirm question text.
 Confirm document actually exists after submission.
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

 UI
 category selector
 filters
 Firestore values where appropriate
 localization

Do not leave "Tablighi Jammat" visible anywhere in the normal application.

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

13. BOTTOM NAVIGATION

The current "Prayer Time" label does not fit properly.

Change it to:

Time

Verify the complete bottom navigation on small mobile screens.

No clipped labels.

No overlapping icons.

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

Use Playwright MCP/CLI to test the actual running application.

Test:

 desktop
 mobile
 light mode
 dark mode
 English
 Urdu / RTL

Inspect screenshots for:

 text overflow
 clipped text
 icon overlap
 broken cards
 navigation problems
 dialogs going off-screen
 incorrect RTL
 unreadable text
 loading problems
 empty states
 error states
 branding inconsistencies

Fix actual problems discovered through screenshots/runtime testing.

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