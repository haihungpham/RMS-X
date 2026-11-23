-- RMS-X seed: the lab's real people and projects, for a Supabase project that has supabase/schema.sql applied.
-- Sources: i-e3s-lab.com (team and project pages, read 2026-11-08; summary in docs/i-e3s-lab-site.md) and the
-- Sep and Oct 2026 DEPI lab performance progress reports.
--
-- Run it once, after schema.sql, as the database owner (SQL Editor or psql). It runs in one transaction.
-- Check it locally: node supabase/check-seed.mjs
--
-- Not in this file, on purpose:
-- * Publications. The site lists another group's sample papers, and the reports give counts, not titles. Add the
--   lab's real papers as achievements once their titles, venues and authors are listed.
-- * The site's courses, seminar speakers, positions and stub news. They are placeholders.
-- * People named only in the reports, with no email: Nguyen Phi Long, Do Danh Cuong, Dr. Trang, Dr. Trung,
--   Dr. Truong (HUST-CLCS), Prof. Akhil, Le Kieu Hiep (HUST-IET).
-- * Suk Hyun Lim (KIER): his profile shows Simon Park's email, so his real one is needed first.
-- * Accounts. person.account_id stays empty; Google sign-in links each person by their verified email.
--
-- Lines marked TODO are best guesses to confirm: project dates, allocations, supervisors and roles.

begin;

/* ---------- people ---------- */
-- Ids: 1… lab staff, 2… RAs, 3… collaborators.
insert into person (id, name, email, kind) values
  ('00000000-0000-0000-0001-000000000001', 'Pham Hai Hung',        'hung.ph@vinuni.edu.vn',    'staff'),  -- Executive PI
  ('00000000-0000-0000-0001-000000000002', 'Ahmad Hajjar',         'ahmad.h@vinuni.edu.vn',    'staff'),  -- Scientific PI
  ('00000000-0000-0000-0001-000000000003', 'Nguyen Thi Minh Chau', '24chau.ntm@vinuni.edu.vn', 'staff'),  -- lab manager, since Apr 2026
  -- Collaborators. Staff without a role read only the public adverts, so they get a role only when they take part.
  ('00000000-0000-0000-0003-000000000001', 'Le Duy Dung',          'dung.ld@vinuni.edu.vn',      'staff'),  -- CECS, VinUni; PI of V-IndoorCARE
  ('00000000-0000-0000-0003-000000000002', 'Simon Park',           'simon.p@vinuni.edu.vn',      'staff'),  -- VinUni; SK01
  ('00000000-0000-0000-0003-000000000003', 'Minh Bau Luong',       'bau.luongminh@hust.edu.vn',  'staff'),  -- HUST; CMIT
  ('00000000-0000-0000-0003-000000000004', 'Son Ich Ngo',          'ngoichson@hknu.ac.kr',       'staff'),  -- Hankyong National University; CMIT
  ('00000000-0000-0000-0003-000000000005', 'Le Quang Thai',        'thaile.gt@gmail.com',        'staff'),  -- industry
  ('00000000-0000-0000-0003-000000000006', 'Le Anh Tuan',          'leanhtuan10212@gmail.com',   'staff'),  -- Siemens DI SW; CMIT
  ('00000000-0000-0000-0003-000000000007', 'Vu Toan Thang',        'thangvt@viettel.com.vn',     'staff'),  -- Viettel Semiconductor
  ('00000000-0000-0000-0003-000000000008', 'Tran Van Bay',         'bay.tv@vinuni.edu.vn',       'staff');  -- CFDWAYS

