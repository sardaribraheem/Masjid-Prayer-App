# Masjid App launch and business execution plan

Updated 14 October 2026. Android-only MVP; final application ID remains pending. **Public launch is on hold.** Production uses older rules, and release/device/moderation gates remain open. A calendar target cannot override those gates. The former 15 October target can serve as an internal progress review, not a promise of public availability.

This is the single execution plan. [FINALTODO.md](FINALTODO.md) tracks requirements, [MVP_REVIEW.md](MVP_REVIEW.md) tracks risks, and [app_guide.md](app_guide.md) covers actual user/manager workflows. Proposed business targets below are experiments, not existing traction or revenue.

## Product and first customer

Start with one local mosque whose imam and committee you can meet and support. The congregation gets the mosque's actual prayer/Jummah timetable, optional advance reminders, approved announcements and a text-only channel for questions. The imam gets one place to update times, answer questions and review event proposals.

The mosque committee is the onboarding partner and potential future paying customer; congregants are the users. Trust depends on correct local congregation times and a responsive mosque manager. Sunrise/sunset labels must not imply additional congregation prayers. Keep ordinary timetable viewing easy for guests.

Android, English/Urdu, restrained prayer cards and text-only community stay in scope. Attendance, media uploads, paid scheduling, payments, multi-mosque administration and broad discovery are deferred. Retain the existing local reminders, but complete their acceptance before advertising delivery reliability.

## Owners and dependencies

| Work | Responsible party | Concrete output |
| --- | --- | --- |
| App/rules fixes and QA | Developer | Reviewed changes, tests, staged acceptance record and release candidate |
| Identity/signing/store account | App owner | Final application ID, matching Firebase registration, private signing backup, Play Console account status |
| Privileged access and rollout | Owner + trusted operator | Independently approved manager/admin UIDs, migration/rollback review, explicit deployment authorization |
| Mosque onboarding | Owner + committee | Authority confirmation, accepted manager, accurate timetable and backup contact |
| Moderation/support | Named owner + mosque manager | Monitored mailbox/report queue and escalation/response process |
| Pilot measurement/business decisions | Owner | Cohort notes, usage/cost/support totals and an explicit expand/hold decision |

No messages are sent to committees/testers, no payments are collected, and no production grants/deployments are performed by writing this plan.

## Phase 1: Finish the remaining app correctness work

Status: **planned; existing core implementation has local evidence.**

