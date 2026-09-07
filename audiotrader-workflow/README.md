# audiotrader-workflow

The Audio Trader engineering workflow as Claude Code skills and slash commands. Mirrors the human checklist in `audiotrader-prism/WORKFLOW_CHECKLIST_FOR_HUMANS.md`, but as machine-invokable tooling.

## Skills (auto-trigger)

Skills load automatically when the context matches their `description`. No invocation needed.

| Skill | Triggers when… |
|---|---|
| `migration-semantic-drift-audit` | An Alembic migration adds, drops, or changes the semantics of a column on a shared table. Audits every writer/reader and flags mock-based tests that hide the drift. |
| `observability-scope-check` | About to claim a feature is done, or open a PR. Verifies logs, metrics, and traces are in scope per `CODING_GUIDELINES.md`. |
| `env-example-sync-check` | Diff modifies env-var reads or the `.env` file. Ensures `.env.example` keeps the contract for first-run setup. |
| `spec-status-update` | Implementation work tied to a `specs/specs_*.md` file is completed, in-progress, or de-scoped. Updates the Status line and milestone checkboxes. |
| `update-architecture-md` | Diff adds or removes a service, package, layer, external integration, or major module. Keeps `docs/ARCHITECTURE.md` C4 diagrams current. |
| `suggesting-adrs` | The conversation crosses into an architectural decision (comparing alternatives, switching providers, new external integration, cross-cutting pattern). Nudges the user to capture it via `/adr-new` before the rationale is lost. |
| `suggesting-grilling` | A plan, spec, or design is about to be committed to without being stress-tested — pre-implementation, pre-plan-writing, brainstorming just finished, terminology drift against `CONTEXT.md`, or cross-context boundary work. Nudges the user to run `/grill` before momentum carries past. |
| `suggesting-principal-reviews` | Work is wrapping up and about to ship — a PR is about to be created, or accumulated work on `main` is about to be pushed. Nudges the user to run the review trinity (correctness → architecture → guidelines) in order; gates down to correctness-only for small diffs. |

## Slash commands (user-invoked)

Run these explicitly. Replace `audiotrader-workflow` with the namespace your install uses (`/plugin list` shows it).

### Principal Engineer reviews

| Command | What it does |
|---|---|
| `/audiotrader-workflow:principal-review-correctness` | Reviews the branch diff for correctness, bugs, and unexpected behaviour. Includes the migration / shared-table audit insight. |
| `/audiotrader-workflow:principal-review-architecture` | Reviews the branch for architecture conformance: ADR/pattern/boundary violations (evidence rule: no citation, no finding) plus a database schema review — one-hop Mermaid ERD rendered from the ORM models showing how new tables graft onto the existing schema, field-purpose summary, and schema smell checklist. |
| `/audiotrader-workflow:principal-review-guidelines` | Reviews the branch against the metrics, thresholds, and dependency rule defined in `CODING_GUIDELINES.md`. Defers to the guidelines as source of truth (no parallel metric list). |
| `/audiotrader-workflow:principal-review-tests` | Reviews the new tests against `CODING_GUIDELINES.md` testing standards (real DB, strong assertions, branch coverage, flakiness signals). |
| `/audiotrader-workflow:principal-review-mutation` | Runs and interprets `mutmut` on the touched modules, applies the project mutation-score threshold, identifies real test gaps. |
| `/audiotrader-workflow:principal-review-duplication` | Reviews the branch for code duplication against the whole codebase (exact, near, and conceptual duplicates). |
| `/audiotrader-workflow:principal-review-organization` | Reviews module boundaries and asks whether the *current folder structure* still serves the codebase as it has grown. Complementary to the guidelines review. |

### Other reviews and authoring

