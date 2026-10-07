---
name: elevate
description: Raise a code change to a high engineering bar. Correctness first, then architecture, robustness and craft. Runs one concurrent wave of eleven finders, verifies their findings in file batches, and applies the fixes. Pass a design brief or plan to review its architecture before any code exists. Use on demand ("/elevate", "elevate this", "review to a high bar") before a code review.
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

Correct first. Then the design shape, because it decides whether line-level work is
worth doing. Then robust, then well-crafted. Never trade a correctness fix for a style
one.

Run the fleet below inline. Do not invoke `/code-review` or `/simplify`. Their angles are
already here, and a skill invocation loads its whole transcript into this context.

> Re-sync: angles A–E are a snapshot of the built-in `/code-review` finders, which are
> compiled into the CLI binary. Diff them against the current set:
> `strings -n 40 ~/.local/share/claude/versions/<latest> | grep -n "### Angle"`

## Phase 0 — Scope once, brief once

Get the change under review:
- `git diff @{upstream}...HEAD`, falling back to the merge base with the default branch
  (`main` or `mainline`), then `git diff HEAD~1`.
- Also `git diff HEAD` when there are uncommitted changes or the range is empty.
- If a PR number, branch, or path was passed as an argument, review that instead.

If the diff only touches comments/docs/renames/formatting with no runtime surface, say
so and stop. There is nothing to elevate. One exception: when the argument is a design
brief or a plan and no code exists yet, build the system section, run J alone with its
verifier, and report only Architecture. A design decision costs least to change before
any code exists.

Otherwise create the brief with `mktemp -t elevate-brief.XXXXXX`, so two sessions never
share one file. Every agent reads the brief. No agent re-runs `git diff` or re-searches
callers. Write into it:
- the unified diff;
- the changed symbols (functions/classes/exports touched);
- **for each changed symbol, its call sites.** Issue every symbol's `Grep` in one
  message. This is the highest-value item in the brief: most real bugs live in the
  interaction between changed code and unchanged callers, which a diff-only reviewer
  cannot see. One call hop out is in review scope even though the diff never touched it;
- **the runtime contract**: what executes this code (a request handler, a serverless
  invocation, a batch job, a UI render, a signal handler) and its lifecycle rules. When
  may the host suspend, freeze, or reclaim the process? What does it guarantee to flush?
  What does it charge per call? For example, AWS Lambda may freeze the process once the
  handler returns, so work that started and was never awaited may never finish;
- **the system section**, when the change adds a component (handler, job, service,
  table, bucket, queue, stack), a read path over stored data, a storage key or layout, a
  read of another team's data, or a published contract, or when a design brief was
  passed:
  - the problem, and each consumer with the question it asks. Write "none found" when
    the sources name no consumer;
  - each write path and each read path: what triggers it, how often it runs, and what
    one run costs in calls, objects read, bytes parsed and latency. Read the code to
    count, and read live volumes with a named profile when the brief names one;
  - the decisions the change makes that a reviewer may question: the data source, where
    computation runs, schedule or event trigger, storage keys and layout, logic copied
    from another team;
  - the deploy state: deployed or not, data already written under the schema, external
    readers. This sets the cost to switch now against later.

  Take these from the passed design brief (copy it verbatim), the CR description, and
  the design docs and README the repo holds;
- the commit messages in the range, and the CR or PR description when one exists;
- the read-only AWS profiles the project's `AGENTS.md` names, if any;
- paths (not contents) of the root `CLAUDE.md`/`AGENTS.md` and any in touched directories.

Then set the budget tier from the diff size:

| Tier | Trigger | Candidates per angle | Max verifier agents |
|---|---|---|---|
| quick | ≤50 changed lines, 1 file | 3 | 2 |
| standard | up to ~500 lines or ~10 files | 6 | 5 |
| deep | larger, cross-cutting, or explicitly requested | 8 | 8 |

A small diff gets fewer candidates per angle, never fewer angles. State the tier you
picked and why, in one line.

## Phase 1 — One concurrent wave (11 agents, single message)

Launch all eleven via the `Agent` tool **in one message**. The angles have no data
dependency on each other. Order belongs to the report and to fix application. Give each
agent the brief path and one angle. Agents H, I and K run with `model: "sonnet"`. The
others inherit the session model.

Finders and verifiers are read-only: no edits, builds, branch changes or AWS writes. An
AWS read uses a profile the brief names, with a narrow query.

Each finder returns up to the tier's candidate budget as
`{file, line, summary, failure_scenario}`. Agents F–I and K add `{principle, cost, fix}`.
J uses its own shape. `principle` names the rule or the industry pattern and its source,
so the finding carries authority. A repo precedent is never a reason, for or against.

