# i-e3s-lab.com — content inventory and comparison with DEPI lab reports (Sep/Oct 2026)

Collected 2026-11-08 from https://i-e3s-lab.com/ (every page reachable from the home page, plus the 19 team profile pages linked from `/team`). Text is summarised; short items (names, titles, labels) are quoted as shown on the site. The site is a Next.js app; `/team` renders client-side, so it was read in a browser.

Sources compared:
- `2026.Sep - DEPI lab - Performance progress report.pptx` (6 slides, by Hung Pham)
- `2026.Oct - DEPI lab - Performance progress report.pptx` (5 slides, by Hung Pham)

> **Heads-up:** a lot of the site is still template/placeholder content (publications from another research group, invented course instructors and seminar speakers, a fake phone number, stock news stories). These are flagged with ⚠️ below so nobody copies them into RMS-X as fact.

---

## 1. Site map

| Path | Status | What it is |
|---|---|---|
| `/` | 200 | Home: hero, 3 research areas, 3 flagship projects, partner logos, CTA |
| `/about` | 200 | Mission, strategy, capability matrix, location |
| `/team` | 200 (client-rendered) | PIs, members, collaborators, alumni tabs |
| `/team/<slug>` | 200 ×19 | Individual profiles |
| `/projects` (and `?area=area-1/2/3`) | 200 | Project portfolio (4 projects); the area filter returns the same list in static HTML |
| `/projects/<slug>` | 200 ×4 | Project detail pages |
| `/publications` | 200 | 5 publication entries ⚠️ |
| `/news` | 200 | 6 news items |
| `/news/<slug>` | 200 ×6 | News detail pages |
| `/courses` | 200 | 3 courses + seminar series ⚠️ |
| `/positions` | 200 | 3 openings + internships ⚠️ (deadlines passed) |
| `/get-involved` | 200 | Contact options and Letter-of-Interest form |
| `/portal` | 200 | "IE³S Knowledge Agent" chat UI (local, no external API) |
| `/contact`, `/resources`, `/virtual-lab`, `/seminars` | **404** | Linked from nav/footer but missing |
| `/sitemap.xml`, `/robots.txt` | 404 | — |

Site-wide header/footer (all pages): name "IE³S Lab | Integrated Engineering for Energy & Environmental Systems", tagline "VinUni · Center for Environmental Intelligence", affiliations "VINUNI ▪ CEI ▪ CECS", footer "© 2026 I-E³S Laboratory ▪ VinUni Center for Environmental Intelligence", social links Twitter / Github / LinkedIn (no real URLs). Logo: `/ie3s-logo.svg`.

---

## 2. Home — https://i-e3s-lab.com/

- **Hero:** "Engineering Intelligence." — simulation-driven engineering that bridges *Engineering Fundamentals*, *Multiscale Modeling* and *Physical AI Digital Twins*. Buttons: Join Our Lab, Highlight Projects.
- **Research areas ("Research Pillars"):**
  1. **Materials & Multiphysics** — coupled thermal, fluid, structural and electrochemical modelling across scales. (`/projects?area=area-1`)
  2. **Process & Systems** — scaling component physics up to system-level performance and reliability models. (`?area=area-2`)
  3. **Physical AI Digital Twins** — twins that move from design tools to operational intelligence platforms. (`?area=area-3`)
- **Flagship projects** (cards): Hybrid Physics–AI Digital Twin for BESS; Integrated Optimization of BESS–Server Thermal Management; AI-enabled HVAC Control System (details in §5).
- **Partner logos** (with links): APL (apl.com), DMS Lab (dms-lab.com), KIER (kier.re.kr), Siemens (siemens.com), VinFast (vinfastauto.com), VinUniversity CEI (vinuni.edu.vn). Images: `/Images/Partners/{apl,cei,dms,kier,siemens,vinfast}.png`.
- **CTA:** invites collaboration; claims "10+ industry partners in our active sandbox".

