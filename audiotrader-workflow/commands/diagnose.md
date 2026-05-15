---
description: Disciplined feedback-loop construction and instrumentation for hard bugs. Builds a fast deterministic pass/fail signal, ranks falsifiable hypotheses, instruments deliberately, validates the regression-test seam, and routes architectural findings to /architecture-deepening at post-mortem. Assumes `superpowers:systematic-debugging` provides the underlying discipline framing.
argument-hint: [<bug description or failing test path>]
---

Diagnose a hard bug with discipline. The value here is **technique**: feedback-loop construction, ranked falsifiable hypotheses, deliberate instrumentation, and seam-aware regression testing. The *discipline* framing — "no fixes without root cause" — is provided by `superpowers:systematic-debugging`, which fires automatically on bug encounters. Use this command when the bug is hard enough that the deeper technique is worth the overhead.

If `$ARGUMENTS` is provided, treat it as the bug description or the failing test path. Otherwise ask what's being diagnosed.

## What this command adds beyond systematic-debugging

`superpowers:systematic-debugging` enforces the discipline of finding root cause before fixing. This command adds:

- **A concrete feedback-loop menu** (10 shapes — pick one, iterate on it)
- **Ranked falsifiable hypotheses** (3–5, shown to user before testing) instead of single-hypothesis-at-a-time
- **Tagged-instrumentation discipline** for clean removal
- **Seam-aware regression-test placement** (if there's no correct seam, that's a finding, not a missing test)
- **An explicit post-mortem step** that hands architectural findings to `/audiotrader-workflow:architecture-deepening`

Use this when the bug has survived a quick `systematic-debugging` pass, or when you know upfront it's a multi-day investigation.

## Phases

### Phase 1 — Build a feedback loop

**This is the skill.** Everything else is mechanical. If you have a fast, deterministic, agent-runnable pass/fail signal for the bug, you will find the cause — bisection, hypothesis-testing, and instrumentation all just consume that signal. If you don't, no amount of staring at code will save you.

Spend disproportionate effort here. Be aggressive. Be creative. Refuse to give up.

**Ways to construct one — try them in roughly this order:**

1. **Failing pytest** at whatever seam reaches the bug — unit, integration, e2e. Run with `pytest -x path/to/test.py::test_name -v`, or `pytest --pdb` to drop into a debugger on failure.
2. **`curl` or `httpx` script** against a running `uvicorn` dev server.
3. **Python CLI invocation** with a fixture input, diffing stdout against a known-good snapshot.
4. **Headless browser** (Playwright) — drives the UI, asserts on DOM / console / network.
5. **Replay a captured trace.** Save a real webhook payload / event row / API response to disk; replay it through the code path in isolation. Particularly useful for marketplace event consumers (eBay, Reverb, Shopify, GMC).
6. **Throwaway harness.** Spin up a minimal subset (one `*Service`, mocked `*Client`s, in-memory `AsyncSession`) that exercises the bug code path with a single function call.
7. **Property / fuzz loop.** If the bug is "sometimes wrong output", run 1000 random inputs with `hypothesis` and look for the failure mode.
8. **Bisection harness.** If the bug appeared between two known states (commit, schema version, dataset), automate "boot at state X, check, repeat" so `git bisect run` can do the work.
9. **Differential loop.** Run the same input through old-version vs new-version (or SQLite vs Postgres) and diff outputs.
10. **HITL bash script.** Last resort. If a human must click, drive *them* with a script so the loop is still structured. Captured output feeds back to you.

**Iterate on the loop itself.** Once you have *a* loop, ask:

- Can I make it faster? (Cache fixtures, skip unrelated init, narrow test scope, `pytest --lf` for last-failed.)
- Can I make the signal sharper? (Assert on the specific symptom, not "didn't crash".)
- Can I make it more deterministic? (Pin time with `freezegun`, seed RNG, freeze HTTP with `respx` or `vcr.py`, isolate the test DB.)

A 30-second flaky loop is barely better than no loop. A 2-second deterministic loop is a debugging superpower.

**Non-deterministic bugs.** The goal is not a clean repro but a **higher reproduction rate**. Loop the trigger 100×, parallelise with `pytest -n auto`, add stress, narrow timing windows, inject `asyncio.sleep(0)` to interleave coroutines. A 50%-flake bug is debuggable; 1% is not — keep raising the rate until it's debuggable.

**When you genuinely cannot build a loop.** Stop and say so explicitly. List what you tried. Ask the user for: (a) access to whatever environment reproduces it, (b) a captured artifact (HAR file, log dump, DB row export, screen recording with timestamps), or (c) permission to add temporary production instrumentation. Do **not** proceed to hypothesise without a loop.

Do not proceed to Phase 2 until you have a loop you believe in.

### Phase 2 — Reproduce

Run the loop. Watch the bug appear.

Confirm:

- [ ] The loop produces the failure mode the **user** described — not a different failure that happens to be nearby. Wrong bug = wrong fix.
- [ ] The failure is reproducible across multiple runs (or, for non-deterministic bugs, reproducible at a high enough rate to debug against).
- [ ] You have captured the exact symptom (error message, wrong output, slow timing, missing DB row, unexpected event status) so later phases can verify the fix actually addresses it.

Do not proceed until you reproduce the bug.

### Phase 3 — Hypothesise

Generate **3–5 ranked hypotheses** before testing any of them. Single-hypothesis generation anchors on the first plausible idea.

