# UC-AI-1: Agentic AI architecture for RMS-X

Status: **design**, not built. It builds on the Agentic AI prerequisites already in the app (README, Phases A–C).

## 1. The idea in one paragraph

Agents do the legwork, and people keep the decisions. An agent reads the same data its person could read and produces **proposals**: a list of named actions, with reasons and evidence. The proposal waits in that person's **Agent inbox**. When the person accepts it, the server runs the steps as that person, through the same rules module as a click in the app, and the audit entry names the proposal. Nothing an agent does can get past a rule that a person would hit. Only actions the PI has allowed in **Agent settings** run without a person, and those are routine, reversible and never key deliverables.

## 2. Layers

```
┌───────────────────────────────────────────────────────────────────────────────┐
│ 1. CHANNELS   App pages · Agent inbox · PI assistant chat · email/notifications │
│               · MCP (Claude Desktop for the PI)                                 │
├───────────────────────────────────────────────────────────────────────────────┤
│ 2. AGENT RUNTIME (worker)                                                       │
│    Event dispatcher → Agent registry + policy → Claude tool-use loop            │
│    Run log (trace, tokens, outcome) · limits per run, per day                   │
├───────────────────────────────────────────────────────────────────────────────┤
│ 3. TOOL GATEWAY                                                                 │
│    Read tools (redactFor as the person)  ·  propose(steps) — the only "write"   │
│    Untrusted-content quarantine: extractor with no tools → typed facts          │
├───────────────────────────────────────────────────────────────────────────────┤
│ 4. CORE (exists)                                                                │
│    Named actions (62) · rules module · runSteps all-or-nothing · withProposal   │
│    Audit (reason, proposalId) · event log · daily sweep · redactFor             │
├───────────────────────────────────────────────────────────────────────────────┤
│ 5. DATA & SOURCES                                                               │
│    Supabase Postgres (records, event, proposal, agent_run) · file storage       │
│    Linked sources: shared folder, repo, mailbox (with consent), DOI/Crossref    │
└───────────────────────────────────────────────────────────────────────────────┘
```

### What already exists, and what is new

| Piece | Status | Where |
|---|---|---|
| Every write is a named action, run by the server as the signed-in person, all or nothing | **Exists** | `action()` in `src/data/actions.ts`, `runSteps` in `src/server/run.ts` |
| Audit entry carries `reason` and `proposalId` | **Exists** | `withProposal` in `src/data/actions.ts` |
| Event log, including time-based events from the daily job | **Exists** | `db.events`, `sweepEvents`, `POST /api/jobs/daily` |
| Read rules applied before data leaves the server | **Exists** | `redactFor` in `src/data/read-rules.ts` |
| Read tools described for MCP | **Exists** for projects and Hub | `TOOLS` in `src/server/read-tools.ts` |
| A Claude call with structured output, tidied by the rules before saving | **Exists** | Position drafting, `src/app/api/position-draft/route.ts` |
| Baselines to measure agents against | **Exists** | Pilot measures, `src/data/measures.ts` |
| `proposal` table and **Agent inbox** page | **New** | |
| Agent registry, **Agent settings** (autonomy per agent) | **New** | |
| Event dispatcher and worker that runs agents | **New** | |
| More read tools: outcomes, updates, progress report, achievements, people | **New** | extend `TOOLS` |
| Ingest connectors and the quarantine extractor | **New** | |
| `agent_run` log and an evaluation set per agent | **New** | |

## 3. The agents

| Agent | Starts on | Reads | Proposes | Default autonomy |
|---|---|---|---|---|
| **Registration** | Contract or proposal PDF uploaded to a project | The PDF (quarantined), project WPs, team | `addOutcomes` rows with kind, title, WP, due date, owner | Suggest |
| **Evidence intake** | New mail, file or DOI in an RA's linked sources | Quarantined facts, the RA's assigned outcomes | `saveUpdate` draft: stage move and evidence link | Draft (RA sends) |
| **Checker** | `update.submitted` | The update, its versions, evidence files, outputs | A check result per item, with reasons, for the lab manager | Suggest |
| **Chaser** | `update.due_soon`, `update.overdue`, `milestone.late` | Owed updates, outcomes due | A reminder message; escalation to the lead after N days | Act (messages only) |
| **Reporter** | Month end (daily job) | `progressReport()` | "This month" notes and risk flags for each project | Draft (PI edits) |
| **PI assistant** | PI asks | All read tools, as the PI | Nothing; answers only, with links to records | Read-only |
| **Hub helper** | RA asks; `hub.page_past_review` | Hub pages the asker may read | An answer quoting the pages; a review draft for the owner | Suggest |
| **Recruitment screener** (later) | `application.received` | CV text (quarantined), position profile | A screening summary for the panel. **Never** a Gate decision | Suggest, after legal approves the AI notice |

