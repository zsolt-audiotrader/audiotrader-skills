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
2. Active voice. Present tense where possible.
3. One instruction or one idea per sentence.
4. One word, one meaning. Call the same thing by the same name every time. No synonym variation.
5. Prefer lists and numbered steps over paragraphs.
6. No idioms, no metaphors, no filler phrases.

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
