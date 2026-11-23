# UC-PAY-1 — Email reminder one week before an RA's monthly pay

Status: in-app part built 2026-11-08; emails wait for the Supabase release.

**Built:** the pay settings on Team and rules (pay day, default the 21st, 0 turns it off; reminder lead, 7 days; review margin, 2 working days), the next pay date and the R6 warning there (`src/rules/pay.ts`), and home-page tasks for each step and the "pay held" notices (`src/data/pay.ts`, tests in `src/rules/pay.test.ts` and `src/data/pay.test.ts`).
**Not built yet:** sending the emails, the second reminder at 3 days with the PI copied (the home task stays up instead), the payment reminder log and `payment.remind` audit entries, split pay (R5), stand-ins for reviewers on leave, and a finance contact.

## 1. Goal

An RA's monthly pay is released only when their monthly update for that month has been **submitted by the RA, checked by the lab manager and approved by the PI**. Seven days before the pay date, RMS-X emails whoever still has a step to do, so no RA's pay is held because a review slipped.

## 2. How it fits the existing update loop

With the default project settings (`PROJECT_DEFAULTS`):

| Step | Rule | November 2026 example (pay for October) |
|---|---|---|
| RA submits the update | Due on the 1st Friday of the month (`dueWeekday 5`, `dueWeek 1`) | Fri 6 Nov |
| Existing "due soon" reminder | 3 days before (`reminderDays`) | from Tue 3 Nov |
| Lab manager checks | Within 3 working days (`checkDays`) | by Wed 11 Nov |
| PI approves | Within 5 working days (`approveDays`) | by Wed 18 Nov |
| Finance gets the approved list | 2 working days before pay (new setting) | by Wed 18 Nov → pay Fri 20 Nov |

**The rule this sets:** with the default settings, the earliest pay day that leaves time for every step in every month is the **21st**. The 20th fails in months whose first Friday is the 7th (for example August 2026), so RMS-X defaults to the 21st. If the lab pays earlier (for example on the 10th), either the update must be due earlier, or the check and approval times must be shorter. RMS-X should warn when the settings and the pay date don't fit (see rule R6).

## 3. Actors

- **System**: runs a daily job at 08:00 Hanoi time.
- **RA**: submits their update.
- **Lab manager** (`admin`): checks submitted updates. With `routineApproval` on, the lab manager also approves updates with no key deliverable.
- **PI**: approves checked updates.
- **Finance contact** (optional, outside RMS-X): receives only the "will be held" notice and the final list of who is cleared for pay.

## 4. Preconditions

- The lab has a **monthly pay date** (for example the 20th), moved to the working day before if it falls on a weekend or lab holiday (the same `lastWorkingDayOnOrBefore` rule the update due dates use).
- Each pay month is linked to the update period that covers the work: **pay for October ← the "November update" (key `2026-11`), which covers October**.
- The RA is on at least one project team that is in the update loop.
- Email sending is turned on (the Supabase release; the MVP has none).

## 5. Main flow

1. The daily job finds the pay date that is exactly **7 days** away.
2. For each RA paid on that date, it collects the update periods the pay depends on: one per project the RA is on, for the month the pay covers.
3. For each update, it works out the missing step:
   - not started or draft → **RA** must submit
   - submitted → **lab manager** must check
   - checked → **PI** must approve (or the lab manager, under routine approval)
   - returned to the RA → **RA** must revise and resubmit
4. It groups the missing steps **by the person who must act** and sends each person one email:
   - **RA**: "Submit your November update for SK01 by [review deadline] so your October pay on 20 Nov isn't delayed." Link: `/projects/<id>/update/<period>`.
   - **Lab manager**: "4 updates are waiting for your check before the 20 Nov pay date." Links: `/projects/queue`.
   - **PI**: "3 checked updates are waiting for your approval before the 20 Nov pay date." Links: `/projects/queue`.
5. Each email states the **review deadline** (pay date minus 2 working days), not just the pay date.
6. The same items appear as tasks on each person's RMS-X home page (alongside the existing update tasks).
7. The system records `payment.remind` in the audit log: who, which pay month, which updates, and whether it was the first or second reminder.

