# Trusted administrator bootstrap

Run these tools in a trusted environment with Application Default Credentials for the intended Firebase project. Service-account credentials must remain outside this repository. These tools bypass client rules; do not expose them in the app or grant credentials to users.

1. Review the administrator's Firebase Auth UID and verify their email. An email address alone is not an authorization grant.
2. Install dependencies: `npm ci --prefix scripts/admin`.
3. Preview: `node scripts/admin/grant-super-admin.mjs --project PROJECT_ID --uid REVIEWED_ADMIN_UID`.
4. Verify the printed project and account. Add `--apply` only when the identity has been reviewed.
5. Sign out/in so the ID token includes `superAdmin: true`. The settings dashboard entry then appears.

Before production deployment, manually audit all existing imam/admin user documents and each masjid's `authorizedImamUids`. The old rules allowed self-assigned roles and unprotected grants. Only add or retain UIDs independently confirmed as authorized managers; ensure each approved user's `masjidId` matches. Do not automatically migrate every elevated user into the protected list. Test approved/revoked users on staging before coordinating app/rule deployment. Pending requests do not grant access.

Request approval in the app uses a transaction: read pending request, applicant, and masjid; create/update the masjid; assign applicant role/association; mark request reviewed. A manager already assigned elsewhere must be transferred/revoked through a separate reviewed operation before another assignment.
