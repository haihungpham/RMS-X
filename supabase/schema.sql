-- RMS-X RA recruitment: production schema (PRD Section 8, revisions R3–R7).
-- Draft for Production 1.0. Not applied yet: the app runs on the local store (src/data/store.tsx).
--
-- How access works:
-- * Row-level security is on for every table and denies by default. The policies below only grant reads.
-- * Closed by default: a table, sequence or function added later is not open to the API roles until a grant opens it,
--   although Supabase opens new objects in public to them.
-- * The API roles (anon, authenticated) cannot insert, update or delete anything. Every write goes through
--   one security-definer function per action in src/data/actions.ts (written with the server port): it checks
--   the role, the stage and the rules first, then writes and adds one audit_event, in one transaction.
-- * Blind screening holds here too: staff cannot read a candidate's name or email while all of that
--   candidate's applications are still at Submitted or Screening.
-- * Scorecards stay hidden from other panel members until the whole panel has submitted (IVW-4).
-- * A candidate reads their own statuses and dates, never the notes, reasons or Gate 3 review behind them.
-- * Capability levels (decision 1) are for the RA, their supervisor and the PI, in the audit log too.
-- * Staff without a role see nothing beyond the public adverts.
--
-- Uses Supabase's auth.uid() and its anon and authenticated roles. Checked by applying it to Postgres
-- (PGlite) with a stub auth schema and reading as each kind of user.

create extension if not exists citext;

-- Supabase grants anon and authenticated every new table, sequence and function in public. Undo that for everything
-- this file and later migrations create: reads are granted below, and EXECUTE only on the helpers the read rules call.
alter default privileges in schema public revoke all on tables from anon, authenticated;
alter default privileges in schema public revoke all on sequences from anon, authenticated;
alter default privileges in schema public revoke execute on functions from anon, authenticated;
alter default privileges revoke execute on functions from public;

/* ---------- reference data ---------- */

create table capability_area (id text primary key, name text not null);
create table capability (id text primary key, area text not null references capability_area, name text not null);

-- R7: weekends and these days move deadlines earlier.
create table holiday (day date primary key, name text not null);

-- SOP numbers. Ranges match SETTING_RULES in src/rules/rules.ts; every change is an audit_event.
create table setting (key text primary key, value numeric not null);

/* ---------- people and roles ---------- */