A candidate names the input, state, or runtime event that makes the code do the wrong
thing, and the resulting behavior. "This might be unsafe" is not a candidate. Pass
through every candidate that clears that bar, even a half-believed one. The verify step
exists to judge them, and a finder that drops one silently bypasses it. That is the main
way real bugs get lost. If two angles flag the same line for different reasons, both go
through.

Judge each intended change by its consequence. Moving logic out of a unit can satisfy
the goal and create a defect at the new site. When something moved, review the
destination on its own terms: is this the right place, under this runtime, at this
layer, with this error and logging contract?

Skip test/fixture hunks (`test/`, `spec/`, `__tests__/`, `*_test.*`, `*.test.*`,
`fixtures/`, `testdata/`) unless the change is *to* test infrastructure.

### Correctness (agents 1–5)

**A — line-by-line diff scan.** Read every hunk line by line, then Read the enclosing
function for each hunk. Bugs in unchanged lines of a touched function are in scope.
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
a timing/ordering dependency. Also check callees: does a parallel change in the same
diff make a call unsafe?

**D — language-pitfall specialist.** Scan for the classic pitfalls of the diff's
language/framework: JS falsy-zero, `==` coercion, closure-captured loop var; Python
mutable default args, late-binding closures, dataclass default evaluated once; Go
nil-map write, range-var capture; SQL injection; timezone/DST drift; float equality;
`hash()` non-determinism; lock-scope shrink; predicate methods with side effects.

**E — wrapper/proxy correctness.** When the change adds or modifies a type that wraps
another (cache, proxy, decorator, adapter): check that every method routes to the
wrapped instance and not back through a registry/session/global. A caching provider
whose `delegate` field resolves via `session.get(...)` instead of `delegate.get(...)`
will re-enter the cache or recurse. Check the wrapper forwards every method its
callers actually use.

### Robustness (agents 6–7)

**F — failure modes.** What happens on the unhappy path? Unhandled exceptions, silent
catch-and-swallow, missing timeouts/retries/idempotency, resource leaks, degradation
behavior, log-and-continue vs fail-fast chosen wrongly, setup/teardown asymmetry in
tests, config defaults flipped. Flag happy-path-only code.
Grounds: *DDIA* (faults are the norm; design for partial failure), *Pragmatic
Programmer* (crash early, assertive programming).

