# Global Preferences

Harness-agnostic agent instructions. This file is symlinked to whatever path a
given harness expects (e.g. `~/.claude/CLAUDE.md`). Machine-local / employer-specific
rules are pulled in via the import at the bottom — absent on machines that don't have it.

## Behavior

- Don't blindly agree with suggestions or requests. If something doesn't actually improve the code, or if the user's suggestion has a downside, say so and explain the tradeoff. Question the human when appropriate.
- "Matches the existing convention" is NOT a justification on its own — it's a description. Existing patterns may be bad. When deciding whether to follow a local pattern, first judge whether the pattern is actually *good* (idiomatic, readable, performant, bug-resistant by industry standards). If the surrounding code does something suboptimal, say so and recommend the better approach, even if it means the new code diverges locally — note the divergence so it's deliberate. Consistency with a bad pattern is a real but secondary cost; weigh it, don't let it win by default. Lead recommendations with the engineering reason (DRY, type-safety, readability, perf, blast radius), and cite convention only as a tiebreaker after the merits are equal.
- After solving something non-trivial (non-obvious root cause, counterintuitive result, multi-piece interaction, or a tricky data/control flow), proactively close with a visual/structured explanation — pick the medium that fits (table, ASCII, Mermaid, or HTML). Skip it for typos, one-liners, renames, and formatting; when unsure whether it clears the bar, offer in one line rather than dumping an essay.
- Put common things in a common home. Before writing a helper, check whether one exists and reuse it; a helper used (or re-rolled) by more than one module belongs in a shared module, not copied. "Every sibling defines its own local copy" is not license to add the (N+1)th — it's a signal to extract. When porting or writing a second near-identical helper, hoist it (and note the divergence if you deliberately keep a local one). Weigh the extraction against blast radius — don't refactor unrelated call sites without need — but new code should consume the shared version.

## Shell Commands

- Prefer multi-line strings over `$()` command substitution or heredocs wherever possible.
- For multi-line git commit messages, use a quoted multi-line string directly — never use `$(cat <<'EOF'...EOF)`.
- Example: `git commit -m "subject\n\nbody line 1\nbody line 2"` or a literal multi-line quoted string.
- The Bash harness runs commands via `eval` under zsh. Do NOT defensively escape `!` as `\!` — that backslash is the bug: zsh leaves `\!` intact, so a literal `\` reaches the program (e.g. in Python, `\!=` is read as a line-continuation char and throws `SyntaxError: unexpected character after line continuation character`). A bare `!` is almost always fine — `!=` is NOT a zsh history expansion (only `!` followed by a word/digit/`!`/`?`/`^` is), so `n % 2 != 1` runs cleanly. Rule: write `!` bare, never `\!`. Only when `!` is genuinely followed by a history designator (e.g. `!foo`, `!1`) rewrite to avoid it — in jq `(x == y) | not`, in tests/shell `-ne`/`-z`/`unless`.
- zsh aborts the whole command on an unmatched glob (`nomatch`), unlike bash which passes it through literally. So `--include=*.java` errors with `no matches found` when the cwd has no `.java` files. Quote globs meant for the program, not the shell: `grep -r --include="*.java" "x" .`, or prefer `rg "x" -g "*.java"` which takes globs as real arguments.

## Code Comments

- In code (production and tests), comments and javadocs should explain the **invariant** the code maintains, not its history or the bug it fixed. No "Regression:", "Fix for X", "added for Y", "previously did A, now does B", or descriptions of the bug being guarded against. Those belong in the commit message and code-review description. Test docstrings should describe the property being asserted, not why the test exists.
- Also no **roadmap / planning-position** markers in shipped comments: no phase/task/ticket markers (`P1`, `P2`, `A1`, `T1`, `#NNN`), no "later phase", "first; … follows", "for now", "shipped", and no references to planning-doc sections (`HLD 02 §5`, design-doc names). A comment says what is true and why it holds — not where the code sits in a plan or which doc/ticket motivated it. That belongs in the CR/commit/planning docs. (Same leak class as the task-markers-in-CR-text rule, applied to code comments.)

## Java Style

- Always use braces for `if`, `else`, `for`, `while` blocks, even when the body is a single line.
- Never fully-qualify a type inline when it isn't needed to disambiguate — add a normal `import` and use the simple name (e.g. `import edu.umd.cs.findbugs.annotations.SuppressFBWarnings;` then `@SuppressFBWarnings(...)`, not `@edu.umd.cs.findbugs.annotations.SuppressFBWarnings(...)`). Only fully-qualify to resolve a genuine name collision.

## Git Commits

- Keep commit title (first line) short — under ~55-60 characters so it doesn't get cut off.
- Put additional details in the commit body, not the title.
- When making iterative fixes to the same logical change (review feedback, bug fixes in just-committed code, refactors), amend the existing commit instead of creating a new one. One clean commit per logical change.

## Match build/verification scope to change scope

Before running any full build/test/lint sweep (`npm run build`, `cargo build`, full `vitest`/`pytest`/`mocha`, etc.), ask: *can this change actually break compile, tests, or static analysis?* If not, skip the sweep entirely.
- Comment / javadoc / markdown / doc-prose, or a pure rename in isolation → **no build**. Just commit & push. These cannot break compilation, tests, or lint/static analysis.
- Single-file logic edit → targeted compile/test of that file if anything, not the full release gauntlet.
- Cross-cutting change, or the final pre-review check → one full sweep is appropriate.

The "build green before review" habit is for code changes, not prose. Don't fire a multi-minute full-test + static-analysis run for a sentence of comment.

<!-- Machine-local / employer-specific instructions. Path is relative to this file
     (config/ai/) and points into the gitignored internal/ dir, so it only
     resolves on machines where that dir exists — silently skipped elsewhere.
     `@import` is Claude-Code-specific; other harnesses render this line as text. -->
@../../internal/AGENTS.local.md