Each hypothesis must be **falsifiable** — state the prediction it makes:

> Format: "If <X> is the cause, then <changing Y> will make the bug disappear / <changing Z> will make it worse."

If you cannot state the prediction, the hypothesis is a vibe — discard or sharpen it.

**Show the ranked list to the user before testing.** They often have domain knowledge that re-ranks instantly ("we just deployed a change to #3 yesterday", "I already ruled out #1"), or know hypotheses they've ruled out elsewhere. Cheap checkpoint, big time saver. Don't block on it — proceed with your ranking if the user is AFK.

### Phase 4 — Instrument

Each probe must map to a specific prediction from Phase 3. **Change one variable at a time.**

**Tool preference, in order:**

1. **Debugger / REPL inspection** if the env supports it. One breakpoint beats ten log lines.
   - `breakpoint()` in the code, or `pytest --pdb` to drop in on failure
   - For asyncio: `asyncio.get_event_loop().set_debug(True)` reveals slow-callback / cancellation issues; `asyncio.all_tasks()` shows what's currently running
2. **Targeted structured logs** at the boundaries that distinguish hypotheses.
3. **Never** "log everything and grep".

**Tag every debug log** with a unique prefix so cleanup is one command. In Prism (which uses `structlog`):

```python
log = log.bind(debug_tag="a4f2")
log.info("entering_reconciler", premise_check=premise.ok, anchor=event.anchor_id)
```

Cleanup at the end: `git grep 'debug_tag=' packages/prism/` and remove. Untagged logs survive accidentally; tagged logs die deliberately.

**Perf branch.** For performance regressions, logs are usually wrong. Instead:

- Establish a baseline measurement (`pytest-benchmark`, `time.perf_counter()`, `cProfile`, or `EXPLAIN ANALYZE` for SQL)
- Bisect (commit-by-commit, or feature-flag toggling)
- Measure first, fix second

**Asyncio-specific instrumentation:**

- `asyncio.all_tasks()` to inspect what coroutines are running / stuck
- `task.get_stack()` for the current frame of a hung task
- `asyncio.get_event_loop().set_debug(True)` for slow-callback warnings
- For "an `await` never returns": check task cancellation propagation, check whether you're awaiting a coroutine that was never scheduled, check whether a sync I/O call is blocking the loop

### Phase 5 — Fix + regression test

Write the regression test **before the fix** — but only if there is a **correct seam** for it.

A correct seam is one where the test exercises the **real bug pattern** as it occurs at the call site. If the only available seam is too shallow (a single-`Service` test when the bug needs multiple `*Service`s interacting, a unit test that can't replicate the cross-channel chain that triggered the bug), a regression test there gives false confidence.

**If no correct seam exists, that itself is the finding.** Note it. The codebase architecture is preventing the bug from being locked down. Flag it for Phase 6 — this is exactly the kind of signal that motivates `/audiotrader-workflow:architecture-deepening`.

If a correct seam exists:

1. Turn the minimised repro into a failing pytest at that seam.
2. Watch it fail.
3. Apply the fix.
4. Watch it pass.
5. Re-run the Phase 1 feedback loop against the original (un-minimised) scenario.

### Phase 6 — Cleanup + post-mortem

**Required before declaring done:**

- [ ] Original repro no longer reproduces (re-run the Phase 1 loop)
- [ ] Regression test passes (or absence of a correct seam is documented)
- [ ] All tagged debug logs removed (`git grep debug_tag=` returns nothing in production paths)
- [ ] Throwaway harnesses deleted (or moved to `scripts/debug/` and noted in the PR)
- [ ] The hypothesis that turned out correct is stated in the commit / PR message — so the next debugger learns the *real* shape of the bug, not just the fix

**Then ask: what would have prevented this bug?**

- If the answer is **better tests**: capture the gap in the regression test you already wrote, or note it in the PR if no correct seam existed.
- If the answer is **better observability**: capture in the PR description so the `observability-scope-check` skill or the next observability sweep folds it in.
- If the answer involves **architectural change** — no good test seam, tangled callers, hidden coupling, a shallow Module that should be deep, a Seam that should exist but doesn't — hand off to `/audiotrader-workflow:architecture-deepening` with the specifics. Make the recommendation **after** the fix is in, not before — you have more information now than when you started.

## Boundaries

- **Not the first response to a bug.** `superpowers:systematic-debugging` is the auto-fire skill that catches every bug / test failure / unexpected behaviour and enforces the "no fixes without root cause" discipline. Use `/diagnose` when the bug is hard enough that the deeper feedback-loop / hypothesis-ranking / seam-discipline technique is worth the overhead.
- **Not a fix request.** This command doesn't fix bugs — it diagnoses them with discipline. The fix is the *output* of the diagnosis.
- **Not a substitute for `/grill`.** If the bug is actually a *design* bug (the plan was wrong, not the implementation), hand off to `/grill` for the design conversation rather than continuing to instrument.

---

Originally adapted from [`mattpocock/skills` — `diagnose`](https://github.com/mattpocock/skills/tree/main/skills/engineering/diagnose). The discipline framing is delegated to `superpowers:systematic-debugging`. Post-mortem architectural findings route to `/audiotrader-workflow:architecture-deepening`. Examples are Python/Prism-flavoured (pytest, structlog, asyncio, marketplace event consumers).
