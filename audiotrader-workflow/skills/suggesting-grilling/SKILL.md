---
name: suggesting-grilling
description: Use when a plan, spec, or design is being committed to without being stress-tested — observable triggers are brainstorming-just-finished, about-to-invoke-writing-plans, about-to-start-implementation, touching revenue-critical surface area (payments, pricing, inventory accuracy, reconciliation, refunds, VAT, channel commissions), a new architectural shape being introduced (new bounded context, first use of a major pattern, new external integration), terminology drift against `CONTEXT.md`, or feature work that spans multiple Audio Trader bounded contexts. Symptoms include "let me start coding", "I'll write the implementation plan", a freshly-written spec file, mixed-up terminology, work touching payments / pricing / reconciliation / refunds, a first-of-its-kind pattern in the codebase. Nudges the user to run `/audiotrader-workflow:grill` once before momentum carries past. Skip for bug fixes, local refactors, single-function design, routine code that follows existing patterns, or work that's already been grilled this conversation.
---

# Suggesting grilling

## Why this matters

`/grill` is most valuable at the *pre-implementation moment* — after a spec is written, before an implementation plan is drafted, before code starts being committed. That moment is easy to miss: momentum carries everyone past it, and once code exists the cost of changing direction goes up.

This skill is a **nudge**. When the conversation crosses into "we're about to commit to this plan" territory, prompt the user to run `/audiotrader-workflow:grill` before that happens. Do not start grilling inline — that's `/grill`'s job. One nudge, easy to dismiss.

Sits alongside [[suggesting-adrs]]: ADR-nudges fire on a *specific decision* worth recording; grilling-nudges fire on a *whole plan* worth stress-testing. They can both fire correctly at different levels of granularity. Pairs with `superpowers:brainstorming` — brainstorming produces a spec, this nudge fires once the spec exists.

## When to fire

Fire when at least one of these signals is present:

- **Brainstorming just finished** — `superpowers:brainstorming` just completed and a spec file was written or committed. This is the canonical pre-plan-writing moment.
- **About to invoke `writing-plans`** — user is about to convert a spec into an implementation plan. Last call to grill before commitment.
- **About to start implementation** — user just said "let me start coding", "I'll start on this now", or began editing implementation files for a plan that hasn't been grilled.
- **Touching revenue-critical surface area** — payment flow (Wise-Payments, future Modulr), pricing logic, inventory accuracy (oversell = chargeback), reconciliation (orphans = money loss), refund handling, VAT/tax calculation, channel commissions. False-positives are tolerable here because the cost of a missed revenue bug is asymmetric — over-grill rather than under-grill.
- **New architectural shape being introduced** — a new bounded context (new repo, new service), the first use of a major pattern in this codebase (CQRS, event sourcing, saga, projector, outbox, etc.), or a new external system being integrated (new channel, new payments provider, new analytics destination). Routine new code that follows existing patterns doesn't count.
- **Cross-context boundary work** — the feature spans multiple Audio Trader repos (Prism + Wise-Payments, Prism + Collection, Warehouse, etc.). Boundaries between contexts are the highest-value grilling targets.
- **Terminology drift** — the user uses 2+ words for what's probably the same concept ("the listing... or item... or stock..."), or a term that conflicts with `CONTEXT.md` if it exists. Mechanical check: read `CONTEXT.md`, look for collisions.
- **Stated-and-shrugged gap** — user names an unresolved question and moves past it without resolving ("we'll figure that out later"), and then continues planning as if it were resolved.

## When NOT to fire

- Bug fix or test fix
- Local refactor or single-function design
- Work that's already been grilled this conversation (track it)
- The user has explicitly said "skip grilling", "I'll handle it", or has dismissed the nudge once for this plan
- Mid-implementation — the moment has mostly passed; interrupting active editing is more cost than value
- Toy or throwaway code
- A plan with only one obvious shape and no domain language at stake

## What to do when triggered

1. **State the plan** as you understand it from the conversation, in one specific sentence. "We're about to implement the Wise-Payments retry handler" beats "we're starting some work".
2. **Name the signal** that triggered the nudge — terminology drift, pre-plan-writing, cross-boundary, stated-and-shrugged gap, etc. One word or short phrase.
3. **Articulate why grilling pays off here** in one sentence — what specifically would a grilling session catch?
4. **Recommend `/grill`** with a suggested short topic argument.
5. **Stop**. One nudge is enough. If the user defers, declines, or says "I'll handle it" — drop it.

## Output format

A single short message, easy to dismiss:

```
[Grilling moment detected]

Plan under discussion: <one specific sentence>
Signal: <pre-plan-writing | pre-implementation | terminology drift | cross-context boundary | stated-and-shrugged gap | brainstorming-just-finished>
Why grilling pays off here: <one sentence — what specifically would it catch>

Suggested next step:
    /audiotrader-workflow:grill "<short topic>"

(Reply "skip" or "later" to dismiss.)
```

If the user accepts, hand off to `/grill` and stop. If the user dismisses, do not raise it again in this conversation for the same plan.

## Red flags

- **Firing on every plan.** Plans naturally have gaps; that's not enough. At least one signal from the *When to fire* list must be present.
- **Pushing back when the user declines.** The user has more context than you do. One nudge per plan.
- **Drafting the grilling questions inline.** Scope is *suggestion only* — `/grill` is the grilling tool.
- **Mid-implementation interruption.** If the user is already coding, the moment has mostly passed. Don't fire just because you noticed something *could* have been grilled.
- **Re-firing for the same plan.** Track which plan was nudged and don't repeat in the same conversation.
- **Firing when grilling already happened.** If a grilling session was completed earlier in the conversation, the work is done.
- **Treating every brainstorming completion as a grilling moment.** Brainstorming already explored the design. Grilling-after-brainstorming pays off when the spec is non-trivial (cross-boundary, domain-heavy, multiple sub-decisions) — not for every spec.