-- RAs, with the supervisor taken from the project they are tagged with on the site. TODO: confirm supervisors.
insert into person (id, name, email, kind, supervisor_id) values
  ('00000000-0000-0000-0002-000000000001', 'Vu Van Hieu',           'hieu.vv@vinuni.edu.vn',    'ra', '00000000-0000-0000-0001-000000000002'),
  ('00000000-0000-0000-0002-000000000002', 'Nguyen Dinh Phong',     '23phong.nd@vinuni.edu.vn', 'ra', '00000000-0000-0000-0001-000000000001'),
  ('00000000-0000-0000-0002-000000000003', 'Vu Nguyen Hoang Anh',   'anh.vnh@vinuni.edu.vn',    'ra', '00000000-0000-0000-0001-000000000001'),
  ('00000000-0000-0000-0002-000000000004', 'Ngo Ngoc Quy',          'quy.nn@vinuni.edu.vn',     'ra', '00000000-0000-0000-0001-000000000002'),
  ('00000000-0000-0000-0002-000000000005', 'Nguyen Tran Nhat Minh', '24minh.ntn@vinuni.edu.vn', 'ra', '00000000-0000-0000-0001-000000000001'),
  ('00000000-0000-0000-0002-000000000006', 'Vo Duy Thanh',          'thanh.vd@vinuni.edu.vn',   'ra', '00000000-0000-0000-0001-000000000001'),
  ('00000000-0000-0000-0002-000000000007', 'Pham Trung Hieu',       'hieu.pt3@vinuni.edu.vn',   'ra', '00000000-0000-0000-0001-000000000002');

-- TODO: the app has one PI; Pham Hai Hung takes it here. Ahmad Hajjar (Scientific PI) supervises and sits on panels.
insert into role_assignment values
  ('00000000-0000-0000-0001-000000000001', 'pi'),
  ('00000000-0000-0000-0001-000000000001', 'supervisor'),
  ('00000000-0000-0000-0001-000000000001', 'panel'),
  ('00000000-0000-0000-0001-000000000002', 'supervisor'),
  ('00000000-0000-0000-0001-000000000002', 'panel'),
  ('00000000-0000-0000-0001-000000000003', 'admin'),
  ('00000000-0000-0000-0003-000000000001', 'supervisor');

-- Start dates are the "since" month on the site; undergraduate RAs are marked in the comment.
insert into ra_record (person_id, start_date) values
  ('00000000-0000-0000-0002-000000000001', '2025-12-01'),
  ('00000000-0000-0000-0002-000000000002', '2025-12-01'),  -- undergraduate RA
  ('00000000-0000-0000-0002-000000000003', '2026-04-01'),
  ('00000000-0000-0000-0002-000000000004', '2026-05-01'),
  ('00000000-0000-0000-0002-000000000005', '2026-05-01'),  -- undergraduate RA
  ('00000000-0000-0000-0002-000000000006', '2026-05-01'),
  ('00000000-0000-0000-0002-000000000007', '2026-05-01');  -- undergraduate RA

