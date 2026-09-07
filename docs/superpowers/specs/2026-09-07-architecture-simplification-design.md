# /architecture-simplification — over-building hunt

**Date**: 2026-09-07
**Status**: Proposed
**Artifact**: `audiotrader-workflow/commands/architecture-simplification.md`

## Problem

`/architecture-deepening` hunts for Modules whose complexity is in the wrong place and proposes concentrating it. It has no counterpart for complexity that should not exist at all. The codebase carries machinery built for conditions production never presents — Seams with one Adapter, resilience for calls that never fail, scale plumbing for volumes that never arrive, layers that forward without transforming, processes that cost more than they catch. Deepening mentions this case only as a footnote ("anti-deepening: collapse, not deepen").

Generic "simplify" advice fails here because it has no definition of what production actually needs. Without that anchor every simplification hunt degrades into YAGNI opinions that the reader cannot verify.

The question the command must answer: *which system, subsystem, or process is over-complicated for our production use, could be cut in lines of code and/or simplified architecturally, why, and what risk needs further assessment or human judgement?*

## Decision

Add a user-invoked slash command, `/audiotrader-workflow:architecture-simplification [<area>]`, as a sibling of `/architecture-deepening`. It is a command, not an auto-trigger skill — a hunt is a deliberate act.

The two commands share one test with two verdicts. The **deletion test** (already in `references/architecture-language.md`): imagine deleting the Module. If complexity **reappears** across callers, the Module was earning its keep — a deepening candidate. If complexity **vanishes**, the Module was hiding nothing — a simplification candidate. Each verdict routes to its hunt.

The command anchors "our production use" in a new vocabulary term, the **Envelope**, inferred from docs and confirmed with the user at the start of every run. The Envelope is not persisted.

## Vocabulary additions to `references/architecture-language.md`

**Envelope**
The range of conditions production actually operates in: scale (orders, listings, events per day, as orders of magnitude), tenancy, live versus planned integrations, operators, team size, deploy shape, uptime expectation. Architecture is judged against the Envelope, not against what the code could handle.
_Avoid_: "requirements" (aspirational), "load" (too narrow), "non-functionals" (jargon).

> **In Prism:** one business, one deploy, a handful of operators, a fixed set of live channels. Established per session by `/architecture-simplification` from docs plus user confirmation; not written to disk.

**The fit test** (new principle, placed directly after the deletion test)
Ask what production exercises through this Interface, then what the Implementation handles that production never presents. The excess is a simplification candidate — if the deletion test agrees that removing it makes complexity vanish rather than reappear.

**Verdict routing** (appended to the deletion test)
Complexity reappears → `/audiotrader-workflow:architecture-deepening`. Complexity vanishes → `/audiotrader-workflow:architecture-simplification`.

**Relationships** (one added line)
The **Envelope** bounds which behaviour a Module's **Depth** is measured against.

## Behaviour

### 1. Establish the Envelope

Read, where present: `CONTEXT.md`, `docs/adr/*.md`, `docs/ARCHITECTURE.md`, `README.md`, `CODING_GUIDELINES.md`, current `specs/`, deploy configuration (Dockerfile, compose, `wrangler.toml`, `.github/workflows/`), `.env.example`.

Produce an Envelope statement of at most eight lines covering: scale, tenancy, live vs planned integrations, operators, team size and deploy shape, uptime expectation. Mark each line **documented** (with its source) or **inferred**.

Present it and ask the user to correct it. One message. **Do not hunt before confirmation.** If the user says "just go", proceed with the inferred values and mark every candidate whose verdict depends on an inferred line.

If `$ARGUMENTS` names an area, the Envelope still covers the whole system; the hunt in step 2 narrows to the area.

### 2. Explore for over-building

Walk the codebase organically, as deepening does. Apply the **fit test** to anything that looks heavier than its job, then the **deletion test** to confirm the verdict. Use CodeGraphContext (`mcp__cgc__execute_cypher_query`, `mcp__cgc__analyze_code_relationships`) for caller counts and implementation counts when available.

