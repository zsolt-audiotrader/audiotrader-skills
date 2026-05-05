---
description: Principal Engineer review of the current branch against CODING_GUIDELINES.md metrics and standards
---

Act as a Principal Engineer reviewing the current feature branch against `packages/prism/CODING_GUIDELINES.md`.

1. **Read `CODING_GUIDELINES.md`** in full. Note the Core Metrics Table (section 1), the Clean Architecture Dependency Rule, and the documented exceptions.
2. **Enumerate changed files**: `git diff main...HEAD --name-only -- '*.py' | grep -v '^tests/'`
3. **For each changed function/class**, evaluate against the metrics:
   - Cyclomatic complexity (CC ≤ guideline threshold)
   - Maintainability Index
   - LCOM4 cohesion
   - Function length, parameter count, nesting depth
   - Use the metric thresholds defined in CODING_GUIDELINES.md, not your own
4. **Verify Clean Architecture compliance**: API → Services → Models. Flag any outward dependency (Models → Services, Schemas → Models) and any peer-layer dependency.
5. **Apply documented exceptions** (CODING_GUIDELINES section "Detailed Exceptions by Category") rather than flagging legitimate domain complexity, generated code, or test code.
6. **Run the actual tooling where possible**:
   ```bash
   cd packages/prism
   .venv/bin/ruff check app/
   .venv/bin/mypy app/
   ```

Produce a comprehensive analysis with three sections:
- **Compliant**: what passes, with metric numbers
- **Violations**: file:line, metric, value vs threshold, recommended fix
- **Exceptions applied**: where you knowingly accepted a value outside the threshold and why

Be specific. "Function `foo` has CC=14 (threshold 10)" beats "complexity is high".