## 4. How a proposal works

```
event ─► dispatcher ─► agent run ─► propose(steps, why, evidence, basedOn)
                                         │
                       policy: may this agent act alone on these actions?
                     ┌───────────────────┴───────────────────┐
                    no                                       yes (routine, allowed by PI)
                     ▼                                        ▼
          Agent inbox of the person                runSteps as agent-for-person
          Accept / Edit then accept / Reject              │
                     ▼                                        │
       runSteps as the person, withProposal(id) ◄─────────────┘
                     ▼
     rules module ─► refused: reason shown, proposal marked failed
                  └► saved: record + audit (proposalId) + events, together
```

- **A proposal is data, not a command.** It holds `steps` (named actions and their arguments), a `why`, the `evidence` links, the `agent`, the person it `actsFor`, and `basedOn`: the versions of the records it read.
- **Stale proposals are refused.** If a record in `basedOn` changed before the proposal is accepted, the person is asked to look again. This is the same idea as the stale-draft rule for stages.
- **Rejecting asks for a short reason.** Reasons feed the agent's evaluation set.
- **Proposals expire** after 14 days.

### Who an agent acts as

- An agent always acts **for one person**, and it reads through `redactFor` as that person. It can't see more than that person sees.
- Its writes are limited twice: by what the person may do, **and** by the agent's own allowlist of action names.
- The audit shows both: `by` is the person, and `proposalId` leads to the agent and the run.

## 5. Autonomy: Agent settings (PI)

Four levels per agent: **Off · Suggest · Draft · Act on routine**.

| Class of action | Highest level the PI can choose |
|---|---|
| Reading, answering questions | Act |
| Reminders and notifications | Act |
| Drafts the person sends themselves (an RA's update, a report's notes) | Draft |
| Check results for the lab manager | Suggest |
| Approving a routine update (no key deliverable), when routine approval is on | Act on routine, and only when every check passed |
| Key deliverables: stage moves for papers, products, testbeds, patents; `setOutcomeStage` | **Always a person** (the existing `forPi` rule) |
| Pay, budgets, recruitment gate decisions, deleting, publishing | **Never an agent** |

## 6. Safety

- **Outside text is untrusted.** Emails, PDFs, CVs and web pages go first to an **extractor** that has no tools and returns typed facts only, for example `{kind: "acceptance", venue, title, date, sender}`. The agent that proposes never sees the raw text. Any text shown to people is inside a marked block.
- **No invented evidence.** Evidence must be a stored file or a link that resolves. The rules module still requires it per stage.
- **Numbers come from code.** The Reporter writes words around `progressReport()`; it never computes percentages.
- **Consent.** Linking a mailbox or a folder is opt-in per RA and can be revoked. Only messages matching filters (publisher domains, the RA's own outcomes) are read.
- **Limits.** Each run has a step and token limit. Each agent has a daily limit. A run that fails three times stops and tells the lab manager.
- **Legal.** The recruitment screener waits for VinUni legal to approve the AI notice and the retention periods.

## 7. Runtime and deployment

Keep it boring: the current Next.js server, Postgres and one worker.

- **Event dispatcher:** the worker reads new rows from the `event` table (an outbox, polled every few seconds) and the daily job. Each event kind maps to the agents subscribed to it. There's no message broker.
- **Agent loop:** Claude API tool use, through the Claude Agent SDK or the SDK's tool runner. Model by job:
  - a fast model (`claude-haiku-5-5`) for sorting mail and extracting facts;
  - `claude-sonnet-5-5` for checking and drafting;
  - `claude-opus-5-5` for the monthly report and reading contracts.
- **MCP server:** wraps the read tools so the PI can use Claude Desktop as the PI assistant, signed in as themselves.
- **Run log (`agent_run`):** the agent, the person, the trigger event, the tools called, tokens, the duration and the proposal it made. The Agent inbox links each proposal to its run.

## 8. Measuring it

Measure against the baselines the pilot already records (AIP-P8):

- RA time to write an update;
- lab manager check time;
- time to compile the monthly lab update;
- the proposal **acceptance rate** per agent, and the rejection reasons.

An agent moves up a level of autonomy only after a pilot shows a high acceptance rate and no wrong stage moves.

## 9. Build order

1. **Proposal table, Agent inbox, run log, Agent settings.** These are the base for everything else.
2. **Reporter and PI assistant.** Read-only, with extra read tools and the MCP server.
3. **Checker**, at Suggest.
4. **Evidence intake**, at Draft, with the quarantine extractor and the first connector: mail forwarded to a lab address, which is simpler than a mailbox connection.
5. **Registration** from contract PDFs.
6. **Chaser** at Act, and routine approval at Act on routine, after the pilot.
7. **Hub helper**, then the **Recruitment screener** once legal approves.