Seven smells, each with the evidence that makes it a finding:

| Smell | What it looks like | Evidence required |
|---|---|---|
| **Speculative generality** | Seam with one Adapter; `Protocol`/ABC with one implementation; registry, strategy, or plugin pattern with one entry; parameters always passed the same value | Implementation count, call sites, `git log` showing no second case ever landed |
| **Dead or unreachable** | Modules with zero callers; endpoints no client calls; event types never emitted or consumed; columns written but never read; scripts or CLI commands nobody runs; settings that have held one value since introduction | CGC caller count, grep, `git log -S`, `.env.example` and config defaults |
| **Pass-through layering** | Chains where each layer forwards without transforming (handler → service → repository → session); wrappers that only rename a library's methods | Deletion test; lines in the layer vs lines of behaviour it adds |
| **Defensive over-engineering** | Retry, backoff, or circuit-breaker on in-process or never-failing calls; re-validation of already-validated data at each layer; exception hierarchies with one catch site | The failure it guards against, and whether that failure has ever occurred (git history, incident notes, logs if visible) |
| **Premature scale** | Caches, batching, queues, worker pools, sharding, pagination machinery for volumes the Envelope never reaches; multi-tenant plumbing for one business | Envelope numbers against the thresholds the code is built for |
| **Duplicate mechanisms** | Two ways to do one job: two HTTP client patterns, two config loaders, two event dispatch paths, two migration paths | Callers of each path; which one the newer code uses |
| **Process weight** | CI steps, scripts, environments, cron jobs, or runbook steps that cost more than they catch | Step duration, what it has caught (`git log` of the step, CI history), who runs it |

**No evidence, no candidate.** A smell that pattern-matches but has no citable evidence is not reported.

### 3. Present candidates

A numbered list, ranked deterministically: **fewest risk flags first**, so the safe wins lead. Within the same flag count, LOC cuts come before architectural flattenings, LOC cuts ordered by LOC descending, flattenings by Seams or layers removed descending. State the ranking rule in one line above the list.

For each candidate:

- **Where** — files and Modules with paths. Use `CONTEXT.md` nouns for the domain and `architecture-language.md` nouns for the shape, exactly as deepening does.
- **Cut** — one of: delete, inline, flatten, replace with a library, collapse two mechanisms into one. Measured LOC that would go, code and tests counted separately (`~420 LOC code + ~310 LOC tests`), from `wc -l` for whole files or named functions/classes for partial cuts. Architectural cuts with flat LOC say so: *"architectural: 3 layers → 1, LOC roughly flat."*
- **Envelope fact** — the specific Envelope line this candidate is measured against. If that line was inferred, say so.
- **Evidence** — the citations from step 2.
- **Risk needing human judgement** — zero or more of a fixed set, each naming the exact question a human must answer:
  - **Product** — a capability would disappear; is it wanted? (product owner)
  - **Data** — migration, data loss, or historical rows that depend on the code
  - **Operational** — behaviour under load or failure not derivable from code; needs metrics, logs, or incident memory
  - **Contractual** — a partner, channel API, or webhook expects the behaviour
  - **Intent** — an ADR, spec, or commit message records a reason; cite it; it may still hold
  - **Invisible** — the deciding evidence is production data the agent cannot see; name the data

  A candidate with no risk flags must say so explicitly and list the signals checked: *"No risk flagged: zero callers (CGC), no config reference, last touched 14 months ago, no ADR."*
- **ADR conflicts** — same rule as deepening: surface only when the friction is real enough to warrant reopening, and mark it.

After the list, a short **Looked at and kept** section: at most five one-liners for things that pattern-match a smell but pass the fit test, each with the Envelope fact that saves them. This proves the Envelope was applied and pre-empts "what about X?".

Do not propose the post-cut shape in detail. Ask: *"Which of these would you like to explore?"*

### 4. Hand off

