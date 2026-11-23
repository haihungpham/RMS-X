// Checks supabase/schema.sql without a Supabase project: applies it to Postgres (PGlite) with a stub
// auth.uid(), seeds a small lab, then reads as each kind of user and tries writes that must be refused.
// Run from the project folder (installs PGlite without changing package.json):
//   npm install --no-save @electric-sql/pglite@0.2.17
//   node supabase/check-schema.mjs
import { PGlite } from '@electric-sql/pglite';
import { citext } from '@electric-sql/pglite/contrib/citext';
import { readFileSync } from 'node:fs';

const db = new PGlite({ extensions: { citext } });
const results = [];
const check = (name, ok, detail = '') => results.push({ ok, name, detail });
const u = (n) => `00000000-0000-0000-0000-${String(n).padStart(12, '0')}`;
const acct = (n) => `10000000-0000-0000-0000-${String(n).padStart(12, '0')}`;
const P = { pi: 1, sup: 2, panel: 3, norole: 4, candA: 5, candB: 6, admin: 7, ra1: 8, ra2: 9 };
const appA = u(101), appB = u(102), pos1 = u(201), pos2 = u(202);
const sk01 = u(501), cmit = u(502), wp1 = u(511), draftUpd = u(601), doneUpd = u(602), ms1 = u(701), art = u(801);

await db.exec(`
  create role anon nologin; create role authenticated nologin;
  create schema auth;
  create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
  grant usage on schema auth to anon, authenticated;
  grant usage on schema public to anon, authenticated;
  -- As on a Supabase project: the API roles get every new object in public by default, and Storage has its own schema.
  alter default privileges in schema public grant all on tables to anon, authenticated;
  alter default privileges in schema public grant all on sequences to anon, authenticated;
  alter default privileges in schema public grant all on functions to anon, authenticated;
  create schema storage;
  create table storage.buckets (id text primary key, name text not null, public boolean not null default false, file_size_limit bigint, allowed_mime_types text[]);
  create table storage.objects (id uuid primary key default gen_random_uuid(), bucket_id text references storage.buckets, name text not null, owner uuid);
  alter table storage.objects enable row level security;
  grant usage on schema storage to anon, authenticated;
  grant select on storage.buckets to anon, authenticated;
  grant select, insert, update, delete on storage.objects to anon, authenticated;
`);
await db.exec(readFileSync(process.argv[2] ?? new URL('./schema.sql', import.meta.url), 'utf8'));
check('schema applies', true);

