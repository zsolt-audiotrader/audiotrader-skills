---
name: suggesting-adrs
description: Use when the conversation involves an architectural decision — comparing 2+ technical alternatives that are load-bearing or hard to reverse, switching providers/vendors/libraries, introducing a cross-cutting pattern, adding a new external integration, or choosing infrastructure/deployment shape. Symptoms include "should we use X or Y", "switching from A to B", weighing pros/cons of approaches, deciding the shape of a new integration/store/queue. Skip for local refactors, naming choices, bug fixes, function-level design.
---

# Suggesting ADRs

## Why this matters

The Audio Trader Prism project records architectural decisions as ADRs in `docs/adr/`. Their value is in being written *while the trade-offs are fresh* — six months later the rationale is lost and the decision looks arbitrary in code review and onboarding.

This skill is a **nudge**. When a conversation crosses into "we're making an architectural decision" territory, prompt the user to capture it via `/adr-new` before momentum carries everyone past the moment. Do not author the ADR inline — that's the user's call.

## When to fire

Fire when the conversation shows one of these signals:

- **Comparing alternatives** — 2+ technical options being weighed (libraries, services, patterns, providers, deployment strategies)
- **Provider / vendor switch** — moving from X to Y where X is load-bearing (e.g. payments provider, analytics, queue tech)
- **New external integration** — adding a 3rd-party service, vendor, or partner system
- **New infrastructure component** — adding a queue, cache, message broker, store, scheduler
- **Cross-cutting pattern** — shaping auth, logging, error handling, observability for the codebase
- **Deployment / topology change** — changing how the system is deployed, scaled, or split
- **Deliberate deviation** — current code does X but new code is being designed to do Y, and the divergence is intentional

## When NOT to fire

- Local refactor, naming choice, single-function design
- Bug fix or test fix
- Reversible-in-a-single-PR decisions
- The user has already said "I'll write an ADR" — they know
- The decision is already captured in an existing ADR — link to it instead

## What to do when triggered

1. **State the decision** as you understand it from the conversation, in one specific sentence. "We're considering moving payments from Wise to Modulr" beats "we're making a payments decision".
2. **List the alternatives** that have been discussed. If only one option appears in chat, ask the user what was rejected — ADRs without alternatives are red flags per `docs/adr/adr.template.md`.
3. **Articulate why it's ADR-worthy** in one sentence — long-term consequence, hard to reverse, cross-cutting impact, or commits the team to a vendor/pattern.
4. **Recommend `/adr-new`** with a suggested short imperative title.
5. **Stop**. One nudge is enough. If the user defers, declines, or says "I'll handle it" — drop it.

## Output format

A single short message, easy to dismiss:

```
[ADR moment detected]

Decision under discussion: <one specific sentence>
Alternatives considered: <list, or "(only one mentioned — what was rejected?)">
Why it warrants an ADR: <one sentence — long-term consequence / hard to reverse / cross-cutting>

Suggested next step:
    /audiotrader-workflow:adr-new "<short imperative title>"

(Reply "skip" or "later" to dismiss.)
```

If the user accepts, hand off to `/adr-new` and stop. If the user dismisses, do not raise it again in this conversation for the same decision.

## Red flags

- **Firing on every decision**. Naming choices, local refactors, and bug fixes are not ADR moments. Re-read the trigger list before firing.
- **Pushing back when the user declines**. The user has more context than you do. One nudge per decision.
- **Drafting the ADR inline**. Scope is *suggestion only* — `/adr-new` is the authoring tool.
- **Mid-implementation interruption**. If the decision was already made and the user is now coding, the moment has mostly passed. A retrospective ADR is fine but flag it at a sensible breakpoint (end of the feature, before merge), not mid-edit.
- **Assuming an alternative was rejected for a reason you'd accept**. Ask the user — the rejection rationale is the most valuable part of the ADR.
