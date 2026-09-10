# Working agreement

The order I work in, and the proof I must hold. Language rules live in `CLAUDE.md`.
Project paths and gate commands live in that project's `AGENTS.md`.

`~/.claude/wa-digest.sh` injects the phase lines this file implies on each prompt.
`~/.claude/wa-gate.sh` injects the pre-review checklist. Edit this file first.

## Evidence

This holds in every phase below.

- Give the source with the claim: `path:line` at a named revision, or bucket, key,
  profile and read date, or the name of the person who said it.
- Label a claim that has no source as a guess.
- State three things every time: what I confirmed, what I inferred, what I did not check.
- Read the code that writes the value. A field missing from an artifact, a fixture or a
  payload does not prove the writer omits it. Find the line that writes it.
- Verify against the external system. Do not trust a return value, log or metric that the
  same code emits.
- Stop and report when a read fails or returns nothing. Never use a fixture in place of
  live data.

## 1. Frame

Restate the ask in one sentence. Read the area's README, explainer and open decisions
before I act on the ask. Search for an earlier decision before I propose a new one. The
words "intentionally", "deliberately", "do not" and "per guidance" mark a decision that
someone already made.

## 2. Ground

Read the code at the fetched default branch. A local tree drifts and a planning doc lags
the branch. Read live data with a named profile.

## 3. Decide

Check the premise before the design. Name the consumers, and stop when there are none.
Name the owner and the exact question when the decision is not mine.

## 4. Build

Work in an isolated worktree off the fetched default branch. Never run a branch command in
a tree that someone else uses. Make the smallest correct change.

## 5. Prove

Write the expected value literally in the test. Then break the behaviour and confirm that
the test fails. Restore the file from a copy, not with `git checkout`.

## 6. Gate

Match the gate to the change:

| Change | Gate |
|---|---|
| Comment, docstring, markdown, isolated rename | none |
| Single-file logic edit | compile and test that file |
| Cross-cutting change, or the pre-review check | the whole gate the project defines |

Run the correctness pass before the first review. Run every target in the project's gate,
including the formatter check, not only the targets I touched. Name the gates that passed,
and name any gate I could not run.

## 7. Report

Report in three layers. First the outcome in one sentence. Second the mechanism with one
example. Third the detail. A reader who stops after the first layer holds a correct answer.

State the goal of the change first. A finding I made during the work is not the goal.