- **Any risk flagged** → `/audiotrader-workflow:grill "cut <Module> per candidate #N"`. Grill's four-gate test decides whether a load-bearing removal becomes an ADR via `/adr-new`.
- **No risk flagged** → no grilling. Say so, and suggest a deletion branch in a separate session with `/audiotrader-workflow:principal-review-correctness` before merge.
- **A candidate turns out to reappear on deletion** (the user or the discussion shows complexity would spread across callers) → hand to `/audiotrader-workflow:architecture-deepening "<Module>"` instead of proposing a cut.

### 5. When the user rejects a candidate

If the rejection carries a **load-bearing reason** — one a future hunt would need to know to avoid re-suggesting the cut ("keep the retry layer, Reverb's API flakes weekly") — offer to record it:

> `/audiotrader-workflow:adr-new "Keep <X>"`

Skip the offer for ephemeral reasons ("not now") or self-evident ones.

### Boundaries

- **Not the built-in `/simplify`.** That is diff-scoped code-quality cleanup that applies fixes. This is codebase-wide, asks whether the thing should exist, and modifies nothing.
- **Not `/architecture-deepening`.** Same deletion test, opposite verdict. Cross-link both ways.
- **Not `/principal-review-duplication` or `/principal-review-organization`.** Those are branch-scoped.
- **Not `/principal-review-guidelines`.** This is not a rule check.
- **Not a feature audit.** The command does not judge whether a capability is valuable from first principles. It flags **Product** risk and leaves the call to a human.
- **Not implementation.** Proposes, hands off, stops.

### Output

- Envelope statement, confirmed
- Ranking rule, one line
- Numbered candidates with the structure above
- Looked at and kept
- Hand-off suggestion for the chosen candidate
- Stay available for another candidate

## Non-goals

- No persisted Envelope file in target repos. Revisit if per-run confirmation proves repetitive.
- No auto-triggering. The command never fires on inferred over-building.
- No stack-specific reference file (a `simplification-smells-python.md` sibling to `deepening-techniques-python.md`). Prism-specific examples live inline in the command until a second consumer appears.
- No change to `/diagnose`'s post-mortem routing. Routing "the bug lived in over-built machinery" to this command is a plausible follow-up, out of scope here.

## Repo mechanics

- **New**: `audiotrader-workflow/commands/architecture-simplification.md` (frontmatter: `description`, `argument-hint: [<area to focus on>]`). Footer notes that the process structure mirrors `architecture-deepening.md`, itself adapted from `mattpocock/skills`.
- **Edit**: `audiotrader-workflow/references/architecture-language.md` — Envelope term, fit test, verdict routing, relationships line, per the section above.
- **Edit**: `audiotrader-workflow/commands/architecture-deepening.md` — Boundaries gains *"Not the simplification hunt. When the deletion test says complexity vanishes, that is `/architecture-simplification`'s candidate, not ours."*
- **Edit**: `NOTICES.md` — add the new command to the mattpocock-derived file list (structure adapted via `architecture-deepening.md`).
- **Edit**: `audiotrader-workflow/README.md` — command table row after `architecture-deepening`; suggested-workflow section unchanged.
- **Edit**: `README.md` — 15 → 16 user-invoked commands.
- **Edit**: `audiotrader-workflow/.claude-plugin/plugin.json` — version `0.9.1` → `0.10.0`.
- **Edit**: `.claude-plugin/marketplace.json` — version `0.7.0` → `0.10.0` (currently drifted) and description counts (7 → 8 skills, 13 → 16 commands).
- **Test** per the contributing guide, in an `audiotrader-prism` checkout: run a fresh session without the command and ask the raw prompt; then run the command. Verify the command (a) stops for Envelope confirmation before hunting, (b) reports only candidates with citable evidence, (c) gives every candidate an Envelope fact, LOC or architectural measure, and a risk class or an explicit "no risk flagged" with signals listed, (d) hands off rather than editing code.
- Branch `feat/architecture-simplification`, PR, squash-merge.
