# UC-ACC-1: Accounts (invites, password reset, access requests)

Status: built 2026-11-08 in the local demo and the Phase B server. Production 1.0 hands passwords and links to Supabase Auth and sends the links by email.

## Why there is no open sign-up

Everyone who needs an account already gets one: candidates by applying, staff added by the PI, RAs added by the PI or lab manager. An account made by anyone would have no role or project, and it would open a second way in around blind screening and the one-person-per-email rule. So people outside RMS-X **ask for access**, and the lab decides.

## What was built

| Need | Where | How it works |
|---|---|---|
| Invite a new person | Team and rules → Accounts → "Make invite link" | Makes a one-time link (`/welcome?code=…`), valid 7 days. The person opens it and sets their own password. |
| Reset a password | Sign-in → "Forgot your password?" (`/login/reset`) | The person enters their email. The page gives the same answer whether or not the email exists. The lab manager gets a home task, "Make a password reset link for X", and the link is valid 2 days. |
| Ask for an account | Sign-in → "ask for access" (`/access`) | Name, email, organisation, project and reason. The lab manager and PI get a home task, "Review N access requests". Approving adds the person (as an RA by either of them, as staff by the PI only) and makes their invite link at once. |
| See who can sign in | Team and rules → Accounts | Each person's sign-in state (demo password, invited, invite expired, own password), open links, reset requests and last sign-in. |

## Rules

- **A1 Who makes links:** the PI makes links for anyone; the lab manager for RAs and candidates only, so only the PI can take over a staff account.
- **A2 Links work once:** an invite for 7 days, a reset for 2. A new link replaces an open one. The old password keeps working until a reset link is used.
- **A3 Only hashes are stored:** the code is made in the browser that shows the link and is shown once. The store keeps a hash of each code and password in `account.secret`, which the server strips before any data leaves it (`read-rules.ts`).
- **A4 Passwords:** at least 10 characters, not the demo password, and not containing the email name. Until someone sets their own, the shared demo password still works for them.
- **A5 No account discovery:** the reset and access pages give the same reply for any email, and asking again within an hour adds nothing.
- **A6 Blind screening:** candidates before Gate 1 are only counted in the account list, and audit entries say "A candidate".
- **A7 Spam limit:** at most 50 open access requests; a second request from the same email replaces the first.
- **A8 Audit:** `account.link`, `account.password`, `account.reset_ask`, `access.request` and `access.decide`. Sign-ins update the account list but are not audited.

## Code

- Rules: `src/data/accounts.ts`, `src/data/account-actions.ts`, `src/rules/sha256.ts`.
- Pages: `src/app/welcome`, `src/app/login/reset`, `src/app/access`, and `src/components/AccountsPanel.tsx` on Team and rules.
- Server: `/api/session/code` sets a password from a link. Sign-ins through `/api/session` and Google are noted on the account.
- Tests: `src/data/accounts.test.ts`.

## Not built yet

- **Emailing the links.** Until the Supabase release, the PI or lab manager copies each link and sends it themselves.
- **Changing your own password while signed in.** For now, ask for a reset.
- **Ending an account** when someone leaves the lab.
- **Rate limits by IP** on the public pages.
- **A read-only partner role.** For now, an approved partner is added as staff with chosen roles, or as an RA.
- **`supabase/schema.sql`** has no `access_request` table yet.
- **Under `RMSX_DEMO_SIGNIN=off`** (Google only), invite links are refused and people sign in with Google.
