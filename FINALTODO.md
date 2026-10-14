# Masjid App requirements tracker

Updated 14 October 2026. [launchplan.md](launchplan.md) is the execution order; [MVP_REVIEW.md](MVP_REVIEW.md) is the risk register; [app_guide.md](app_guide.md) explains actual workflows. This tracker replaces duplicate session roadmaps while preserving the original requirement numbers.

**Public launch: HOLD.** No complete workflow is certified for the current signed app and deployed backend. “Local” means implemented with scoped local evidence; “Partial” means implementation or acceptance remains incomplete; “Deferred” means excluded from this MVP. Neither Local nor Partial means release verified.

## Original requirements

| ID | Requirement | Current status / remaining work |
| --- | --- | --- |
| 1 | User roles and permissions | Local: ordinary signup, verification and scoped managers. Super-admin is a separate server-issued claim. Firebase verified-email posting gate is not implemented; resolve that earlier requirement explicitly before launch. |
| 2 | Authentication | Local login/signup/reset, profile/password changes and account flow. Device account switching, reset email delivery and failure/restart acceptance remain open. |
| 3 | Account and imam contact emails | Model distinguishes account email from optional contact info; registration form does not collect a separate imam contact. |
| 4 | Mosque credentials/management | Source uses Auth UID grants, no plaintext-password seeding. Review legacy privileged users/documents and deploy coordinated rules. |
| 5 | Mosque registration | Partial: applicant account plus pending request; name/location required. Urdu name, Jamia toggle and optional contact fields are not in the current form. Approval and first timetable need staging/device acceptance. |
| 6 | Mosque verification | Local pending/approved/rejected requests and transactional approval. Applicant status/progress UI and notifications are missing. |
| 7 | Muqtaddi verification | Local request/review; approved members receive approval-required event permission. Staging/device acceptance and explicit full-grant/revoke management UI remain open. |
| 8 | Firestore security | 35 local rules cases recorded. Production still serves older rules; migration, bootstrap, indexes, deployment and denied-operation acceptance are required. |
| 9 | Mosque name display/cache | Local wrapping and selected-mosque updates improved. Remaining native text-scaling/restart acceptance. |
| 10 | Mosque list dark mode | Local browser visual evidence; complete native Urdu/light/dark acceptance. |
| 11 | Cache and reads | Partial: bounded content feeds and preference handling. Directory still reads every mosque; review account-switch/cache behavior and quota usage. |
| 12 | Prayer notifications | Local configurable Android scheduler; one real background test delivered. Reboot, revoked permissions, actual daily/Friday alerts, Doze, tap navigation and signed build remain open. |
| 13 | Prayer page | Local timetable/countdown parsing and restrained cards. Final native/localized/offline acceptance pending. |
| 14 | Urdu prayer names | Client localization implemented; duplicating prayer labels in Firestore is unnecessary for current UI. Manual Urdu mosque-name entry remains a future form improvement. |
| 15 | Imam prayer editing | Partial: manager editor exists. Unset/invalid times default to noon; Friday save failure is ignored; local model changes precede save success. Fix and test before pilot. |
| 16 | Event/community naming | Implemented: Events = CommunityPage; Community = QuestionsPage; Time label fits navigation. |
| 17 | Event creation/approval | Local permission and approval flows; pending events private in source rules. Staging/device acceptance needed. |
| 18 | Event categories | Canonical categories and Jammat label implemented. Review legacy stored categories during migration. |
| 19 | Imam event management | Local edit/delete and separate pending queue; acceptance for failures and unauthorized access remains open. |
| 20 | Attendance registration | Deferred: no attendance UI or persistence. |
| 21 | Community text-only | Attachment/upload controls removed. Do not delete legacy production content automatically. |
| 22 | Posts/comments | Local: 4,000-character posts and 1,000-character comments; pagination and deletion. Current production lacks required permissions. |
| 23 | Community permissions | Source validates ownership, text-only schema and bounds. Public report/block controls and posting-policy acceptance are missing; required before public community release. |
| 24 | Imam answers | Local answer storage and immediate browser refresh; staging/device acceptance pending. |
| 25 | Content lifecycle/expiry | Partial: actual deletion/approval supported. Automatic archival/custom expiry is deferred and must not be promised. |
| 26 | Profile | Display name, role/status/email and edit flow exist. Avatar uploads remain excluded; complete native acceptance. |
| 27 | Settings | Theme, language, reminders, privacy, help, logout and deletion exist. Native/offline/permission recovery acceptance pending. |
| 28 | Support | Mail intent uses sardaribraheem277@gmail.com. Owner must confirm mailbox ownership, monitoring and response process. |
| 29 | Privacy | In-app EN/UR description updated. Public policy/deletion URLs, accurate store Data safety and SDK review remain open. |
| 30 | Account deletion | Local UID-attributed cleanup, recent authentication and retry flow. Staging/native interruption, legacy content and manager handover must pass. |
| 31 | Keyboard/layout | Browser small-screen forms improved. Real Android keyboard, accessibility scaling and all key forms still need acceptance. |
| 32 | Icons | Bundled Streamline navigation/header icons and Material prayer/management icons. Keep attribution; launcher/splash/final branding review pending. |
| 33 | Sample data | Production seeding removed from app; isolated emulator fixture script retained. Current production legacy inventory/cleanup is unverified; do not reuse old document-ID deletion lists. |
| 34 | Firebase runtime | Emulator/browser and native startup evidence exist. Current production workflows cannot be certified before backend migration/deployment. |
| 35 | UI QA | 29 core and 6 reminder browser assertions recorded; coverage is scoped, not every platform/state. Native signed acceptance remains open. |
| 36 | Honest evidence | Current docs distinguish local/device/deployed status. Record exact build/date/scenario before changing a requirement to release verified. |