await db.exec(`
  insert into capability_area values ('re', 'Research'); insert into capability values ('cfd', 're', 'CFD');
  insert into person (id, account_id, name, email, kind) values
    ('${u(1)}', '${acct(1)}', 'Lab PI', 'pi@example.edu', 'staff'),
    ('${u(2)}', '${acct(2)}', 'Supervisor', 'sup@example.edu', 'staff'),
    ('${u(3)}', '${acct(3)}', 'Panel', 'panel@example.edu', 'staff'),
    ('${u(4)}', '${acct(4)}', 'Staff without role', 'norole@example.edu', 'staff'),
    ('${u(5)}', '${acct(5)}', 'Candidate A', 'a@example.com', 'candidate'),
    ('${u(6)}', '${acct(6)}', 'Candidate B', 'b@example.com', 'candidate'),
    ('${u(7)}', '${acct(7)}', 'Lab admin', 'admin@example.edu', 'staff');
  insert into person (id, account_id, name, email, kind, supervisor_id) values
    ('${u(8)}', '${acct(8)}', 'RA One', 'ra1@example.edu', 'ra', '${u(2)}'),
    ('${u(9)}', '${acct(9)}', 'RA Two', 'ra2@example.edu', 'ra', null);
  insert into role_assignment values ('${u(1)}', 'pi'), ('${u(2)}', 'supervisor'), ('${u(2)}', 'panel'), ('${u(3)}', 'panel'), ('${u(7)}', 'admin');
  insert into project (id, code, title, funder, pi_id, start_date, end_date, rhythm, updates_from) values
    ('${sk01}', 'SK01', 'Thermal', 'CEI', '${u(1)}', '2026-01-01', '2027-12-31', 'monthly', '2026-09-01'),
    ('${cmit}', 'CMIT', 'Digital twin', 'CMIT', '${u(1)}', '2026-01-01', '2027-12-31', null, null);
  insert into work_package values ('${wp1}', '${sk01}', 'WP1', 'Modeling');
  insert into position (id, title, project_id, wp_id, status) values ('${pos1}', 'RA', '${sk01}', '${wp1}', 'published'), ('${pos2}', 'Draft', '${cmit}', null, 'draft');
  insert into application (id, code, position_id, person_id, status, degree, cv_link, topic_idea, source) values
    ('${appA}', next_application_code('SK01'), '${pos1}', '${u(5)}', 'submitted', 'MSc', 'https://x.y/cv', 'idea', 'online'),
    ('${appB}', next_application_code('SK01'), '${pos1}', '${u(6)}', 'shortlisted', 'MSc', 'https://x.y/cv', 'idea', 'online');
  insert into consent (application_id, purpose, text_version, given_at) values ('${appA}', 'assessment', 'v1', now());
  insert into screening (application_id, topic_score, blind_declared) values ('${appA}', 4, true);
  insert into interview (application_id, date) values ('${appB}', current_date);
  insert into panel_member (application_id, person_id) values ('${appB}', '${u(2)}'), ('${appB}', '${u(3)}');
  insert into scorecard values ('${appB}', '${u(2)}', '{"caps": 4}', '{}', now()), ('${appB}', '${u(3)}', '{"caps": 2}', '{}', null);
  insert into submission (application_id, kind, version, title, link, by) values ('${appB}', 'topic_proposal', 1, 'Slides', 'https://x.y/s.pdf', '${u(6)}');
  insert into audit_event (by, action, summary, application_id) values ('${u(1)}', 'gate1.decide', 'Gate 1: shortlisted', '${appB}');
  insert into audit_event (by, action, summary, person_id) values ('${u(1)}', 'level.confirm', 'Level change confirmed: CFD → 3 Expert', '${u(8)}');
  insert into status_event (application_id, from_status, to_status, by, note) values
    ('${appA}', null, 'submitted', '${u(5)}', null), ('${appB}', 'screening', 'shortlisted', '${u(1)}', 'Strong topic idea (the Gate 1 reason)');
  insert into gate3_review (application_id, plan_version, sections, ratings, comment) values ('${appB}', 1, '{}', '{}', 'Revise section 3');
  insert into file (id, storage_path, name, size, type, uploaded_by) values
    ('${u(901)}', 'a/cv.pdf', 'cv.pdf', 1000, 'application/pdf', '${u(5)}'), ('${u(902)}', 'b/cv.pdf', 'cv.pdf', 1000, 'application/pdf', '${u(6)}');
  update application set cv_file_id = '${u(902)}' where id = '${appB}';
  insert into storage.objects (bucket_id, name) values ('applications', 'a/cv.pdf'), ('applications', 'b/cv.pdf');
  insert into capability values ('write', 're', 'Scientific writing');
  insert into ra_record values ('${u(8)}', '2025-01-06', '2027-01-05'), ('${u(9)}', '2025-03-03', '2027-03-02');
  insert into achievement (id, person_id, type, title, date, status, added_by, verified_by, verified_at) values
    ('${u(301)}', '${u(8)}', 'journal', 'RA One paper', '2026-10-01', 'accepted', '${u(8)}', '${u(2)}', now()),
    ('${u(302)}', '${u(9)}', 'talk', 'RA Two talk', '2026-09-01', 'done', '${u(9)}', null, null);
  insert into achievement_capability values ('${u(301)}', 'write');
  insert into development_target values ('${u(8)}', 'cfd', 3, '2027-01-01');
  insert into level_record (person_id, capability, level, by, note) values ('${u(8)}', 'cfd', 2, '${u(2)}', 'Course'), ('${u(9)}', 'write', 2, '${u(1)}', 'Paper');
  insert into person_baseline values ('${u(8)}', 'cfd', 2), ('${u(9)}', 'cfd', 1);
  insert into level_proposal (person_id, capability, level, evidence, by) values ('${u(8)}', 'write', 3, 'Accepted paper', '${u(8)}');
  insert into ra_review (id, person_id, by, goals) values ('${u(401)}', '${u(8)}', '${u(2)}', 'Submit the next paper');
  insert into ra_review_rating values ('${u(401)}', 'progress', 'meets');

  -- Projects: the supervisor leads SK01; RA One is on SK01; RA Two splits between SK01 and CMIT. Only SK01 has a budget.
  insert into project_budget values ('${sk01}', 2400, 1150);
  insert into project_member (project_id, person_id, role, allocation, start_date) values
    ('${sk01}', '${u(2)}', 'lead', 20, '2026-01-01'), ('${sk01}', '${u(8)}', 'ra', 100, '2026-01-01'),
    ('${sk01}', '${u(9)}', 'ra', 50, '2026-01-01'), ('${cmit}', '${u(9)}', 'ra', 50, '2026-01-01');
  insert into milestone (id, project_id, wp_id, code, title, owner_id, due, status) values ('${ms1}', '${sk01}', '${wp1}', 'M1', 'Model', '${u(8)}', '2026-12-01', 'on_track');
  insert into project_update (id, project_id, author_id, period, status) values ('${draftUpd}', '${sk01}', '${u(8)}', '2026-11', 'draft');
  insert into project_update (id, project_id, author_id, period, status, submitted_at, checked_by, checked_at, approved_by, approved_at) values
    ('${doneUpd}', '${sk01}', '${u(8)}', '2026-10', 'approved', now(), '${u(7)}', now(), '${u(1)}', now());
  insert into update_item values ('${draftUpd}', '${ms1}', 'on_track', 'at_risk', 'Slower', null), ('${doneUpd}', '${ms1}', 'not_started', 'on_track', 'Started', null);

  -- Hub
  insert into hub_section values ('kb', '${u(7)}', '2027-01-01', null);
  insert into hub_article (id, category, title, body, owner_id) values ('${art}', 'template', 'Project update', 'Use this', '${u(7)}');
  insert into hub_suggestion (article_id, by, text) values ('${art}', '${u(8)}', 'Add an example');
  insert into facility (name, status, owner_id, training) values ('Workstations', 'available', '${u(7)}', 'none');
  insert into announcement (title, by) values ('News', '${u(7)}');
`);

