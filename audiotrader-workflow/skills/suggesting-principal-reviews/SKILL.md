---
name: suggesting-principal-reviews
description: Use when work is wrapping up and about to ship — the user asks to create a PR ("create the PR", "open a PR", `gh pr create`), is about to push accumulated work on main (`git push origin main`, "ship it", "we're done", "let's wrap up", "EOD"), or `finishing-a-development-branch` is running or about to run. Skip for trivial or doc-only diffs, and when the review trinity already ran on this work in this conversation.
---

# Suggesting principal reviews

## Why this matters

The review trinity — correctness, architecture, guidelines — is most valuable at the *last moment before shipping*, and that moment is exactly when momentum skips it. Left unprompted, the natural move is to suggest an ad-hoc subset ("let's run correctness and the QA review") and silently drop the rest — most often the architecture review, precisely on branches with migrations where its schema section matters most.

This skill is a **nudge**, modeled on [[suggesting-grilling]]: one short message recommending the trinity in its canonical order, easy to dismiss. Do not start reviewing inline — the slash commands are the review tools.

## When to fire

Fire when a wrap-up cue appears **and** the work hasn't been trinity-reviewed this conversation:

- **PR about to be created** — "create the PR", "open a PR", about to run `gh pr create`
- **Main-branch wrap-up** — the user works directly on `main` without PRs: about to `git push origin main` with accumulated commits, or says "ship it", "we're done", "deployed", "let's wrap up", "EOD"
- **`finishing-a-development-branch`** is running or about to run

## Size gate

Measure the diff on the same range the review commands will use — feature branch: against the default branch; on `main`: the unpushed range `@{u}..HEAD`.

- **Substantial** (2+ modules touched, **or** any migration/model change present, **or** a new external integration): suggest the **full trinity**.
- **Small** (single module, no schema changes): suggest `/principal-review-correctness` alone.
- **Trivial** (docs, comments, config-only, test-only tweaks): don't fire.

## The canonical order — and why it is not negotiable

Rework cascades top-down; each review's failure invalidates the polish the later ones would apply:

1. `/audiotrader-workflow:principal-review-correctness` — built the wrong thing? Nothing else matters.
2. `/audiotrader-workflow:principal-review-architecture` — wrong pattern, ADR conflict, or wrong schema shape rewrites code that line-level review would have polished pointlessly.
3. `/audiotrader-workflow:principal-review-guidelines` — line-level quality last, once outcome and structure are settled.

**The trinity is a fixed set, not a menu.** Do not substitute members ("tests review instead of guidelines"), and do not drop the architecture review because "the migration only adds new tables" or "tests pass" — new tables are exactly what its schema section renders, and green tests say nothing about ADR conformance. The other review commands (`tests`, `mutation`, `duplication`, `organization`, `qa-feature-review`) have their own triggers; mention them only if the user asks what else is available.

## Output format

A single short message, easy to dismiss:

```
[Pre-ship review moment]

Work wrapping up: <one specific sentence>
Scope: <N files, M modules, migrations yes/no> → <full trinity | correctness only>

Suggested order before shipping:
    1. /audiotrader-workflow:principal-review-correctness
    2. /audiotrader-workflow:principal-review-architecture
    3. /audiotrader-workflow:principal-review-guidelines

(Reply "skip" to ship without them.)
```

If the user accepts, run the commands in order, fixing findings between steps. If the user dismisses, ship without further comment and do not raise it again for this work.

## Red flags

- **Suggesting a subset or substitute of the trinity.** Correctness + QA is not the trinity. The set and order are fixed; the size gate is the only sanctioned reduction.
- **Dropping the architecture review on migration branches.** That's the highest-value case for it, not an exemption.
- **Firing on trivial diffs.** A one-file fix pushed to main doesn't need three reviews — the nudge must stay cheap to keep.
- **Reviewing inline instead of nudging.** Scope is *suggestion only*; the slash commands do the reviewing.
- **Re-firing after dismissal.** One nudge per shippable unit of work.
- **Blocking the ship.** This is advisory. If the user says push, push.