create table person (
  id uuid primary key default gen_random_uuid(),
  account_id uuid unique,                 -- auth.users id; null for an outside candidate until they sign in (R6)
  name text not null,
  email citext unique check (email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'),  -- R6: one person per email, whatever the case
  kind text not null check (kind in ('staff', 'ra', 'candidate')),
  supervisor_id uuid references person,
  baseline_at timestamptz,
  check (email is not null or kind = 'ra')   -- an RA added from before RMS-X may have none (null here; '' in the local store)
);

create table role_assignment (
  person_id uuid references person on delete cascade,
  role text not null check (role in ('pi', 'admin', 'supervisor', 'panel')),
  primary key (person_id, role)
);

-- R6 backfill: baseline levels for RAs hired before RMS-X
create table person_baseline (
  person_id uuid references person on delete cascade,
  capability text references capability,
  level smallint not null check (level between 0 and 4),
  primary key (person_id, capability)
);

/* ---------- projects (src/data/projects.ts): positions, RAs and outputs link to them by id ---------- */

create table project (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (code ~ '^[A-Z0-9][A-Z0-9-]{1,9}$'),  -- used in application codes, e.g. SK01-001
  title text not null, goal text, funder text not null, pi_id uuid references person,
  start_date date not null, end_date date not null check (end_date > start_date),
  -- Joining the update loop: from this date, with this rhythm; both are set together and then kept.
  rhythm text check (rhythm in ('monthly', 'fortnightly')), updates_from date,
  check ((rhythm is null) = (updates_from is null)),
  about jsonb  -- summary, focus and facilities when the project is shown on the public About us page
);
-- PRJ-3: the PI's budget summary (million VND), in its own table so the read rule can keep it to the PI.
create table project_budget (
  project_id uuid primary key references project on delete cascade,
  total numeric not null check (total > 0), spent numeric not null check (spent >= 0)
);
create table work_package (
  id uuid primary key default gen_random_uuid(), project_id uuid not null references project on delete cascade,
  code text not null, title text not null, unique (project_id, code)
);

/* ---------- positions ---------- */

create table position (
  id uuid primary key default gen_random_uuid(),
  title text not null, project_id uuid references project, wp_id uuid references work_package,  -- the funder is the project's
  type text check (type in ('Full-time', 'Part-time')), description text,
  team text, facilities text, contact_email text, partner_nda boolean not null default false,
  partners text check (length(partners) <= 500),   -- AIP-R9: the partners the RA works with, as candidates see them
  status text not null check (status in ('draft', 'published', 'closed', 'cancelled', 'filled')),
  published_at timestamptz, closing_date date
);

create table profile_item (
  position_id uuid references position on delete cascade,
  capability text references capability,
  min_level smallint not null check (min_level between 0 and 4),
  essential boolean not null,
  primary key (position_id, capability)
);

-- R6: position history, like status_event
create table position_event (
  id bigserial primary key, position_id uuid references position on delete cascade,
  from_status text, to_status text not null, by uuid references person, at timestamptz not null default now(), note text
);

/* ---------- files ---------- */

-- The bytes are in Supabase Storage (bucket "applications", read with this row; see the end of the file); this row is the metadata.
create table file (
  id uuid primary key default gen_random_uuid(),
  storage_path text not null unique,
  name text not null,
  size integer not null check (size between 1 and 10485760),   -- 10 MB, as MAX_FILE_BYTES in src/data/files.ts
  type text not null,
  uploaded_by uuid references person,
  uploaded_at timestamptz not null default now()
);

/* ---------- applications ---------- */

-- Codes are numbered per project prefix across all positions of the project (SK01-001, SK01-002, …), so two
-- positions in one project never share a code.
create table application_code_counter (prefix text primary key, last integer not null);

create table application (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  position_id uuid not null references position,
  person_id uuid not null references person,
  status text not null check (status in ('submitted','screening','shortlisted','interviewed','selected','offer_made','contracting',
    'onboarding','plan_with_pi','active','not_shortlisted','not_selected','offer_declined','not_passed','withdrawn','closed')),
  degree text not null,
  cv_file_id uuid references file, cv_link text,
  topic_idea text not null default '',    -- a few sentences, or a title when the idea is a document
  topic_file_id uuid references file, topic_link text,
  -- AIP-R6: the CV as text, pasted by the candidate. Untrusted input: tools and agents read it as data inside a
  -- delimited block, never as instructions and never mixed with system text.
  cv_text text check (length(cv_text) <= 20000),
  -- AIP-R8: the candidate's declaration of AI use. The rules module asks it of every new online application;
  -- applications from before the question have none.
  ai_used boolean, ai_use text check (length(ai_use) <= 1000),
  source text not null check (source in ('online', 'file', 'manual', 'demo')),   -- demo rows are purged before the pilot (Section 13)
  reserve_rank smallint check (reserve_rank >= 1),
  supervisor_id uuid references person,  -- set at the contract step, required to start onboarding
  created_at timestamptz not null default now(),
  unique (position_id, person_id),
  check (cv_file_id is not null or cv_link ~* '^https?://'),
  check (topic_link is null or topic_link ~* '^https?://'),
  check (topic_idea <> '' or topic_file_id is not null or topic_link is not null),
  check (ai_use is null or ai_used),
  check (not coalesce(ai_used, false) or coalesce(ai_use, '') <> '')
);
-- ONB-7: one open offer per position at a time; and one candidate per place in the reserve list.
create unique index application_one_open_offer on application (position_id) where status in ('offer_made', 'contracting', 'onboarding', 'plan_with_pi');
create unique index application_reserve_rank on application (position_id, reserve_rank) where reserve_rank is not null;

-- R6: one row per consent, with the notice version shown. A withdrawn consent is marked, never deleted;
-- giving it again adds a row.
create table consent (
  id bigserial primary key, application_id uuid not null references application on delete cascade,
  purpose text not null check (purpose in ('assessment', 'host', 'pool')),
  text_version text not null, given_at timestamptz not null, withdrawn_at timestamptz,
  check (withdrawn_at is null or withdrawn_at >= given_at)
);
create unique index consent_one_live_per_purpose on consent (application_id, purpose) where withdrawn_at is null;

-- What the candidate gives and later confirms; the candidate can read it.
create table rating (
  application_id uuid references application on delete cascade,
  capability text references capability,
  self_level smallint check (self_level between 0 and 4), evidence text,
  baseline_level smallint check (baseline_level between 0 and 4),   -- from the verified levels at Gate 3
  primary key (application_id, capability)
);

/* ---------- screening and Gate 1 (staff only) ---------- */

create table screening (
  application_id uuid primary key references application on delete cascade,
  topic_score smallint check (topic_score between 1 and 5), learning boolean not null default false, blind_declared boolean not null default false,
  match_pct numeric,
  rule_result text check (rule_result in ('meets', 'fails')),   -- frozen at the Gate 1 decision
  rule_settings jsonb,                                           -- the settings the decision used
  reason text, by uuid references person, at timestamptz
);
create table screening_rating (
  application_id uuid references application on delete cascade,
  capability text references capability,
  verified_level smallint not null check (verified_level between 0 and 4),
  primary key (application_id, capability)
);

/* ---------- interview and Gate 2 ---------- */

create table interview (
  application_id uuid primary key references application on delete cascade,
  date date, place text, template_sent_at timestamptz
);
-- A member taken off the panel is marked removed with a reason (R7). Once any scorecard is submitted,
-- rows cannot be deleted (trigger below), and a member with a scorecard can never be deleted (foreign key).
create table panel_member (
  application_id uuid references interview on delete cascade,
  person_id uuid references person,
  coi_declared_at timestamptz, removed_at timestamptz, removed_by uuid references person, removed_reason text,
  conflict boolean not null default false,   -- removed because they declared a conflict of interest (AIP-R7)
  primary key (application_id, person_id),
  check ((removed_at is null) = (removed_reason is null)),
  check (not conflict or removed_at is not null)
);
-- AIP-R7: a declared conflict of interest. The person, and any agent acting for them, no longer reads the
-- application or anything hanging off it (staff_sees below). Kept for the record; never deleted.
create table conflict_of_interest (
  application_id uuid references application on delete cascade,
  person_id uuid references person,
  at timestamptz not null default now(), note text not null check (note <> '' and length(note) <= 500),
  primary key (application_id, person_id)
);

-- Scores are locked once submitted (trigger below).
create table scorecard (
  application_id uuid, person_id uuid,
  scores jsonb not null, evidence jsonb not null, submitted_at timestamptz,
  primary key (application_id, person_id),
  foreign key (application_id, person_id) references panel_member on delete restrict
);

-- Gate 2 as decided, frozen so later changes to settings or roles do not rewrite it.
create table gate2_decision (
  application_id uuid primary key references application on delete cascade,
  rule_result text not null check (rule_result in ('go', 'nogo')),
  avg numeric not null, min_crit numeric not null, pi_scores boolean not null, rule_settings jsonb not null,
  reason text, by uuid not null references person, at timestamptz not null default now()
);

/* ---------- offer and contract ---------- */

create table offer (
  application_id uuid primary key references application on delete cascade,
  offered_at timestamptz not null, response_due date not null, answer text check (answer in ('accepted', 'declined')),
  answered_at timestamptz, by uuid references person,
  check (response_due >= offered_at::date),
  check ((answer is null) = (answered_at is null))
);

create table contract_item (
  application_id uuid references application on delete cascade,
  item text not null check (item in ('contract', 'nda', 'ip', 'pnda', 'policies', 'safety')),
  done boolean not null default false, at timestamptz,
  primary key (application_id, item)
);
create table contract_dates (
  application_id uuid primary key references application on delete cascade,
  start_date date, probation_end date, partner_nda boolean not null default false,
  check (probation_end is null or start_date is null or probation_end > start_date)
);

-- The new RA's confirmation that they read an agreement or policy, with the version shown. Accepting the lab
-- policies is the 'policies' item on the checklist; agreements to sign are ticked by the lab admin.
create table agreement_read (
  application_id uuid references application on delete cascade,
  item text not null check (item in ('contract', 'nda', 'ip', 'pnda', 'policies')),
  version text not null, read_at timestamptz not null default now(),
  primary key (application_id, item)
);

/* ---------- proposals, plan and Gate 3 ---------- */

-- Topic proposals (IVW-2) and research proposals (ONB-3). A new upload is the next version; none is overwritten.
create table submission (
  id bigserial primary key,
  application_id uuid not null references application on delete cascade,
  kind text not null check (kind in ('topic_proposal', 'research_proposal')),
  version smallint not null check (version >= 1),
  title text not null, file_id uuid references file, link text, notes text,
  submitted_at timestamptz not null default now(), by uuid not null references person,
  unique (application_id, kind, version),
  check (file_id is not null or link ~* '^https?://')
);

create table research_plan (
  application_id uuid references application on delete cascade, version smallint check (version >= 1),
  link text, file_id uuid references file, notes text, submitted_at timestamptz not null default now(), by uuid references person,
  primary key (application_id, version),
  check (file_id is not null or link ~* '^https?://')
);
-- Plan section C5: at Gate 3 these become the new RA's project milestones (handoff 3).
create table plan_milestone (
  application_id uuid, version smallint, n smallint check (n between 1 and 12),
  title text not null check (title <> ''), due date not null, wp_id uuid references work_package,
  primary key (application_id, version, n),
  foreign key (application_id, version) references research_plan on delete cascade
);

create table gate3_review (
  application_id uuid primary key references application on delete cascade,
  plan_version smallint,  -- the plan version this review is for; comment and Revise marks reset per version
  sections jsonb not null, ratings jsonb not null, comment text, decision text check (decision in ('approve', 'revise', 'not_passed')),
  by uuid references person, at timestamptz
);

/* ---------- RA profiles (src/data/profiles.ts) ---------- */

-- Placement for RAs who joined before RMS-X; an RMS-X hire's start is the contract start.
create table ra_record (
  person_id uuid primary key references person on delete cascade,
  start_date date, contract_end date  -- the funder comes from the RA's projects
);
-- Development targets from research plan section C10.
create table development_target (
  person_id uuid references person on delete cascade,
  capability text references capability,
  level smallint not null check (level between 0 and 4),
  due date not null,
  primary key (person_id, capability)
);
-- Levels confirmed after the baseline or Gate 3, with the evidence. Never changed or deleted (trigger below).
create table level_record (
  id bigserial primary key,
  person_id uuid not null references person on delete cascade,
  capability text not null references capability,
  level smallint not null check (level between 0 and 4),
  at timestamptz not null default now(), by uuid not null references person, note text
);
-- Level changes asked for; the supervisor confirms up to Practitioner (2), the PI any (SUPERVISOR_MAX_LEVEL).
create table level_proposal (
  id uuid primary key default gen_random_uuid(),
  person_id uuid not null references person on delete cascade,
  capability text not null references capability,
  level smallint not null check (level between 0 and 4),
  evidence text not null check (evidence <> ''),
  by uuid not null references person, at timestamptz not null default now(),
  status text not null default 'pending' check (status in ('pending', 'confirmed', 'declined')),
  decided_by uuid references person, decided_at timestamptz, reason text,
  check (status <> 'declined' or coalesce(reason, '') <> ''),
  check ((status = 'pending') = (decided_at is null))
);
create unique index level_proposal_one_pending on level_proposal (person_id, capability) where status = 'pending';

create table achievement (
  id uuid primary key default gen_random_uuid(),
  person_id uuid not null references person on delete cascade,
  -- Key deliverables (src/data/profiles.ts): disclosure (patents), journal and conference (publications), prototype,
  -- spinoff, competition and challenge.
  type text not null check (type in ('journal', 'conference', 'talk', 'disclosure', 'software', 'result', 'prototype', 'testbed', 'deliverable',
    'spinoff', 'competition', 'challenge', 'award', 'training', 'mentoring')),
  title text not null check (title <> ''), venue text, date date not null,
  status text not null check (status in ('planned', 'submitted', 'accepted', 'published', 'done')),
  link text check (link is null or link ~* '^https?://'),
  added_by uuid not null references person, added_at timestamptz not null default now(),
  verified_by uuid references person, verified_at timestamptz,
  project_id uuid references project,           -- the funder report credits it here; none for work outside projects
  update_id uuid,                               -- the approved project update it came from (foreign key below)
  author_role text check (author_role in ('main', 'co')),
  authors text check (length(authors) <= 500),   -- AIP-P5: everyone credited, in order
  check ((verified_by is null) = (verified_at is null)),
  check (status <> 'planned' or verified_at is null),
  check (author_role is null or type in ('journal', 'conference'))
);
create table achievement_capability (
  achievement_id uuid references achievement on delete cascade,
  capability text references capability,
  primary key (achievement_id, capability)
);

-- Six-monthly reviews. Not changed once written, except that the RA marks one read, once, and may reply (trigger below).
create table ra_review (
  id uuid primary key default gen_random_uuid(),
  person_id uuid not null references person on delete cascade,
  at timestamptz not null default now(), by uuid not null references person,
  comment text not null default '', goals text not null check (goals <> ''),
  read_at timestamptz, response text
);
create table ra_review_rating (
  review_id uuid references ra_review on delete cascade,
  area text not null check (area in ('progress', 'outputs', 'caps', 'team', 'integrity')),
  rating text not null check (rating in ('exceeds', 'meets', 'below')),
  primary key (review_id, area)
);
-- Decision 3 is the setting 'papers_count_from_submission' (0: papers count once accepted, the default; 1: once submitted).

/* ---------- history and logs ---------- */

/* ---------- project updates (src/rules/projects.ts, src/data/project-actions.ts) ---------- */

create table project_member (
  project_id uuid references project on delete cascade, person_id uuid references person on delete cascade,
  role text not null check (role in ('lead', 'ra')), allocation smallint not null check (allocation between 1 and 100),
  start_date date not null, end_date date check (end_date is null or end_date >= start_date),
  application_id uuid references application,  -- set when the RA joined at Gate 3 (handoff 2)
  primary key (project_id, person_id)
);
-- Statuses are as last approved: only an approved update changes them (trigger below).
create table milestone (
  id uuid primary key default gen_random_uuid(), project_id uuid not null references project on delete cascade,
  wp_id uuid references work_package, code text not null, title text not null, owner_id uuid references person, due date not null,
  status text not null default 'not_started' check (status in ('not_started', 'on_track', 'at_risk', 'late', 'done')),
  update_id uuid,  -- the approved update that last changed it (foreign key below)
  unique (project_id, code)
);
create table project_update (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references project, author_id uuid not null references person,
  period text not null,  -- YYYY-MM for monthly updates (the month due), the due date for fortnightly ones
  status text not null default 'draft' check (status in ('draft', 'submitted', 'checked', 'approved')),
  issues text, help text, created_at timestamptz not null default now(), submitted_at timestamptz,
  checked_by uuid references person, checked_at timestamptz, check_note text, checked_items text[],
  approved_by uuid references person, approved_at timestamptz, pi_comment text,
  approved_unchecked text,  -- the PI's reason for approving without the lab manager's check
  -- Approval by exception (setting 'routine_approval'): the lab manager approved a checked update with no key
  -- deliverable; or sent one to the PI all the same (cleared when the update is returned).
  approved_routine boolean not null default false,
  to_pi boolean not null default false,
  unique (project_id, author_id, period),
  check ((status = 'draft') = (submitted_at is null)),
  check (status not in ('checked') or checked_at is not null),
  check (status <> 'approved' or (approved_at is not null and (checked_at is not null or coalesce(approved_unchecked, '') <> ''))),
  check (not approved_routine or (status = 'approved' and checked_at is not null and approved_unchecked is null)),
  check (not to_pi or status in ('checked', 'approved'))
);
create table update_item (
  update_id uuid references project_update on delete cascade, milestone_id uuid references milestone,
  was text not null, now text not null, note text, evidence text,
  primary key (update_id, milestone_id)
);
create table update_output (
  id uuid primary key default gen_random_uuid(), update_id uuid not null references project_update on delete cascade,
  achievement_id uuid references achievement, type text not null, title text not null, venue text, date date not null,
  status text not null, link text check (link is null or link ~* '^https?://'), author_role text, authors text check (length(authors) <= 500),
  -- For a change to an existing achievement: that achievement as it was when the RA added it. The approval writes only
  -- the fields the RA changed, so an edit made since stays, and stops when the same field was changed both ways.
  was jsonb check (was is null or achievement_id is not null)
);
create table update_return (
  id bigserial primary key, update_id uuid not null references project_update on delete cascade,
  by uuid not null references person, at timestamptz not null default now(),
  note text not null check (note <> ''), from_status text not null check (from_status in ('submitted', 'checked'))
);
create table update_reminder (
  id bigserial primary key, project_id uuid not null references project, person_id uuid not null references person,
  period text not null, by uuid not null references person, at timestamptz not null default now()
);
-- AIP-P6: every version sent, as it was sent (items, outputs, issues, help); the "what changed" view compares the last
-- two. Rows are never changed (trigger below).
create table update_version (
  update_id uuid references project_update on delete cascade, n smallint check (n >= 1),
  at timestamptz not null default now(), content jsonb not null,
  primary key (update_id, n)
);
-- AIP-P7: where the project's work is, in its own table so the public About us page, which reads project, never shows it.
create table project_link (
  project_id uuid primary key references project on delete cascade,
  folder_url text check (folder_url ~* '^https://'), repo_url text check (repo_url ~* '^https://'),
  check (folder_url is not null or repo_url is not null)
);
alter table milestone add foreign key (update_id) references project_update;
alter table achievement add foreign key (update_id) references project_update;
-- The update rules the PI sets: numbers in setting; the rhythm and the check items here. 'routine_approval' is 0 when
-- the PI approves every update (the default) and 1 when the lab manager approves those with no key deliverable.
create table text_setting (key text primary key, value text not null);
create table update_check_item (n smallint primary key, label text not null unique);
create table output_target (year smallint primary key, main_papers smallint not null, co_papers smallint not null, disclosures smallint not null);

/* ---------- Hub (src/data/hub.ts) ---------- */

create table hub_section (
  id text primary key check (id in ('kb', 'facilities', 'cei', 'partners')),
  owner_id uuid not null references person, review_due date not null, reviewed_at timestamptz
);
create table hub_article (
  id uuid primary key default gen_random_uuid(),
  category text not null check (category in ('sop', 'template', 'guide', 'onboarding')),
  title text not null, body text not null, link text, version integer not null default 1 check (version >= 1),
  updated_at timestamptz not null default now(), owner_id uuid not null references person,
  -- AIP-H1: who reads it (anyone; lab staff and RAs; the PI only) and when its owner reviews it next.
  access text not null default 'staff' check (access in ('public', 'staff', 'pi')),
  review_due date not null default (current_date + 182)
);
create table article_project (article_id uuid references hub_article on delete cascade, project_id uuid references project on delete cascade, primary key (article_id, project_id));
create table hub_suggestion (
  id uuid primary key default gen_random_uuid(), article_id uuid not null references hub_article on delete cascade,
  by uuid not null references person, at timestamptz not null default now(), text text not null,
  status text not null default 'open' check (status in ('open', 'done', 'declined')),
  decided_by uuid references person, decided_at timestamptz, reply text,
  check (status <> 'declined' or coalesce(reply, '') <> '')
);
create table facility (
  id uuid primary key default gen_random_uuid(), name text not null, description text,
  status text not null check (status in ('available', 'in_use', 'maintenance')), status_note text, status_until date,
  location text, owner_id uuid not null references person,
  training text not null check (training in ('required', 'briefing', 'none')), rules text[] not null default '{}',
  updated_at timestamptz not null default now(),
  check ((status = 'available') = (status_until is null))
);
create table facility_project (facility_id uuid references facility on delete cascade, project_id uuid references project on delete cascade, primary key (facility_id, project_id));
-- AIP-H3: bookings for whole days, first and last day included. Two bookings of one facility never overlap (trigger
-- below); cancelled ones are kept.
create table facility_booking (
  id uuid primary key default gen_random_uuid(), facility_id uuid not null references facility on delete cascade,
  person_id uuid not null references person, project_id uuid references project,
  what text not null check (length(what) between 3 and 200), from_day date not null, to_day date not null,
  status text not null default 'booked' check (status in ('booked', 'cancelled')),
  at timestamptz not null default now(), cancelled_by uuid references person, cancelled_at timestamptz,
  check (to_day >= from_day and to_day <= from_day + 29),
  check ((status = 'cancelled') = (cancelled_at is not null))
);
create index facility_booking_days on facility_booking (facility_id, from_day);
create table announcement (
  id uuid primary key default gen_random_uuid(), title text not null, body text,
  by uuid not null references person, at timestamptz not null default now(), until date
);

create table status_event (
  id bigserial primary key, application_id uuid references application on delete cascade,
  from_status text, to_status text not null, by uuid references person, at timestamptz not null default now(), note text
);

-- VW-6 workaround log
create table workaround (
  id bigserial primary key, date date not null, task text not null, why text, by uuid references person,
  application_id uuid references application on delete set null
);

-- Every action adds one row (AuditEvent in src/data/types.ts). Rows are never changed or deleted. The ids
-- are kept as plain values, without foreign keys, so the log outlives a deleted draft position or a
-- record removed under data retention. Summaries never name a candidate and never carry scores.
create table audit_event (
  id bigserial primary key,
  at timestamptz not null default now(),
  by uuid not null,
  action text not null,
  summary text not null,
  application_id uuid, position_id uuid, person_id uuid, project_id uuid, update_id uuid,
  changes jsonb,
  reason text,         -- AIP-R3: why, where the action takes a reason
  proposal_id uuid     -- AIP-R3: the agent proposal the person accepted, when the change came from one
);
create index audit_event_application on audit_event (application_id);
create index audit_event_position on audit_event (position_id);
create index audit_event_project on audit_event (project_id);
create index audit_event_proposal on audit_event (proposal_id) where proposal_id is not null;

-- AIP-F3: one event table for every module, for triggers and measures (AppEvent in src/data/types.ts). Actions write
-- their events in the same transaction as the change; a daily job writes the kinds that come with time (due soon,
-- overdue, late, past review), once each (the unique index). Ids and dates only: no names, no scores.
create table event (
  id bigserial primary key, at timestamptz not null default now(),
  module text not null check (module in ('recruitment', 'projects', 'hub')),
  kind text not null check (kind in (
    'application.received', 'application.imported', 'gate1.decided', 'interview.scheduled', 'panel.complete', 'contract.item_open', 'gate3.decided',
    'update.due_soon', 'update.submitted', 'update.returned', 'update.approved', 'update.overdue', 'milestone.late',
    'hub.page_published', 'hub.page_changed', 'hub.page_past_review')),
  check (module = case split_part(kind, '.', 1) when 'update' then 'projects' when 'milestone' then 'projects' when 'hub' then 'hub' else 'recruitment' end),
  by uuid,   -- none for the daily job
  application_id uuid, position_id uuid, project_id uuid, update_id uuid, milestone_id uuid, article_id uuid, person_id uuid,
  key text
);
create index event_kind_at on event (kind, at);
create unique index event_once on event (kind, coalesce(milestone_id, article_id, project_id), coalesce(person_id, '00000000-0000-0000-0000-000000000000'::uuid), key)
  where kind in ('update.due_soon', 'update.overdue', 'milestone.late', 'hub.page_past_review');

create table notification (
  id bigserial primary key, recipient text not null, template text not null, payload jsonb, created_at timestamptz default now(), sent_at timestamptz
);

/* ---------- rules the database keeps on its own ---------- */

create function next_application_code(p_prefix text) returns text language sql as $$
  insert into application_code_counter as c (prefix, last) values (upper(p_prefix), 1)
  on conflict (prefix) do update set last = c.last + 1
  returning upper(p_prefix) || '-' || case when last < 1000 then lpad(last::text, 3, '0') else last::text end
$$;
-- After importing applications with their codes (the local store, a spreadsheet), run once so new codes follow on.
create function catch_up_application_codes() returns void language sql as $$
  insert into application_code_counter as c (prefix, last)
    select substring(code from '^(.*)-[0-9]+$'), max(substring(code from '-([0-9]+)$')::int) from application group by 1
  on conflict (prefix) do update set last = greatest(c.last, excluded.last)
$$;

create function reject_change() returns trigger language plpgsql as $$
begin
  raise exception '%', tg_argv[0];
end $$;

-- Roles are for lab staff only, so a candidate or RA can never sit on a panel or decide a gate.
create function role_for_staff_only() returns trigger language plpgsql as $$
begin
  if not exists (select 1 from person where id = new.person_id and kind = 'staff') then
    raise exception 'Roles are for lab staff only';
  end if;
  return new;
end $$;
create trigger role_for_staff_only before insert or update on role_assignment for each row execute function role_for_staff_only();

-- The status flow (FLOW in src/rules/rules.ts): an application moves only along it, whoever writes.
create function application_flow() returns trigger language plpgsql as $$
begin
  if (old.status, new.status) not in (values
    ('submitted', 'screening'), ('submitted', 'withdrawn'), ('submitted', 'closed'),
    ('screening', 'shortlisted'), ('screening', 'not_shortlisted'), ('screening', 'withdrawn'), ('screening', 'closed'),
    ('shortlisted', 'interviewed'), ('shortlisted', 'withdrawn'), ('shortlisted', 'closed'),
    ('interviewed', 'selected'), ('interviewed', 'not_selected'), ('interviewed', 'withdrawn'), ('interviewed', 'closed'),
    ('selected', 'offer_made'), ('selected', 'withdrawn'), ('selected', 'closed'),
    ('offer_made', 'contracting'), ('offer_made', 'offer_declined'), ('offer_made', 'withdrawn'),
    ('contracting', 'onboarding'), ('contracting', 'withdrawn'),
    ('onboarding', 'plan_with_pi'), ('onboarding', 'not_passed'), ('onboarding', 'withdrawn'),
    ('plan_with_pi', 'active'), ('plan_with_pi', 'onboarding'), ('plan_with_pi', 'not_passed')) then
    raise exception 'Cannot move an application from % to %', old.status, new.status;
  end if;
  return new;
end $$;
create trigger application_flow before update of status on application
  for each row when (old.status is distinct from new.status) execute function application_flow();

create trigger audit_append_only before update or delete on audit_event
  for each row execute function reject_change('audit_event rows cannot be changed or deleted');

create function scorecard_locked() returns trigger language plpgsql as $$
begin
  if old.submitted_at is not null then raise exception 'This scorecard is submitted and locked'; end if;
  return case when tg_op = 'DELETE' then old else new end;
end $$;
create trigger scorecard_locked before update or delete on scorecard for each row when (current_setting('rmsx.purge', true) is distinct from 'on') execute function scorecard_locked();

-- R7: once scoring has started a member leaves the panel by being marked removed, with a reason.
create function panel_member_kept() returns trigger language plpgsql as $$
begin
  if exists (select 1 from scorecard where application_id = old.application_id and submitted_at is not null) then
    raise exception 'Scoring has started: mark the panel member removed instead of deleting them';
  end if;
  return old;
end $$;
create trigger panel_member_kept before delete on panel_member for each row when (current_setting('rmsx.purge', true) is distinct from 'on') execute function panel_member_kept();

create trigger submission_kept before update or delete on submission
  for each row when (current_setting('rmsx.purge', true) is distinct from 'on') execute function reject_change('A proposal is never changed or deleted; send a new version');

create trigger level_record_kept before update or delete on level_record
  for each row execute function reject_change('A confirmed level is never changed or deleted; confirm a new one');
create trigger ra_review_rating_kept before update or delete on ra_review_rating
  for each row execute function reject_change('Review ratings are not changed once written');

create function ra_review_kept() returns trigger language plpgsql as $$
begin
  if tg_op = 'DELETE' then raise exception 'A review is never deleted'; end if;
  if old.read_at is not null or new.at <> old.at or new."by" <> old."by" or new.person_id <> old.person_id
     or new.comment <> old.comment or new.goals <> old.goals then
    raise exception 'A review is not changed once written; the RA may only mark it read and reply';
  end if;
  return new;
end $$;
create trigger ra_review_kept before update or delete on ra_review for each row execute function ra_review_kept();

-- An approved update is the project record's history: it and its rows are never changed.
create function update_kept() returns trigger language plpgsql as $$
begin
  if old.status = 'approved' then raise exception 'An approved update is not changed.'; end if;
  return case when tg_op = 'DELETE' then old else new end;
end $$;
create trigger update_kept before update or delete on project_update for each row execute function update_kept();
create function update_rows_kept() returns trigger language plpgsql as $$
begin
  if exists (select 1 from project_update where id = old.update_id and status = 'approved') then
    raise exception 'An approved update is not changed.';
  end if;
  return case when tg_op = 'DELETE' then old else new end;
end $$;
create trigger update_item_kept before update or delete on update_item for each row execute function update_rows_kept();
create trigger update_output_kept before update or delete on update_output for each row execute function update_rows_kept();
create function version_kept() returns trigger language plpgsql as $$
begin
  if coalesce(current_setting('rmsx.purge', true), '') <> 'on' then raise exception 'A sent version of an update is not changed.'; end if;
  return case when tg_op = 'DELETE' then old else new end;
end $$;
create trigger update_version_kept before update or delete on update_version for each row execute function version_kept();
-- AIP-H3: one booking of a facility per day.
create function booking_free() returns trigger language plpgsql as $$
begin
  if new.status = 'booked' and exists (
    select 1 from facility_booking b where b.facility_id = new.facility_id and b.id <> new.id and b.status = 'booked'
      and b.from_day <= new.to_day and b.to_day >= new.from_day) then
    raise exception 'This facility is already booked on some of these days.';
  end if;
  return new;
end $$;
create trigger booking_free before insert or update on facility_booking for each row execute function booking_free();
-- Only an approved update changes a milestone's status (approved by the PI, or by the lab manager under the routine
-- rule): the approval function sets rmsx.approving for its transaction.
create function milestone_status_by_approval() returns trigger language plpgsql as $$
begin
  if new.status is distinct from old.status and coalesce(current_setting('rmsx.approving', true), '') <> 'on' then
    raise exception 'A milestone''s status changes only when an update is approved.';
  end if;
  return new;
