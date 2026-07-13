---
name: explain
description: Produce a clear visual/structured explanation, choosing the best medium (table, ASCII diagram, Mermaid, or HTML) for the content. Works at two scopes — a single solved problem (root cause, why the fix works, counterintuitive result) OR a whole-session recap (what we did, why it was needed, what problem we're solving, where it sits in the bigger arc). Use at the end of a session that did something non-trivial, or on demand when the user asks to "explain", "break this down", "why did that work", "what did we achieve / accomplish", "recap", or wants a writeup of a bug/design decision.
user-invocable: true
allowed-tools:
  - Read
  - Write
---

# /explain — Explain a solved problem with the right visual medium

Turn a non-trivial thing you just figured out (a bug root cause, a design
decision, a counterintuitive result, a tricky data flow) into an explanation
the user can actually absorb — using whichever medium fits the *content*, not a
default wall of prose.

## First: which scope is being asked for?

Before picking a medium, decide what the user wants explained — these need
different content, and conflating them is the most common failure:

- **Problem scope** — one bug, one decision, one tricky flow. "Why did that
  work?", "explain this fix", "why is summing those ratios wrong?". Answer with
  root cause → visual → why the wrong instinct fails → takeaway.
- **Session scope** — the whole arc of what was just done. "What did we
  achieve?", "what did we accomplish / do?", "recap", "what problem are we
  solving?". Answer at *project altitude*, not implementation detail:
  1. **The problem** — what was broken/missing and why it mattered (the
     business/architectural reason, not the code).
  2. **What we achieved** — a table of the concrete wins, each with *why it was
     needed*. Outcomes, not a commit log.
  3. **Where it sits** — the bigger arc: what this unblocks, what's still ahead.

  For session scope, do NOT lead with the last edit you happened to make — lead
  with the goal of the whole session. If the most recent change was a small
  cleanup, it belongs in a single row, not the headline.

When the request is ambiguous, default to **session scope** if the user said
"we"/"this session"/"achieve"/"accomplish", and **problem scope** if they
pointed at a specific bug, function, or result.

## When to produce this

**On demand:** whenever the user invokes `/explain` or asks to "explain",
"break it down", "draw it", "why did that work", "what did we achieve", "recap",
or wants a writeup.

**Proactively, at the end of a session** — but ONLY when the work clears a
real complexity bar. Produce it when any of these hold:

- The root cause was non-obvious or took multi-step reasoning to find.
- The result is counterintuitive (the correct answer contradicts a reasonable
  first instinct — e.g. "why summing these ratios is wrong").
- A non-trivial data/control flow, state machine, or dependency graph is
  involved.
- The fix touched several interacting pieces and the *why* isn't visible from
  the diff alone.

**Do NOT fire for:** typo fixes, one-line changes, mechanical refactors,
renames, formatting, or anything where a single sentence already says it all.
When unsure whether it clears the bar, ask the user with one line ("want me to
write this up visually?") rather than dumping an unprompted essay.

## Pick the medium from the content (this is the whole point)

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
| Rich/interactive artifact the user wants to keep, multiple linked diagrams, styled comparison | **Standalone HTML file** written to disk, then tell them the path |

Guidance:
- **Default to a table or ASCII** for terminal-read answers — they render
  inline with zero dependencies. Reach for Mermaid when the relationships are
  graph- or sequence-shaped and a table would flatten them.
- **Only write an HTML file** when the user wants something durable/shareable,
  or the explanation genuinely needs interactivity, layout, or several diagrams
  together. Don't write a file for something a 6-row table covers — and
  remember writing a file to disk is a side effect, so prefer inline unless
  durability is the point. When you do, give them the absolute path.
- Prefer the *simplest* medium that carries the idea. A table beats a diagram
  beats an HTML page when all three would work.

## Structure of the explanation

Lead with the answer, then show why. A good explanation usually has:

1. **The headline** — one sentence: what was actually going on / the answer.
2. **The visual** — the table/diagram/page that carries the core insight.
3. **Why the wrong instinct is wrong** (when there is one) — name the intuitive
   answer, show concretely why it fails. This is the highest-value part when the
   result is counterintuitive.
4. **The fix / takeaway** — what was changed and the rule to remember.

Keep it tight. The visual should do the heavy lifting; don't pad with prose the
diagram already shows.

## Mermaid note

Use fenced ```mermaid blocks. Keep node labels short. Test mentally that the
syntax is valid (matched brackets, valid arrow types) — a broken diagram is
worse than a table.