## 3. About — https://i-e3s-lab.com/about

- **Mission:** develop advanced engineering solutions that integrate resilient intelligent systems.
- **Strategy & values:** established **2024** at the VinUni Center for Environmental Intelligence; "Living Engineering Sandbox" philosophy — treat real infrastructure as dynamic systems that are sensed, modelled and optimised in real time.
- **Capability matrix:** (1) High-Fidelity Modeling — digital twins of energy storage with physics-informed ML; (2) Resilient Controls — AI control for microgrids and urban infrastructure; (3) Data Intelligence — sensor fusion and real-time telemetry.
- **Location:** VinUni Center for Environmental Intelligence, Hanoi. Contact: `hung.ph@vinuni.edu.vn`, "Schedule Sandbox Visit".

## 4. Team — https://i-e3s-lab.com/team

Counters on page: **PIs 2 · Members 8 · Collaborators 9 · Alumni 0** ("No Alumni Records").

### 4.1 PIs
| Name | Role | Focus (summary) | Profile |
|---|---|---|---|
| Ahmad Hajjar | Scientific PI, VinUniversity | Multiphysics modelling of thermal, mechanical, coupled systems | `/team/ahmad-hajjar` |
| Pham Hai Hung | Executive PI, VinUniversity | Multiphysics modelling, AI/ML, Physics–AI digital twins for energy & environment | `/team/pham-hai-hung` |

Both PI profiles list "Joined 2026", Dept. of Computer Science & Electrical Engineering, Office Building E, Education "Doctorate (PhD)", links Google Scholar / ORCID / LinkedIn / GitHub (no real URLs). ⚠️ Both show the same placeholder phone `+84 123 456 789` and the same placeholder career history ("2022.09–2023.12 Postdoctoral Researcher, Stanford University, Energy Systems Lab"), which looks like template text. Emails: `hung.ph@vinuni.edu.vn`, `ahmad.h@vinuni.edu.vn`.

### 4.2 Researchers & staff (8)
| Name | Role | Since | Track | Project tag | Focus (summary) |
|---|---|---|---|---|---|
| Nguyen Thi Minh Chau | Lab Manager | Apr 2026 | Process & System | BESS–Server Cooling DT | Lab coordination |
| Vu Van Hieu | Research Assistant | Dec 2025 | Digital Twin | BESS–Server Cooling DT | Multiphysics for HVAC, process, building energy |
| Nguyen Dinh Phong | Undergrad RA | Dec 2025 | Digital Twin | BESS Digital Twin | Computational engineering, AI optimisation |
| Vu Nguyen Hoang Anh | Research Assistant | Apr 2026 | Process & System | BESS Digital Twin | Battery thermal runaway & safety |
| Ngo Ngoc Quy | Research Assistant | May 2026 | Process & System | BESS–Server Cooling DT | Experimental cooling / thermal-fluid testing |
| Nguyen Tran Nhat Minh | Undergrad RA | May 2026 | Digital Twin | BESS Digital Twin | PINNs, digital twins, virtual sensing |
| Vo Duy Thanh | Research Assistant | May 2026 | Digital Twin | BESS Digital Twin | Battery electrochemical–thermal modelling |
| Pham Trung Hieu | Undergrad RA | May 2026 | Materials & Multiphysics | — | Multiphysics for product design |

Each has a profile at `/team/<slug>` with education level and a VinUni email (not repeated here). Photos: `/images/people/<slug>.png` (present for Hieu, Phong, Minh, Thanh; others not seen).

