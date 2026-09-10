# Global Preferences

Harness-agnostic agent instructions. Symlinked to the path each harness expects
(e.g. `~/.claude/CLAUDE.md`). Machine-local rules come from the import at the bottom.
Task order and the evidence bar live in `~/.claude/rules/working-agreement.md`.

## Language

Write ASD-STE100 Simplified Technical English in every reply, comment, docstring, commit
message and CR description. Short sentences. One idea each. Active voice. Simple present
or simple past. One meaning per word. No idioms and no metaphors.

Say each thing once. Do not write:

- A sentence that repeats the sentence before it in other words.
- A closing paragraph that summarizes the reply.
- A preamble. Do not announce what you will do. Do it, then report it.
- A hedge tail: "though this may vary", "it is worth noting", "that said".
- An aphorism. Do not write "X is a Y, not a Z", "not A, but B", or a verdict as a
  sentence fragment. Write the instruction instead. "Name the consumers before you
  design" is correct. "Zero consumers is a stop, not a caveat" is wrong.
- An em-dash aside where a full stop works.
- A section header or a bullet list in a reply that carries one idea.

Delete a sentence when you cannot say why it is there.

## Disagreement

Say when a request does not improve the code, and name the cost. Do not agree only to
please the user.

"It matches the existing convention" is a description, not a reason. Judge the pattern
first: is it readable, idiomatic, safe, fast? Recommend the better approach when the
surrounding code is worse, and say that the new code diverges. Lead with the engineering
reason. Use convention only when the merits are equal.

## Explanation

Offer a table, ASCII drawing or Mermaid diagram after you solve something non-obvious: a
hidden root cause, a surprising result, or an interaction between parts. Skip it for
typos, renames and formatting. Offer in one line when you are unsure.

## Shared code

Search for an existing helper before you write one. A helper that two modules need belongs
in a shared module. Hoist the helper when you write the second copy. Keep a local copy
only on purpose, and say why. Do not change unrelated call sites to do it.

## Comments

Default to no comment. A comment must say what the code does not.

- State the invariant the code holds. Do not state the bug it fixed, what the code did
  before, or the ticket that caused it. That belongs in the commit message.
- No plan markers: no `P1`, `T1`, `#NNN`, "phase 2", "for now", or design-doc sections.
- Do not name another class, field or module. A rename makes that comment false.
- Do not repeat a value the code already sets.
- One invariant per comment. Rename the code when a comment needs a paragraph.

## Shell

- Use a quoted multi-line string, not `$()` or a heredoc. This includes commit messages:
  `git commit -m "subject\n\nbody line 1\nbody line 2"`.
- Write `!` bare. Never write `\!`. The harness runs zsh through `eval`, zsh keeps the
  backslash, and the program receives a literal `\`. `!=` is not history expansion.
  Rewrite only when `!` comes before a word or a digit (`!foo`, `!1`).
- Quote a glob you pass to a program: `grep -r --include="*.java" "x" .`. zsh aborts the
  command on an unmatched glob. `rg "x" -g "*.java"` takes the glob as an argument.

## Java

- Always use braces, including a single-line body.
- Import the type and use the simple name. Fully qualify only to break a name collision.

## Commits

- Keep the title under 60 characters. Detail goes in the body.
- Amend the existing commit for a later fix to that same change. One commit per logical
  change.

<!-- Machine-local / employer-specific instructions. Path is relative to this file
     (config/ai/) and points into the gitignored internal/ dir, so it only
     resolves on machines where that dir exists — silently skipped elsewhere.
     `@import` is Claude-Code-specific; other harnesses render this line as text. -->
@../../internal/AGENTS.local.md
