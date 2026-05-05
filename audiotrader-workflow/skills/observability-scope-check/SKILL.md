---
name: observability-scope-check
description: Use before claiming a feature is done or opening a PR, to verify logs, metrics, and traces are in scope for the new code. Triggers on completion claims, PR-creation requests, or when the user says "we're done", "ready to ship", or asks for a final review.
---

# Observability Scope Check

## Why this matters

Observability added after an incident is one round-trip too late. Every new service entry point, background job, external API call, and error path needs logging/metrics/tracing *before* it ships, not after the first prod surprise.

This is a pre-ship gate, not a code review style preference.

## When to use

Run this check when:
- About to claim a feature/branch is "done"
- Opening or refreshing a PR
- The diff adds: a new endpoint, worker job, ETL, external API client, or error path

Skip for: pure-refactor diffs that change no behaviour, doc-only changes, test-only changes.

## Procedure

### Determine the review scope

```bash
DEFAULT=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
DEFAULT=${DEFAULT:-main}
CURRENT=$(git branch --show-current)
```

Choose `BASELINE`:

- **`$CURRENT` ≠ `$DEFAULT`** (feature branch): `BASELINE=$DEFAULT`
- **`$CURRENT` = `$DEFAULT`** with unpushed commits: `BASELINE=@{u}`
- **Otherwise**: **stop and ask the user** what range to review.

### Run the check

1. **Read the project logging conventions** in `packages/prism/CODING_GUIDELINES.md` (Logging section). Note required structured fields (`event`, `correlation_id`, `user_id` if applicable), log levels, and metric naming patterns.
2. **Enumerate the new behaviours** in the diff:
   ```bash
   git diff $BASELINE...HEAD --name-only | xargs grep -l 'def \|async def \|@router\|@app\.' 2>/dev/null
   ```
3. **For each new behaviour, confirm**:
   - **Entry log** — `logger.info` with `event=` at the start of the operation
   - **Exit log** — success or failure logged with timing
   - **Error log** — every `except` has `logger.error(..., exc_info=True)` (or `.exception(...)`)
   - **Metric** — counter or histogram for latency/throughput where the rate matters
   - **Trace span** — for slow paths or anything calling external services
4. **Check Grafana coverage**: if a new metric is added, is there a panel/alert for it? If yes, link it. If no, flag for follow-up.

## Output format

```
Observability gaps found:
- app/services/foo.py:42  no entry log on `process_batch`
- app/workers/baz.py:18   exception swallowed without logger.exception
- new metric `prism_foo_total` has no Grafana panel

To address: [list of one-line actions]
```

If zero gaps: say so explicitly. Do not produce a fake checklist.

## Red flags

- "We can add logging later" — later = after the first incident.
- "It's just an internal helper" — internal helpers fail too.
- "Errors propagate up so they'll be logged" — verify the upstream actually logs them; many `try/except` in middleware swallow context.
