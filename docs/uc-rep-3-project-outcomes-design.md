# UC-REP-3: Project outcomes instead of milestones

Status: built 2026-11-08, with the recommended choices: the stage % in the table below, Activity for work steps, BMS as a type of Product or prototype, and the existing paper-counting rule.

## How to use it

- **Register the deliverables:** project → Set up → **Outcomes and milestones**. Three ways in:
  - **Add from a funder template** (CEI, VinIF, Industry);
  - **Paste a list**, one line each: `kind; title; due date`;
  - **Add one**.
- **Milestones planned before outcomes** show a kind suggested from their title, marked "suggested". Change any that are wrong, then press **Confirm the suggested kinds**.
- **RA, monthly:** the update form shows each outcome with a **Stage now** dropdown and asks for the evidence that stage needs. A paper submitted, or a prototype validated, goes into the RA's outputs automatically when the update is approved.
- **Report:** progress % is the average stage of the registered deliverables. The overview shows publications, products and testbeds. Each project slide has a deliverables table with a stage bar per row.

## Built, and not built

- **Code:**
  - rules in `src/rules/outcomes.ts`;
  - the data helper `outcomeOf` in `src/data/projects.ts`;
  - writes in `src/data/project-actions.ts`: `saveMilestone` with kind, `addOutcomes`, `confirmKinds`, stage checks on send, and the output written on approval;
  - tests in `src/data/outcomes.test.ts`.
- **Not built yet:**
  - changing the stage % from Team and rules (they are fixed in `src/rules/outcomes.ts` for now);
  - a stage history chart;
- **Since built:** the PI can set an outcome's stage directly, between updates. It's the **Set stage** button on the project's Outcomes tab, and it needs the stage's evidence. See `docs/outcomes-quick-guide.md`.

## What the PI asked

- Deliverables in the report should put **publications**, **products and prototypes** (for example a BMS) and **testbeds** first.
- Milestones should become **project outcomes**: the deliverables registered with the funder.
- An RA's milestones are the same kinds of things: a paper submitted or accepted, a testbed designed, a BMS built.
- Entering all this should be simple, so the progress report fills itself.

## What RMS-X does today, and why it is not simple

| Today | Problem |
|---|---|
| **Milestones** (`Milestone`) have a title, owner, due date and a generic status: not started, on track, at risk, late, done. | "Journal paper" is a milestone only "on track" or "done". It cannot say *submitted* or *accepted*, so the report cannot either. |
| **Outputs** (`Achievement`) have a type and a status: planned, submitted, accepted, published, done. | They are separate from milestones. An RA whose paper is accepted reports it twice in the same update: the milestone moves to Done, and an output is added. Nothing links the two. |
| The output types have `prototype`, `software` and `deliverable`. | There is no **testbed**, and no way to tell a BMS from any other prototype. |
| Progress % = milestones done ÷ all milestones. | A paper that is submitted but not yet accepted counts as 0%, and an admin step counts as much as a journal paper. |

## Recommendation: one record, the **outcome**, with a stage ladder per kind

Replace the milestone with an **outcome**: one row per registered deliverable. The outcome is also the RA's milestone, so the RA moves it along and nothing is entered twice.

### 1. Outcome kinds, each with its own stages

| Kind | Stages (with % for the progress report) | Evidence asked at the stage |
|---|---|---|
| **Journal paper** / **Conference paper** | Planned 0 · Drafting 25 · Submitted 50 · Revision 70 · Accepted 90 · Published 100 | Submission confirmation; acceptance email; DOI |
| **Product / prototype** (choose a subtype: BMS, device, controller, software) | Planned 0 · Design 25 · Build 50 · Testing 75 · Validated / delivered 100 | Design review; test report; photo or demo link |
| **Testbed** | Planned 0 · Design 30 · Build / commissioning 60 · Operational 100 | Design file; commissioning report |
| **Patent / IP** | Planned 0 · Disclosure 40 · Filed 80 · Granted 100 | Disclosure form; filing number |
| **Report / other** (final report, dataset, workshop) | Planned 0 · Drafting 50 · Delivered 100 | The report |

The stages and their % are the PI's to change (Team and rules), like the other SOP numbers. **Late** and **at risk** still come from the due date, so health works as it does now.

### 2. What each person enters

| Who | When | Input | Effort |
|---|---|---|---|
| **PI or project lead** | At project set-up, once | The outcome list from the funder contract: kind, title, owner RA, due date. Quickest way: choose a funder template ("CEI: 2 journal papers, 1 prototype, 1 testbed, final report"), which makes the rows, then fill in titles and dates. You can also paste the contract's deliverables table. | About 5 minutes per project |
| **RA** | In the monthly update (the form they already use) | For each outcome they own, one dropdown with the **next stage**, an evidence link and an optional note. Nothing else is required. | About 30 seconds per outcome that moved |
| **Lab manager, then PI** | When they check and approve the update, as now | The evidence link is already in the update. On approval, the outcome moves to its new stage. | Same as now |

The output record is made automatically. When a paper reaches **Accepted** or **Published**, a product reaches **Validated**, or a testbed becomes **Operational**, approval writes the RA's achievement, credited to the project. There is no separate "Add an output" for registered work. "Add an output" stays for **unregistered** work (an extra conference paper, a talk or an award). The PI can then **register** that work as an outcome with one click.

### 3. What the progress report shows

- **Project overview:**
  - **outcome progress %**: the average of the outcomes' stage %;
  - a count per focus kind, for example "Papers 1 published · 2 submitted / 4 · Prototype 1 testing · Testbed operational";
  - the time-gone marker, as now.
- **Project slide:**
  - the **outcomes table**, publications first, then products and prototypes, then testbeds, then the rest;
  - each row shows the stage, a % bar, the owner, the due date, and "moved this month";
  - other outputs are collapsed to one line, for example "and 3 other outputs".
- **RA summary:**
  - the outcomes each RA owns, with the papers submitted and accepted this year, and products and testbeds by stage;
  - this replaces the generic count of milestones done.

### 4. Changing over

- Existing milestones become outcomes of kind **Report / other**, and their old status is carried over:
  - Done → Delivered;
  - every other status (not started, on track, at risk, late) → Planned, kept with its due date.
- Milestones whose titles name a paper, prototype or testbed are suggested for a different kind, for the PI to confirm on one page.
- Work packages stay as they are, and outcomes still belong to one.
- Updates already approved stay as they are.

## Decisions for the PI

1. **Stage % weights:** use the table above, or a simpler done/not-done count per kind?
2. **Are work steps that are not deliverables still kept?** Examples are "Site data collected" and "HiL tests".
   - Recommended: keep them as kind **Activity**, shown on the project page but left out of the outcome progress %.
3. **BMS:** a subtype of Product / prototype (recommended), or its own kind?
4. **Paper counting:** does "Submitted" count in the funder report? This is already a PI setting, and it would apply to outcomes too.

## Size of the change

Medium:
- a new `kind` and `stage` on the milestone, plus stage rules in `src/rules/projects.ts`;
- the update form's milestone rows become stage dropdowns;
- approval writes the achievement;
- set-up templates and paste;
- the report's progress % and tables;
- data migration for existing records;
- tests.

The current update, check and approval flow and the report pages stay as they are.
