# RMS-X · RA Recruitment, Projects and Hub (Next.js)

A port of the Rev0 MVP (`RMS-X · RA recruitment.html`, the claude.ai artifact) to Next.js and TypeScript, with these changes from *RMS-X RA Recruitment PRD: proposed revisions*:

- R3, fairness
- R4, full status flow with an offer step
- R5 and R6, pilot items
- R7, rule fixes

Styling follows the DEPI Lab – VinUni design system, scaled for an app.

## Run

```bash
npm install
npm run dev      # http://localhost:3000
npm test         # 313 tests: SOP worked examples, the application flow, who may do what, audit, deadlines, projects, updates, home page, Hub
npm run prod     # production build + server on http://localhost:3001 (much faster pages)
```

The tests live next to the code (`*.test.ts`). The main ones:

| File | What it checks |
| --- | --- |
| `src/rules/sop-checks.test.ts` | The SOP worked examples |
| `src/rules/deadlines.test.ts` | Deadlines and holidays |
| `src/data/flow.test.ts` | One application from Submitted to Active |
| `src/data/roles.test.ts` | Who may do each action: everyone else is refused and changes nothing |
| `src/data/integrity.test.ts` | Rule fixes from the review |
| `src/data/audit.test.ts` | The audit log and refusals |
| `src/data/tasks.test.ts` | Each person's task list |
| `src/data/local.test.ts` | The store: a change is saved in full or not at all, and saved data is read back |
| `src/data/accounts.test.ts` | Sign-in and the area guards |
| `src/data/demo.test.ts` | That the demo data obeys the rules |
| `src/data/projects.test.ts` | Project teams and milestones; positions, RAs and outputs linked to projects |
| `src/data/home.test.ts` | The shared task list the home page reads |
| `src/rules/projects.test.ts` | Update periods and due dates, working-day limits, lateness and project health, the update flow and the check |
| `src/data/updates.test.ts` | The update loop on the demo data, refusals, the PI stepping in, reminders and the update rules as settings |
| `src/data/setup.test.ts` | Project set-up: creating projects, milestones, the team and the PI's budget |
| `src/data/homepage.test.ts` | The RMS-X home page: tasks across modules, the next 14 days, the lab at a glance, recent activity |
| `src/data/hub.test.ts` | The Hub: knowledge base, suggested edits, facilities, announcements and section reviews |
| `src/data/handoffs.test.ts` | The handoffs with RA Recruitment and the monthly lab update |

`npm run build` writes to `.next-prod` and `npm run dev` to `.next`, so both can run at once. Re-run `npm run prod` after code changes. Each port keeps its own localStorage, so demo data on :3000 and :3001 is separate.

## Layout

