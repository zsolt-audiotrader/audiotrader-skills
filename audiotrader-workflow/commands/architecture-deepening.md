---
description: Codebase-wide hunt for shallow modules and deepening opportunities. Surfaces architectural friction, proposes refactors that turn shallow modules deep, hands off to /grill for the candidate the user picks. Routes load-bearing rejections to /adr-new. Uses the vocabulary in references/architecture-language.md.
argument-hint: [<area to focus on, e.g. "channel_sync" or "inventory">]
---

Hunt for **deepening opportunities** in the codebase. Surface modules where the Interface is nearly as complex as the Implementation, propose refactors that turn shallow modules into deep ones. Use precise architectural vocabulary from `references/architecture-language.md` — **Module**, **Interface**, **Depth**, **Seam**, **Adapter**, **Leverage**, **Locality**.

The aim is testability and AI-navigability.

If `$ARGUMENTS` is provided, focus the hunt on that area. Otherwise scan the whole codebase.

## Glossary commitment

This command commits to the vocabulary in [`../references/architecture-language.md`](../references/architecture-language.md). Use these terms exactly in every suggestion. Don't drift into "component", "boundary", or generic "service" (the codebase uses `Service` as a specific noun for a kind of Module — respect the distinction). Consistent language is the point.

Defer to `CONTEXT.md` for the codebase's domain vocabulary (Listing, Stock, Channel, Reconciler, Emitter, etc.). Architecture vocabulary describes the *shape*; domain vocabulary describes the *thing*. Use both — *"deepening the **Reconciler** Module's Interface"* reads better than *"deepening the event-coordination module"*.

## Process

### 1. Explore

Read first:

- `CONTEXT.md` at the project root (domain glossary, if it exists)
- `docs/adr/*.md` — surface decisions the hunt should not re-litigate
- `docs/ARCHITECTURE.md` and `CODING_GUIDELINES.md` — the documented shape and the team's rules

Then walk the codebase. Don't follow rigid heuristics — explore organically and note where you experience friction:

- Where does understanding one concept require bouncing between many small Modules?
- Where are Modules **shallow** — Interface nearly as complex as the Implementation?
- Where have pure functions been extracted just for testability, but the real bugs hide in how they're called (no **Locality**)?
- Where do tightly-coupled Modules leak across their Seams?
- Which parts of the codebase are untested, or hard to test through their current Interface?

Apply the **deletion test** to anything you suspect is shallow: would deleting it concentrate complexity, or just move it? A "yes, concentrates" is the signal you want.

For Python codebases, see [`../references/deepening-techniques-python.md`](../references/deepening-techniques-python.md) for stack-specific patterns: Protocol vs ABC, async-as-Seam, in-memory SQLite vs testcontainers, constructor-injected DI as a Seam.

**Use CodeGraphContext** (`mcp__cgc__execute_cypher_query`, `mcp__cgc__analyze_code_relationships`) for impact analysis if available. Mechanical signals from CGC:

- Modules with high incoming-import count + complex Interface = strong deepening candidates
- Tight bidirectional clusters = a `package/` waiting to emerge
- Modules with one caller = candidates for inlining (anti-deepening: collapse, not deepen)

### 2. Present candidates

Present a numbered list of deepening opportunities. For each candidate:

- **Files** — which files / Modules are involved (with paths)
- **Problem** — why the current architecture is causing friction
- **Solution** — plain English description of what would change
- **Benefits** — explained in terms of **Leverage** (what callers gain) and **Locality** (what maintainers gain), and how tests would improve

**Use CONTEXT.md vocabulary for the domain, and `architecture-language.md` vocabulary for the architecture.** If CONTEXT.md defines "Listing", talk about *"the Listing intake Module"* — not *"the ShopifyHandler"*, not *"the Listing service"* (unless the actual class is named `ListingService`).

**ADR conflicts**: if a candidate contradicts an existing ADR, surface it only when the friction is real enough to warrant revisiting the ADR. Mark it clearly (_"contradicts ADR-0007 — but worth reopening because…"_). Don't list every theoretical refactor an ADR forbids.

Do NOT propose Interfaces yet. Ask the user: *"Which of these would you like to explore?"*

### 3. Hand off to /grill for the chosen candidate

Once the user picks a candidate, hand off to `/audiotrader-workflow:grill` with the candidate as the topic. `/grill` will walk the design tree with them — constraints, dependencies, the shape of the deepened Module, what sits behind the Seam, what tests survive.

Do **not** start grilling inline. `/grill` is the grilling tool. Suggest:

> `/audiotrader-workflow:grill "deepen <module-name> per candidate #N"`

### 4. Side effects during grilling

The grilling session (running under `/grill`) will:

- **Update CONTEXT.md inline** when domain terminology gets resolved
- **Offer ADR creation** when a load-bearing decision emerges (handed off to `/audiotrader-workflow:adr-new`)
- **Optionally explore alternative Interface shapes** via [`../references/interface-design.md`](../references/interface-design.md) — the parallel-sub-agent "design it twice" pattern

### 5. When the user rejects a candidate

If the user rejects a candidate with a **load-bearing reason** (one a future explorer would need to know to avoid re-suggesting the same thing), offer to record it as an ADR:

> "Want me to record this as an ADR so future architecture reviews don't re-suggest it? `/audiotrader-workflow:adr-new "<short imperative title>"`"

Skip the offer for ephemeral reasons ("not worth it right now") or self-evident ones.

## Boundaries

- **Not branch-scoped.** This command surveys the codebase at HEAD. For branch-scoped structural review (placement of new code, folder strain), use `/audiotrader-workflow:principal-review-organization` — they're complementary.
- **Not the structural rule check.** `/audiotrader-workflow:principal-review-guidelines` verifies `CODING_GUIDELINES.md` compliance (Dependency Rule, naming rules). This is different — it asks whether the *shape* is right, not whether the *rules* are followed.
- **Not implementation.** This command proposes refactors and hands off to grilling. It does not modify code. If the user accepts a deepening, the implementation is a separate session.

## Output

- Numbered list of candidates with the structure above
- Hand off to `/grill` for the chosen candidate
- Stay available for follow-up if the user wants to explore another candidate

---

Originally adapted from [`mattpocock/skills` — `improve-codebase-architecture`](https://github.com/mattpocock/skills/tree/main/skills/engineering/improve-codebase-architecture). The grilling phase is delegated to `/audiotrader-workflow:grill`, ADR authoring to `/audiotrader-workflow:adr-new`. The vocabulary is preserved verbatim where load-bearing and adapted where the AudioTrader codebase has established its own terms (Service / Client / Emitter / Consumer / Reconciler).
