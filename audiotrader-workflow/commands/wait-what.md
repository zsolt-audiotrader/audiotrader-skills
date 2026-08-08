---
description: Re-explain something in ASD-STE100-inspired Simplified Technical English. No arguments — re-explains your previous response; with arguments — explains that term, file, or concept. Uses CONTEXT.md glossary terms as the approved technical vocabulary.
argument-hint: [<term, file path, or concept>]
---

The user is confused. Re-explain, in Simplified Technical English, following every rule below.

## Target

- If `$ARGUMENTS` is non-empty: explain `$ARGUMENTS` — a term, a file path, or a concept. If it names a file, read it first.
- If `$ARGUMENTS` is empty: re-explain your previous substantive response — the last message where you explained, analysed, or proposed something. Skip trivial acknowledgements.

## Writing rules (ASD-STE100-inspired)

Your explanation must follow all of these:

1. Sentences of 20 words or fewer. Up to 25 for purely descriptive sentences.
2. Never use a long word where a short one carries the same meaning.
3. Active voice. Present tense where possible.
4. One instruction or one idea per sentence.
5. One word, one meaning. Call the same thing by the same name every time. No synonym variation.
6. Match the shape to the content. Use a numbered list only for an ordered sequence of steps. Use a bullet list only for a genuine set of parallel items. For everything else — describing what a thing is, why it works, or how one fact leads to another — write short-sentence paragraphs. Do not force a list when the content is not a sequence or a set.
7. No idioms, no metaphors, no filler phrases.
8. If following these rules would make a sentence awkward or unclear, break the rule. Clarity for the reader wins over literal compliance.

## Technical Names

- If the project root has a `CONTEXT.md`, read it. Its glossary terms are your approved technical vocabulary. Use each term with exactly its glossary meaning.
- Any technical term not in the glossary gets a one-sentence plain definition the first time you use it.
- If there is no `CONTEXT.md`, define every technical term inline the same way.

## Gap-filling

Confusion is often a missing premise, not complex wording. If the original explanation assumed something unstated:

- State the missing premise.
- Only use facts you can verify from the conversation or the codebase. Do not invent.
- Flag each added premise: "This fact was not in the first explanation: …".

## Ending

Close with one line inviting the user to name any sentence that is still not clear.