| Path | What |
| --- | --- |
| `src/rules/` | Rules module: pure functions, no React or storage. `catalog.ts` holds the SOP catalogs (36 capabilities in 6 areas, criteria, plan sections). `rules.ts` holds gates, matching, the status flow and deadlines. `sop-checks.ts` holds the worked examples. `projects.ts` holds the Projects module rules: update periods, the update flow, the check and project health. |
| `src/data/` | `types.ts` (entities), `actions.ts` (every write, each checked against the rules and the actor's role), `projects.ts` (projects, teams and milestones), `updates.ts` and `project-actions.ts` (project updates: what each person reads, and every write), `tasks.ts` (what each application needs next), `home.ts` (the shared task list), `store.tsx` (local store), `demo.ts` (demo data) |
| `src/app/` | Pages. Public: `/`, `/jobs`, `/jobs/[id]`. Sign-in: `/login`. Home for staff and RAs: `/home`. Recruitment: `/staff/...` (staff). RAs and candidates: `/me`. Projects: `/projects/...` and Hub: `/hub/...` (staff and RAs) |
| `public/templates/` | Templates candidates download: CV (Word), topic idea (Word, 1–2 pages with 3–5 references), topic discussion slides for the interview (PowerPoint), research proposal with plan sections C0–C12 (Word) |
| `supabase/schema.sql` | Draft Postgres schema for Production 1.0, with row-level security that denies by default. Check it without a Supabase project: `npm install --no-save @electric-sql/pglite@0.2.17`, then `node supabase/check-schema.mjs` |

## What is different from Rev0

- **Status flow (R4):**
  - The flow is Submitted → Screening → Shortlisted → Interviewed → Selected → Offer made → Contracting → Onboarding → Plan with PI → Active.
  - It adds these final statuses: Offer declined, Not passed and Closed.
  - A plan can be sent back for revision, and reserve candidates can be offered the position.
  - Each new plan version gets a fresh Gate 3 review: the comment is cleared and sections marked Revise go back to Not reviewed. The old comment stays in the history.
  - A supervisor is assigned at the contract step and is required to start onboarding. The plan task goes to that supervisor.
- **Fairness (R3):**
  - The screener must make a blind-screening declaration.
  - When the PI scores, the panel needs at least 3 members.
  - The page warns when the decider also scored, or when the screener also interviewed.
  - The CV form tells candidates to leave out their photo, date of birth and marital status.
- **Rules (R7):**
  - All deadlines are in calendar days, counting the start date as day 1: the research plan is due on day 28 and Gate 3 is on day 60, no later than the last day of probation.
  - A deadline that falls on a weekend or holiday moves earlier.
  - The minimum profile level is a setting. It defaults to 0 as in SOP v1.1, because SOP example SK01 uses level-0 items.
  - The PI can remove a panel member who has not submitted, 3 days after the interview.
- **Pilot items (R5, R6):**
  - Workaround log.
  - Consent recorded per purpose.
  - Baseline entry for current RAs, which feeds capability coverage.
  - One person record per email, including outside candidates.
  - Position history.
- **Decisions stay as made:**
  - Gate 1 and Gate 2 keep the rule result and the settings they were decided with, so a later change to the settings or roles does not rewrite them. The Gate 3 review is frozen once decided.
  - Once a scorecard is submitted, panel members can be added but not taken off; only the PI removes a member who has not submitted, with a reason.
  - A position's capability profile is locked once anyone has applied. Saving a position never changes its status or history, and adverts move only draft → published ⇄ closed, or to cancelled.
  - SOP settings have allowed ranges (for example a panel of 2–10), and every change is kept with who made it, on Team and rules.
  - An online application is always the applicant's own: a visitor cannot use an email that already has an account, and staff emails cannot apply. Online applications close on the closing date.
  - A candidate can answer an offer until its answer date; after that, staff record the answer.
  - Only the RA's own supervisor (or the lab manager or PI) sends the research plan, and roles are for staff only.
- **Audit (Phase 2):**
  - Every action adds one event to an append-only audit log: who, what, when, and the old and new values where a record was edited. The PI and lab manager see it under "All changes" on each application and position; setting and role changes are on Team and rules. Summaries never name a candidate and never show scores.
  - Each action checks everything before it writes, so a refused action changes nothing (tested for each kind of refusal).
  - A new topic or research proposal is the next version; earlier versions stay listed. A consent taken back is marked withdrawn, not deleted.
  - Application codes are numbered per project after the highest code in use, so they never repeat.
- **Usability and accessibility (Phase 3):**
  - Every field's label, hint and error are tied to its input (`Field` in `src/components/ui.tsx`), so screen readers name every control; a skip link leads to the content.
  - A refused action shows its reason next to the buttons that tried it (`useAction` in `src/data/store.tsx` with `ActionError`); toasts are for success only.
  - The application form is kept in the browser as you type, until it is sent, and has numbered sections with jump links. Files can be chosen or dropped.
  - Level buttons show the level's name (Aware … Lead). The progress rail says each step's state in words, not only colour, and runs down the page on phones.
  - Staff can search, filter and sort applications (search finds names only after Gate 1), and the number tiles on the staff home open the matching list.
  - Candidates see a dated history of their application (no notes or scores), and reserve candidates are told they are reserves.
  - Cancelling or deleting a position, recording a withdrawal and failing probation ask for confirmation. Only the PI sees the demo reset.
- **RA profiles (part A):**
  - One profile per RA, whether they joined before RMS-X or were hired through it (`src/data/profiles.ts`): placement, capabilities over time with the evidence for each change and development targets (plan C10), and achievements.
  - The RAs page lists every RA with contract end, capabilities, achievements and what needs attention; each RA opens to a profile page. RAs see their own profile on their page.
  - Capability levels and targets are shown to the PI, the RA's own supervisor and the RA, not the lab manager (`canSeeLevels`). Only checked work that is accepted, published or done counts in reports.
- **RA profiles (part B):**
  - RAs add their achievements and propose level changes with evidence on their own page. Their supervisor checks achievements and decides level changes; the PI decides Expert and Lead levels (`SUPERVISOR_MAX_LEVEL` in `src/data/profiles.ts`) and may act on any RA.
  - What the supervisor or PI enters is checked at once. An RA's change to a checked achievement sends it back for checking, and an RA cannot remove checked work. Declining a level change needs a reason, shown to the RA.
  - The staff home lists RA work waiting for each person, and the PI sees an RA's change log on their profile. Every step writes an audit event.
  - Who may do what is in one place (`may` in `src/data/profiles.ts`); the pages show buttons from it and the actions refuse with the same rules.
- **RA profiles (part C):** under RAs, three tabs:
  - **Capability matrix** (PI; supervisors see their own RAs): every RA against every capability, with practitioner counts, who could mentor (Expert or Lead), gaps for open and draft positions, and mentoring suggestions for unmet development targets.
  - **Outputs and funder report** (PI and lab manager): counted outputs by funder, project and kind for a period, the list behind them, and a CSV download that Excel opens with Vietnamese names intact. Each output is credited to the project it was recorded for, and that project's funder.
  - The logic is in `src/data/reports.ts`.
- **Decision 3:** the PI chooses on Team and rules whether papers count once accepted (the default) or once submitted; the change is logged, and the outputs page and profiles state the rule in force.
- **RA profiles (part D):**
  - Six-monthly reviews: the RA's supervisor or the PI rates five areas, comments (needed for a Below) and sets goals; the RA reads it and may reply. A review is not changed once written. It is due six months after the last one, or after the start (Gate 3 for RMS-X hires); the supervisor is asked from two weeks before, and the roster flags overdue reviews.
  - `supabase/schema.sql` has the profile tables (placement, targets, confirmed levels, level changes, achievements, reviews) with read rules matching the app: levels, targets and reviews for the RA, their supervisor and the PI; achievements and placement also for the lab manager. Triggers keep confirmed levels and written reviews from being changed.
- **Onboarding agreements:** the new RA reads the key points of the contract, NDA, IP agreement, partner NDA and lab policies on their own page, confirms each, and accepts the policies there (`src/data/agreements.ts`, demo summaries to be replaced with the lab's documents). Staff see on the checklist what the RA has read and when, and still record signed copies and the safety induction.
- **Schema for Production 1.0 (`supabase/schema.sql`):**
  - Row-level security on every table, denying by default. The API roles can only read; every write is meant to go through one database function per action.
  - Blind screening holds in the database: staff cannot read a candidate's name until one of their applications is past Gate 1. Scorecards stay hidden until the whole panel has submitted, and staff without a role see only the public adverts.
  - Triggers keep the audit log append-only, lock submitted scorecards, stop panel members being deleted once scoring has started, and keep roles for staff.
  - Adds the missing tables: Gate 2 decisions, proposals with versions, file details, holidays, verified levels apart from the candidate's own ratings, and a counter for application codes. Emails are case-insensitive.

## Projects and Hub module, P0 (foundation)

The second module (*PRD: RMS-X Projects and Hub module*) is being built in phases. P0 lays the ground both modules share:

- **Projects are records** (`src/data/projects.ts`): each project has a code, funder, PI, period, goal and work packages, with milestones (owner, due date, status as last approved) and a team (lead or RA, share of time, start and end). The demo has the lab's seven projects: SK01, SK02, CMIT, V-IndoorCARE, the air quality device, EV charging with BESS and PV, and Hydrogen with HUST-CLCS. Their milestones and teams are demo data, with statuses that follow the PRD's health rule.
- **Linked by id, not by name:**
  - A position chooses its project and work package, and takes its funder from the project. Application codes use the project code (SK01-001, CMIT-001, EVC-001).
  - An RA's projects come from their team memberships, largest share first. Before handoff 2, an RMS-X hire who is on no team yet shows the project of the position they were hired for. A current RA added on the RAs page joins their project's team full time.
  - Each achievement records the project it came from (one the RA is or was on), or none for work such as training. The funder report credits it there, so outputs no longer follow the RA's current project. Achievements gain two kinds from the PRD: research result and prototype.
  - The About us page lists the projects marked for it.
- **Lab manager:** the role called lab admin is now named lab manager, as in the PRD. Its id stays `admin`.
- **Shared task list** (`src/data/home.ts`): each module lists what waits for a person in one shape (module, for whom, title, detail, due date, link, source), and the staff home merges them. Tasks are worked out from the records, so one goes away when its work is done. Application tasks still never name a candidate before Gate 1.
- **Saved data:** the data format is now version 2. Data saved by earlier builds named projects in free text and is not read back; the demo data loads instead.

## Projects and Hub module, P1 (update rules)

P1 adds the update loop as rules and actions; the pages for it come in P2. The PI can already change the rules on Team and rules.

- **Periods** (`src/rules/projects.ts`): updates are monthly by default and named by the month they are due. The November update covers October and is due on the first Friday of November; a due date on a holiday moves earlier. A project can instead report every two weeks, counted from its start. A project takes updates from the day it joins the update loop and keeps the rhythm it joined with, so a later change to the lab default does not re-time its past updates.
- **The flow:**
  1. The RA keeps a draft, pre-filled from their milestones that are not done.
  2. Sending it needs a line for each milestone whose status changed or is at risk or late; unchanged ones need nothing.
  3. The lab manager marks it checked only with every check item ticked and evidence for every milestone marked done; otherwise they return it with a note.
  4. The PI approves it, alone or with others checked at the same time, or returns it with a comment.
  5. A return sends it back to the RA as a draft with its content, and clears the check.
- **Only approval changes the record:** milestone statuses, and the outputs reported, which become the RA's achievements, credited to the project and checked by the PI. A report can also move one of the RA's outputs on, such as a paper from submitted to accepted. An approval is refused if a milestone changed since the update was sent.
- **The PI stepping in:** the PI may approve a submitted update without the lab manager's check, with a written reason that is kept on the update. Evidence for milestones marked done is still needed.
- **Health:** a milestone past its due date and not done counts as late automatically. A project is Late when a milestone is late by more than 30 days, At risk when any is late or two are at risk, and On track otherwise.
- **Overdue and reminders:** an update not sent by its due date is overdue. The lab manager or PI can send a reminder from 3 days before the due date, once a day. Reminders are recorded; emails come later.
- **Settings** (Team and rules → Project updates, PI only, each change logged): rhythm, due weekday and week, reminder days, working days for the check (3) and the approval (5), the two health thresholds, and the check items.
- **Who may do what** (`mayProject` in `src/data/updates.ts`, from PRD section 8):
  - Only RAs on the team write their own updates.
  - The lab manager checks and returns submitted updates. The PI approves, and returns checked updates or submitted ones when stepping in.
  - The PI, lab manager and project lead see a project's updates; the rest of the team sees them once approved. RAs see only their projects, and the budget is for the PI.
- **Demo:** two months of approved updates, and this month's: two checked and waiting for the PI, two submitted and waiting for the lab manager (one with evidence missing, one asking for help), one draft, and the air quality device's October update overdue. Milestones are owned by RAs on the team.

## Projects and Hub module, P2 (pages)

- **Projects** (`/projects`): one card per project with its funder, health, milestones done, next milestone, team and last approved update; search and filters by funder and health. RAs see only the projects they are on.
- **Project page** (`/projects/[id]`): tabs for the overview (goal, health, work packages, the budget for the PI only, the update rhythm and Hub links), milestones, outputs, team and updates.
- **Set up** (`/projects/new`, `/projects/[id]/edit`):
  - The PI or lab manager creates a project. They and the project lead keep its details, work packages and milestones.
  - The PI and lab manager keep the team and start a project's updates. Only the PI sets the budget, which never appears in the change log.
  - A milestone's status is never edited here. A milestone or work package already reported on stays.
- **Update form** (`/projects/[id]/update/[period]`): pre-filled from the RA's open milestones. Asks for a line only where a status moved, evidence for anything done, outputs (new, or one of the RA's moving on), issues and help needed. A returned update shows the note.
- **Update page** (`/projects/updates/[id]`): what changed since the last approved update, flags, the status track, the lab manager's check list and the PI's approval, with return notes.
- **Updates waiting** (`/projects/queue`): the check queue, and the approval queue with select-all and batch approval.
- **My work** (`/projects/work`): one workspace with a section per role the person has. RAs see their updates, milestones, outputs and team. The lab manager sees the check queue and overdue updates, with Send reminder. The PI sees portfolio health, approvals waiting, projects and top risks. A lead sees the projects they lead.

## Projects and Hub module, P3 (the RMS-X home page)

- **Home** (`/home`) is where staff and RAs land after signing in; candidates still land on their own page.
  - **Needs you now:** tasks from every module, tagged and sorted by due date.
  - **Next 14 days:** each person's own dates: interviews, plan and Gate 3 deadlines, advert closings, updates and milestones due.
  - **Lab at a glance (PI):** people by stage, projects by health, outputs against this year's targets, capability gaps.
  - **People and projects (PI and lab manager):** who joins soon, projects that need people, contracts ending in 60 days.
  - **From the Hub**, and **recent activity** limited to what the person may see. A candidate is never named.
- **Navigation:** staff and RAs have one grouped menu on the left (`src/components/Shell.tsx`). It shows only the pages each person can use, marks the current page, and counts what is waiting on Home and Updates waiting. On a phone it opens from a Menu button. The public site and candidates keep the top bar.
  - **Staff:** Home; Recruitment (Overview, Applications, Positions, Workarounds); Projects (My work, All projects, Updates waiting, Monthly lab update); Hub (Hub home, Knowledge base, Lab facilities); People (RAs, Capability matrix, Outputs and funder report); Admin (Team and rules).
  - **RAs:** Home, My page, Projects (My work, My projects) and Hub.
- **Interface:**
  - Work waiting for someone shows as a ledger grouped by how soon it is due (Overdue, Due this week, Later, No due date). Each row is one link to the page that does the work (`TaskLedger` in `src/components/tasks.tsx`, on the home page and the Recruitment overview).
  - The lab's figures are labelled in place, with project health as one bar and outputs drawn against this year's targets.
  - Headings follow one type scale (minor third from 15px), and numbers use aligned figures.
  - The DEPI triangle marks where you are: beside each page title and the current menu item. Pills are kept for statuses and flags.
  - Lists use one clickable row (`RowLink` in `src/components/ui.tsx`): what it is, a line of detail, and statuses at the end, with no separate Open or View buttons.
  - Short facts about one thing, such as a project's funder, lead and dates, are labelled (`Facts`) rather than joined with dots. Progress toward a total uses one bar (`Bar`).
  - Secondary panels (activity, Hub links, news) are outlined rather than filled, so the main work stands out.
- **Dates:** timestamps are stored in UTC, but the lab's day is Vietnam's. Turning a timestamp into a day always goes through `localDate` in `src/data/demo.ts`, for example for review dates, "reminded today" and check deadlines. Cutting the ISO string gave the day before until 07:00 in Hanoi.
- **Shared tasks** now come from four sources: applications, RA profiles, project updates (the RA's updates due, checks for the lab manager, approvals and late projects for the PI) and the Hub (section reviews, suggested edits).
- **Output targets:** the PI sets yearly targets on Team and rules (main-author papers, co-author papers, invention disclosures). Papers record whether the RA was the main author or a co-author.

## Projects and Hub module, P4 (Hub)

- **Hub home** (`/hub`): search, the four sections with their owner, counts and review date (overdue ones flagged), announcements (the lab manager and PI post them) and what changed lately. CEI and partner pages come in the second release; their sections already have owners and review dates.
- **Knowledge base** (`/hub/kb`): articles by category (SOPs, templates, how-to guides, onboarding) with version, date and owner. A change to the text, title or file is a new version. Anyone in the lab suggests an edit; the lab manager or PI takes it up or declines it with a reason. The application templates are articles.
- **Lab facilities** (`/hub/facilities`): status (with until when, for in use or maintenance), training, rules and the projects using each one. Booking comes later.
- **Section reviews:** each section is reviewed every six months. Its owner is asked from two weeks before, and the PI can hand a section to a new owner.

## Projects and Hub module, P5 (handoffs and the monthly lab update)

- **Handoff 1:** choosing a project for a position fills in an empty team and facilities from the project.
- **Handoffs 2 and 3:**
  - The plan sent to the PI can list its milestones (section C5, M1–M12, within the project).
  - At Gate 3 the new RA joins the position's project team (full time, or half time for a part-time position) from their start date.
  - The plan's milestones become their project milestones, not started.
- **Handoff 4:** approved outputs already become achievements. The RA profile also shows, for the review, the updates approved, milestones finished and outputs approved since the last review.
- **Monthly lab update** (`/projects/report`, REP-1): for a month, each project's health, updates approved, waiting or overdue, the milestones that moved, outputs, issues and help, all from approved updates. It downloads as text for the lab's template.
- Handoff 5 (the transition review) waits for the second release. Contracts ending in 60 days already show on the home page.

## Projects and Hub module, P6 (schema)

`supabase/schema.sql` now has the Projects and Hub tables. Positions, achievements and plan milestones link to projects by id, and the RA record no longer holds a funder. The read rules follow PRD section 8:

- **Projects:** RAs and leads see the projects they are on; the PI and lab manager see all; the public sees only advertised projects. The budget is in its own table, which only the PI reads.
- **Updates:** a draft is seen by its author, the PI, the lab manager and the project lead; the rest of the team sees it once approved.
- **Hub:** for staff and RAs. A suggested edit is seen by its author and the lab manager or PI.
- **Triggers:** an approved update and its rows are never changed. A milestone's status changes only inside an approval, which sets `rmsx.approving` for its transaction.
- **Constraints** keep one update per RA, project and period. They also cover sent dates, a reason for approving without the check, short project codes, team shares, author roles on papers only, an end date for facilities in use, and a reply for declined suggestions.

`node supabase/check-schema.mjs` runs the schema checks (119 now).

## Backend audit fixes

- **Approved outputs:** an update that changes one of the RA's existing outputs keeps that output as it was when the RA added it (`was`). The approval writes only the fields the RA changed, so a later correction by the supervisor stays. It stops only when both changed the same field.
- **Team places:** an RA who left a project and joins it again at Gate 3 is taken back on their old row, so each person has one place per project, as in the schema.
- **Who reads what in the schema:**
  - Candidates read their status history through `my_status_event`, which has statuses and dates only. Gate reasons, notes and the Gate 3 review are staff only.
  - The lab manager no longer reads level changes in the audit log.
  - Baseline levels follow decision 1: the RA, their supervisor and the PI.
- **Closed by default:** the schema undoes Supabase's default grants, so a later table, sequence or function is closed to the API until it is granted. Only the helpers the read rules call can be run through the API. The check script grants the API roles as Supabase does, so it tests this.
- **Storage:** CVs, slides, proposals and plans go in the private `applications` bucket, with a 10 MB limit and the accepted file types. A file is read with its row in `file`, and nothing is uploaded through the API.
- **Rules the database now keeps:**
  - An application moves only along the status flow.
  - A position has one open offer at a time, and each place in the reserve list holds one candidate.
  - An RA from before RMS-X may have no email; everyone else needs a valid one.
  - Application codes go past 999, and `catch_up_application_codes()` lines up the counters after an import.
- **Data retention:** `purge_application()` removes an application with its history, files and candidate, and keeps the audit log. It is for the server only and never removes an RA's hiring application.

## Drafting a position with Claude

On a project page, the PI or lab manager clicks **New position** (`/projects/[id]/position`). They write a few lines about the position, and Claude drafts the title, contract type, work package, description and capability profile. Each capability comes with a line on why it is there, and the draft lists questions the brief left open.

- **Review:** the draft shows with the profile rules checked. Nothing is saved until the PI clicks **Use this draft**. It then opens in the position editor as a draft, and its history and the audit log say it was drafted from a brief. Publishing stays a separate step for the PI.
- **What the app fills in:** the project, team and facilities (as for any new position), and the contact email from the lab's latest advert. Claude never sets the closing date or the partner NDA.
- **Never trusted as is:** the draft is tidied in `positionFromDraft` (`src/data/position-draft.ts`). Unknown or repeated capabilities are dropped, levels stay within 0–4 and the lab's minimum, and a work package must be the project's own. Saving runs `savePosition`, the same rules as a position typed in by hand.
- **Server:** `src/app/api/position-draft/route.ts` calls `claude-opus-5-5` with structured outputs (the Zod schema in `src/data/position-draft-schema.ts`). The server-side fallback is on, so if Claude declines, the API retries on Anthropic's recommended fallback model. The brief is never logged.
- **Setup:** add `ANTHROPIC_API_KEY=<your key>` to `.env.local` and restart the app. Without it, the page says drafting needs a key; **Start from a blank position** and the JSON import still work.
- **From a JSON file:** the same page imports a position written elsewhere, by hand or in a chat with Claude, with no API key needed.
  - **Download the template** gives a file for the project. Besides the fields, it lists the project's work packages, the level scale and the lab's capabilities.
  - A capability can be given by id or name, and a work package by id or code (WP2). Keys starting with `_` are notes and are ignored.
  - The file goes through the same review and tidying as Claude's draft (`readDraftFile` in `src/data/position-draft.ts`). Its history says it was imported from a JSON file.
- **Before real use:** the route cannot check who is calling until real sign-in arrives. Anyone who can reach the server can use it, up to 1,500 characters per brief. With Supabase Auth, it must check for the PI or lab manager.

## Approval by exception (the PI's key deliverables)

The PI approves only the updates that report a key deliverable. A **key deliverable** is a patent (invention disclosure), a publication (journal or conference paper), a prototype, a spin-off, a competition or a challenge. Spin-off, competition and challenge are new output types. The lab manager approves the other updates.

- **Switch:** **Team and rules** › project update rules › *The lab manager approves updates without a key deliverable*. It is off by default, because the SOP has the PI approve every update. Only the PI changes it, and the change is logged.
- **The lab manager's check:** for an update with no key deliverable, the check page offers **Check and approve** (one step) or **Check and send to the PI**. Every approval rule still applies, and the update records that the lab manager approved it under the rule (`approvedRoutine`).
- **What still goes to the PI** (`forPi` in `src/data/updates.ts`):
  - a key deliverable among the outputs, including one an output turns into another kind of work;
  - an update the PI returned before;
  - an update the lab manager sent on.

  The check page lists the reason, and the lab manager's approval is refused for these.
- **What the PI sees:**
  - **Updates waiting** lists only updates that need the PI, tagged with their key deliverables. It also lists what the lab manager approved in the last 30 days.
  - **My work** has a **Key deliverables** table across the projects, with each one's status. The PI can change a status or its date there (**Change**), without waiting for the RA's update. The change counts as checked by the PI and is logged (`setDeliverableStatus` in `src/data/project-actions.ts`). While an update that changes the same deliverable waits for review, the row links to that update instead.
  - The PI's tasks and menu count leave out routine updates. The lab manager gets them instead.
- **Not undone:** an approved update stays final. If the PI disagrees with a routine approval, the RA's next update corrects the milestone.
- **Schema:** `project_update.approved_routine` and `to_pi`, with constraints: a routine approval needs the check, and only a checked update is sent on. The setting is `routine_approval`.

## Agentic AI prerequisites (Phase A, 4 Nov 2026)

What this release builds from *Prerequisites for Agentic AI: RA Recruitment and Projects and Hub* (31 items, AIP-*). Each item works in this build and in `supabase/schema.sql`. Tests: `src/data/prereqs.test.ts`.

- **Audit entries** (AIP-R3, P3, F3): every entry has room for a `reason` and a `proposalId`. Actions that take a reason store it there: gate decisions, returns, withdrawals, panel removals, workarounds and conflicts. An agent's proposal that a person accepts runs the same action inside `withProposal(id, …)`, and the entry names the proposal.
- **One event log** (AIP-R4, P4, H4, F3): `db.events` in this build, the `event` table in the schema. Actions write their events along with the change:
  - recruitment: application received or imported, Gate 1 decided, interview scheduled, panel complete, contract item open, Gate 3 decided;
  - projects: update submitted, returned, approved;
  - Hub: page published, page changed.

  Events that come with time are written once each by `sweepEvents` (`src/data/events.ts`): update due soon or overdue, milestone late, Hub page past its review date. This build runs the sweep when the app loads; production runs it as a daily job. Events carry ids and dates, never names or scores.
- **CV as text** (AIP-R6): an optional field on the application form, kept apart from everything else. It is untrusted input: tools and agents must read it as data inside a marked block, never as instructions.
- **Conflicts of interest** (AIP-R7): staff declare a conflict on the application page. From then on the application is closed to them: it is left out of their lists and tasks, refused in their actions, and hidden by the schema's read rules (`staff_sees`). A panel member who has not submitted leaves the panel. The PI's own conflicts go to CEI under the SOP.
- **AI use** (AIP-R8): online candidates say whether they used AI tools, and how. The position page and the form carry the AI notice (`AI_NOTICE` in `src/data/demo.ts`). **The notice text still needs VinUni legal's approval.**
- **Partners** (AIP-R9): a Partners field on positions, shown on the advert. **The 4P scorecard waits for SOP Annex A.**
- **Evidence and authors** (AIP-P5): an RA can no longer send Done without evidence; the rules module refuses it. Outputs and achievements carry an author list.
- **Update versions** (AIP-P6): every sent version is kept. The review page shows what changed since the previous version.
- **Project links** (AIP-P7): each project has a shared folder and a code repository link (https only), shown to the people who see the project. In the schema they sit in their own table, so the public About page never reads them. **Listing an RA's new files and commits comes in Phase B.**
- **Hub pages** (AIP-H1): each page has an owner, a version, an access level (anyone, lab staff and RAs, or the PI only) and its own review date. The owner gets a review task 14 days before that date. Only the PI makes or changes a PI-only page.
- **Facility bookings** (AIP-H3): whole days, up to 30 at a time and six months ahead. Two bookings of one facility never overlap, and a facility under maintenance can't be booked. The person who booked, the lab manager or the PI can cancel. Bookings are on each facility's page; the schema refuses overlaps with a trigger.
- **Pilot measures** (AIP-R14, P8): **Admin › Pilot measures** (`/staff/measures`) works out baselines from the records:
  - days from a position's closing date to Gate 1;
  - days in screening;
  - the lab manager's check time and the approval time, in working days.

  The page also lists what the pilots must time by hand: screener effort, the questions candidates ask, RA writing time and the monthly lab update.
- **Writes through the API:** the schema grants the API roles read access only, so every write must go through a server action. The checks confirm that direct inserts are refused.

`node supabase/check-schema.mjs` runs the schema checks, 25 of them for these items.

## Agentic AI prerequisites, Phase B (local) and Phase C

Phase B is built to run locally: the server keeps the records and decides. Production swaps the file store for Supabase. Tests: `src/server/server.test.ts`.

**Run it:** `npm run build:server`, then `npm run start:server` (http://localhost:3004; preview config `rmsx-server`). The browser-only build is unchanged on port 3001. The server keeps its records in `.rmsx-server/state.json`, starting from the demo data.

- **Named actions** (AIP-R1, R3, P1, P3): all 62 writes are registered by name (`action()` in `src/data/actions.ts`). In server mode the browser runs an action on its own copy for an instant answer and records the steps and the new ids. It sends them to `POST /api/action`, which runs the same steps on the server's records as the signed-in person, all or nothing (`src/server/run.ts`). The server accepts only known action names, at most 10 steps, and new ids in the app's own form that aren't in use. If the server refuses, the browser shows the reason and the data as saved.
- **One change at a time:** each change runs alone and is saved by writing a new file and swapping it in. The record, its audit entry and its events are saved together.
- **What each person reads** (AIP-R2, P2): `redactFor` (`src/data/read-rules.ts`) applies the schema's read rules before any data leaves the server:
  - names hidden before Gate 1, and other panel members' scores until the whole panel has submitted;
  - candidates see their own application only, without staff notes;
  - budgets for the PI only, and drafts for their author and reviewers;
  - conflicts of interest, Hub access levels, and level data under decision 1.
- **Sign-in** (AIP-F1):
  - A signed, http-only session cookie names the person; the browser never chooses who it acts as.
  - Demo sign-in still works; `RMSX_DEMO_SIGNIN=off` turns it off.
  - **Google sign-in** goes through Supabase Auth (`/api/auth/google`, then `/auth/callback`). The server confirms the token with Supabase and signs in only the person with that verified email (`personForIdentity`).
  - It needs `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY`, plus Google enabled in the Supabase project with `/auth/callback` as a redirect URL. Not tried end to end yet, as those aren't set.
- **Read endpoints for MCP** (AIP-F4): `GET /api/read/projects` and `GET /api/read/hub`, as the signed-in person. They have typed output schemas, `limit`, `cursor` and `q`. `TOOLS` in `src/server/read-tools.ts` describes them for an MCP server.
- **Daily job** (AIP-P4, H4, R13): `POST /api/jobs/daily` with the header `x-rmsx-job-secret: $RMSX_JOB_SECRET`. It writes the time-based events, then deletes applications past retention once the PI has recorded the approval.
- **Settings for a real deployment:** `RMSX_SESSION_SECRET` (required in production), `RMSX_JOB_SECRET`, `RMSX_STORE_FILE`, `RMSX_DEMO_SIGNIN=off`.
- **Schema:** lab members (staff with a role, and RAs) read each other's names (`is_lab_member`), as the team pages need. 119 checks.

**Phase C in the app** (Admin › **Data readiness**, `/staff/data`):
- **Retention** (AIP-R13): **draft** periods of 6 months after the last decision, or 12 for the talent pool. The PI can change them. Nothing is deleted until the PI records where VinUni legal approved them, and changing the periods needs approval again. Deleting an application also deletes its events, and the candidate if they have nothing else in the lab; RAs' hiring records stay.
- **Demo data** (AIP-R11): counts the demo applications, the open or draft positions without a real contact email, and the people with example emails. The PI can delete the demo applications.
- **The 20 questions RAs ask most** (AIP-H2): draft answers written from the SOP and the app's rules. One button adds them as guides for lab staff and RAs, each marked as a draft, to review within 30 days.

**Still open:**
- **Supabase:** moving the records into the normalized tables (a store that reads and writes `supabase/schema.sql`), file storage, and a real run of Google sign-in. All need the project URL and keys.
- **Linked work sources** (AIP-P7): listing an RA's new files and commits.
- **For people:**
  - VinUni legal: the retention periods and the AI notice;
  - PI and CEI: SOP v1.2;
  - PI: SOP Annex A for the 4P scorecard;
  - lab manager: check the 20 draft answers;
  - the pilot baselines.

## Not done yet (Production 1.0)

- **Sign-in and roles:** `/login` is a mock sign-in (`src/data/accounts.ts`). Every person with an email is an account (staff, current RAs and candidates), and all share one demo password, which is shown on the sign-in page. Staff land on `/staff`; RAs and candidates land on `/me`, where candidates follow their status, accept or decline an offer, and withdraw. Nothing enforces roles on a server yet: the read rules are written in the schema, and the write functions come with the server port.
- **Data:** stored in this browser only: records in localStorage, uploaded files (CVs, topic and research proposals) in IndexedDB, so a file opens only in the browser it was uploaded in. Real candidate data must not go in this build.
- **Not built yet:**
  - Email notifications and reminders. Reminders are recorded in the app.
  - Server file storage (Supabase Storage), including evidence files for updates.
  - Vietnamese, CEI report export and data retention.
  - From the Projects and Hub second release: the timeline view, outputs register, risks log, CEI and partner pages, and handoff 5.