### 4.3 Collaborators (9)
| Name | Type | Affiliation (as shown) | Project tag | Focus (summary) |
|---|---|---|---|---|
| Simon Park | Academy (internal) | VinUniversity | BESS–Server Cooling DT | Sensing, ontology data models, DT, mechanical integration |
| Le Duy Dung | Academy (internal) | CECS-VinUniversity | — | AI search/recommendation, AI simulation for indoor environments |
| Minh Bau Luong | Academy (external) | Hanoi University of Science and Technology | BESS Digital Twin | Reacting thermofluids, energy systems |
| Son Ich Ngo | Academy (external) | Hankyong National University | BESS Digital Twin | CFD, DT, physics-informed methods |
| Suk Hyun Lim | Academy (external) | Korea Institute of Energy Research (KIER) | — | Hydrotreatment/hydrocracking reactors, oil upgrading, pyrolysis oil |
| Le Quang Thai | Industry | "External collaborator" | — | DT for engineering analysis & monitoring |
| Le Anh Tuan | Industry | Siemens DI SW | BESS Digital Twin | Automotive e-drive, electrified powertrains |
| Vu Toan Thang | Industry | Viettel Semiconductor | — | Process design, TEA, LCA, battery recycling, CO₂ capture |
| Tran Van Bay | Industry | CFDWAYS | — | CFD, thermal–fluid modelling, process optimisation |

Data issues spotted: ⚠️ Le Duy Dung is labelled "Undergraduate Research Assistant" although he is PI of the HVAC project and listed with a PhD; ⚠️ Suk Hyun Lim's profile shows Simon Park's email; names on profile pages are all lower-case.

## 5. Projects — https://i-e3s-lab.com/projects

Filter tags shown: AI, AI Control, BESS, Battery Systems, CFD, Circular Economy, Cloud-Edge Deployment, Data Center, Digital Twin, Energy Efficiency, Energy Systems, Environmental Intelligence, Forecasting, Graphene Oxide, HVAC, Indoor Air Quality, LiDAR, Liquid Cooling, Mechanical Energy Harvesting, Optimization, PDMS, PINN, Physics-AI, Recycled Materials, Reinforcement Learning, Self-powered Devices, Sensors, Server Cooling, Smart Buildings, Storage, Sustainable Materials, Thermal Management, Thermal Safety, Triboelectric Nanogenerator, Virtual Sensing, Wearable Energy. "Displaying 4 of 4 Projects".

Each detail page has: status, deployment year, TRL, domain, lead, funding, span, challenge, solution, framework blocks, 6 objectives, 5 deliverables (all "On-going"), team, consortium, an external "projectPage" link, and hero/cover images at `/images/projects/<slug>/{hero,cover}.png`.

### 5.1 Hybrid Physics–AI Digital Twin for BESS — `/projects/bess-digital-twin`
- **Status** ongoing · **Deployment** 2025 · **TRL** 3 · **Domain** Battery Systems · **Span** 18 months · **Funding** CMIT · **Partners** Volterra, VinFast, CMIT.
- **Pitch:** "Vietnam's first" hybrid physics–AI DT for BESS — electrochemical aging + CFD-derived thermal prediction + AI diagnostics.
- **Challenge:** degradation, thermal-runaway risk, uneven module aging, tropical climate stress, EV-charging stress.
- **Objectives (summary):** hybrid DT under tropical conditions; manufacturer-agnostic BESS–EVCS design basis and datasets; telemetry + degradation/thermal/safety models; reduced-order and PI-AI models for SoH/RUL and temperature; early anomaly warning; cloud-edge DT platform.
- **Deliverables:** thermal prediction & safety model; SoH/RUL engine; BESS ontology & telemetry schema; DT prototype; technical report & publication.
- **Team:** Pham Hai Hung (Executive PI), Ahmad Hajjar (Scientific PI), Vo Duy Thanh, Nguyen Dinh Phong, Nguyen Tran Nhat Minh (research members), Le Duy Dung (collaborator).
- **External link:** ⚠️ points to a CMIT page about *multiferroic materials for spintronics* — wrong link: https://cmit.vinuni.edu.vn/project/multiferroic-materials-for-next-generation-spintronic-applications/

