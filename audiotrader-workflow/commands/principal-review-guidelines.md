---
description: Principal Engineer review of the current branch against CODING_GUIDELINES.md metrics and standards
---

Act as a Principal Engineer reviewing the current feature branch against `packages/prism/CODING_GUIDELINES.md`.

## Determine the review scope

```bash
DEFAULT=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
DEFAULT=${DEFAULT:-main}
CURRENT=$(git branch --show-current)
```

Choose `BASELINE`:

- **`$CURRENT` ≠ `$DEFAULT`** (feature branch): `BASELINE=$DEFAULT`
- **`$CURRENT` = `$DEFAULT`** with unpushed commits: `BASELINE=@{u}`
- **Otherwise**: **stop and ask the user** what range to review.

## Review

1. **Read `CODING_GUIDELINES.md`** in full. The guidelines are the source of truth — for metrics, thresholds, the Dependency Rule, and the documented exceptions.
2. **Enumerate changed files**: `git diff $BASELINE...HEAD --name-only -- '*.py' | grep -v '^tests/'`
3. **For each changed function/class**, evaluate against the **Core Metrics Table** in `CODING_GUIDELINES.md`. Use the metrics, thresholds, and exception clauses defined there as-is — do not maintain a parallel list in this prompt. If the guidelines change, this review changes with them automatically.
4. **Verify Clean Architecture compliance**: confirm imports respect the layer rules documented in the guidelines. Flag any forbidden dependency (outward, peer-layer) found on the diff.
5. **Apply documented exceptions** rather than flagging legitimate domain complexity, generated code, or test code. The exceptions sections of `CODING_GUIDELINES.md` are the contract — cite the specific clause when applying one.
6. **Run the actual tooling where possible**:
   ```bash
   cd packages/prism
   .venv/bin/ruff check app/
   .venv/bin/mypy app/
   ```

## Output

Three sections:
- **Compliant** — what passes, with metric numbers
- **Violations** — file:line, metric, value vs threshold (with cite to the relevant CODING_GUIDELINES section), recommended fix
- **Exceptions applied** — where you knowingly accepted a value outside the threshold, with cite to the exception clause that allows it

Be specific. "Function `foo` has CC=14 (CODING_GUIDELINES section 1 threshold: 10)" beats "complexity is high".