end $$;
create trigger milestone_status_by_approval before update on milestone for each row execute function milestone_status_by_approval();

-- Data retention and the demo rows (Section 13): removes one application with everything that hangs off it, and the
-- candidate when they have no other application, past the history triggers above (rmsx.purge, for this transaction
-- only). The audit log stays. An RA's hiring application is kept. Returns the storage paths of the files removed, for
-- the server to delete from the bucket. Not callable through the API.
create function purge_application(app uuid) returns setof text language plpgsql as $$
declare
  pid uuid;
  files uuid[];
begin
  select person_id into pid from application where id = app;
  if pid is null then raise exception 'Application not found'; end if;
  if exists (select 1 from application where id = app and status = 'active') then raise exception 'An RA''s hiring application is kept'; end if;
  select coalesce(array_agg(f), '{}') into files from (
    select cv_file_id from application where id = app union select topic_file_id from application where id = app
    union select file_id from submission where application_id = app union select file_id from research_plan where application_id = app) s(f)
  where f is not null;
  perform set_config('rmsx.purge', 'on', true);
  delete from scorecard where application_id = app;
  delete from application where id = app;
  return query delete from file where id = any (files) returning storage_path;
  delete from person where id = pid and kind = 'candidate' and not exists (select 1 from application where person_id = pid);
  perform set_config('rmsx.purge', 'off', true);