const codes = (await db.query(`select code from application order by code`)).rows.map((r) => r.code);
check('application codes count up per project prefix', codes.join() === 'SK01-001,SK01-002', codes.join());

async function as(who, sql) {
  const account = who === 'anon' ? '' : acct(P[who]);
  await db.exec(`reset role; select set_config('request.jwt.claim.sub', '${account}', false); set role ${who === 'anon' ? 'anon' : 'authenticated'};`);
  try { return (await db.query(sql)).rows; } finally { await db.exec('reset role'); }
}
async function refused(name, fn, pattern) {
  try { await fn(); check(name, false, 'was allowed'); }
  catch (e) { check(name, pattern.test(e.message), e.message); }
  finally { await db.exec('reset role'); }
}
async function allowed(name, fn) {
  try { await fn(); check(name, true); } catch (e) { check(name, false, e.message); }
}
const col = (rows, c) => rows.map((r) => r[c]).sort().join(', ');

// The public
check('anon sees published positions only', col(await as('anon', 'select title from position'), 'title') === 'RA');
check('anon sees the capability map', (await as('anon', 'select * from capability')).length === 2);
check('anon sees no applications, people or files', (await as('anon', 'select 1 from application union all select 1 from person union all select 1 from file')).length === 0);

// Candidates
check('candidate A sees only their own application', col(await as('candA', 'select code from application'), 'code') === 'SK01-001');
check('candidate A sees only themselves among people', col(await as('candA', 'select name from person'), 'name') === 'Candidate A');
check('candidate A sees their consent but not their screening', (await as('candA', 'select 1 from consent')).length === 1 && (await as('candA', 'select 1 from screening')).length === 0);
check('candidate B sees their topic proposal but no scorecards or panel', (await as('candB', 'select 1 from submission')).length === 1
  && (await as('candB', 'select 1 from scorecard union all select 1 from panel_member')).length === 0);
const myHistory = await as('candB', 'select * from my_status_event');
check('a candidate reads their statuses and dates, never the notes, who moved them or the Gate 3 review',
  (await as('candB', 'select 1 from status_event union all select 1 from gate3_review')).length === 0
  && col(myHistory, 'to_status') === 'shortlisted' && Object.keys(myHistory[0] ?? {}).sort().join() === 'application_id,at,from_status,to_status'
  && col(await as('candA', 'select to_status from my_status_event'), 'to_status') === 'submitted'
  && (await as('anon', 'select 1 from my_status_event').catch(() => 'denied')) === 'denied', JSON.stringify(myHistory));

// Staff
const supPeople = col(await as('sup', 'select name from person'), 'name');
check('blind screening: staff see Candidate B (past Gate 1) but not Candidate A', supPeople === 'Candidate B, Lab PI, Lab admin, Panel, RA One, RA Two, Staff without role, Supervisor', supPeople);
check('staff see both applications by code', (await as('sup', 'select 1 from application')).length === 2);
check('IVW-4: a panel member sees only their own scorecard until all are in', col(await as('sup', 'select person_id from scorecard'), 'person_id') === u(2));
check('IVW-4: a member with a draft sees only their draft', col(await as('panel', 'select person_id from scorecard'), 'person_id') === u(3));
await db.exec(`update scorecard set submitted_at = now() where person_id = '${u(3)}'`);
check('IVW-4: all scorecards show once the panel has submitted', (await as('sup', 'select 1 from scorecard')).length === 2);
check('staff without a role see only the public adverts and themselves',
  (await as('norole', 'select 1 from application')).length === 0 && col(await as('norole', 'select name from person'), 'name') === 'Staff without role'
  && col(await as('norole', 'select title from position'), 'title') === 'RA');
check('the PI reads the whole audit log, the lab admin all but level changes, other staff none',
  (await as('pi', 'select 1 from audit_event')).length === 2 && col(await as('admin', 'select action from audit_event'), 'action') === 'gate1.decide'
  && (await as('sup', 'select 1 from audit_event')).length === 0);
check('staff read the notes on status moves and the Gate 3 review', (await as('sup', 'select 1 from status_event where note is not null')).length === 1
  && (await as('pi', 'select 1 from gate3_review')).length === 1);
check('staff see drafts', col(await as('sup', 'select title from position'), 'title') === 'Draft, RA');

// RA profiles (decision 1): levels, targets and reviews for the RA, their supervisor and the PI; achievements also for the lab admin
const seen = async (who, table) => (await as(who, `select person_id from ${table}`)).map((r) => r.person_id).sort().join(',');
const both = [u(8), u(9)].join(',');
check('an RA sees only their own achievements, levels, targets and reviews',
  (await seen('ra1', 'achievement')) === u(8) && (await seen('ra1', 'level_record')) === u(8) && (await seen('ra1', 'development_target')) === u(8) && (await seen('ra1', 'ra_review')) === u(8));