/* ---------- projects ---------- */
-- Codes match the app's demo projects, plus TENG, which is only on the site. TODO: confirm every start and end date.
insert into project (id, code, title, goal, funder, pi_id, start_date, end_date, about) values
  ('00000000-0000-0000-0004-000000000001', 'SK01', 'Integrated Optimization of BESS–Server Thermal Management',
   'AI and forecast-driven thermal and energy management that coordinates battery storage and server cooling, validated by experiments and CFD on a lab-scale digital twin. Joint SK Innovation–VinUniversity project.',
   'SK Innovation', '00000000-0000-0000-0001-000000000002', '2026-01-01', '2028-12-31',  -- 36 months
   '{"summary": "CFD and system models of battery and server cooling, turned into AI thermal prediction, sizing and scheduling, and a lab-scale digital twin.", "focus": ["Thermal management", "Server cooling", "BESS", "Digital twin", "Forecasting"], "facilities": "Lab-scale 2 kW system, testbed with cooling, Siemens simulation software"}'),
  ('00000000-0000-0000-0004-000000000002', 'SK02', 'AI-Based Forecasting and Optimal Scheduling of a VPP towards Industrial Load',
   'Forecast industrial load and generation for a virtual power plant and schedule its storage, on the lab''s digital-twin platform.',
   'CEI', null, '2026-01-01', '2027-12-31', null),  -- TODO: lead is Nguyen Phi Long (not yet in person); funder to confirm
  ('00000000-0000-0000-0004-000000000003', 'CMIT', 'Hybrid Physics–AI Digital Twin for BESS in EV Charging Stations',
   'A hybrid physics–AI digital twin for battery storage at EV charging stations under tropical conditions: electrochemical ageing, CFD-derived thermal prediction, SoH/RUL estimation and early anomaly warning on a cloud-edge platform.',
   'CMIT', '00000000-0000-0000-0001-000000000001', '2025-07-01', '2026-12-31',  -- 18 months from 2025
   '{"summary": "Electrochemical ageing, CFD-derived thermal prediction and AI diagnostics combined in one digital twin of battery storage at EV charging stations.", "focus": ["Battery systems", "Digital twin", "Physics-AI", "PINN", "Thermal safety"], "facilities": "SiL / HiL setup, BESS, BMS and battery setup"}'),
  ('00000000-0000-0000-0004-000000000004', 'VIC', 'V-IndoorCARE: AI-enabled HVAC Control for Greener, Healthier Indoor Facilities',
   'Healthier indoor air at lower HVAC energy: LiDAR 3D models of rooms, CFD/PINN airflow models, an indoor air quality sensor network and reinforcement-learning HVAC control, validated in real rooms.',
   'VinIF', '00000000-0000-0000-0003-000000000001', '2024-09-01', '2026-12-31',  -- TODO: the site calls it V-IndoorSMART, funded by CEI ENVISION
   '{"summary": "Virtual sensing that rebuilds full indoor fields of CO2, temperature and airflow from a few low-cost sensors, for ventilation control.", "focus": ["Indoor air quality", "HVAC", "Virtual sensing", "Reinforcement learning", "LiDAR"], "facilities": "IAQ sensor network, test rooms"}'),
  ('00000000-0000-0000-0004-000000000005', 'AQ', 'Smart Low-Cost Air Quality Monitoring System for Hanoi',
   'A low-cost, calibrated air quality monitor, designed with the lab''s device optimisation framework and field-tested in Hanoi.',
   'CEI', null, '2025-01-01', '2026-12-31', null),
  ('00000000-0000-0000-0004-000000000006', 'EVC', 'EV Charging with Green Infrastructure: BESS–PV–EVCS',
   'Forecasting and control for a charging hub that combines the grid, rooftop PV, battery storage and EV chargers, with VinFast.',
   'CEI', null, '2026-01-01', '2027-12-31', null),  -- TODO: leads are Do Danh Cuong and Nguyen Phi Long
  ('00000000-0000-0000-0004-000000000007', 'H2', 'Hydrogen: PEM Fuel Cell Research with HUST-CLCS',
   'PEM fuel cell topics with HUST-CLCS: flow channel optimisation, digital twins for health monitoring, and net-zero process integration.',
   'HUST-CLCS', null, '2026-01-01', '2027-12-31', null),
  ('00000000-0000-0000-0004-000000000008', 'TENG', 'High-Performance Triboelectric Nanogenerator from Recycled Materials',
   'A GO/PDMS triboelectric nanogenerator using graphene oxide from graphite recovered from spent batteries, harvesting walking, tapping and jumping motion to power LEDs and small electronics.',
   'CEI ENVISION', '00000000-0000-0000-0001-000000000002', '2024-09-01', '2026-12-31',
   '{"summary": "Energy harvesting from body motion with a nanogenerator made from recycled battery graphite.", "focus": ["Triboelectric nanogenerator", "Recycled materials", "Energy harvesting"], "facilities": ""}');

-- Work packages, as in the app's demo projects.
insert into work_package (project_id, code, title)
select p.id, w.code, w.title from (values
  ('SK01', 'WP1', 'Thermal modeling'), ('SK01', 'WP2', 'Lab-scale validation'), ('SK01', 'WP3', 'Optimization and control'), ('SK01', 'WP4', 'Reporting and steering'),
  ('SK02', 'WP1', 'Data and forecasting'), ('SK02', 'WP2', 'Scheduling'), ('SK02', 'WP3', 'Pilot and reporting'),
  ('CMIT', 'WP1', 'Twin models'), ('CMIT', 'WP2', 'Control and validation'), ('CMIT', 'WP3', 'Field trial and reporting'),
  ('VIC', 'WP1', 'Sensing and data'), ('VIC', 'WP2', 'Models and virtual sensors'), ('VIC', 'WP3', 'Control and scale-up'),
  ('AQ', 'WP1', 'Device design'), ('AQ', 'WP2', 'Field test and calibration'),
  ('EVC', 'WP1', 'Forecasting'), ('EVC', 'WP2', 'Sizing and control'), ('EVC', 'WP3', 'Pilot and reporting'),
  ('H2', 'WP1', 'Models'), ('H2', 'WP2', 'Test cells and experiments'), ('H2', 'WP3', 'Reporting')
) as w(project, code, title) join project p on p.code = w.project;