end $$;

/* ---------- who can read what ---------- */

-- Helpers run as the owner so policies can use them without recursing into each other's row-level security.
create function me() returns uuid language sql stable security definer set search_path = public, pg_temp as $$
  select id from person where account_id = auth.uid()
$$;
create function has_role(variadic roles text[]) returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select exists (select 1 from role_assignment where person_id = me() and role = any (roles))
$$;
-- Staff with at least one role. Staff without a role are treated like the public.
create function is_lab_staff() returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select exists (select 1 from role_assignment where person_id = me())
$$;
-- AIP-R7: staff read an application and everything hanging off it unless they declared a conflict with it.
create function staff_sees(app uuid) returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select is_lab_staff() and not exists (select 1 from conflict_of_interest where application_id = app and person_id = me())
$$;
create function can_see_application(app uuid) returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select staff_sees(app) or exists (select 1 from application where id = app and person_id = me())
$$;
create function position_is_public(pos uuid) returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select exists (select 1 from position where id = pos and status in ('published', 'closed', 'filled'))
$$;
-- Blind screening: a candidate is named to staff once one of their applications is past Gate 1.
create function candidate_named(p uuid) returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select exists (select 1 from application where person_id = p and status not in ('submitted', 'screening'))
$$;
-- IVW-4: everyone on the panel (not removed) has submitted.
create function panel_all_in(app uuid) returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select exists (select 1 from panel_member where application_id = app and removed_at is null)
     and not exists (
       select 1 from panel_member pm where pm.application_id = app and pm.removed_at is null
         and not exists (select 1 from scorecard s where s.application_id = app and s.person_id = pm.person_id and s.submitted_at is not null))