**G — runtime contract & cost.** The defects here hide in correct-looking lines. Work
from the runtime contract and the call sites in the brief, not from the diff alone.
*Lifecycle:* does the code assume work completes that the host may never run? Look for
async work started but not awaited before the unit of execution ends, cleanup on a path
the runtime can skip, and state cached across invocations that the platform may discard
or reuse. *Contracts one hop out:* does a called module behave as the caller assumes?
Check its severity levels, error types, retry and timeout behavior, and whether it
throws or returns. An expected, handled condition that the callee reports as a failure
pages someone. The offending line sits in a file the diff never touched, and it is still
this change's defect. *Waste:* correct code that pays a cost it does not need. Look for
work done eagerly but consumed on one branch only, a fetch inside a concurrent batch
that one mode discards, per-item I/O where a batch call exists, and log or metric volume
out of proportion to its value.
Grounds: *DDIA* (know the guarantees the platform actually gives you), *Pragmatic
Programmer* (don't assume it, prove it), *Staff Engineer's Path* (a cost paid on every
request is a design decision).

### Craft (agents 8–9)

For each finding state the concrete cost: what is duplicated, wasted, or harder to
maintain.

**H — structure & responsibility.** SRP: does each unit do one thing, or does it mix
levels of abstraction and change for more than one reason? DRY applied with judgment:
flag *knowledge* duplication (the same rule encoded twice) and reuse misses (a helper
that already exists). Equally flag the opposite failure: a premature or wrong
abstraction forcing unrelated cases together. Prefer "duplicate until the abstraction
is obvious." Also: redundant or derivable state, deep nesting, dead code left behind.
Grounds: *Clean Code* (one thing, one level of abstraction), *Pragmatic Programmer*
(DRY = one authoritative representation; rule of three).

**I — interface, domain purity & naming.** Is each signature honest and minimal? Flag
parameters a method can derive itself (thread `site`, derive `siteId` locally, do not
pass both), booleans that should be enums, primitive obsession where a value object
would enforce an invariant, `Optional` as a *parameter* (avoid) vs a *return* (fine),
leaky return types, easy-to-misuse ordering of like-typed args. Does domain logic stay
free of I/O and infrastructure types? Flag persistence/DTO/framework beans in domain
signatures, business rules stranded in controllers, and an anemic model where behavior
belongs on the entity. Do names reveal intent without a comment, and match the
ubiquitous language?
Grounds: *Clean Code* (few arguments, no flag args, intention-revealing names), *DDD*
(layered architecture, entities own their invariants), *Pragmatic Programmer* (design
by contract; easy to use right, hard to use wrong).

### Architecture (agent 10)

**J — design shape.** After correctness, this angle carries the most weight. It finds
the easy implementation where a better architecture exists. Line-level defects belong
to the other angles.

Example of the target finding: a scoring API read 14–28 plan files from S3, each up to
several MB, and parsed them on every request. Every line was correct. The better shape
writes the score to DynamoDB each time the planner runs, so a request costs one or a
few `GetItem` calls. The price was one table and one write step. The easy shape avoided
that infrastructure and paid for it on every read.

Work in two steps, so the current code does not anchor your design:
1. Read only the system section. Design the shape you would build for each consumer:
   where the result is computed, where it is stored, and what one read costs.
2. Read the diff and its call sites. Each place where your shape costs materially less,
   or serves a consumer the current shape cannot, is a candidate.

When the brief has no system section, derive the read and write paths from the diff and
its call sites, then do both steps. Test both shapes against five questions:

- *Where does computation live?* Compare how often each result is read with how often
  its inputs change. A result that many reads recompute from the same inputs belongs on
  the write path, stored once. A result that few reads need, from inputs that change
  often, stays on the read path.
- *Who owns the data and the logic?* A rule copied from another team drifts with no
  signal when the owner changes it. A read of another team's internal store couples
  this change to their schema. The usual better shape: the owner publishes the value.
- *Is the machinery proportionate, in both directions?* Too much: a component with no
  named consumer, or a schedule, a second store or a service where an event, one store
  or a library serves the same consumers. Too little: a shape chosen because it adds no
  infrastructure, where one table or one write step removes a cost that every read
  pays.
- *Which pattern does the industry use here?* Name it and its source. A shape copied
  from a local precedent where the industry pattern differs is a finding.
- *Which contracts will be hard to change?* Storage keys and layouts, event and wire
  shapes, identifiers other systems store, coupling that amplifies a likely change. Each
  costs little before the first deploy and needs a migration after it. Flag one with no
  versioning or compatibility story. Flag altitude errors: a special case bolted onto
  shared infrastructure, or a fix one layer below the problem.

Return at most 6 findings, ranked by impact, as
`{where, current, better, principle, cost, switch_now, switch_later, confidence}`.
`where` is a `file:line` or a decision from the brief. `cost` is what breaks, what is
duplicated, or what a likely change costs. `confidence` is high, medium or low. Give one
concrete example per finding. When the current shape is the right one, say so in one
line and return no finding for it.
Grounds: *DDIA* (ch. 1 fan-out on write against fan-out on read; ch. 11–12 derived
data, materialized views, the boundary between write and read paths; schema
evolution), *DDD* (bounded contexts, published language), Fowler (CQRS, event-driven
patterns), *AWS Well-Architected*, *Google SRE*, *Staff Engineer's Path* (design for
the change you need next; reduce blast radius).

### Written rules and prose (agent 11)

**K — written rules and prose.** Review the prose the change adds against the rules
below. They hold whether or not a `CLAUDE.md` exists. Also read the
`CLAUDE.md`/`AGENTS.md` files the brief lists, and flag a real violation of any rule
they add. Quote that rule.
- *Comments and docstrings.* Each one states an invariant the code does not show. Flag
  one that narrates history, names the bug or ticket behind it, carries a plan marker
  (`P1`, `phase 2`, "for now"), or repeats a value the code already sets. Flag one that
  names another class, field or module, because a rename makes it false. One invariant
  per comment. A comment that needs a paragraph asks for a rename instead.
- *Logic explained in prose.* Where a comment describes a multi-step rule, a precedence
  order, or an index/offset convention, a two-line worked example reads faster. Write
  the example in the finding.
- *Runtime output.* Judge every log line, error, assertion message, CLI string and skip
  reason the change adds from the seat of a reader with no source at hand. It must name
  the value that failed, the predicate, and the scope it applies to.
- *Commit message and CR description.* Title under 60 characters. One idea per
  sentence, active voice. Flag a preamble, a closing paragraph that restates the body,
  a hedge tail ("it is worth noting", "that said"), an aphorism ("X is a Y, not a Z"),
  an em-dash aside where a full stop works, a plan marker, and AI attribution.

Quote the offending text and give the rewrite. A finding without the rewrite or the
example does not count.
Grounds: *ASD-STE100* Simplified Technical English (one idea per sentence, active voice,
one meaning per word), *Clean Code* ch. 4 (a comment explains intent; redundant,
journal and misleading comments are defects).

## Phase 2 — Dedup, then verify in batches (+ sweep, same wave)

Dedup candidates that point at the same line or mechanism, keeping the one with the
most concrete failure scenario.

Then group the survivors and launch the verifiers **plus the sweep finder in a single
message**. The sweep needs the candidate list, which you now have, so it does not wait
on verify results.

