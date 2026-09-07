---
description: Codebase-wide hunt for over-building — Modules, Seams, and processes whose complexity exceeds what production actually needs. Establishes the production Envelope with the user first, surfaces evidence-gated cut candidates with measured LOC and the human judgement each one needs, hands off to /grill. Sibling of /architecture-deepening (same deletion test, opposite verdict). Uses the vocabulary in references/architecture-language.md.
argument-hint: [<area to focus on, e.g. "channel_sync" or "inventory">]
---

Hunt for **over-building** in the codebase: systems, subsystems, and processes that are more complicated than production use requires and could be cut in lines of code or simplified architecturally. Use the vocabulary in `references/architecture-language.md` — **Module**, **Interface**, **Depth**, **Seam**, **Adapter**, **Envelope** — and its two tests, the **fit test** and the **deletion test**.

Every candidate answers four questions: *what* is over-built, *why* it exceeds production use, *how much* would go, and *what risk needs human judgement* before cutting.

If `$ARGUMENTS` names an area, narrow the hunt (step 2 onward) to it. The Envelope (step 1) always covers the whole system.

## Glossary commitment

This command commits to the vocabulary in [`../references/architecture-language.md`](../references/architecture-language.md). Use those terms exactly. Defer to `CONTEXT.md` for domain nouns (Listing, Stock, Channel, Reconciler, Emitter, etc.). Architecture vocabulary describes the *shape*; domain vocabulary describes the *thing*. *"Collapse the Reconciler's retry Seam"* reads better than *"remove the event-coordination wrapper"*.

## One test, two verdicts

The **deletion test**: imagine deleting the Module. If complexity **reappears** across callers, the Module was earning its keep — that is `/audiotrader-workflow:architecture-deepening`'s candidate, not ours. If complexity **vanishes**, the Module was hiding nothing — that is ours.

The **fit test** finds where to apply it: what does production exercise through this Interface, and what does the Implementation handle that production never presents? The excess is the candidate.

Production use is defined by the **Envelope**, which is why step 1 comes before any hunting.

## Process

### 1. Establish the Envelope — do not hunt before it is confirmed

Read, where present: `CONTEXT.md`, `docs/adr/*.md`, `docs/ARCHITECTURE.md`, `README.md`, `CODING_GUIDELINES.md`, current `specs/`, deploy configuration (Dockerfile, compose, `wrangler.toml`, `.github/workflows/`), `.env.example`.

Write an **Envelope statement** of at most eight lines:

- **Scale** — orders, listings, events per day, as orders of magnitude
- **Tenancy** — how many businesses, how many deploys
- **Integrations** — which channels and partners are live, which are planned
- **Operators** — who uses it day to day, roughly how many
- **Team and deploy shape** — who maintains it, how it ships
- **Uptime expectation** — what an hour of downtime costs

Mark every line **documented** (with the file it came from) or **inferred**.

Present the statement and ask the user to correct it. One message, then wait. If the user answers *"just go"*, proceed with the inferred values and mark every candidate whose verdict depends on an inferred line.

### 2. Explore for over-building

Walk the codebase organically. Apply the fit test to anything heavier than its job, then the deletion test to confirm the verdict. **Use CodeGraphContext** (`mcp__cgc__execute_cypher_query`, `mcp__cgc__analyze_code_relationships`) for caller counts and implementation counts when available; otherwise grep and `git log`.

Seven smells. A smell becomes a finding only with the evidence in the right-hand column.

| Smell | What it looks like | Evidence required |
|---|---|---|
| **Speculative generality** | Seam with one Adapter; `Protocol`/ABC with one implementation; registry, strategy, or plugin pattern with one entry; parameters always passed the same value | Implementation count, call sites, `git log` showing no second case ever landed |
| **Dead or unreachable** | Modules with zero callers; endpoints no client calls; event types never emitted or consumed; columns written but never read; scripts or CLI commands nobody runs; settings that have held one value since introduction | CGC caller count, grep, `git log -S`, `.env.example` and config defaults |
| **Pass-through layering** | Chains where each layer forwards without transforming (handler → service → repository → session); wrappers that only rename a library's methods | Deletion test; lines in the layer vs lines of behaviour it adds |
| **Defensive over-engineering** | Retry, backoff, or circuit-breaker on in-process or never-failing calls; re-validation of already-validated data at each layer; exception hierarchies with one catch site | The failure it guards against, and whether it has ever occurred (git history, incident notes, logs if visible) |
| **Premature scale** | Caches, batching, queues, worker pools, sharding, pagination machinery for volumes the Envelope never reaches; multi-tenant plumbing for one business | Envelope numbers against the thresholds the code is built for |
| **Duplicate mechanisms** | Two ways to do one job: two HTTP client patterns, two config loaders, two event dispatch paths, two migration paths | Callers of each path; which one the newer code uses |
| **Process weight** | CI steps, scripts, environments, cron jobs, or runbook steps that cost more than they catch | Step duration, what it has caught (`git log` of the step, CI history), who runs it |