$$;

-- An RA's supervisor: on the person for RAs who joined before RMS-X, on the hiring application for RMS-X hires.
create function ra_supervisor(p uuid) returns uuid language sql stable security definer set search_path = public, pg_temp as $$
  select coalesce((select supervisor_id from person where id = p),
                  (select supervisor_id from application where person_id = p and status = 'active' limit 1))
$$;
-- Decision 1: capability levels, targets and reviews are seen by the RA, their supervisor and the PI.
create function sees_ra_levels(p uuid) returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select p = me() or has_role('pi') or (has_role('supervisor') and ra_supervisor(p) = me())
$$;
-- Placement and achievements are seen by those, and by the lab admin.
create function sees_ra_outputs(p uuid) returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select sees_ra_levels(p) or has_role('admin')
$$;

-- Projects (PRD section 8): the PI and lab manager see every project; the lead and RAs the ones they are on today.
create function on_project(p uuid) returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select exists (select 1 from project_member where project_id = p and person_id = me() and start_date <= current_date and (end_date is null or end_date >= current_date))
$$;
create function leads_project(p uuid) returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select exists (select 1 from project_member where project_id = p and person_id = me() and role = 'lead' and start_date <= current_date and (end_date is null or end_date >= current_date))
$$;
create function sees_project(p uuid) returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select has_role('pi', 'admin') or on_project(p)
$$;
-- An update: its author, the PI, the lab manager and the project lead; the rest of the team once it is approved.
create function sees_update(u uuid) returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select exists (select 1 from project_update x where x.id = u
    and (x.author_id = me() or has_role('pi', 'admin') or leads_project(x.project_id) or (x.status = 'approved' and on_project(x.project_id))))
