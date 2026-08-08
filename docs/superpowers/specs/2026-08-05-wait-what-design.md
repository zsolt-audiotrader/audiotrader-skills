# /wait-what — STE re-explanation command

**Date**: 2026-08-05
**Status**: Approved
**Artifact**: `audiotrader-workflow/commands/wait-what.md`

## Problem

When an agent's explanation confuses the reader, the reader has no low-friction way to ask for a genuinely simpler restatement. Blanket instructions ("always write in Simplified Technical English" in a global CLAUDE.md) degrade every response and were found not to work. The working pattern, borrowed from a community suggestion, is on-demand: a "wait-what?" trigger the user fires only at the moment of confusion.

## Decision

Add a user-invoked slash command, `/audiotrader-workflow:wait-what`, that re-explains something in ASD-STE100-inspired Simplified Technical English. It is a command, not an auto-trigger skill — the user decides when it runs.

Strictness: STE **writing rules** only, not the STE controlled dictionary (the ~900-word dictionary targets aircraft maintenance and excludes software vocabulary; full compliance is impossible for a model and undesirable for this domain). The project's `CONTEXT.md` glossary stands in as the approved "Technical Names" list, which ties the command into the `/grill` ecosystem.

## Behavior

1. **Target selection**
   - With `$ARGUMENTS`: explain that — a term, a file path, a concept.
   - Without arguments: re-explain the assistant's previous substantive response (skip over trivial acknowledgements).

2. **STE writing rules** (the output must follow all of these)
   - Sentences of 20 words or fewer; up to 25 for descriptive text.
   - Never use a long word where a short one carries the same meaning.
   - Active voice; present tense where possible.
   - One instruction or one idea per sentence.
   - One word, one meaning — the same thing is always called by the same name; no synonym variation.
   - Match shape to content: numbered lists for ordered steps, bullet lists for genuine parallel sets, short-sentence paragraphs for everything descriptive. Never force a list when the content is neither a sequence nor a set.
   - No idioms, no metaphors, no filler.
   - Escape hatch: if following these rules would make a sentence awkward or unclear, break the rule — clarity for the reader wins over literal compliance.

3. **Technical Names**
   - If the project root has `CONTEXT.md`, read it. Its glossary terms are the approved technical vocabulary, used with exactly their glossary meaning.
   - Any technical term not in the glossary gets a one-sentence plain definition on first use.
   - No `CONTEXT.md` → fail soft: define all technical terms inline.

4. **Gap-filling**
   - If the confusion likely stems from a missing premise, state that premise.
   - Only facts verifiable from the conversation or the codebase; no invented claims.
   - Added premises are flagged: "This fact was not in the first explanation: …".

5. **Ending**
   - One closing line inviting the user to name any sentence that is still not clear.

## Non-goals

- No auto-triggering. The command never fires on inferred confusion.
- No strict ASD-STE100 dictionary compliance.
- No change to how other commands or skills write their normal output.

## Repo mechanics

- New file: `audiotrader-workflow/commands/wait-what.md` (frontmatter: `description`, `argument-hint`).
- Bump `audiotrader-workflow/.claude-plugin/plugin.json` version `0.8.0` → `0.9.0`.
- Update command counts in both READMEs (14 → 15 user-invoked commands).
- Test per the contributing guide: invoke the command in a real project against a deliberately dense explanation; verify the output follows the rules above.
- Branch `feat/wait-what`, PR, squash-merge.