**In Prism**, the usual places to look: `*Client` wrappers and what sits between them and the `*Service` that uses them; retry or backoff decorators and what they actually wrap; `BaseChannelEventConsumer` subclasses and event types with no Emitter; `app/utils/` helpers with one caller; settings in `.env.example` that every environment sets identically; `.github/workflows/` steps and `scripts/` entries nobody has run since they landed.

**No evidence, no candidate.** A smell that pattern-matches but has nothing citable is not reported.

### 3. Present candidates

Rank deterministically and state the rule in one line above the list: **fewest risk flags first**, so the safe wins lead; within the same flag count, LOC cuts before architectural flattenings, LOC cuts by LOC descending, flattenings by Seams or layers removed descending.

For each numbered candidate:

- **Where** — files and Modules with paths. Domain nouns from `CONTEXT.md`, shape nouns from `architecture-language.md`.
- **Cut** — one of *delete*, *inline*, *flatten*, *replace with a library*, *collapse two mechanisms into one*. Measured LOC that would go, code and tests counted separately: `~420 LOC code + ~310 LOC tests`. Use `wc -l` for whole files; name the functions or classes for partial cuts. Architectural cuts with flat LOC say so: *"architectural: 3 layers → 1, LOC roughly flat."*
- **Envelope fact** — the specific Envelope line this candidate is measured against. If that line was inferred, say so.
- **Evidence** — the citations from step 2.
- **Risk needing human judgement** — zero or more of these, each naming the exact question a human must answer:
  - **Product** — a capability would disappear; is it wanted? (product owner)
  - **Data** — migration, data loss, or historical rows that depend on the code
  - **Operational** — behaviour under load or failure not derivable from code; needs metrics, logs, or incident memory
  - **Contractual** — a partner, channel API, or webhook expects the behaviour
  - **Intent** — an ADR, spec, or commit message records a reason; cite it; it may still hold
  - **Invisible** — the deciding evidence is production data the agent cannot see; name the data

  A candidate with no risk flags says so and lists the signals checked: *"No risk flagged: zero callers (CGC), no config reference, last touched 14 months ago, no ADR."*
- **ADR conflict** — only when the friction is real enough to warrant reopening; mark it (*"contradicts ADR-0004 — but worth reopening because…"*).

After the list, **Looked at and kept**: at most five one-liners for things that pattern-match a smell but pass the fit test, each with the Envelope fact that saves them. This shows the Envelope was applied and pre-empts *"what about X?"*.

Do not design the post-cut shape yet. Ask: *"Which of these would you like to explore?"*

### 4. Hand off for the chosen candidate

- **Any risk flagged** → hand off to `/audiotrader-workflow:grill`. Grill walks the cut with the user and its four-gate test decides whether a load-bearing removal becomes an ADR via `/audiotrader-workflow:adr-new`. Suggest:

  > `/audiotrader-workflow:grill "cut <Module> per candidate #N"`

- **No risk flagged** → no grilling. Say so, and suggest a deletion branch in a separate session with `/audiotrader-workflow:principal-review-correctness` before merge.
- **The cut would make complexity reappear** (the user, or the discussion, shows callers would each absorb it) → it was a deepening candidate all along. Suggest:

  > `/audiotrader-workflow:architecture-deepening "<Module>"`

Do **not** grill inline and do **not** implement.

### 5. When the user rejects a candidate

If the rejection carries a **load-bearing reason** — one a future hunt would need to know to avoid re-suggesting the cut (*"keep the retry layer, Reverb's API flakes weekly"*) — offer to record it:

> "Want me to record this as an ADR so future simplification hunts don't re-suggest it? `/audiotrader-workflow:adr-new "Keep <X>"`"

Skip the offer for ephemeral reasons (*"not now"*) or self-evident ones.

## Boundaries

- **Not the built-in `/simplify`.** That is diff-scoped code-quality cleanup that applies fixes. This is codebase-wide, asks whether the thing should exist at all, and modifies nothing.
- **Not `/audiotrader-workflow:architecture-deepening`.** Same deletion test, opposite verdict. Complexity that would reappear on deletion is theirs.
- **Not `/audiotrader-workflow:principal-review-duplication` or `/principal-review-organization`.** Those are branch-scoped; this surveys HEAD.
- **Not `/audiotrader-workflow:principal-review-guidelines`.** This is not a rule check.
- **Not a feature audit.** The command does not judge whether a capability is valuable from first principles. It flags **Product** risk and leaves the call to a human.
- **Not implementation.** Proposes, hands off, stops.

## Output

- Envelope statement, confirmed by the user
- Ranking rule, one line
- Numbered candidates with the structure in step 3
- Looked at and kept
- Hand-off suggestion for the chosen candidate
- Stay available if the user wants to explore another candidate

---

Process structure mirrors [`architecture-deepening.md`](./architecture-deepening.md), which was adapted from [`mattpocock/skills` — `improve-codebase-architecture`](https://github.com/mattpocock/skills/tree/main/skills/engineering/improve-codebase-architecture). The Envelope, the fit test, the smell table, and the risk classes are original to this plugin.