$$;
-- The Hub is for staff and RAs (an RA hired through RMS-X is still a candidate person, with an active application).
-- Staff with a role, and RAs (from before RMS-X, or hired through it).
create function is_lab_member() returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select is_lab_staff() or exists (select 1 from person where id = me() and kind = 'ra')
      or exists (select 1 from application where person_id = me() and status = 'active')
$$;
create function uses_hub() returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select exists (select 1 from person where id = me() and kind in ('staff', 'ra'))
      or exists (select 1 from application where person_id = me() and status = 'active')
$$;

do $$
declare t record;
begin
  for t in select tablename from pg_tables where schemaname = 'public' loop
    execute format('alter table public.%I enable row level security', t.tablename);
  end loop;
end $$;

revoke all on all tables in schema public from anon, authenticated;
revoke all on all sequences in schema public from anon, authenticated;
grant select on all tables in schema public to anon, authenticated;
revoke execute on function next_application_code(text) from public;
-- The read rules call these as the signed-in user, and the first three for the public too. Every other function in
-- this file (next_application_code, purge_application, ra_supervisor, the triggers) is for the server only.
grant execute on function me(), has_role(text[]), is_lab_staff(), staff_sees(uuid), can_see_application(uuid), position_is_public(uuid), candidate_named(uuid),
  panel_all_in(uuid), sees_ra_levels(uuid), sees_ra_outputs(uuid), sees_project(uuid), sees_update(uuid), uses_hub(), is_lab_member() to authenticated;
