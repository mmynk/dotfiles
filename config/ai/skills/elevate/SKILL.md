---
name: elevate
description: Raise a code change to a high engineering bar — correctness first, then craft and robustness. Runs one concurrent wave of correctness finders (line-scan, removed-behavior, cross-file, language-pitfall, wrapper/proxy), a conventions check, and a principle-grounded craft/robustness layer (SRP, DRY, DDD domain purity, API design, naming, failure modes, data-evolution safety) drawing on Clean Code, The Pragmatic Programmer, Designing Data-Intensive Applications, Domain-Driven Design (Evans), and The Staff Engineer's Path — then verifies findings in file-batched groups and applies the fixes. Use on demand ("/elevate", "elevate this", "review to a high bar") before a code review.
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Grep
  - Glob
  - Skill
  - Agent
---

# /elevate — raise a change to a high engineering bar

Correct first, then robust, then well-crafted. A beautiful function that returns the
wrong answer fails elevate. Never trade a correctness fix for a style one.

This skill runs its own fleet inline. It does **not** invoke `/code-review` or
`/simplify`, for two reasons: those two overlap each other (`/simplify`'s four angles
are a subset of `/code-review`'s cleanup angles — they share one source module), and
invoking a skill loads its full transcript into this context, which serializes work
that has no data dependency. The angles below already cover both, plus the two
correctness angles `/code-review` runs only at `xhigh`.

> Re-sync note: the correctness angles in Phase 1 track the built-in `/code-review`
> finder set. They are a snapshot, not a live reference — the originals are compiled
> into the CLI binary. To diff against the current version:
> `strings -n 40 ~/.local/share/claude/versions/<latest> | grep -n "### Angle"`

## Structural rules — these are what make it fast

1. **One discovery pass, shared.** Phase 0 builds the brief once. Every agent reads
   that file. No agent re-runs `git diff` or re-greps for callers.
2. **One finder wave.** All of Phase 1 launches in a **single message**. Correctness
   and craft have no data dependency on each other — ordering belongs to the *report*
   and to *fix application*, not to execution.
3. **Verify in file-batched groups, never per candidate.** One agent per candidate is
   the dominant cost of a naive review fleet and it re-reads the same file N times.
4. **Budget scales with the diff; the angle list does not.** A small diff gets fewer
   candidates per angle, not fewer angles — coverage shape stays constant at every size.

## Phase 0 — Scope once, brief once

Get the change under review:
- `git diff @{upstream}...HEAD`, falling back to `git diff main...HEAD` / `git diff HEAD~1`.
- Also `git diff HEAD` when there are uncommitted changes or the range is empty.
- If a PR number, branch, or path was passed as an argument, review that instead.

If the diff only touches comments/docs/renames/formatting with no runtime surface, say
so and stop — there is nothing to elevate.

Otherwise write `/tmp/elevate-brief.md` containing:
- the unified diff;
- the changed symbols (functions/classes/exports touched);
- **for each changed symbol, its call sites** — one `Grep` per symbol. This is the
  single highest-value item in the brief: most real bugs live in the interaction
  between changed code and unchanged callers, which a diff-only reviewer cannot see;
- paths (not contents) of the root `CLAUDE.md` and any `CLAUDE.md` in touched directories.

Then set the budget tier from the diff size:

| Tier | Trigger | Candidates per angle | Max verifier agents |
|---|---|---|---|
| quick | ≤50 changed lines, 1 file | 3 | 2 |
| standard | up to ~500 lines or ~10 files | 6 | 5 |
| deep | larger, cross-cutting, or explicitly requested | 8 | 8 |

State the tier you picked and why, in one line.

## Phase 1 — One concurrent wave (9 agents, single message)

Launch all of the following via the `Agent` tool **in one message**. Give each the
path `/tmp/elevate-brief.md` (not the diff inline) and one angle. Each returns up to
the tier's candidate budget as `{file, line, summary, failure_scenario}`; the craft
agents add `{principle, cost, fix}`, where `principle` names the rule and its source
so the finding carries authority.

Pass through every candidate with a nameable failure scenario. A finder that silently
drops half-believed candidates bypasses the verify step — that is the main way real
bugs get lost. Do not let one angle's conclusions suppress another's: if two angles
flag the same line for different reasons, both go through.

Skip test/fixture hunks (`test/`, `spec/`, `__tests__/`, `*_test.*`, `*.test.*`,
`fixtures/`, `testdata/`) unless the change is *to* test infrastructure.

### Correctness (agents 1–5)

**A — line-by-line diff scan.** Read every hunk line by line, then Read the enclosing
function for each hunk — bugs in unchanged lines of a touched function are in scope.
For every line ask: what input, state, timing, or platform makes this line wrong? Look
for inverted/wrong conditions, off-by-one, null/undefined deref, missing `await`,
falsy-zero checks, wrong-variable copy-paste, error swallowed in catch, unescaped
regex metacharacters.

**B — removed-behavior auditor.** For every line the diff deletes or replaces, name the
invariant or behavior it enforced, then find where the new code re-establishes it. If
you cannot find it, that is a candidate: a removed guard, a dropped error path, a
narrowed validation, a deleted test that covered a real case.

**C — cross-file tracer.** Using the call sites already in the brief, check whether the
change breaks any of them: a new precondition, a changed return shape, a new exception,
a timing/ordering dependency. Also check callees — does a parallel change in the same
diff make a call unsafe?

**D — language-pitfall specialist.** Scan for the classic pitfalls of the diff's
language/framework: JS falsy-zero, `==` coercion, closure-captured loop var; Python
mutable default args, late-binding closures, dataclass default evaluated once; Go
nil-map write, range-var capture; SQL injection; timezone/DST drift; float equality;
`hash()` non-determinism; lock-scope shrink; predicate methods with side effects.

**E — wrapper/proxy correctness.** When the change adds or modifies a type that wraps
another (cache, proxy, decorator, adapter): check that every method routes to the
wrapped instance and not back through a registry/session/global — a caching provider
whose `delegate` field resolves via `session.get(...)` instead of `delegate.get(...)`
will re-enter the cache or recurse. Check the wrapper forwards every method its
callers actually use.

### Robustness (agent 6)

**F — failure modes.** What happens on the unhappy path? Unhandled exceptions, silent
catch-and-swallow, missing timeouts/retries/idempotency, resource leaks, degradation
behavior, log-and-continue vs fail-fast chosen wrongly, setup/teardown asymmetry in
tests, config defaults flipped. Flag happy-path-only code.
Grounds: *DDIA* (faults are the norm; design for partial failure), *Pragmatic
Programmer* (crash early, assertive programming).

### Craft (agents 7–9)

These three replace both `/simplify`'s four angles and the old eight-dimension catalog.
For each finding state the concrete cost — what is duplicated, wasted, harder to
maintain, or which `CLAUDE.md` rule is broken — not a crash.

**G — structure & responsibility.** SRP: does each unit do one thing, or does it mix
levels of abstraction and change for more than one reason? DRY applied with judgment:
flag *knowledge* duplication (the same rule encoded twice) and reuse misses (a helper
that already exists), but equally flag the opposite failure — a premature or wrong
abstraction forcing unrelated cases together. Prefer "duplicate until the abstraction
is obvious." Also: redundant or derivable state, deep nesting, dead code left behind.
Grounds: *Clean Code* (one thing, one level of abstraction), *Pragmatic Programmer*
(DRY = one authoritative representation; rule of three).

**H — interface, domain purity & naming.** Is each signature honest and minimal? Flag
parameters a method can derive itself (thread `site`, derive `siteId` locally — do not
pass both), booleans that should be enums, primitive obsession where a value object
would enforce an invariant, `Optional` as a *parameter* (avoid) vs a *return* (fine),
leaky return types, easy-to-misuse ordering of like-typed args. Does domain logic stay
free of I/O and infrastructure types — no persistence/DTO/framework beans in domain
signatures, no business rules stranded in controllers, no anemic model where behavior
belongs on the entity? Do names reveal intent without a comment, and match the
ubiquitous language?
Grounds: *Clean Code* (few arguments, no flag args, intention-revealing names), *DDD*
(layered architecture, entities own their invariants), *Pragmatic Programmer* (design
by contract; easy to use right, hard to use wrong).

**I — evolvability, altitude & conventions.** Will this be cheap to change? Flag
coupling that amplifies future change, schema/wire formats with no
forward/backward-compatibility story, breaking a published contract without
versioning, and altitude errors — a special case bolted onto shared infrastructure
where the mechanism should generalize, or a fix applied one layer below where the
problem actually is. Then check the change against the `CLAUDE.md` files in the brief:
read them and flag real violations, quoting the rule so the report can cite it.
Grounds: *DDIA* (evolvability, schema compatibility), *Staff Engineer's Path* (design
for the change you need next; reduce blast radius), *Pragmatic Programmer*
(orthogonality, reversible decisions).