### 5.2 Integrated Optimization of BESS–Server Thermal Management — `/projects/bess-server-DT`
- **Status** planned · **Deployment** 2026 · **TRL** 4 · **Domain** Energy Systems · **Span** 36 months · **Funding** SK Innovation · **Partners** SK Innovation, DMS, CEI.
- **Pitch:** joint SK Innovation–VinUniversity project; AI, forecast-driven thermal & energy management for combined BESS and server cooling.
- **Objectives (summary):** coordinate BESS and server cooling with AI/DT; forecast-driven models; validate cooling via experiments + CFD; load forecasting & BESS scheduling; DT prototype; testbed design packages.
- **Deliverables:** validated AI thermal/cooling prediction models; integrated sizing & scheduling method; lab-scale DT prototype; testbed design package (sensors, data architecture, BOM); Year-1 report and Year-2 roadmap.
- **Team:** Ahmad Hajjar (PI / Scientific PI), Pham Hai Hung (Co-PI / Executive PI), "VinUniversity CEI Team", "SK Innovation Team".
- **External link:** https://research.vinuni.edu.vn/vinuni-and-sk-innovation-establish-joint-research-collaboration-on-energy-systems-and-digital-infrastructure/

### 5.3 An Advanced AI-enabled HVAC Control System (V-IndoorSMART) — `/projects/ai-enabled-hvac-control`
- **Status** ongoing · **Deployment** 2024 · **TRL** 4 · **Domain** Smart Buildings · **Span** TBD · **Funding** CEI ENVISION Grant Program · **Partners** CEI, CECS.
- **Pitch:** AI HVAC management for greener, healthier indoor facilities in Vietnam — 3D indoor modelling, airflow simulation, sensing, real-time control.
- **Objectives (summary):** mobile-LiDAR 3D models of indoor spaces; CFD/PINN airflow & heat transfer; IAQ sensor network; AI HVAC control (RL); validation in controlled and real rooms; energy saving with comfort/IAQ.
- **Deliverables:** sensing & data infrastructure; 3D modelling workflow; CFD/PINN model; AI HVAC system; validation report.
- **Team:** Le Duy Dung (PI), Pham Hai Hung (Executive PI), Vu Van Hieu (RA), Nguyen Tran Nhat Minh (Undergrad RA).
- **External link:** https://cei.vinuni.edu.vn/project/an-advanced-ai-enabled-hvac-control-system-towards-greener-and-healthier-indoor-facilities-in-vietnam/

### 5.4 High-Performance Triboelectric Nanogenerator Based on Recycled Materials — `/projects/recycled-material-teng-energy-harvesting`
- **Status** ongoing · **Deployment** 2024 · **TRL** 3 · **Domain** Energy Harvesting · **Span** TBD · **Funding** CEI ENVISION Grant Program · **Partner** CEI, VinUniversity.
- **Pitch:** GO/PDMS TENG using graphene oxide from graphite recovered from spent batteries; harvests walking/tapping/jumping motion to power LEDs and small electronics.
- **Team:** Ahmad Hajjar (PI). Not on the home page; not reachable from the home page except via `/projects`.
- **External link:** https://cei.vinuni.edu.vn/project/high-performance-triboelectric-nanogenerator-based-on-recycled-materials-for-mechanical-energy-harvesting/

## 6. Publications — https://i-e3s-lab.com/publications ⚠️

Five entries, each with Link / Code / Abstract buttons:

| Title | Authors | Venue / status |
|---|---|---|
| Engineering Regression Without Real-Data Training: Domain Adaptation for Tabular Foundation Models Using Multi-Dataset Embeddings | Regenwetter, Yu, Picard, Ahmed | Under review, 2026 |
| GIT-BO: High-Dimensional Bayesian Optimization with Tabular Foundation Models | Yu, Picard, Ahmed | ICLR 2026 |
| TopoEdit: Fast Post-Optimization Editing of Topology Optimized Structures | Chen, Carstensen, Ahmed | Under review, 2026 |
| MicroLad: 2D-to-3D Microstructure Reconstruction and Generation via Latent Diffusion and Score Distillation | Lee, Ahmed | CMAME 2026 |
| FLOAT: Fatigue-Aware Design Optimization of Floating Offshore Wind Turbine Towers | Ribeiro et al., Ahmed | Under review, 2026 |