check('the supervisor sees their own RA\u2019s levels and reviews, not another RA\u2019s',
  (await seen('sup', 'level_record')) === u(8) && (await seen('sup', 'ra_review')) === u(8) && (await seen('sup', 'level_proposal')) === u(8));
check('the lab admin sees every RA\u2019s achievements and placement, but no levels, targets or reviews',
  (await seen('admin', 'achievement')) === both && (await seen('admin', 'ra_record')) === both
  && (await as('admin', 'select 1 from level_record union all select 1 from development_target union all select 1 from ra_review union all select 1 from level_proposal')).length === 0);
check('the PI sees every RA\u2019s levels', (await seen('pi', 'level_record')) === both);
check('baseline levels follow decision 1: the RA, their supervisor and the PI, not the lab admin or a panel member',
  (await seen('ra1', 'person_baseline')) === u(8) && (await seen('sup', 'person_baseline')) === u(8) && (await seen('pi', 'person_baseline')) === both
  && (await as('admin', 'select 1 from person_baseline')).length === 0
  && (await as('panel', 'select 1 from person_baseline')).length === 0);
check('a panel member and staff without a role see no RA profile data',
  (await as('panel', 'select 1 from achievement union all select 1 from level_record union all select 1 from ra_record')).length === 0
  && (await as('norole', 'select 1 from achievement union all select 1 from level_record')).length === 0);
check('achievement capabilities follow the achievement', (await as('admin', 'select 1 from achievement_capability')).length === 1 && (await as('ra2', 'select 1 from achievement_capability')).length === 0);

// Projects (PRD section 8): RAs see the projects they are on; the budget is the PI's; drafts stay with their author and reviewers
const codesOf = async (who) => col(await as(who, 'select code from project'), 'code');
check('an RA sees the projects they are on, the PI and lab manager see all, the public only advertised ones',
  (await codesOf('ra1')) === 'SK01' && (await codesOf('ra2')) === 'CMIT, SK01' && (await codesOf('pi')) === 'CMIT, SK01'
  && (await codesOf('admin')) === 'CMIT, SK01' && (await codesOf('anon')) === 'SK01', `${await codesOf('ra1')} / ${await codesOf('anon')}`);
check('only the PI reads the budget', (await as('pi', 'select 1 from project_budget')).length === 1
  && (await as('admin', 'select 1 from project_budget union all select 1 from project_budget')).length === 0 && (await as('sup', 'select 1 from project_budget')).length === 0);
check('milestones and teams follow the project', (await as('ra1', 'select 1 from milestone')).length === 1 && (await as('norole', 'select 1 from milestone union all select 1 from project_member')).length === 0
  && (await as('anon', 'select 1 from milestone')).length === 0);
const updatesOf = async (who) => col(await as(who, 'select period from project_update'), 'period');
check('a draft update is seen by its author, the PI, the lab manager and the project lead, not the rest of the team',
  (await updatesOf('ra1')) === '2026-10, 2026-11' && (await updatesOf('pi')) === '2026-10, 2026-11' && (await updatesOf('admin')) === '2026-10, 2026-11'
  && (await updatesOf('sup')) === '2026-10, 2026-11' && (await updatesOf('ra2')) === '2026-10', await updatesOf('ra2'));
check('an approved update is seen by the team, and its rows follow it', (await as('ra2', 'select now from update_item')).map((r) => r.now).join() === 'on_track'
  && (await as('panel', 'select 1 from project_update union all select 1 from update_item')).length === 0);

// Hub: for staff and RAs
check('the Hub is for staff and RAs, not candidates or the public', (await as('ra1', 'select 1 from hub_article')).length === 1 && (await as('sup', 'select 1 from facility')).length === 1
  && (await as('candA', 'select 1 from hub_article union all select 1 from facility union all select 1 from announcement')).length === 0
  && (await as('anon', 'select 1 from hub_article')).length === 0);
check('a suggested edit is seen by its author and the lab manager or PI', (await as('ra1', 'select 1 from hub_suggestion')).length === 1
  && (await as('ra2', 'select 1 from hub_suggestion')).length === 0 && (await as('admin', 'select 1 from hub_suggestion')).length === 1);

// No direct writes through the API
await refused('a candidate cannot insert an application', () => as('candA', `insert into application (code, position_id, person_id, status, degree, cv_link, source)
  values ('X-1', '${pos1}', '${u(5)}', 'submitted', 'MSc', 'https://x.y/cv', 'online')`), /permission denied/);
await refused('the PI cannot update a row directly', () => as('pi', `update position set status = 'published' where id = '${pos2}'`), /permission denied/);
await refused('the PI cannot write the audit log directly', () => as('pi', `insert into audit_event (by, action, summary) values ('${u(1)}', 'x', 'y')`), /permission denied/);
await refused('the API cannot take application codes', () => as('anon', `select next_application_code('SK01')`), /permission denied/);
await refused('the API cannot call helpers the read rules do not use', () => as('candA', `select ra_supervisor('${u(8)}')`), /permission denied/);
await refused('the API cannot purge records', () => as('pi', `select purge_application('${appA}')`), /permission denied/);