## Phase 2 — Dedup, then verify in batches (+ sweep, same wave)

Dedup candidates that point at the same line or mechanism, keeping the one with the
most concrete failure scenario. Same defect, same location, same reason → keep one.

Then group the survivors and launch the verifiers **plus the sweep finder in a single
message** — the sweep needs the candidate list, which you now have, so it does not
wait on verify results.

**Batching rule** — the core speed/rigour knob:

```
1. Split candidates into two pools:
     correctness = angles A-F and the sweep
     craft       = angles G-I
   Correctness gets small batches (a wrong call ships a bug). Craft gets large
   ones (a wrong call costs a dismissed suggestion).

2. Sort each pool by file path, so candidates in the same file stay adjacent.

3. Fill batches greedily down each sorted pool:
     correctness -> at most 4 candidates per batch
     craft       -> at most 10 candidates per batch
   Keep a file's candidates in one batch where the cap allows. When a single
   file exceeds the cap, split it across consecutive batches — they reload the
   same file cheaply, and the cap protects attention.

4. Enforce the tier's max verifier agents. If the batch count exceeds it,
   merge craft batches into each other first (up to 16 each), then merge
   correctness batches — never past 6 candidates. If that still exceeds the
   cap, keep the highest-severity correctness batches as their own agents and
   fold the remaining craft candidates into the last one.

5. Never spawn an agent for a batch of one unless it is the only batch. A lone
   leftover candidate joins the smallest batch in its own pool.
```

