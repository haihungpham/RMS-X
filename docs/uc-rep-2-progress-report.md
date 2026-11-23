# UC-REP-2: Progress report for the PI

Status: built 2026-11-08. It replaces the "Monthly lab update" page (REP-1) at the same address; the lab update is now the report's last section.

## How to use it

1. Open **Progress report** in the menu (`/projects/report`). The PI and the lab manager see it.
2. Choose the month. The page opens on the newest month whose updates were due by today.
3. Read it on the page, or preview it as it prints, without the menu:
   - **Preview as slides:** a 16:9 deck in the lab's style (navy title bar, red accent). One slide prints per page, so **Save as PDF** gives a PDF deck you can present or attach. The slides are:
     1. **Cover:** lab, month, who it is for and the date, with three headline numbers.
     2. **Project progress overview:** a table of every project with its health, its progress in % (a bar for milestones done, with a marker for time gone), its milestones, a deliverables update (key deliverables delivered, and how many were updated this month) and its next milestone.
     3. **One "Project progress update" per project:**
        - the progress in % (milestones done, time gone) and its health;
        - a work-package table, each with a % bar;
        - a **Deliverables update** table (deliverable, type, status, who), marking those updated this month;
        - what moved this month, issues and help asked for, and the next milestone.
     4. **RA progress summary.**

     A slide with a lot in it shrinks its tables to fit the page, as PowerPoint's autofit does.
   - **Preview as document:** the long-form report below.

   From either preview, **Print or save as PDF** opens the browser's print window, and the **Slides / Document** switch changes format. Esc or **Close preview** goes back.
4. **Download as text** saves the same report as Markdown (`depi-progress-report-YYYY-MM.md`), to keep, send to CEI or paste into the lab's template.

The report is made fresh from the records every time it is opened, so it never goes out of date and nothing is stored.

## What it holds

- **Summary:** projects by health, updates approved/waiting/overdue for the month, RAs needing attention.
- **Project progress summary:** one row per project in the update loop, showing:
  - funder, lead and number of RAs;
  - health;
  - milestones done, late and at risk;
  - the month's updates;
  - outputs counted and in the pipeline;
  - the next milestone and its owner;
  - the budget spent, for the PI and only when a budget is set.
- **RA progress summary:** one row per RA, with those needing attention first, showing:
  - projects and supervisor;
  - the month's updates;
  - milestones they own;
  - outputs counted this year, in the pipeline and waiting for a check;
  - their next review;
  - development targets met (PI only);
  - what needs attention (an overdue update, a late milestone, the review, the contract end, checks).
- **Project detail:** what approved updates say: milestones that moved, outputs, issues and help asked for (REP-1).

## Rules

- **R1:** only approved updates are quoted; the others are counted.
- **R2:** outputs count once checked, by the lab's rule on when papers count (Team and rules).
- **R3:** the lab manager's copy leaves out budgets and capability targets, and says so.

## Code

- Data: `src/data/progress-report.ts`. It reuses `labUpdate` and `labUpdateSections` from `src/data/lab-update.ts`.
- Progress %: milestones done of all milestones, overall and per work package. Time gone runs from the project's start date to its end date. Deliverables are the outputs credited to the project: key deliverables first, then other finished outputs.
- Slides: `src/components/ReportSlides.tsx`.
- Page: `src/app/projects/report/page.tsx`. The preview and print styles are at the end of `src/app/globals.css`.
- Tests: `src/data/progress-report.test.ts`.

## Not built yet

- Sending the report by email, or making it on a schedule.
- A report for a date range longer than one month, or for one project only.
- Charts (for example milestones over time).
- A real .pptx download. The slides save as PDF; an editable PowerPoint file would need a generator such as pptxgenjs.