// Closed by default, although Supabase opens new objects in public to the API roles
await db.exec(`create table later_table (id int); insert into later_table values (1); create function later_fn() returns int language sql as 'select 1';`);
await refused('a table added by a later migration is closed to the API', () => as('ra1', 'select * from later_table'), /permission denied/);
await refused('a function added by a later migration cannot be called through the API', () => as('anon', 'select later_fn()'), /permission denied/);

// Files in Storage
const bucket = (await db.query(`select public, file_size_limit from storage.buckets where id = 'applications'`)).rows[0];
check('the file bucket is private, 10 MB a file', bucket?.public === false && Number(bucket?.file_size_limit) === 10485760, JSON.stringify(bucket));
check('a candidate reads only their own files in Storage, staff read them all, the public none',
  col(await as('candA', 'select name from storage.objects'), 'name') === 'a/cv.pdf' && (await as('sup', 'select 1 from storage.objects')).length === 2
  && (await as('anon', 'select 1 from storage.objects')).length === 0);
await refused('nobody uploads to Storage through the API', () => as('candA', `insert into storage.objects (bucket_id, name) values ('applications', 'a/other.pdf')`), /row-level security/);

// Rules the database keeps even for the server functions
await refused('audit events cannot be changed', () => db.exec(`update audit_event set summary = 'edited'`), /cannot be changed or deleted/);
await refused('audit events cannot be deleted', () => db.exec(`delete from audit_event`), /cannot be changed or deleted/);
await refused('roles are for staff only', () => db.exec(`insert into role_assignment values ('${u(5)}', 'panel')`), /staff only/);
await refused('a panel member cannot be deleted once scoring started', () => db.exec(`delete from panel_member where person_id = '${u(3)}'`), /Scoring has started/);
await refused('a submitted scorecard is locked', () => db.exec(`update scorecard set scores = '{}' where person_id = '${u(2)}'`), /locked/);
await refused('one person per email, whatever the case', () => db.exec(`insert into person (name, email, kind) values ('Copy', 'PI@Example.EDU', 'staff')`), /duplicate key/);
await refused('one live consent per purpose', () => db.exec(`insert into consent (application_id, purpose, text_version, given_at) values ('${appA}', 'assessment', 'v1', now())`), /duplicate key/);
await refused('an application needs a CV file or https link', () => db.exec(`insert into application (code, position_id, person_id, status, degree, cv_link, topic_idea, source)
  values ('X-2', '${pos2}', '${u(5)}', 'submitted', 'MSc', 'cv.pdf', 'idea', 'online')`), /check constraint/);
await refused('a proposal is never overwritten', () => db.exec(`update submission set title = 'Edited'`), /send a new version/);
await refused('the offer answer date cannot be before the offer', () => db.exec(`insert into offer (application_id, offered_at, response_due) values ('${appB}', now(), current_date - 1)`), /check constraint/);

await refused('a confirmed level is never changed', () => db.exec(`update level_record set level = 4`), /never changed or deleted/);
await refused('a written review is not changed', () => db.exec(`update ra_review set comment = 'Edited' where id = '${u(401)}'`), /not changed once written/);
await db.exec(`update ra_review set read_at = now(), response = 'Thanks' where id = '${u(401)}'`);
check('the RA may mark a review read once, with a reply', (await db.query(`select response from ra_review where id = '${u(401)}'`)).rows[0].response === 'Thanks');
await refused('a review cannot be changed after it is read', () => db.exec(`update ra_review set response = 'Changed' where id = '${u(401)}'`), /not changed once written/);
await refused('one pending level change per capability', () => db.exec(`insert into level_proposal (person_id, capability, level, evidence, by) values ('${u(8)}', 'write', 4, 'More', '${u(8)}')`), /duplicate key/);
await refused('declining a level change needs a reason', () => db.exec(`update level_proposal set status = 'declined', decided_at = now() where person_id = '${u(8)}'`), /check constraint/);
await refused('planned work cannot be checked', () => db.exec(`insert into achievement (person_id, type, title, date, status, added_by, verified_by, verified_at) values ('${u(8)}', 'journal', 'Plan', '2027-01-01', 'planned', '${u(8)}', '${u(2)}', now())`), /check constraint/);

