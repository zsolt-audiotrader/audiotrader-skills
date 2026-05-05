---
description: Principal Engineer review of tests on the current branch against CODING_GUIDELINES testing expectations
---

Act as a Principal Engineer reviewing the **tests** on the current feature branch against the testing standards in `packages/prism/CODING_GUIDELINES.md` (Test Quality Standards section).

1. **Read the Test Quality Standards section** of `CODING_GUIDELINES.md`. Internalise the rules: mock HTTP, real DB; coverage targets; assertion strength; test isolation expectations.
2. **List new and modified tests**:
   ```bash
   git diff main...HEAD --name-only -- 'tests/' '**/test_*.py' '**/*_test.py'
   ```
3. **For each test, check**:
   - **Boundary**: Are HTTP calls mocked? Is the DB real (or an equivalent integration substrate)? Flag any test that mocks the DB inappropriately — these hide schema and migration drift.
   - **Assertions**: Does the test assert specific behaviour, or just that nothing raised? Strong assertions check return value structure, side effects, persisted state, emitted events.
   - **Coverage of branches**: Does the new code have tests for the success path, the documented error paths, and at least one edge case?
   - **Naming**: `test_<unit_under_test>_<scenario>_<expected_outcome>` — flag opaque test names.
   - **Fixtures**: Are fixtures shared appropriately? Any test mutating module-level state without cleanup?
   - **Flakiness signals**: `time.sleep`, `datetime.now()` without freezing, network calls that escape the mock boundary, ordering dependencies between tests.
4. **Check that the new code's tests actually exercise the new behaviour**. Diff coverage matters more than absolute coverage.
5. **Verify the suite runs clean**:
   ```bash
   cd packages/prism && .venv/bin/pytest tests/ -v --tb=short
   ```

Produce a report: **Strong**, **Weak (specific gap + fix)**, **Missing (untested branch + suggested test)**.
