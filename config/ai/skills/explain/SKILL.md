---
name: explain
description: Produce a clear visual/structured explanation, choosing the best medium (table, ASCII diagram, Mermaid, HTML, or a code walkthrough) for the content. Works at three scopes — a single solved problem (root cause, why the fix works, counterintuitive result), a whole-session recap (what we did, why it was needed, where it sits), OR a code walkthrough of a method/diff/class the reader has to review (high level, then a dry run over a fake input, with the code shown before every explanation). Use at the end of a session that did something non-trivial, or on demand when the user asks to "explain", "break this down", "why did that work", "what did we achieve / accomplish", "recap", "walk me through this code", "I don't know what this does", or wants a writeup of a bug/design decision.
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Grep
  - Glob
  - Bash
---

# /explain — Explain something with the right medium

Turn a non-trivial thing into an explanation the user can absorb, using whichever
medium fits the *content*, not a default wall of prose.

## First: which scope is being asked for?

Three scopes. They need different content, and conflating them is the most common
failure.

- **Problem scope** — one bug, one decision, one tricky flow. "Why did that work?",
  "explain this fix", "why is summing those ratios wrong?". Answer with root cause →
  visual → why the wrong instinct fails → takeaway.
- **Session scope** — the whole arc of what was just done. "What did we achieve?",
  "recap", "what problem are we solving?". Answer at *project altitude*:
  1. **The problem** — what was broken or missing, and why it mattered.
  2. **What we achieved** — a table of concrete wins, each with why it was needed.
  3. **Where it sits** — what this unblocks, what is still ahead.

  Lead with the goal of the whole session, never with the last edit you happened to
  make. A small cleanup is one row, not the headline.
- **Code scope** — a method, a class, a diff, or a CR the reader has to review and
  does not follow. "Walk me through this", "what does this do", "I need to review
  this and I don't understand it", or the user pastes code back at you. See the
  section below; it has its own recipe and its own hard rules.

When the request is ambiguous: **code scope** if the user pasted code or named a
function, **session scope** if they said "we" / "this session" / "achieve", and
**problem scope** if they pointed at a specific bug or result.

## When to produce this

**On demand:** whenever the user invokes `/explain` or asks to "explain", "break it
down", "draw it", "why did that work", "what did we achieve", "recap", "walk me
through", or wants a writeup.

**Proactively, at the end of a session** — but ONLY when the work clears a real
complexity bar. Produce it when any of these hold:

- The root cause was non-obvious or took multi-step reasoning to find.
- The result is counterintuitive.
- A non-trivial data/control flow, state machine, or dependency graph is involved.
- The fix touched several interacting pieces and the *why* is not visible from the
  diff alone.

**Proactively, for code scope: when an agent wrote code a human now has to review.**
An agent can produce more code in an hour than a reviewer can absorb, and a review
that does not understand the code is not a review. Offer a walkthrough in one line
when you hand over a change with a new algorithm, a two-pass loop, a new data shape,
or a rule that only makes sense against a fact about live data.

**Do NOT fire for:** typo fixes, one-line changes, mechanical refactors, renames,
formatting, or anything where one sentence says it all.

---

# Code scope — the recipe

The reader is about to review this code and cannot follow it. They do not need prose
about it. They need to watch it run.

## Hard rules

1. **Show the code before you explain it. Every time.** Paste the block, then explain
   it. Never make the reader scroll back to find what you are describing, and never
   describe a block you have not shown. This is the rule that makes the difference;
   keep it even when the block is three lines.
2. **Dry-run a fake input.** Not a description of what would happen. An actual input,
   actual state after each step, actual output.
3. **Size the fake input so every branch fires at least once**, including the branch
   the reader is confused about. Number the rows so the trace can cite them.
4. **Show state after each step, not just the final answer.** The reader's confusion
   almost always lives in what a collection holds part-way through.
5. **Name the domain fact that makes the code non-obvious.** If you cannot name one,
   the code does not need a walkthrough, and you should say so instead.