⚠️ None of these authors are lab members — this looks like sample data copied from another group's site. Links are placeholders (e.g. `https://doi.org/10.1109/TIE.2026.1234567`, `github.com/ie3s-lab/...` repos). **The lab's real papers (from the reports) are not on the site.**

## 7. News — https://i-e3s-lab.com/news

Filters: All, Technology, Achievements, Events, Research.

| Date | Title | Category | Lead shown | Path | Note |
|---|---|---|---|---|---|
| 27 Apr 2026 | Breakthrough AI Creates Real-Time "Digital Twins" for Healthier Buildings | Technology | Vu Van Hieu | `/news/breakthrough-ai-digital-twins-healthier-buildings` | Real, full article |
| 26 Mar 2026 | IE³S Lab Wins National Research Grant | Achievements | Ahmad Hajjar | `/news/national-research-grant-win` | ⚠️ generic stub (claims 5 PhD positions and a 1 MWh battery test facility); stock photo |
| 19 Mar 2026 | BESS Digital Twin V2.0 Launch | Technology | Pham Hai Hung | `/news/bess-digital-twin-v2-launch` | ⚠️ one-line stub; stock photo |
| 5 Mar 2026 | Grid Resilience Symposium 2026 | Events | Vu Van Hieu | `/news/grid-resilience-symposium-2026` | ⚠️ one-line stub; stock photo |
| 13 Feb 2026 | Physics-Informed ML Breakthrough | Research | Ahmad Hajjar | `/news/physics-informed-ml-breakthrough` | ⚠️ stub; tags "Nature Energy" |
| 27 Jan 2026 | Sustainability Hackathon Winner | Achievements | Minh Bau Luong | `/news/hackathon-winner-2026` | ⚠️ stub (blockchain energy settlement) |

**Article summary — Healthier Buildings (27 Apr 2026):** an AI framework that reconstructs full 4D (x, y, z, t) indoor fields — CO₂, temperature, airflow, pollutants — from a few low-cost sensors, closing the gap between sparse sensors and slow CFD; runs in a fraction of a second on standard hardware, enabling ventilation control that improves safety and cuts over-ventilation energy. Sections: Research Topic; Potentials and Breakthroughs; Benefits. Figures: `/images/news/hero-digital-twin.png`, `/images/news/approach-digital-twin.png`, `/images/news/results.png`. (This matches the V-IndoorCARE virtual-sensing work.)

## 8. Courses — https://i-e3s-lab.com/courses ⚠️

- IE3S-101 Fundamentals of Energy Systems — "Dr. Alex Rivera", Fall 2026, core undergraduate.
- IE3S-502 Advanced Digital Twins for Infrastructure — "Dr. Alex Rivera & James Wilson", Spring 2026, graduate.
- Industry Training: Battery Management Optimization — "Sarah Chen", July 2026, professional certificate.
- **Engineering Intelligence Seminar**, Fridays 4:30 PM; speakers "Prof. Elena Kostas (MIT)" and "Marco Rossi (Enel X)".

⚠️ Instructors and speakers are not lab people; all placeholder. Contact link `mailto:contact@ie3s.edu` (not a real lab domain).

## 9. Positions — https://i-e3s-lab.com/positions ⚠️

- PhD Candidate: Physics-Informed ML for Energy Storage — full funding, deadline 15 May 2026 (passed).
- Research Assistant: Urban Resilience Digital Twins — rolling.
- Postdoctoral Researcher: Decoupled Control for Microgrids — 2-year, deadline 1 Jun 2026 (passed).
- "Sandbox Internships" year-round; "Submit General Prospectus" → `mailto:contact@ie3s.edu?subject=Internship Inquiry`.

