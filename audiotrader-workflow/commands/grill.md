---
description: Interview-style grilling of an existing plan, spec, or design against the project's CONTEXT.md glossary and recorded ADRs. Surfaces contradictions, sharpens fuzzy terms, captures resolutions inline.
argument-hint: [<plan summary, spec path, or topic>]
---

Grill the user relentlessly about every aspect of `$ARGUMENTS` (or, if empty, ask what they want to stress-test, then continue). Walk down each branch of the design tree, resolving dependencies one at a time. For each question, propose your recommended answer. Ask one question at a time and wait for feedback before continuing. If a question can be answered by exploring the codebase or reading a spec, do that instead of asking.

## Three outputs

A grilling session produces:

1. **A sharper plan in the user's head** — the dominant value of most sessions; transient, no artefact.
2. **`CONTEXT.md` updates** — when a term gets resolved, captured inline as the conversation surfaces it.
3. **An ADR (occasionally)** — when a genuinely hard-to-reverse, surprising, real-trade-off decision emerges. Routed to `/audiotrader-workflow:adr-new`, not written inline.

The weighting shifts per session. Some grillings produce nothing on disk and that's correct. Don't manufacture artefacts to feel productive.

## Where things live

- **Glossary**: `CONTEXT.md` at the **project root** (the repo you're currently in). Every Audio Trader repo gets its own — Prism, Wise-Payments, Collection, Warehouse, Website, Pricing-worker — each owns its local domain language. If cross-repo glossary drift becomes louder than the cross-repo plumbing, lift to a workspace-level `CONTEXT-MAP.md`.
- **ADRs**: `docs/adr/` at the project root — convention is `ADR-NNNN-slug.md` per `docs/adr/adr.template.md` where one exists.

Create `CONTEXT.md` lazily — only when the first term is resolved during the session.

## Grilling moves

### Challenge against the glossary
When the user uses a term that conflicts with the existing language in `CONTEXT.md`, call it out immediately. "Your glossary defines `Listing` as X, but you seem to mean Y — which is it?"

### Sharpen fuzzy language
When the user uses vague or overloaded terms, propose a precise canonical term. "You're saying 'item' — do you mean the **Listing**, the **Lot**, or the underlying **Stock**? Those are different things."

### Discuss concrete scenarios
Stress-test domain relationships with specific scenarios. Invent edge cases that force the user to be precise about boundaries between concepts.

### Cross-reference with code
When the user states how something works, check whether the code agrees. If you find a contradiction, surface it: "Your reconciler emits one event per orphan, but you just said partial-batch handling is supported — which is right?"

### Update CONTEXT.md inline
When a term is resolved, update `<project-root>/CONTEXT.md` right there. Don't batch. Use the format in [`../references/context-md-format.md`](../references/context-md-format.md).

`CONTEXT.md` is a glossary — **totally devoid of implementation details**. Do not treat it as a spec, a scratch pad, or a repository for implementation decisions.

### Route ADR-worthy decisions to /adr-new
Only flag an ADR when all three are true:

1. **Hard to reverse** — cost of changing your mind later is meaningful
2. **Surprising without context** — a future reader will wonder "why did they do it this way?"
3. **The result of a real trade-off** — there were genuine alternatives and you picked one for specific reasons

If any of the three is missing, skip the ADR. When all three hold, suggest:

> `/audiotrader-workflow:adr-new "<short imperative title>"`

Do not author the ADR inline — `/adr-new` is the authoring tool and uses the project's existing template.

## Boundaries

- **Not brainstorming.** If the user is designing from scratch rather than stress-testing something that already exists, hand off to `superpowers:brainstorming`.
- **Not the ADR nudge.** `suggesting-adrs` fires as a one-shot during normal work. This command is an explicit grilling session — different rhythm.
- **One question at a time.** Don't overwhelm.
- **Prefer code over hypothesis.** If a question can be answered by reading the code or specs, read them rather than asking.

---

Originally adapted from [`mattpocock/skills` — `grill-with-docs`](https://github.com/mattpocock/skills/tree/main/skills/engineering/grill-with-docs). ADR authoring is delegated to `/audiotrader-workflow:adr-new` instead of inline writing, and the glossary location is project-root-relative rather than fixed.
