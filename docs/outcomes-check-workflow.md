# Checking project outcomes: test workflow

A walk-through of registering, assigning, reporting, approving and reporting on deliverables. It covers the PI, lab manager, project lead and RA. Allow about 30 minutes.

## Before you start

- Open **http://localhost:3001** in a **private (incognito) window**.
  - The window starts with fresh demo data and leaves your normal browser's data alone.
  - Closing it throws the test data away. To start again, open a new private window.
- Sign in from the demo account list on the sign-in page (**Use**, then **Sign in**). The password is `rmsx-demo`.
- To switch person, use **Sign out** at the bottom of the menu.

| Who | Email | Role in the test |
|---|---|---|
| PI | pi@example.edu | Registers, assigns, approves, sets stages |
| Lab manager | labmanager@example.edu | Checks updates; copy of the report without budgets and targets |
| Project lead of AQ | panel@example.edu | Can register and assign on AQ |
| RA on AQ and SK02 | ra3@example.edu | Nguyen Dinh Phong: reports stages |

Tick each **Expect** line as you go. Anything different is a finding: note the step number.

---

## A. Register (PI)

**A1. See the demo outcomes.** All projects → **AQ** → **Outcomes** tab.
- [ ] Expect the three steps at the top: Register, Report, Approve.
- [ ] Expect the registered deliverables in this order:
  - Calibration paper (Journal paper, Planned 0%);
  - Prototype v1 (Validated 100%);
  - Sensor board v2 (Testing 75%);
  - Prototype v2 (Build 50%);
  - Final report (Planned 0%).
- [ ] Expect Device requirements, Sensor selection and Field test on the **Tasks** tab, not on Outcomes.

**A2. Confirm suggested kinds.** All projects → **H2** → Outcomes.
- [ ] Expect a yellow note: "8 milestones have a suggested kind only".
- Press **Confirm them on Set up**, then **Confirm the suggested kinds**.
- [ ] Expect the "(suggested)" labels to disappear. Test cell design is a Testbed; Paper is a Journal paper; Partnership agreement is an Activity.

**A3. Add from a template.** On H2's Set up page, press **Add from a funder template**, choose **CEI**, then **Add 6 outcomes**.
- [ ] Expect 6 new rows: 2 journal papers, 1 conference paper, 1 prototype, 1 testbed and a final report. Each is Planned and due on the project's end date.

**A4. Paste a list.** On the same page, press **Paste a list** and type:
```
BMS; BMS prototype v1; 2027-03-31
Testbed; HiL bench
nonsense
```
- [ ] Expect "2 read", plus a warning about line 3. **Add** is disabled until line 3 is removed.
- Remove line 3, then press **Add 2**.
- [ ] Expect the BMS row to show as "Product or prototype (BMS)".

## B. Assign to an RA (PI, then project lead)

**B1.** As the PI: RAs → **Nguyen Dinh Phong** → **Assigned deliverables and tasks**.
- [ ] Expect his deliverables from AQ and SK02 first, each with its project code, then his tasks.
- Press **Assign a deliverable**:
  - Project: AQ;
  - Kind: Product or prototype, Type: BMS;
  - Title: `BMS board`;
  - Due: any date before June 2027.
- Press **Assign to Nguyen Dinh Phong**.
- [ ] Expect "BMS board" in his list at Planned 0%, and on AQ's Outcomes tab with him as owner.

**B2. Owner rules.** In Set up for **SK01**, add a deliverable and choose Nguyen Dinh Phong as its owner.
- [ ] Expect him not to be offered as owner, because he isn't on SK01. If he could be chosen, saving should be refused with "The owner must be an RA on the team".