## 6. Other paths

| Case | What happens |
|---|---|
| All of an RA's updates already approved | No email about that RA. |
| Still missing **3 days** before pay | Second reminder to the person who must act, with the PI copied. |
| Still missing on the **review deadline** | "Pay will be held" notice to the PI and lab manager (and finance, if set), listing the RAs and the step that is missing. The RA is told their pay is held and why. |
| Step done after the first email | That person gets no more reminders for that pay month. |
| RA on two projects (e.g. Vu Van Hieu on SK01 and V-IndoorCARE) | Both updates must be approved. Each funder's share of the pay can be released on its own once that project's update is approved (setting R5). |
| Project on a **fortnightly** rhythm | Every fortnightly update whose period falls in the pay month must be approved. |
| RA started this month, or project joined the loop after the month (`updatesFrom`) | No update is expected for that month, so nothing blocks the pay and no reminder is sent. |
| RA's contract ended before the pay month | Only the last month worked is checked; no reminder after that. |
| Email bounces | The home-page task stays, and the lab manager sees "could not email [name]". |
| Reviewer on leave | Goes to the person standing in for them, if set; otherwise to the PI. |

## 7. Rules

- **R1 Lead time:** 7 days before the pay date by default; a project setting from 3 to 14 days.
- **R2 Review deadline:** the pay date minus 2 working days by default (time for finance), a setting from 0 to 5.
- **R3 One email per person per day:** all their items in one message; never two emails for the same pay month on the same day (dedupe on person + pay month + reminder kind).
- **R4 Privacy:** emails never show pay amounts, salary bands or another RA's details. The lab manager's and PI's emails list names and projects only. Pay is personal data.
- **R5 Split pay:** off by default (all of an RA's updates must be approved). When on, each project's share is cleared separately.
- **R6 Settings check:** when the PI saves project settings or the pay date, RMS-X warns if `due date + checkDays + approveDays + review margin` falls after the pay date for any month.
- **R7 Candidates:** applicants never receive these emails.

## 8. New data

- **PaySchedule** (lab setting): pay day of the month, lead days (R1), review margin (R2), split pay on/off (R5), finance contact email.
- **PayReminder** (log, one row per email): pay month, person emailed, kind (`first`, `second`, `held`), the update ids it covered, sent at, delivery status.
- **Audit action** `payment.remind` (and `payment.held`), in the same audit log as `update.remind`.

Nothing about pay amounts is stored in RMS-X.

## 9. Acceptance examples (default settings, pay date 20 Nov 2026)

1. **RA hasn't submitted.** On Fri 13 Nov, Nguyen Dinh Phong's November update for SK02 is still a draft. He gets one email with the deadline Wed 18 Nov. The lab manager and PI get nothing about him.
2. **Waiting for the check.** Ngo Ngoc Quy submitted on 6 Nov, still not checked on 13 Nov. The lab manager gets one email listing it, along with any others waiting for a check.
3. **Waiting for the PI.** Two updates checked, not approved, on 13 Nov. The PI gets one email listing both.
4. **Second reminder.** The PI hasn't approved by Tue 17 Nov (3 days before pay). The PI gets a second email; the lab manager is copied.
5. **Held.** Still not approved on Wed 18 Nov. The PI, lab manager and finance contact get the "pay will be held" notice; the RA is told why.
6. **Weekend pay date.** Pay date 20 Dec 2026 is a Sunday, so it moves to Fri 18 Dec, with the first reminder on Fri 11 Dec and the review deadline on Wed 16 Dec.
7. **Done early.** All updates approved by 12 Nov. No emails for the 20 Nov pay date.
8. **No duplicates.** The job runs twice on 13 Nov. Each person still gets only one email.

## 10. Open questions for the lab

1. What is the actual pay day each month, and is it the same for all funders (CEI, CMIT, VinIF, SK)?
2. Does finance need a list of cleared RAs from RMS-X, or only the "held" exceptions?
3. Should a held pay be released automatically when the update is approved later, or wait for the next pay run?
4. Should split pay (R5) be on for RAs who work on more than one project?