1. Fix the imam timetable editor. Unset/invalid times must remain visibly unset; picking must work from that state. Require deliberate valid entries and preserve an optional Friday policy consistent with the prayer/reminder screens. Save prayer/Jummah data coherently; commit local changes only after success. Verify a new empty timetable and failed/denied saves.
2. Complete public community moderation: EN/UR posting-policy acceptance before contributions, report content/report user, blocking, and a manager/operator review queue. Protect report reads and enforce bounded fields/identity/status transitions in server rules. Verify blocks across refresh/restart and all relevant posts/comments/answers. Manager deletion alone is insufficient for a public community. [Google Play UGC policy](https://support.google.com/googleplay/android-developer/answer/9876937?hl=en)
3. Resolve the earlier verified-email requirement: current posting is signed-in, not Firebase-email-verified. Either implement the gate and recovery UX or record the owner's explicit scope decision; mosque membership verification remains separate.
4. Run Flutter analysis/tests and the affected rule/browser tests. Keep required denial/failure scenarios and localized small-screen checks in the evidence.

**Exit gate:** no default/partial-save timetable misinformation; moderation controls work with server permissions; posting eligibility is explicit; all changed behavior passes appropriate local checks. This is not deployed acceptance.

## Phase 2: Prepare and activate the compatible backend

Status: **local source/rules tested; production migration/deployment pending.**

1. Build a read-only inventory of legacy privileged users, mosque grants, creator attribution, malformed dates/categories and suspected samples. Confirm actual committee authority; never use old document IDs as a deletion list or automatically trust legacy elevated roles.
2. Prepare a reviewed migration, recovery/rollback procedure and compatible client/rules/index package. Keep ISO-string ordering until a separately reviewed timestamp migration. Retain backups/recovery evidence appropriate to the selected Firebase plan; verify capabilities before relying on them.
3. Rehearse the migration in a separate staging project with synthetic/labeled staging fixtures, then test ordinary signup, pending imam registration, transactional approval, scoped management, proposal privacy, comments and interrupted/retried cleanup. Test denied self-promotion/cross-mosque writes.
4. Prepare the trusted `superAdmin` UID bootstrap using [the reviewed procedure](scripts/admin/README.md). Review project/identity/grants before applying; editable emails confer no privileges.
5. After separate explicit authorization, coordinate production grants/data migration, rules/index deployment and client compatibility. Retrieve the active rules again, compare the reviewed source, verify deployed indexes and actual allowed/denied workflows, and record the evidence. [Current production audit](scripts/qa/PRODUCTION_AUDIT.md)

**Exit gate:** active backend matches reviewed policy; the compatible client works against migrated grants; unauthorized operations fail; recovery/support procedures are usable. Until this passes, demos use emulators/staging and trusted testing only.

## Phase 3: Create and accept the Android release candidate

Status: **debug build/device startup and one background reminder test pass; signed acceptance pending.**

1. Owner confirms final application ID and store identity. Register/update the matching Android Firebase app, retain the correct native config locally, and prepare owner-controlled signing backed up outside Git. Review launcher quality/rights, splash, app name and store artwork.
2. Prepare the release candidate in the reviewed environment after identity/backend prerequisites. Release builds must never use the debug key or emulator configuration. [Android release gate](scripts/qa/ANDROID_RELEASE.md)
3. Run guest/member/imam/admin acceptance on the signed artifact: correct mosque/times, signup/login/logout/account switching, posting/comments/answers, verification/proposals/approval, persistence, denied permissions, network failure and retryable deletion. Include Urdu RTL, light/dark, small-screen keyboard and large text.
4. Complete [reminder acceptance](scripts/qa/PRAYER_REMINDERS.md): 15/20/custom lead, actual daily/Friday alerts, app closed, reboot, revocation/recovery, tap navigation, timezone/midnight and battery restrictions. Record expected/actual times on the owner's phone and additional target devices where available.
5. Publish a public privacy page and a working account-deletion request page; verify the support process without reinstalling the app. Complete accurate Data safety, content rating, target audience, reviewer access and required permission declarations. In-app policy alone does not finish store setup. [User-data policy](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en), [deletion guidance](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en)
6. Check the actual Play Console account's eligibility. Personal accounts created after 13 November 2023 currently require at least 12 continuously opted-in closed testers for 14 days before applying for production access; application/review follows. This prevents promising a one-week public store launch if that requirement applies. [Official testing requirements](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en)

**Exit gate:** signed artifact passes the agreed device matrix; store resources work; required closed testing and production access are complete; remaining limitations are accurately disclosed.

## Phase 4: Run a focused mosque pilot

Start only after the safety/backend gates for real users pass. Proposed cohort: **one mosque, one accountable imam/manager, one backup committee contact and 20–30 Android congregants**. Pilot duration: two weeks minimum, extended for unresolved issues or applicable store-testing requirements. Recruit a varied mix of devices, ages and Urdu/English preferences; include people who need help with installations.

### Onboard the first mosque

1. Meet the committee and imam. Explain what the app does today; obtain consent for the listing and named manager. Verify authority independently, without collecting identity documents the current app does not need.
2. Help the applicant register/claim through the documented pending-request flow. A trusted reviewer approves the correct request and mosque association. Never turn an ordinary signup into automatic imam access.
3. Enter the real timetable, confirm every prayer and Friday time against the mosque's noticeboard, and compare the app on two phones. Record who maintains it and when changes are checked. Do not invent example production times.
4. Train the imam in a short session: timetable edits, questions/answers, event approvals, deletion/moderation and escalation. Request progress is currently handled through the operator; do not promise applicant-status notifications.
5. Put up a committee-approved QR poster linking to the appropriate test/store installation page. Give a short announcement after prayer only with approval. Demonstrate guest viewing first, then optional account/community and reminder setup. Use explicit tester opt-in.

Suggested pitch: “Your mosque's prayer times and announcements in one Urdu/English app. The imam controls updates; reminders are optional, and community posts are text only.” Do not advertise guaranteed alarms or features outside scope.

### Measure whether people can use it comfortably

Use a private, minimal pilot sheet and voluntary check-ins initially; no analytics SDK is assumed to exist. Record cohort counts and task outcomes, not private question text or religious activity profiles. Obtain consent for feedback and delete unnecessary contact details after the pilot.

| Proposed acceptance target | How to observe it |
| --- | --- |
| Zero known incorrect published timetable values | Manager compares noticeboard/app whenever times change; log and resolve each discrepancy |
| At least 8 of 10 observed newcomers select the mosque and find the next prayer without help | Observe the task once; note where help was required |
| Manager can update times and handle a question/proposal without developer intervention | Complete each task live; confirm saved data after reopening |
| At least half of participating testers voluntarily report using it in week two | Check-in denominator = actual participating cohort; do not label this automatic retention analytics |
| Zero unresolved unauthorized-access, data-loss or deletion-blocking incidents | Triage log with owners and closure evidence |
| Support effort and Firebase usage fit the owner's budget | Track time, costs, reads/writes/storage and issues daily during pilot |

These are proposed go/no-go criteria, not measured results. Any security issue or incorrect timetable pauses expansion immediately. Poor task completion triggers focused fixes and another observation, not a new feature bundle.

## Phase 5: Grow locally and test revenue

Only after the pilot passes, approach **two nearby mosques** through the first committee's introduction. Repeat the same authority/timetable/training checklist. Aim for 50–100 participating users across the small group as an experiment; avoid paid advertising until repeat usage and manager willingness are demonstrated.

Keep the initial pilot free. Interview at least five committee decision-makers: who maintains times today, what mistakes cost them, what support they need, who approves spending, and whether they would fund continued support. Do not treat download counts or compliments as willingness to pay.

First revenue hypothesis: a mosque funds optional managed onboarding/support or a local sponsor funds an agreed free community service. Keep prayer viewing and the pilot's basic member experience free. Do not add in-app checkout, donations, ads, subscriptions or paid digital features in this release; each requires a separate product, billing-policy and implementation review. Prepare a small written offer only after learning the required support scope, and test one paid commitment before building payment machinery.

Use actual economics: monthly service contribution = revenue received minus allocated hosting, moderation, support time and other direct costs. Also account for acquisition time, store/setup costs and taxes when deciding viability. A sponsor covering one expense does not establish a sustainable business. Set pricing from observed workload and committee budgets; no market-validated price exists yet.

## Operating the service

| Cadence | Action |
| --- | --- |
| Daily during pilot | Check timetable changes, reports/support, permission failures and Firebase usage; acknowledge ordinary support within a proposed 24 hours |
| Immediately for serious incidents | Stop promotion/new onboarding; involve the owner/trusted operator; correct timetable or access through reviewed procedures and verify recovery |
| Weekly | Review usage, support hours, unresolved issues, manager engagement and backup contact; approve only scoped changes |
| Before every mosque expansion | Confirm ownership/manager grant, current timetable, training, moderation capacity and directory/read growth |
| Before every app rollout | Repeat changed-flow tests, signed smoke acceptance and compatibility review; preserve signing/migration recovery records |

Monitor the actual Firebase console quota/usage for the current plan. Spark has finite quotas; text-only content does not make growth unlimited. Pagination reduces some reads but the directory is still unbounded and valid-request spam can consume quota. Set an owner-approved spending envelope before enabling any paid service; do not change billing automatically. Keep reminders local and avoid adding Storage uploads for this MVP.

## What can proceed now

Clean docs/source references, prepare the correctness/moderation changes and staging migration package, complete local tests, draft store copy/resources and recruit potential committee partners/testers manually. Final ID, trusted UID identities, signing custody and deployment/publication authorization remain owner-controlled decisions, not assumed answers.

The immediate business goal is **one mosque maintaining accurate times and real congregants returning comfortably**. Move to more mosques and paid commitments only when the pilot provides evidence.
