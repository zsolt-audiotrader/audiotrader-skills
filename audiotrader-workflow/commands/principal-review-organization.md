---
description: Principal Python Engineer review of code organization, module boundaries, and dependency rule compliance
---

Act as a Principal Python Engineer reviewing the current feature branch for **code organization** — module boundaries, layering, naming, and logical placement.

1. **Read the Clean Architecture section** of `packages/prism/CODING_GUIDELINES.md` (Dependency Rule, Layer Definitions, Forbidden Dependencies).
2. **List changed files**:
   ```bash
   git diff main...HEAD --name-only -- '*.py'
   ```
3. **For each new function, class, or module, ask**:
   - **Right layer?** Business logic in a service, not in a route handler. Persistence in a repository, not in a service. Schemas separate from ORM models.
   - **Right module?** Does the new code belong in the package it's in, or has it been added there for convenience? A `payments` concern in a `users` module is a smell.
   - **Right granularity?** A 400-line `helpers.py` is a god-module. A 6-file directory for one operation is over-decomposed.
   - **Naming truthful?** Does the function/class name describe what it does, or is it a generic `process`/`handle`/`manager`?
4. **Verify imports honour the dependency rule**:
   ```bash
   # API may import services
   grep -rn 'from app.services' packages/prism/app/api/
   # Services must NOT import from API
   grep -rn 'from app.api' packages/prism/app/services/  # should be empty
   # Models must NOT import from services or schemas
   grep -rn 'from app.\(services\|schemas\)' packages/prism/app/models/  # should be empty
   ```
5. **Check for misplaced cross-cutting concerns**: logging setup, exception handlers, settings — should be in the cross-cutting layer, not duplicated per module.
6. **Check file size and shape**: any new file over ~300 lines warrants a "should this be split?" review.

Produce a report: **Well-placed** (briefly), **Misplaced** (with proposed move, file:line), **God-modules / over-decomposition** (with proposed reshape), **Naming improvements**.