None of these match the recruiting needs in the reports (see §11).

## 10. Get involved / Portal

- **/get-involved:** three routes — Work With Us (industry pilots, DT, joint R&D), Join the Lab (PhD, Master, RA, UROP), Connect (talks, visits). Letter-of-Interest form with interest options: PhD/Master's, Research Assistant (Project Officer), UROP, Affiliate Program (Industry), Sponsored Research, International Collaboration. Location card titled ⚠️ "Visit **i-PSD** Lab" (wrong lab name) — Vinhomes Ocean Park, Gia Lam, Hanoi; Google Maps link.
- **/portal:** "IE³S Portal — Knowledge Agent" chat box; footer says "Local Semantic Engine v1.0.0 ▪ No external APIs connected".

---

## 11. Comparison with the Sep and Oct 2026 progress reports

The reports call the lab **"Digital Energy Process Intelligence (DEPI) lab"**; the site calls it **"IE³S Lab — Integrated Engineering for Energy & Environmental Systems"**. Neither mentions the other name.

### 11.1 Projects

| Project (report name) | In reports | On site |
|---|---|---|
| SK01 — Integrated Optimization of BESS-Server Thermal Management (CEI/SK; Ahmad; core member; 2 RAs + 1 master RA, 3 master candidates) | ✅ both | ✅ §5.2 — but site says **"planned"**, while reports show it running (steering committee done, half-year report and 1st deliverables in progress, Siemens software, VSF cloud) |
| SK02 — AI-Based Forecasting and Optimal Scheduling of VPP towards industrial load (Nguyen Phi Long; DT platform) | ✅ both | ❌ missing |
| CMIT — Hybrid Physics–AI DT for BESS in EVCS (PI: Hung; 4 RAs + HUST team) | ✅ both | ✅ §5.1 (external link wrong) |
| V-IndoorCARE (VinIF; Le Duy Dung) | ✅ both | ⚠️ partly — site project is "V-IndoorSMART", funded by **CEI ENVISION**, while reports say **VinIF** and use the name V-IndoorCARE. Same team and topic; name and funder disagree. |
| Smart Low-Cost Air Quality Monitoring System, Hanoi (CEI; 1 student RA; device optimisation framework done) | ✅ both | ❌ missing |
| EV charging with green infrastructure — BESS-PV-EVCS (CEI; Do Danh Cuong, Nguyen Phi Long; VinFast; Prof. Akhil) | ✅ both | ❌ missing (VinFast only appears as a BESS DT partner) |
| Hydrogen project group (Dr. Trang, Dr. Trung, Dr. Trường — HUST-CLCS; PEMFC topics) | ✅ both | ❌ missing |
| Common research with KIER, IS-VNU, IET-HUST, HUST-CLCS, HKNU, IUH | ✅ both | ⚠️ only KIER, HUST and Hankyong (HKNU) appear, as collaborator affiliations / logos |
| Triboelectric nanogenerator from recycled materials (Ahmad, CEI ENVISION) | ❌ | ✅ §5.4 — only on the site |

### 11.2 Pipeline / proposals (reports only — none on the site)
- **Sep:** NAFOSTED spray-drying Physics–AI multiscale framework (3 bn VND, with HUST-IET / Le Kieu Hiep) — accepted; NAFOSTED RDF fuel pellets (1.5 bn VND, HUST-CLCS / Do Xuan Truong) — rejected as ineligible, to resubmit; three PEMFC scoping topics (flow channel optimisation; DT for health monitoring; net-zero PEMFC process integration, with IS-VNU); Minh Thạch energy (~50K expected). Targets: 4–6 Q1 (CEI main) and 6–8 Q1 common research in AY26-27, 4–6 RAs to recruit.
- **Oct:** GGPOWER collaboration project (co-fund) — accepted; "Software-Defined Battery Intelligence and Digital Twins for Next-Generation Sustainable Energy Storage" (CEI ENVISION) — planned; Minh Thạch energy still scoping.