-- The deliverables on the site, as milestones not yet started. TODO: give each its real due date and owner; the
-- project end date stands in for now. Statuses change only through approved updates.
insert into milestone (project_id, wp_id, code, title, due)
select p.id, wp.id, m.code, m.title, p.end_date from (values
  ('SK01', 'WP1', 'D1', 'Validated AI thermal and cooling prediction models'),
  ('SK01', 'WP3', 'D2', 'Integrated sizing and scheduling method'),
  ('SK01', 'WP2', 'D3', 'Lab-scale digital twin prototype'),
  ('SK01', 'WP2', 'D4', 'Testbed design package: sensors, data architecture, bill of materials'),
  ('SK01', 'WP4', 'D5', 'Year-1 report and Year-2 roadmap'),
  ('CMIT', 'WP1', 'D1', 'Thermal prediction and safety model'),
  ('CMIT', 'WP1', 'D2', 'SoH/RUL engine'),
  ('CMIT', 'WP1', 'D3', 'BESS ontology and telemetry schema'),
  ('CMIT', 'WP2', 'D4', 'Digital twin prototype'),
  ('CMIT', 'WP3', 'D5', 'Technical report and publication'),
  ('VIC', 'WP1', 'D1', 'Sensing and data infrastructure'),
  ('VIC', 'WP2', 'D2', '3D indoor modeling workflow'),
  ('VIC', 'WP2', 'D3', 'CFD/PINN airflow model'),
  ('VIC', 'WP3', 'D4', 'AI HVAC control system'),
  ('VIC', 'WP3', 'D5', 'Validation report')
) as m(project, wp, code, title)
join project p on p.code = m.project
left join work_package wp on wp.project_id = p.id and wp.code = m.wp;

-- Teams from the site's project tags. TODO: confirm allocations (100% for one project, split evenly for two).
insert into project_member (project_id, person_id, role, allocation, start_date)
select p.id, t.person::uuid, 'ra', t.allocation, t.start::date from (values
  ('SK01', '00000000-0000-0000-0002-000000000001', 50,  '2026-01-01'),  -- Vu Van Hieu
  ('VIC',  '00000000-0000-0000-0002-000000000001', 50,  '2025-12-01'),
  ('SK01', '00000000-0000-0000-0002-000000000004', 100, '2026-05-01'),  -- Ngo Ngoc Quy
  ('CMIT', '00000000-0000-0000-0002-000000000002', 100, '2025-12-01'),  -- Nguyen Dinh Phong
  ('CMIT', '00000000-0000-0000-0002-000000000003', 100, '2026-04-01'),  -- Vu Nguyen Hoang Anh
  ('CMIT', '00000000-0000-0000-0002-000000000005', 50,  '2026-05-01'),  -- Nguyen Tran Nhat Minh
  ('VIC',  '00000000-0000-0000-0002-000000000005', 50,  '2026-05-01'),
  ('CMIT', '00000000-0000-0000-0002-000000000006', 100, '2026-05-01')   -- Vo Duy Thanh
) as t(project, person, allocation, start) join project p on p.code = t.project;

/* ---------- targets, facilities and news from the reports ---------- */

-- Oct 2026 report: 6 main-author and 3 co-author papers by the end of 2026. TODO: invention disclosure target.
insert into output_target values (2026, 6, 3, 0);

-- Funded by SK01. Assembly slipped from before 20 Oct to November 2026.
insert into facility (id, name, description, status, status_note, status_until, location, owner_id, training) values
  ('00000000-0000-0000-0005-000000000001', 'Lab-scale 2 kW BESS–server cooling system',
   'Lab-scale system for SiL/HiL tests of battery and server cooling, with a testbed, PLC-SCADA and solar–wind–BESS integration.',
   'maintenance', 'Being assembled; ready in November 2026.', '2026-11-30', 'DEPI Lab, VinUni',
   '00000000-0000-0000-0001-000000000002', 'required');
insert into facility_project values ('00000000-0000-0000-0005-000000000001', '00000000-0000-0000-0004-000000000001');

insert into announcement (title, body, by, at, until) values
  ('Visiting researcher: Dr. Lim Seok Hyun (KIER), 18–20 November',
   'Dr. Lim visits from the Korea Institute of Energy Research to work with the lab on upgrading and upcycling.',
   '00000000-0000-0000-0001-000000000001', '2026-11-01', '2026-11-20');

commit;