**Batching rule**, the core speed/rigour knob:

```
1. Split candidates into three pools:
     correctness  = angles A-G
     architecture = angle J
     craft        = angles H, I, K
   Correctness gets small batches (a wrong call ships a bug). Craft gets large
   ones (a wrong call costs a dismissed suggestion). By that test G splits:
   its lifecycle and contract candidates are correctness, its waste ones craft.
   K goes to craft whole: wrong prose misleads a reader, and it never changes
   the answer the code returns.

2. The architecture pool is one batch with its own verifier, outside the tier
   cap. Its candidates span files and need the system section.

3. Sort the correctness and craft pools by file path, so candidates in the same
   file stay adjacent.

4. Fill batches greedily down each sorted pool:
     correctness -> at most 4 candidates per batch
     craft       -> at most 10 candidates per batch
   Keep a file's candidates in one batch where the cap allows. When a single
   file exceeds the cap, split it across consecutive batches. They reload the
   same file cheaply, and the cap protects attention.

5. Enforce the tier's max verifier agents. If the batch count exceeds it,
   merge craft batches into each other first (up to 16 each), then merge
   correctness batches, never past 6 candidates. If that still exceeds the
   cap, keep the highest-severity correctness batches as their own agents and
   fold the remaining craft candidates into the last one.

6. Never spawn an agent for a batch of one unless it is the only batch. A lone
   leftover candidate joins the smallest batch in its own pool.
```

This means 15 files with one candidate each become ~4 agents, not 15; and one file
with 20 correctness candidates becomes 5 batches of 4, capped back to the tier.

Craft verifiers run with `model: "sonnet"`. The others inherit the session model. Each
verifier gets the brief path, the file(s) its batch touches, and its batch of
candidates. For each candidate it returns exactly one of:
- **CONFIRMED**: can name the inputs/state that trigger it and the wrong result.
- **PLAUSIBLE**: cannot fully confirm, but cannot rule it out either.
- **REFUTED**: demonstrably not a defect.

The architecture verifier checks each premise against the code and live data. Is the
current shape as stated? Does the cost hold (count the objects, read the volumes)? Does
the better shape serve every named consumer? It refutes a candidate when the current
shape is the right one for those consumers. Code that works and adds no infrastructure
does not make the current shape right.

Keep **CONFIRMED and PLAUSIBLE**; drop only REFUTED. A missed bug ships; a false
positive costs five seconds to dismiss.

**Sweep finder (same wave).** A fresh reviewer who has the deduped candidate list.
Re-read the diff and enclosing functions looking *only* for defects not already listed.
The job is gaps, not re-confirmation. Focus on what a first pass tends to miss: moved
or extracted code that dropped a guard or anchor, second-tier language footguns,
setup/teardown asymmetry in tests, config defaults flipped. If nothing is new, return
nothing. Verify its few candidates yourself with the same three verdicts: read each
cited line. A third agent round costs more time than those reads.

## Phase 3 — Apply and report

Apply the surviving fixes in priority order. Correctness fixes always land. Skip, with
a one-line reason, any fix that would change intended behavior, sprawl well beyond the
diff, or that you judge a false positive. Do not auto-apply a behavior-changing fix for
a candidate that is only PLAUSIBLE: report it with its failure scenario and let the
user decide.

Never auto-apply an architecture finding. It changes the design, and the owner decides.
Do not apply a craft fix inside a unit that a CONFIRMED architecture finding would
replace. List it under Skipped. Correctness fixes there still land, because the code
may ship as it is.

Where a test already covers the code a candidate sits in, running that test is better
evidence than another round of reasoning. Prefer it when it is cheap.

Push back when a principle would make the code worse here (a forced abstraction, a
stream that hurts readability, an SRP split that fragments a cohesive unit), and cite
the tradeoff. Write fixes with `final`/immutable locals.

Report grouped by severity:
- **Correctness** (A–E + sweep): what was wrong, what was fixed, what is PLAUSIBLE and
  awaits a judgment call.
- **Architecture** (J): each decision for the owner as current → better, cost, switch
  now against later, confidence, and its example.
- **Robustness** (F–G): failure modes hardened, runtime assumptions corrected, wasted
  work removed.
- **Craft** (H–I): each tagged with the principle that motivated it.
- **Written rules and prose** (K): violations fixed with the rule quoted, worked
  examples added. Give commit and CR text rewrites in the report. Do not amend a commit
  or edit a CR.
- **Skipped**: findings deliberately not applied, with reasons.

State the tier that ran and the agent count, so the reader knows the depth of what
actually executed. Name the runtime contract you reviewed against, and say whether the
brief had a system section. Name the files you read one hop outside the diff. If you
read none, say so, because the review then covered only the changed lines. If the
change was already clean at this bar, say that plainly rather than inventing work.
Delete the brief file.