### 11.3 Publications
- **Reports:** main-author 02 submitted (Oct; was 01 planned for Sep), co-author 02 accepted + 03 under review; target 06 main + 03 co-author by end-2026; CMIT 01 under review + 02 more by end-2026; VinIF 02 under review + 03 more; hydrogen group 1 published (Q2) in Oct; many "in preparation, submit in November".
- **Site:** none of the lab's papers; only 5 unrelated placeholder entries. **Biggest gap.**

### 11.4 People
- **Site has, reports don't:** the full named roster (2 PIs, 8 staff/RAs, 9 collaborators with affiliations, start dates, tracks) and individual profiles.
- **Reports have, site doesn't:** Nguyen Phi Long, Do Danh Cuong, Dr. Trang, Dr. Trung, Dr. Trường (HUST-CLCS), Prof. Akhil, Le Kieu Hiep (HUST-IET); headcounts (16 RAs across projects; PhD and master candidates; HUST master student co-supervised); visiting researchers in Oct — Prof. Wang Wei-Cheng (National Cheng Kung University, hydrogen & CCUS, 27 Oct–3 Nov) and Dr. Lim Seok Hyun (KIER, upgrading/upcycling, 18–20 Nov). (Note the KIER researcher is spelled "Suk Hyun Lim" on the site and "Lim Seok Huyn" in the report.)

### 11.5 Facilities and operations (reports only)
- **Digital workspace plan (Sep → Oct status):** 2× 55" TVs, toolbox, safety box — "awaiting approval"; 2 kW lab-scale system — slipped from before 20 Oct to November, assembly starting; VR glasses (added in Oct, 15 Nov). All funded by SK01. Layout: digital-twin TV wall, lab-scale SiL/HiL setup, testbed with cooling, solar–wind–BESS integration, PLC-SCADA, BESS system, VR/XR demo showcase area, "SK x VinUni" teaching support. Oct adds a TTV + TIM + heatsink assembly image.
- **Requests to EES–CEI:** recruiting; SK procurement and budget-line transfer; building the DEPI lab; datacenter events in Singapore (spin-off networking, Sep).
- The site only hints at this as the "Living Engineering Sandbox" and a "1 MWh battery test facility" in a stub news item — which the reports don't support.

### 11.6 Things the site has that the reports don't
Mission/strategy text, the three research areas, TRL and objectives/deliverables per project, the indoor digital-twin news article, partner logos (APL, DMS Lab, Siemens, VinFast, KIER, CEI), the Letter-of-Interest contact flow, and the Portal chatbot.

### 11.7 Fix list for the site (if wanted)
1. Replace the placeholder publications with the lab's real papers.
2. Replace or remove placeholder courses, seminar speakers, positions, stub news, PI phone numbers and Stanford history.
3. Fix the 404 links (`/contact`, `/resources`, `/virtual-lab`, `/seminars`), the "i-PSD Lab" label, the wrong CMIT project link, Le Duy Dung's role, and Suk Hyun Lim's email.
4. Change SK01 from "planned" to "ongoing"; reconcile V-IndoorSMART/V-IndoorCARE and the VinIF/CEI funder.
5. Add the missing projects: SK02 VPP, air-quality device, EV charging BESS-PV-EVCS, hydrogen/PEMFC.
6. Decide on one lab name (DEPI vs IE³S).

---

## Open question

The request didn't say what this information is for. It could feed the RMS-X public **About us** page (`src/app/page.tsx`), the **jobs** page, or the demo data for the seven projects (team members, partners, TRL, objectives and deliverables are the most reusable parts). No app code has been changed.
