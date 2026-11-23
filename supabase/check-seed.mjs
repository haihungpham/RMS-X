// Checks supabase/seed.sql without a Supabase project: applies schema.sql and then seed.sql to Postgres (PGlite) with a
// stub auth schema, as check-schema.mjs does, and counts what the seed added.
//   npm install --no-save @electric-sql/pglite@0.2.17
//   node supabase/check-seed.mjs
import { PGlite } from '@electric-sql/pglite';
import { citext } from '@electric-sql/pglite/contrib/citext';
import { readFileSync } from 'node:fs';

const db = new PGlite({ extensions: { citext } });
await db.exec(`
  create role anon nologin; create role authenticated nologin;
  create schema auth;
  create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
  create schema storage;
  create table storage.buckets (id text primary key, name text not null, public boolean not null default false, file_size_limit bigint, allowed_mime_types text[]);
  create table storage.objects (id uuid primary key default gen_random_uuid(), bucket_id text references storage.buckets, name text not null, owner uuid);
  alter table storage.objects enable row level security;
`);
await db.exec(readFileSync(new URL('./schema.sql', import.meta.url), 'utf8'));
await db.exec(readFileSync(new URL('./seed.sql', import.meta.url), 'utf8'));

const count = async (sql) => (await db.query(sql)).rows[0].n;
const rows = {
  'staff': `select count(*)::int n from person where kind = 'staff'`,
  'RAs': `select count(*)::int n from person where kind = 'ra'`,
  'roles': `select count(*)::int n from role_assignment`,
  'projects': `select count(*)::int n from project`,
  'work packages': `select count(*)::int n from work_package`,
  'milestones': `select count(*)::int n from milestone`,
  'milestones without a work package': `select count(*)::int n from milestone where wp_id is null`,
  'team places': `select count(*)::int n from project_member`,
  'RAs over 100%': `select count(*)::int n from (select person_id from project_member group by 1 having sum(allocation) > 100) x`,
  'RAs without a project': `select count(*)::int n from person p where kind = 'ra' and not exists (select 1 from project_member m where m.person_id = p.id)`,
  'facilities': `select count(*)::int n from facility`,
  'announcements': `select count(*)::int n from announcement`,
};
for (const [label, sql] of Object.entries(rows)) console.log(`${label}: ${await count(sql)}`);
console.log('seed applies');