// Projects and Hub rules the database keeps
await refused('an approved update is never changed', () => db.exec(`update project_update set issues = 'Edited' where id = '${doneUpd}'`), /approved update is not changed/);
await refused('an approved update is never deleted', () => db.exec(`delete from project_update where id = '${doneUpd}'`), /approved update is not changed/);
await refused('the rows of an approved update are never changed', () => db.exec(`update update_item set note = 'Edited' where update_id = '${doneUpd}'`), /approved update is not changed/);
await db.exec(`update update_item set note = 'Slower than planned' where update_id = '${draftUpd}'`);
check('a draft update can still be changed', (await db.query(`select note from update_item where update_id = '${draftUpd}'`)).rows[0].note === 'Slower than planned');
await refused('a milestone’s status changes only through an approval', () => db.exec(`update milestone set status = 'done' where id = '${ms1}'`), /only when an update is approved/);
await db.exec(`update milestone set due = '2026-12-15' where id = '${ms1}'`);
await db.exec(`begin; select set_config('rmsx.approving', 'on', true); update milestone set status = 'at_risk', update_id = '${draftUpd}' where id = '${ms1}'; commit;`);
check('the plan can move a due date, and an approval can change the status', (await db.query(`select status, due::text from milestone where id = '${ms1}'`)).rows[0].status === 'at_risk');
await refused('one update per RA, project and period', () => db.exec(`insert into project_update (project_id, author_id, period) values ('${sk01}', '${u(8)}', '2026-11')`), /duplicate key/);
await refused('a sent update has a sent date', () => db.exec(`insert into project_update (project_id, author_id, period, status) values ('${sk01}', '${u(9)}', '2026-11', 'submitted')`), /check constraint/);
await refused('an approval without the check needs the PI’s reason', () => db.exec(`insert into project_update (project_id, author_id, period, status, submitted_at, approved_by, approved_at) values ('${sk01}', '${u(9)}', '2026-12', 'approved', now(), '${u(1)}', now())`), /check constraint/);
await refused('a routine approval by the lab manager needs the check', () => db.exec(`insert into project_update (project_id, author_id, period, status, submitted_at, approved_by, approved_at, approved_unchecked, approved_routine) values ('${sk01}', '${u(9)}', '2026-12', 'approved', now(), '${u(7)}', now(), 'Away', true)`), /check constraint/);
await refused('only a checked update is sent on to the PI', () => db.exec(`insert into project_update (project_id, author_id, period, status, submitted_at, to_pi) values ('${sk01}', '${u(9)}', '2026-12', 'submitted', now(), true)`), /check constraint/);

check('an RA sees the lab’s staff and RAs, but no candidates', (await as('ra1', `select 1 from person where kind = 'candidate'`)).length === 0
  && (await as('ra1', `select 1 from person where kind in ('staff', 'ra')`)).length > 1);

// Agentic AI prerequisites (AIP-*): conflicts, events, versions, project links, Hub access and bookings
await db.exec(`insert into conflict_of_interest (application_id, person_id, note) values ('${appA}', '${u(2)}', 'Former student')`);
check('a conflicted supervisor no longer reads the application, its screening, consent or history (AIP-R7)',
  (await as('sup', `select 1 from application where id = '${appA}' union all select 1 from screening where application_id = '${appA}'
    union all select 1 from consent where application_id = '${appA}' union all select 1 from status_event where application_id = '${appA}'`)).length === 0);
check('the rest of the staff still read it, and the supervisor reads the others',
  (await as('admin', `select 1 from application where id = '${appA}'`)).length === 1 && (await as('sup', `select 1 from application where id = '${appB}'`)).length === 1);
check('a conflict is read by the person who declared it, the PI and the lab manager',
  (await as('sup', 'select 1 from conflict_of_interest')).length === 1 && (await as('pi', 'select 1 from conflict_of_interest')).length === 1
  && (await as('panel', 'select 1 from conflict_of_interest')).length === 0);
await refused('a panel member marked as conflicted has a removal on record', () => db.exec(`update panel_member set conflict = true where application_id = '${appB}' and person_id = '${u(3)}'`), /check constraint/);

await db.exec(`insert into event (module, kind, by, application_id, key) values ('recruitment', 'gate1.decided', '${u(1)}', '${appA}', 'shortlisted'), ('recruitment', 'gate1.decided', '${u(1)}', '${appB}', 'shortlisted');
  insert into event (module, kind, project_id, person_id, key) values ('projects', 'update.overdue', '${sk01}', '${u(8)}', '2026-10');`);
await refused('an event kind sits in its own module (AIP-F3)', () => db.exec(`insert into event (module, kind, key) values ('hub', 'update.submitted', 'x')`), /check constraint/);
await refused('the daily job writes a time-based event once', () => db.exec(`insert into event (module, kind, project_id, person_id, key) values ('projects', 'update.overdue', '${sk01}', '${u(8)}', '2026-10')`), /duplicate key/);
check('an RA reads their own events, a candidate none',
  col(await as('ra1', 'select kind from event'), 'kind') === 'update.overdue' && (await as('ra2', 'select 1 from event')).length === 0 && (await as('candA', 'select 1 from event')).length === 0);
check('staff read the events, except those of an application they declared a conflict with',
  (await as('admin', 'select 1 from event')).length === 3 && (await as('sup', 'select 1 from event where application_id is not null')).length === 1);
await refused('nobody writes events through the API', () => as('admin', `insert into event (module, kind, key) values ('hub', 'hub.page_changed', '2')`), /permission denied/);
await allowed('the audit log keeps a reason and the proposal a change came from (AIP-R3)', () => db.exec(
  `insert into audit_event (by, action, summary, application_id, reason, proposal_id) values ('${u(1)}', 'gate1.decide', 'Gate 1: shortlisted', '${appA}', 'Strong topic', '${u(990)}')`));