## Release work in execution order

- [ ] Resolve the timetable editor's unset-time and partial-save defects.
- [ ] Add posting-policy acceptance, bounded private reporting and public-feed user blocking, with server permissions and moderation workflow.
- [ ] Prepare/review legacy data and grant inventory, trusted bootstrap, migration/rollback and compatible deployment package; validate in staging.
- [ ] Obtain separate deployment authorization, deploy rules/indexes and verify actual active policy and workflows.
- [ ] Confirm final application ID, Firebase Android registration and owner-controlled signing; review launcher/splash/store branding.
- [ ] Complete real Android and signed-artifact acceptance, including reminder and interrupted deletion scenarios.
- [ ] Publish privacy/deletion resources and complete store setup/testing requirements.
- [ ] Run the gated mosque pilot and collect the business evidence defined in launchplan.

## Preserved future scope

Applicant request status; Urdu mosque name and optional contact/Jamia fields; full event permission management; directory pagination; abuse/rate controls; timestamp migration; reviewed legacy cleanup; ownership handover tools; improved discovery and optional Maps; richer verification management; multi-mosque administration; advanced analytics; attendance; payments. Media uploads remain excluded from this MVP.

Do not expand these into launch features without a clear need. Manager contacts and ownership checks can be handled manually during a small pilot, while authorization remains server enforced. Resolve required security/privacy issues before collecting public contributions.

## Evidence and document maintenance

Latest recorded checks: clean analysis, 38 Flutter tests, 35 rules emulator cases; 29 core browser assertions and 6 reminder browser assertions in separate passes. One Android 14 debug background reminder delivered on time. See [UI QA](scripts/qa/UI_QA.md), [device QA](scripts/qa/ANDROID_DEVICE_QA.md) and [production audit](scripts/qa/PRODUCTION_AUDIT.md) for limits.

Obsolete session logs, duplicate roadmaps, unsafe setup instructions and tracked temporary browser snapshots were removed on 14 October. Their historical text remains in Git history. Keep current requirements here, execution/business decisions in launchplan, and detailed test procedures under scripts/qa and test/firestore.