grant execute on function is_lab_staff(), position_is_public(uuid), sees_project(uuid) to anon;

create policy read_all on capability_area for select to anon, authenticated using (true);
create policy read_all on capability for select to anon, authenticated using (true);
create policy read_signed_in on holiday for select to authenticated using (true);
create policy read_signed_in on setting for select to authenticated using (true);

create policy read on position for select to anon, authenticated using (status in ('published', 'closed', 'filled') or is_lab_staff());
create policy read on profile_item for select to anon, authenticated using (position_is_public(position_id) or is_lab_staff());
create policy read on position_event for select to authenticated using (is_lab_staff());

-- Lab members (staff and RAs) see each other, so team pages name their people; staff see a candidate once named.
create policy read on person for select to authenticated using (
  id = me() or (is_lab_staff() and (kind <> 'candidate' or candidate_named(id))) or (is_lab_member() and kind in ('staff', 'ra')));
create policy read on role_assignment for select to authenticated using (person_id = me() or is_lab_staff());
create policy read on person_baseline for select to authenticated using (sees_ra_levels(person_id));   -- levels: decision 1

create policy read on file for select to authenticated using (uploaded_by = me() or is_lab_staff());

create policy read on application for select to authenticated using (person_id = me() or staff_sees(id));
create policy read on conflict_of_interest for select to authenticated using (person_id = me() or has_role('pi', 'admin'));
create policy read on consent for select to authenticated using (can_see_application(application_id));
create policy read on rating for select to authenticated using (can_see_application(application_id));
create policy read on interview for select to authenticated using (can_see_application(application_id));
create policy read on offer for select to authenticated using (can_see_application(application_id));
create policy read on contract_item for select to authenticated using (can_see_application(application_id));
create policy read on contract_dates for select to authenticated using (can_see_application(application_id));
create policy read on agreement_read for select to authenticated using (can_see_application(application_id));
create policy read on submission for select to authenticated using (can_see_application(application_id));
create policy read on research_plan for select to authenticated using (can_see_application(application_id));
-- The PI's Gate 3 marks and comments, and the notes on status moves (gate reasons, revision and not-passed comments),
-- are staff only. The candidate reads their statuses and dates through my_status_event, below.
create policy read on gate3_review for select to authenticated using (staff_sees(application_id));
create policy read on status_event for select to authenticated using (staff_sees(application_id));

