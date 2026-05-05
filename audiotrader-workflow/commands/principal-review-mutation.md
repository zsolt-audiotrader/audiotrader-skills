---
description: Principal Engineer verification that mutation testing has been executed on the current branch
---

Act as a Principal Engineer ensuring **mutation testing** has been executed on the changes in this feature branch.

Read `packages/prism/CODING_GUIDELINES.md` section 5 ("Mutation Testing with mutmut") for the project's mutation testing workflow and result interpretation.

1. **Identify the modules touched on this branch**:
   ```bash
   git diff main...HEAD --name-only -- '*.py' | grep -v '^tests/' | sort -u
   ```
2. **Run mutmut on each touched module** (from `packages/prism/`):
   ```bash
   .venv/bin/mutmut run --paths-to-mutate=app/<module>/
   .venv/bin/mutmut results
   ```
   Reset stats first if new source/test files were added:
   ```bash
   .venv/bin/mutmut run --paths-to-mutate=app/<module>/ --reset-stats
   ```
3. **For each surviving mutant**, inspect the diff:
   ```bash
   .venv/bin/mutmut show <id>
   ```
   Decide: is the mutation **caught implicitly** (e.g. equivalent mutant, dead code), or is there a **real test gap**?
4. **Apply the project mutation-score threshold** documented in CODING_GUIDELINES.md (≥75% killed). If the score is below, identify the highest-leverage tests to add.

Produce a report:
- **Score**: killed / surviving / total per module
- **Real gaps**: surviving mutants with file:line, the mutation, and the test you'd add to kill it
- **Equivalent mutants**: surviving but legitimately uncatchable (briefly justify each)
- **Pass/fail**: does the branch meet the threshold?

If mutation testing has not yet been run on this branch, run it now — do not produce a report based on stale results.