| Command | What it does |
|---|---|
| `/audiotrader-workflow:qa-feature-review` | Principal QA Engineer review: enumerates scenario classes (golden, boundary, invalid, auth, concurrency, failure modes, idempotency, observability) and finds gaps in the test coverage. |
| `/audiotrader-workflow:multi-hat-spec-review <spec-path>` | Reviews a spec from CEO, CTO, and CFO perspectives in turn, then synthesises top concerns. |
| `/audiotrader-workflow:grill [<plan, spec path, or topic>]` | Interview-style grilling of an existing plan, spec, or design against the project's `CONTEXT.md` glossary and ADRs. Surfaces contradictions, sharpens fuzzy terms, captures resolutions inline. Routes ADR-worthy decisions to `/adr-new`. |
| `/audiotrader-workflow:architecture-deepening [<area>]` | Codebase-wide hunt for shallow Modules and deepening opportunities. Surfaces architectural friction using an explicit vocabulary (Module / Interface / Depth / Seam / Adapter / Leverage / Locality), proposes refactors, hands off to `/grill` for the candidate the user picks. Complementary to `/principal-review-organization` (which is branch-scoped). |
| `/audiotrader-workflow:architecture-simplification [<area>]` | Codebase-wide hunt for over-building: Modules, Seams, and processes whose complexity exceeds what production needs. Establishes the production **Envelope** with you first, then surfaces evidence-gated cut candidates with measured LOC (or the architectural flattening), the Envelope fact each is judged against, and the human judgement each needs (Product / Data / Operational / Contractual / Intent / Invisible). Hands off to `/grill` when risk is flagged. Sibling of `/architecture-deepening`: same deletion test, opposite verdict. |
| `/audiotrader-workflow:diagnose [<bug or failing-test path>]` | Disciplined feedback-loop construction and instrumentation for hard bugs. 10-item feedback-loop menu, ranked falsifiable hypotheses, tagged debug logs, seam-aware regression testing, post-mortem that routes architectural findings to `/architecture-deepening`. Assumes `superpowers:systematic-debugging` is the auto-fire layer; use this when the bug needs the deeper technique. |
| `/audiotrader-workflow:adr-new <title>` | Authors a new ADR following `docs/adr/adr.template.md` and the project naming convention. |
| `/audiotrader-workflow:run-ci-locally` | Runs every step of the GitHub Actions CI pipeline locally, fixes failures, doesn't sample. |
| `/audiotrader-workflow:wait-what [<term, file, or concept>]` | Re-explains the previous response (or the named term/file/concept) in ASD-STE100-inspired Simplified Technical English: short sentences, active voice, one idea per sentence, `CONTEXT.md` glossary terms as the approved vocabulary, missing premises stated and flagged. For the moment an explanation loses you. |

## Suggested workflow

A standard feature lifecycle, end to end:

1. **Spec** — write the spec; run `/multi-hat-spec-review specs/specs_<date>_<name>.md` for stakeholder pressure-testing.
2. **Decide** — for architectural decisions, run `/adr-new "<decision title>"`.
3. **Implement** — code + tests with TDD (`superpowers:test-driven-development`).
4. **Pre-PR sweep** (the `suggesting-principal-reviews` skill nudges the first three, in this order, at wrap-up):
   - `/principal-review-correctness`
   - `/principal-review-architecture`
   - `/principal-review-guidelines`
   - `/principal-review-tests`
   - `/principal-review-mutation`
   - `/principal-review-duplication`
   - `/principal-review-organization`
   - `/qa-feature-review`
   - `/run-ci-locally`
5. **Auto-fired skills handle** observability scope, `.env.example` sync, ARCHITECTURE.md updates, spec status, migration drift detection, ADR-moment nudges, grilling-moment nudges, and the pre-ship trinity nudge — you don't invoke them, they load when relevant.
6. **Open PR**, get review, merge, push.

## Notes

- Slash commands are **prompt templates**, not auto-firing rules. They're explicit gates you choose to run.
- Skills are **conditioning context** that load when their description matches the current task. They steer behaviour during normal work — you don't see them invoked.
- Many commands and skills reference `packages/prism/CODING_GUIDELINES.md`. They expect to be run from a checkout of `audiotrader-prism` (or a sibling worktree).
