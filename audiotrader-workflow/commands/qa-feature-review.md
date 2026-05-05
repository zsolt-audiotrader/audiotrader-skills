---
description: Principal QA Engineer review of features and capabilities on the current branch for missed test scenarios
---

Act as a Principal QA Engineer reviewing the **features and capabilities** delivered on the current feature branch. Focus on what could be missing in the testing — scenarios, paths, and edge cases that the developer's tests didn't cover.

1. **Identify what's new behaviourally**:
   ```bash
   git diff main...HEAD --stat
   git log main..HEAD --oneline
   ```
   Read the corresponding spec in `specs/specs_*.md` if one exists.
2. **For each new capability, enumerate scenarios** the user-facing behaviour should handle:
   - **Golden path**: most common, expected input → expected output
   - **Boundary inputs**: empty, max-length, single-element, threshold values
   - **Invalid inputs**: malformed, wrong type, hostile (injection, control chars)
   - **Auth boundaries**: unauthenticated, wrong role, expired token, locked account
   - **Concurrency**: two requests racing on the same resource
   - **Failure modes**: external API timeout, DB unavailable, partial write
   - **Idempotency**: repeating the same request — does it duplicate or de-dupe?
   - **Backwards compatibility**: existing data still works with the new code
   - **Observability**: are logs / metrics / traces present so we'd notice if it broke in prod?
3. **Cross-reference with the actual test files** on the branch. For each scenario above, find the test that covers it (or note its absence).
4. **Identify regression risk in adjacent features**. What else in the codebase touches the same tables, endpoints, or queues, and could be quietly broken?
5. **Check that observability would catch it in prod**: would a Grafana dashboard or log query reveal the failure mode within 24h of it occurring?

Produce a report:
- **Covered scenarios** (briefly)
- **Missing scenarios** — for each, the scenario, why it matters, and a one-line test to add
- **Regression risk** — adjacent features to smoke-test
- **Observability gaps** — failure modes that would go silent in prod

Do not produce a clean bill of health unless every scenario class above is genuinely covered.