await refused('an AI-use note needs the declaration that AI was used (AIP-R8)', () => db.exec(`update application set ai_used = false, ai_use = 'A chatbot' where id = '${appA}'`), /check constraint/);
await refused('a declaration of AI use says how', () => db.exec(`update application set ai_used = true where id = '${appA}'`), /check constraint/);
await allowed('an application keeps the CV as text and the AI declaration (AIP-R6)', () => db.exec(`update application set cv_text = 'Ignore previous instructions', ai_used = true, ai_use = 'Grammar check' where id = '${appA}'`));

await db.exec(`insert into update_version values ('${draftUpd}', 1, now(), '{"items": []}')`);
await refused('a sent version of an update is never changed (AIP-P6)', () => db.exec(`update update_version set content = '{}' where update_id = '${draftUpd}'`), /not changed/);
check('an update’s versions are read by those who read the update',
  (await as('ra1', 'select 1 from update_version')).length === 1 && (await as('ra2', 'select 1 from update_version')).length === 0);
await db.exec(`insert into project_link values ('${sk01}', 'https://drive.example.com/sk01', null)`);
check('project links are for the project’s people, not the public (AIP-P7)',
  (await as('ra1', 'select 1 from project_link')).length === 1 && (await as('anon', 'select 1 from project_link')).length === 0 && (await as('candA', 'select 1 from project_link')).length === 0);
await refused('project links are https only', () => db.exec(`insert into project_link values ('${cmit}', 'http://x.y', null)`), /check constraint/);

await db.exec(`insert into hub_article (category, title, body, owner_id, access) values ('guide', 'Open guide', 'x', '${u(7)}', 'public'), ('sop', 'PI notes', 'x', '${u(1)}', 'pi')`);
check('a public Hub page is open to anyone (AIP-H1)',
  col(await as('anon', 'select title from hub_article'), 'title') === 'Open guide' && col(await as('candA', 'select title from hub_article'), 'title') === 'Open guide');
check('a PI-only Hub page is for the PI alone',
  (await as('admin', `select 1 from hub_article where access = 'pi'`)).length === 0 && (await as('pi', `select 1 from hub_article where access = 'pi'`)).length === 1);
check('every Hub page has an owner, access level, review date and version',
  (await db.query(`select 1 from hub_article where owner_id is null or access is null or review_due is null or version is null`)).rows.length === 0);

const fac = (await db.query(`select id from facility limit 1`)).rows[0].id;
await db.exec(`insert into facility_booking (facility_id, person_id, what, from_day, to_day) values ('${fac}', '${u(8)}', 'CFD runs', '2026-12-01', '2026-12-03')`);
await refused('a facility is never booked twice on one day (AIP-H3)', () => db.exec(`insert into facility_booking (facility_id, person_id, what, from_day, to_day) values ('${fac}', '${u(9)}', 'Tests', '2026-12-03', '2026-12-04')`), /already booked/);
await allowed('a cancelled booking frees its days', () => db.exec(`update facility_booking set status = 'cancelled', cancelled_by = '${u(7)}', cancelled_at = now() where person_id = '${u(8)}';
  insert into facility_booking (facility_id, person_id, what, from_day, to_day) values ('${fac}', '${u(9)}', 'Tests', '2026-12-03', '2026-12-04')`));
await refused('a booking is 30 days at most', () => db.exec(`insert into facility_booking (facility_id, person_id, what, from_day, to_day) values ('${fac}', '${u(9)}', 'Long', '2027-01-01', '2027-03-01')`), /check constraint/);
check('bookings are read by the lab, not by candidates', (await as('ra1', 'select 1 from facility_booking')).length === 2 && (await as('candA', 'select 1 from facility_booking')).length === 0);
await refused('nobody books through the API directly: bookings go through the server action', () => as('ra1', `insert into facility_booking (facility_id, person_id, what, from_day, to_day) values ('${fac}', '${u(8)}', 'Runs', '2027-02-01', '2027-02-02')`), /permission denied/);
await refused('a project code is short and unique', () => db.exec(`insert into project (code, title, funder, start_date, end_date) values ('sk 1', 'X', 'CEI', '2026-01-01', '2027-01-01')`), /check constraint/);
await refused('a project joins the update loop with a rhythm', () => db.exec(`insert into project (code, title, funder, start_date, end_date, updates_from) values ('SK09', 'X', 'CEI', '2026-01-01', '2027-01-01', '2026-02-01')`), /check constraint/);
await refused('a team share is 1 to 100 percent', () => db.exec(`insert into project_member (project_id, person_id, role, allocation, start_date) values ('${cmit}', '${u(8)}', 'ra', 120, '2026-01-01')`), /check constraint/);
await refused('only papers have an author role', () => db.exec(`insert into achievement (person_id, type, title, date, status, added_by, author_role) values ('${u(8)}', 'talk', 'Talk', '2026-10-01', 'done', '${u(8)}', 'main')`), /check constraint/);
await refused('a facility in use says until when', () => db.exec(`insert into facility (name, status, owner_id, training) values ('Rig', 'in_use', '${u(7)}', 'required')`), /check constraint/);
await refused('a declined suggestion needs a reply', () => db.exec(`update hub_suggestion set status = 'declined', decided_by = '${u(7)}', decided_at = now()`), /check constraint/);
await refused('the API cannot write projects or updates directly', () => as('pi', `update milestone set title = 'X'`), /permission denied/);