6. **Verify a claim the code makes about its data.** Comments go stale. When the code
   or its comment asserts something about live data, measure it, and report the number
   even when it contradicts the comment.

## The order

**1. Why it exists.** One paragraph. The job the code does, and — when relevant — the
job it must NOT do. This is the part that makes the rest land. Do not restate the
code.

**2. The input shape.** One real row, from live data or a fixture, as JSON or a
literal. Then name the fields the code reads, and say it ignores the rest. A reader
who does not know the input shape cannot follow any loop.

**3. The domain fact.** The thing outside the code that the code is shaped by. An
ASCII drawing usually beats prose here. Examples: a parent field whose value is the
sum of its children, a timestamp in site-local time, an axis that exists only after a
categoriser runs.

**4. The fake example.** A numbered table of input rows. Keep it to 5–8 rows. Design
it, do not copy it: each row should exist to trigger one branch.

**5. The trace.** One table row per input row. Columns: the branch taken, then every
piece of mutable state after that step. Finish with the return value and any counters
or logs.

**6. Block by block.** For each block the reader asked about, and each block carrying
a decision: the code first, then what it does and why it is written that way.

**7. The reader's own questions.** Restate each in their words and answer it directly.
When their mental model is wrong, say which two things they have merged, and separate
them explicitly. That is usually the whole confusion.

**8. What is worth their attention.** Close with the one or two things a reviewer
should actually check, and say plainly which parts need no scrutiny.

## Two failure modes to avoid

**Explaining the code twice.** The trace already shows the mechanism. The prose after
a block should say why the code is that shape, not narrate the lines again.

**A fake example that dodges the hard case.** When the reader asks about a branch, the
example must reach it. An example where the interesting branch never fires teaches
nothing and reads as evasion.

---

# Problem and session scope — pick the medium from the content

Match the explanation form to the *shape* of the idea. Often combine 2–3.

| Content shape | Best medium |
|---|---|
| Comparing options / before-vs-after / "which number is right" | **Markdown table** |
| Numeric example proving a point (worked calculation) | **Table** of the steps, or inline math with a punchline |
| Sequence of steps, request flow, call chain | **Mermaid** `sequenceDiagram` or `flowchart` |
| State transitions, lifecycle | **Mermaid** `stateDiagram-v2` |
| Dependency / relationship graph | **Mermaid** `graph` / `flowchart` |
| Box-and-arrow layout, small tree, memory/struct diagram, ranges | **ASCII diagram** (renders everywhere, no tooling) |
| Timeline, Gantt-ish phases | **Mermaid** `gantt` or an ASCII timeline |
| Walking a loop or a branch over an input | **Trace table** — one row per step, columns for the state |
| Rich/interactive artifact the user wants to keep, several linked diagrams | **Standalone HTML file** written to disk, then tell them the path |

Guidance:
- **Default to a table or ASCII** for terminal-read answers. They render inline with
  no dependencies. Reach for Mermaid when the relationships are graph- or
  sequence-shaped and a table would flatten them.
- **Only write an HTML file** when the user wants something durable or shareable, or
  the explanation needs interactivity or several diagrams together. Writing a file is
  a side effect, so prefer inline unless durability is the point. Give the absolute
  path when you do.
- Prefer the *simplest* medium that carries the idea. A table beats a diagram beats an
  HTML page when all three would work.

## Structure, for problem and session scope

1. **The headline** — one sentence: what was actually going on.
2. **The visual** — the table or diagram that carries the core insight.
3. **Why the wrong instinct is wrong**, when there is one. Name the intuitive answer
   and show concretely why it fails. This is the highest-value part when the result is
   counterintuitive.
4. **The fix / takeaway** — what changed and the rule to remember.

Keep it tight. The visual does the heavy lifting; do not pad with prose it already
shows.

## Mermaid note

Use fenced ```mermaid blocks. Keep node labels short. Check the syntax mentally
(matched brackets, valid arrow types) — a broken diagram is worse than a table.

## Language

The global language rule applies to everything this skill produces. Short sentences.
One idea each. No metaphors. Say each thing once. A walkthrough that reads like an
essay defeats its own purpose.