create policy read on screening for select to authenticated using (staff_sees(application_id));
create policy read on screening_rating for select to authenticated using (staff_sees(application_id));
create policy read on panel_member for select to authenticated using (staff_sees(application_id));
create policy read on gate2_decision for select to authenticated using (staff_sees(application_id));
create policy read on scorecard for select to authenticated using (person_id = me() or (staff_sees(application_id) and panel_all_in(application_id)));
-- AIP-F3: events for staff, without the applications they declared a conflict with; each person reads their own.
create policy read on event for select to authenticated using (
  person_id = me() or (is_lab_staff() and (application_id is null or staff_sees(application_id))));
create policy read on workaround for select to authenticated using (is_lab_staff());
-- The lab admin reads the log except level changes, which are decision 1 data.
create policy read on audit_event for select to authenticated using (has_role('pi') or (has_role('admin') and action not like 'level.%'));
create policy read on ra_record for select to authenticated using (sees_ra_outputs(person_id));
create policy read on achievement for select to authenticated using (sees_ra_outputs(person_id));
create policy read on achievement_capability for select to authenticated using (
  exists (select 1 from achievement a where a.id = achievement_id and sees_ra_outputs(a.person_id)));
create policy read on development_target for select to authenticated using (sees_ra_levels(person_id));
create policy read on level_record for select to authenticated using (sees_ra_levels(person_id));
create policy read on level_proposal for select to authenticated using (sees_ra_levels(person_id));
create policy read on ra_review for select to authenticated using (sees_ra_levels(person_id));
create policy read on ra_review_rating for select to authenticated using (
  exists (select 1 from ra_review r where r.id = review_id and sees_ra_levels(r.person_id)));
-- application_code_counter and notification: no policy, so no API access at all.

-- A candidate's own status history, as /me shows it: statuses and dates, never the notes or who moved it. The view
-- reads status_event as its owner, so it filters to the caller itself.
create view my_status_event as
  select application_id, from_status, to_status, at from status_event
  where application_id in (select id from application where person_id = me());
revoke all on my_status_event from anon, authenticated;
grant select on my_status_event to authenticated;

-- Projects and Hub
create policy read on project for select to anon, authenticated using (
  sees_project(id) or about is not null or exists (select 1 from position where project_id = project.id and status in ('published', 'closed', 'filled')));
create policy read on project_budget for select to authenticated using (has_role('pi'));
create policy read on work_package for select to authenticated using (sees_project(project_id));
create policy read on project_member for select to authenticated using (sees_project(project_id));
create policy read on milestone for select to authenticated using (sees_project(project_id));
create policy read on project_update for select to authenticated using (sees_update(id));
create policy read on update_item for select to authenticated using (sees_update(update_id));
create policy read on update_output for select to authenticated using (sees_update(update_id));
create policy read on update_return for select to authenticated using (sees_update(update_id));
create policy read on update_reminder for select to authenticated using (person_id = me() or has_role('pi', 'admin'));
create policy read on update_version for select to authenticated using (sees_update(update_id));
create policy read on project_link for select to authenticated using (sees_project(project_id));
create policy read on plan_milestone for select to authenticated using (can_see_application(application_id));
create policy read_signed_in on text_setting for select to authenticated using (true);
create policy read_signed_in on update_check_item for select to authenticated using (true);
create policy read_signed_in on output_target for select to authenticated using (is_lab_staff());
create policy read on hub_section for select to authenticated using (uses_hub());
-- AIP-H1: by the page's access level. Public pages are open to anyone, signed in or not.
create policy read on hub_article for select to authenticated using (access = 'public' or (access = 'staff' and uses_hub()) or has_role('pi'));
create policy read_public on hub_article for select to anon using (access = 'public');
create policy read on article_project for select to authenticated using (uses_hub());
create policy read on hub_suggestion for select to authenticated using (by = me() or has_role('pi', 'admin'));
create policy read on facility for select to authenticated using (uses_hub());
create policy read on facility_project for select to authenticated using (uses_hub());
create policy read on facility_booking for select to authenticated using (uses_hub());
create policy read on announcement for select to authenticated using (uses_hub());

/* ---------- files in Supabase Storage ---------- */

-- CVs, topic slides, proposals and plans: one private bucket, 10 MB a file, the types the forms accept. A file is read by
-- whoever may read its row in public.file. Nobody uploads or deletes through the API: the server action issues a
-- signed upload URL and adds the file row; purge_application returns the paths to delete.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values ('applications', 'applications', false, 10485760,
  array['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/vnd.openxmlformats-officedocument.presentationml.presentation'])
on conflict (id) do update set public = false, file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;
create policy "applications: read with the file row" on storage.objects for select to authenticated
  using (bucket_id = 'applications' and exists (select 1 from public.file f where f.storage_path = objects.name));