// The status flow and the offer rules, kept even for the server functions
await allowed('a status moves along the flow', () => db.exec(`update application set status = 'interviewed' where id = '${appB}'`));
await refused('a status never moves against the flow', () => db.exec(`update application set status = 'shortlisted' where id = '${appB}'`), /Cannot move an application from interviewed to shortlisted/);
await refused('a status never skips the gates', () => db.exec(`update application set status = 'active' where id = '${appA}'`), /Cannot move an application from submitted to active/);
await db.exec(`insert into person (id, name, email, kind) values ('${u(10)}', 'Candidate C', 'c@example.com', 'candidate'), ('${u(11)}', 'Candidate D', 'd@example.com', 'candidate');
  insert into application (id, code, position_id, person_id, status, degree, cv_link, topic_idea, source, reserve_rank)
    values ('${u(103)}', 'SK01-050', '${pos1}', '${u(10)}', 'offer_made', 'MSc', 'https://x.y/cv', 'idea', 'online', 1);`);
await refused('one open offer per position', () => db.exec(`insert into application (code, position_id, person_id, status, degree, cv_link, topic_idea, source)
  values ('SK01-051', '${pos1}', '${u(11)}', 'contracting', 'MSc', 'https://x.y/cv', 'idea', 'online')`), /duplicate key/);
await refused('one candidate per place in the reserve list', () => db.exec(`update application set reserve_rank = 1 where id = '${appB}'`), /duplicate key/);

// People, codes and data retention
await allowed('RAs from before RMS-X may have no email', () => db.exec(`insert into person (name, kind) values ('RA without email', 'ra'), ('Another RA without email', 'ra')`));
await refused('a candidate or staff member needs an email', () => db.exec(`insert into person (name, kind) values ('No email', 'candidate')`), /check constraint/);
await refused('an email must look like one', () => db.exec(`insert into person (name, email, kind) values ('Bad', 'not-an-email', 'staff')`), /check constraint/);
await db.exec(`update application_code_counter set last = 998 where prefix = 'SK01'`);
const nextCode = async (prefix) => (await db.query(`select next_application_code('${prefix}') as c`)).rows[0].c;
const past999 = [await nextCode('SK01'), await nextCode('SK01')].join();
check('codes go past 999 without losing a digit', past999 === 'SK01-999,SK01-1000', past999);
await db.exec(`insert into application (code, position_id, person_id, status, degree, cv_link, topic_idea, source) values ('CMIT-007', '${pos2}', '${u(11)}', 'submitted', 'MSc', 'https://x.y/cv', 'idea', 'file');
  select catch_up_application_codes();`);
const afterImport = [await nextCode('CMIT'), await nextCode('SK01')].join();
check('after an import, new codes follow on from the highest in use', afterImport === 'CMIT-008,SK01-1001', afterImport);
await refused('a kept proposal still refuses a plain delete', () => db.exec(`delete from submission where application_id = '${appB}'`), /send a new version/);
const purged = (await db.query(`select purge_application('${appB}') as path`)).rows.map((r) => r.path).join();
const left = (await db.query(`select 'application' as t from application where id = '${appB}' union all select 'submission' from submission where application_id = '${appB}'
  union all select 'scorecard' from scorecard where application_id = '${appB}' union all select 'panel' from panel_member where application_id = '${appB}'
  union all select 'status' from status_event where application_id = '${appB}' union all select 'file' from file where id = '${u(902)}'
  union all select 'person' from person where id = '${u(6)}'`)).rows.map((r) => r.t).join();
check('purging removes an application with its scorecards, proposals, history and files, and the candidate, and returns the paths to delete',
  purged === 'b/cv.pdf' && left === '', `${purged} / left: ${left}`);
check('the audit log outlives a purge', (await db.query(`select 1 from audit_event where application_id = '${appB}'`)).rows.length === 1);
await db.exec(`insert into application (id, code, position_id, person_id, status, degree, cv_link, topic_idea, source) values ('${u(104)}', 'SK01-060', '${pos1}', '${u(11)}', 'active', 'MSc', 'https://x.y/cv', 'idea', 'online')`);
await refused('an RA’s hiring application is never purged', () => db.query(`select purge_application('${u(104)}')`), /hiring application is kept/);

for (const r of results) console.log(`${r.ok ? 'PASS' : 'FAIL'}  ${r.name}${r.ok ? '' : '  -> ' + r.detail}`);
console.log(`\n${results.filter((r) => r.ok).length} of ${results.length} checks passed`);
process.exit(results.every((r) => r.ok) ? 0 : 1);
