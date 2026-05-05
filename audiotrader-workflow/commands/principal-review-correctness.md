---
description: Principal Python Engineer review of the current branch for outcome correctness AND code correctness
---

Act as a Principal Python Engineer with 15+ years of production Python experience. Review the changes on this feature branch for **outcome correctness** (does it deliver what was promised?) and **code correctness** (is the code itself right?).

## Determine the review scope

```bash
DEFAULT=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
DEFAULT=${DEFAULT:-main}
CURRENT=$(git branch --show-current)
```

Choose `BASELINE`:

- **`$CURRENT` ≠ `$DEFAULT`** (feature branch): `BASELINE=$DEFAULT`
- **`$CURRENT` = `$DEFAULT`** with unpushed commits: `BASELINE=@{u}`
- **Otherwise** (on default with nothing unpushed, detached HEAD, no upstream): **stop and ask the user** what range to review. Do not fabricate a scope.

Use `$BASELINE...HEAD` (or `$BASELINE..HEAD` for `git log`) wherever the steps below need a comparison range.

## Review

1. **Outcome correctness — did we build the right thing?**
   - Look for a spec in `specs/specs_*.md` covering this work (match by branch name, recent edits, or ask the user). Read its **Acceptance Criteria** section.
   - For each AC, find the **evidence** in the diff: which commit, which file, which test demonstrates it's met. Map them explicitly.
   - Flag any AC that is **unmet**, **partially met**, or where the evidence is **unconvincing** (e.g. the only test mocks the very thing the AC requires).
   - **If no spec or no acceptance criteria exists** — construct AC from context (commit messages, the issue, the user's stated goal) and **stop to have the user verify them** before proceeding with the rest of the review. Do not invent ACs and silently grade against them.
2. **Code correctness — is the code itself right?** Run `git diff $BASELINE...HEAD --stat` and `git diff $BASELINE...HEAD`. For each modified function, ask: are there inputs that would produce wrong output? Off-by-ones, type coercion surprises, timezone bugs, race conditions, ordering assumptions?
3. **Migration / shared-table audit** — if any Alembic migration changed the schema or semantics of a table that is read or written by 2+ modules, audit every writer and reader. CI being green is **not** sufficient evidence of safety: existing tests often mock the SQL response, and mocks freeze the old schema while reality breaks.
4. **Error paths** — are exceptions caught at the right level? Is context preserved (`exc_info=True`, `raise ... from e`)? Does any `except` swallow important state silently?
5. **Concurrency-adjacent code** — any shared state, any async/await without proper await, any DB session reused across requests, any background task without a timeout?
6. **External API calls** — timeouts set? retries with backoff? idempotency keys where needed?

## Output

Two sections:

- **Outcome correctness** — per AC: met / unmet / partial / unconvincing, with evidence (or lack of it). Lead with this. Code that is internally correct but solves the wrong problem is still wrong.
- **Code correctness** — findings grouped by severity (Critical / High / Medium / Low). For each: file:line, the issue, and the concrete fix.

If the branch is clean, say so explicitly — do not invent issues.
