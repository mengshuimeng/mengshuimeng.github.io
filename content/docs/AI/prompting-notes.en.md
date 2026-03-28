---
title: Prompting Notes
description: A lightweight reference for writing clearer prompts, refining outputs, and using AI tools more effectively.
slug: prompting-notes
---

# Prompting Notes

This page is a compact reminder for everyday prompting. It is meant for practical use: getting cleaner answers, improving code comments, and turning vague requests into structured tasks.

## A Simple Prompt Structure

Use four basic parts when the model output is unstable:

1. Role: tell the model who it should act as.
2. Task: describe the concrete job to finish.
3. Constraints: define output format, length, style, or scope.
4. Examples: provide one or two examples when the format matters.

## Typical Use Cases

- Ask the model to write comments for an existing code block.
- Ask for input, output, and behavior summaries before a function definition.
- Ask for a cleaner rewrite of notes, reports, or README text.
- Ask for a draft implementation first, then refine it in later rounds.

## A Better Way To Iterate

- Start with a plain request.
- Add structure if the result is too vague.
- Add constraints if the result is too long or off-topic.
- Add examples if the format is still inconsistent.
- Keep only the useful context instead of pasting everything.

## Good Habits

- Be explicit about the expected output.
- Split large tasks into smaller steps.
- Verify code and facts instead of trusting the first answer.
- Avoid sending sensitive keys, credentials, or private data.

## Quick Template

```text
Role: You are a senior Python developer.
Task: Explain this function and add a short comment block above it.
Constraints: Keep the explanation under 80 words.
Output: First the comment block, then a one-paragraph explanation.
```
