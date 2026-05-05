---
description: Run every step of the GitHub Actions CI pipeline locally and fix issues until clean
---

Run **every** step from the GitHub Actions CI configuration locally, in order, and fix any failures until the codebase passes the full quality gate.

This is not a sampling pass. Run them all — no exceptions.

## Procedure

1. **Read the workflow files**:
   ```bash
   ls .github/workflows/
   ```
   Identify the CI workflow(s) that gate PRs (typically `ci.yml`, `test.yml`, `lint.yml` or similar).
2. **Enumerate every step** that runs on PR / push to main. For each step, extract:
   - The shell command or action invocation
   - The required environment / setup (Python version, Node version, secrets)
   - The working directory
3. **Execute each step in order**. Use absolute paths. Do not skip steps because they "look like they'd pass". Examples:
   ```bash
   # ruff
   cd packages/prism && .venv/bin/ruff check app/ tests/
   # mypy
   cd packages/prism && .venv/bin/mypy app/
   # pytest
   cd packages/prism && .venv/bin/pytest tests/ -v --tb=short
   # alembic check (if used in CI)
   cd packages/prism && .venv/bin/alembic check
   # any custom scripts the CI runs
   ```
4. **For each failure**:
   - Read the error fully. Don't paper over it.
   - Identify the root cause (use the `superpowers:systematic-debugging` skill if the cause isn't obvious).
   - Fix the underlying issue.
   - Re-run the step.
5. **Don't bypass**: never use `--no-verify`, `# noqa`, `# type: ignore`, or `pytest.skip` to silence a CI step. If a step is genuinely wrong, fix the step config in the workflow file and document why.
6. **Verify all steps pass clean** before reporting done. Track which steps you've run.

## Output

Produce a final summary:
- **Steps run** (full list with pass/fail)
- **Fixes applied** (file:line, what changed, why)
- **Remaining failures** (if any, with explanation)

Only claim "CI clean locally" when every step from every workflow has actually passed in your terminal.