This means 15 files with one candidate each become ~4 agents, not 15; and one file
with 20 correctness candidates becomes 5 batches of 4, capped back to the tier.

Each verifier gets the brief, the file(s) its batch touches, and its batch of
candidates. For each candidate it returns exactly one of:
- **CONFIRMED** — can name the inputs/state that trigger it and the wrong result.
- **PLAUSIBLE** — cannot fully confirm, but cannot rule it out either.
- **REFUTED** — demonstrably not a defect.

Keep **CONFIRMED and PLAUSIBLE**; drop only REFUTED. A missed bug ships; a false
positive costs five seconds to dismiss.

**Sweep finder (same wave).** A fresh reviewer who has the deduped candidate list.
Re-read the diff and enclosing functions looking *only* for defects not already listed
— the job is gaps, not re-confirmation. Focus on what a first pass tends to miss:
moved or extracted code that dropped a guard or anchor, second-tier language footguns,
setup/teardown asymmetry in tests, config defaults flipped. If nothing is new, return
nothing — do not pad. Verify anything it finds in one additional batch.

## Phase 3 — Apply and report

Apply the surviving fixes, honoring the priority order. Correctness fixes always land.
Skip — with a one-line reason, not an argument — any fix that would change intended
behavior, sprawl well beyond the diff, or that you judge a false positive. Do not
auto-apply a behavior-changing fix for a candidate that is only PLAUSIBLE: report it
with its failure scenario and let the user decide.

Where a test already covers the code a candidate sits in, running that test is better
evidence than another round of reasoning. Prefer it when it is cheap.

Push back, don't rubber-stamp: if a principle would make the code worse here (a forced
abstraction, a stream that hurts readability, an SRP split that fragments a cohesive
unit), say so and cite the tradeoff. Weigh engineering merit over dogma. Prefer
`final`/immutable locals and locally-derived values.

Close with a tight summary grouped by severity:
- **Correctness** (A–E + sweep) — what was wrong, what was fixed, what is PLAUSIBLE
  and awaiting a judgment call.
- **Robustness** (F) — failure modes hardened.
- **Craft** (G–I) — each tagged with the principle that motivated it.
- **Skipped** — findings deliberately not applied, with reasons.

State the tier that ran and the agent count, so the reader knows the depth of what
actually executed. If the change was already clean at this bar, say that plainly
rather than inventing work.
