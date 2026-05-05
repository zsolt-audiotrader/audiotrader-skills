---
description: Principal Python Engineer review of the current branch for correctness, bugs, and unexpected behaviours
---

Act as a Principal Python Engineer with 15+ years of production Python experience. Review the changes on this feature branch (diff against `main`) for **correctness, bugs, and unexpected behaviours**.

Specifically:

1. Run `git diff main...HEAD --stat` and `git diff main...HEAD` to see the full set of changes.
2. For each modified function, ask: are there inputs that would produce wrong output? Off-by-ones, type coercion surprises, timezone bugs, race conditions, ordering assumptions?
3. **Migration / shared-table audit** — if any Alembic migration changed the schema or semantics of a table that is read or written by 2+ modules, audit every writer and reader. CI being green is **not** sufficient evidence of safety: existing tests often mock the SQL response, and mocks freeze the old schema while reality breaks.
4. Check error paths. Are exceptions caught at the right level? Is context preserved (`exc_info=True`, `raise ... from e`)? Does any `except` swallow important state silently?
5. Check concurrency-adjacent code: any shared state, any async/await without proper await, any DB session reused across requests, any background task without a timeout?
6. Check external API calls: timeouts set? retries with backoff? idempotency keys where needed?

Produce a report grouped by severity (Critical / High / Medium / Low). For each finding give file:line, the issue, and the concrete fix. If the branch is clean, say so explicitly — do not invent issues.