**B3.** Sign in as **panel@** (AQ's lead) and open Nguyen Dinh Phong's page.
- [ ] Expect **Assign a deliverable** to be offered, but only for AQ and SK02, the projects Le Duy Dung leads.
- [ ] Expect no **Set stage** buttons. Only the PI sets stages by hand.

## C. Report (RA)

**C1.** Sign in as **ra3@**. Open My page.
- [ ] Expect "My deliverables and tasks", with no Assign button.

**C2.** Go to **My work** → **AQ November update**. Under **1. Outcomes and milestones**:
- **Sensor board v2:** set Stage now to **Validated**.
  - [ ] Expect "How it is going" to disappear, because the last stage means Done.
  - [ ] Expect Evidence to be marked * and to ask for the test report, photo or demo link.
- **Calibration paper:** set Stage now to **Submitted**. Leave Evidence empty.
- Press **Send for checking**.
  - [ ] Expect it to be refused with "M7: add the submission confirmation as evidence for Submitted".
- Fill in the evidence:
  - Sensor board v2: `https://example.com/board-tests`;
  - Calibration paper: `receipt.pdf`.
- Press **Send for checking**.
  - [ ] Expect it to be sent, opening the update page.

## D. Check (lab manager)

**D1.** Sign in as **labmanager@**. Open **Updates waiting** → the AQ November update.
- [ ] Expect the table to show stages in the Was and Now columns: Testing → Validated, and Planned → Submitted.
- Tick every check item, then press **Mark checked**.
- [ ] Expect the update to go to the PI's queue.
- With routine approval on in Team and rules, it still goes to the PI, with the reason "Registered deliverable: … to …". The automated tests cover this, so you don't need to switch it on here.

## E. Approve (PI)

**E1.** Sign in as **pi@**. Open **Updates waiting** → the AQ update → **Approve update**.
- [ ] On AQ's Outcomes tab, expect Sensor board v2 at **Validated 100%**, Done, and Calibration paper at **Submitted 50%**.
- [ ] On Nguyen Dinh Phong's page under **Achievements**, expect 2 new checked entries:
  - "Sensor board v2" (Prototype or product, Done), with the link from the evidence;
  - "Calibration paper" (Journal paper, Submitted).
- [ ] Expect no duplicates.

## F. Report (PI)

**F1.** Open **Progress report**, month **November 2026 updates**.
- [ ] In the project summary, expect AQ's Progress % to be higher than before. Publications should read "1 paper: 1 submitted", and Products should show Sensor board v2: Validated.
- [ ] In the RA summary, expect Nguyen Dinh Phong's "Papers 2026" to include 1 submitted.

**F2.** Press **Preview as slides**.
- [ ] On the AQ slide, expect the deliverables table with the paper first.
- [ ] Expect Sensor board v2 to be marked "Moved in November".
- [ ] Expect every slide to fit its page.

**F3.** Sign in as **labmanager@** and open the report.
- [ ] Expect the note "leaves out budgets and capability targets", and no Targets met column.

## G. Manual input (PI)

**G1.** As the PI, open AQ → Outcomes → **Calibration paper** → **Set stage** → **Accepted**. Leave Evidence empty and press **Save stage**.
- [ ] Expect it to be refused with "Add the acceptance email as evidence for Accepted".
- Add `accept.pdf` and save.
- [ ] Expect Accepted 90%. On the RA's page, expect the same achievement, now Accepted.

**G2. Rejected paper.** As the PI, **Set stage** on Calibration paper → **Drafting**, with the note "Rejected".
- [ ] Expect Drafting 25%.
- [ ] On the RA's page, expect the achievement back at **Planned**, so it's in the pipeline and not counted.
- [ ] Expect the report's Publications to say none submitted.

**G3. Blocked while under review.** Sign in as **ra3@** and send the **AQ October update**, moving **Prototype v2** to Testing with evidence. Then, as the PI, press **Set stage** on Prototype v2.
- [ ] Expect it to be refused with "The AQ October update waiting for review reports M5. Approve or return that update instead".
- The same block applies to every outcome in that update, because an update lists all the RA's open outcomes. Approve or return it to free them.

**G4. Lab manager.** Sign in as **labmanager@**.
- [ ] Expect no Set stage buttons anywhere.

---

## How it behaves, by design or for now

| Behaviour | Why |
|---|---|
| Stage % are fixed (for example a paper at Submitted is 50%) | Not yet editable in Team and rules. |
| Stages the PI sets by hand aren't marked "Moved in <month>" on slides | That mark comes from approved updates for the month. The audit log records manual sets as "set by the PI". |
| When an outcome's owner changes, its existing output stays credited to the first RA | Credit goes to whoever did the work. Later stages still move that output on. |
| An achievement entered *before* its outcome was registered isn't linked | It shows under "Other outputs", and the outcome writes a new output when it's out. Remove the old achievement on the RA's page if it's the same work. |
| An RA's draft that didn't touch a stage follows the PI's later change; one that chose an earlier stage is refused | This keeps an old draft from undoing the PI's update. The RA chooses the stage again and sends. |
| Moving a paper back before Submitted puts its output back in the pipeline | A rejected paper stops counting until it is submitted again. |
