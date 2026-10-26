---
name: post-merge
description: Post-merge work after a change lands upstream, scoped to the repo whose work merged — save an explainer of the merged work to the repo's docs folder when the work was complex enough, switch to the default branch, pull, delete the merged branch, reconcile docs the merged change made stale, AND reclaim the scratch files and build scaffolding the session left on disk. Knows a workspace of several repos under one root but cleans only the repos this session changed, never the whole tree unless explicitly asked. Use on demand ("clean up after the merge", "/post-merge", "tidy the repos", "delete merged branches", "the CR merged"), typically right after a CR merges.
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Skill
---

# /post-merge — explain the merged work, then return repos to a clean default branch

Post-merge work in four parts, all confined to what this session touched:
(0) save an explainer of the merged work, when the work clears the complexity bar;
(A) get back on the default branch, pull, and delete the branch that carried that work;
(B) update docs the merged change made stale;
(C) reclaim the scratch files and build scaffolding the session left on disk. Deleting a
branch, editing a doc and removing a file are all destructive, so Parts A to C are built around
**proving the change is safe before making it** — a branch is dropped only when its work is
provably upstream, a doc is edited only where it provably describes behavior the merge
replaced, and a file is removed only when this session created it.

Proof of safety is not permission. Scope comes first: a deletion can be perfectly proven
and still be one the user never asked for. Read **Scope** before running anything.

## Scope

**The repos this session actually changed — and nothing else.** A merge in repo X justifies
cleaning repo X. It never justifies touching repo A, B, or C: their branches are unrelated
local work whose owner did not ask you to judge it. Cleaning them is not hygiene for this
merge, it is unrequested maintenance of someone's working state.

Read the scope off the session, not off the filesystem:
- **Committed or merged in this session** → in scope.
- **Only read, grepped, or built** → NOT in scope. Reading a file is not touching a repo.
- **A workspace with 14 repos where you changed one** → one repo in scope, 13 out.

Re-invoking the command in the same session does **not** widen the scope. A second
`/post-merge` means "do it again", not "do it everywhere" — the session context
that named repo X is still the session context.

**Widen only on an explicit instruction, and confirm the count first.** A tree-wide sweep
is legitimate when the user asks for one ("clean up every package", "tidy the whole tree",
naming the other repos). Even then, state how many repos and how many branches you would
delete and get a yes before the first deletion — a sweep that removes a dozen-plus branch
names across several repos is not what anyone pictures when they say "tidy up". With no
session context at all (a fresh session, nothing committed yet), ask which repo to clean
rather than inferring the whole tree from the working directory.

### Which branches inside an in-scope repo

Prefer the branch that carried the merged work. Other merged branches in the same repo are
fair to offer, but **list them and their tips first and let the user pick** — do not fold
them into the same silent sweep. "Provably upstream" makes a deletion *recoverable*, not
*wanted*: what is lost is the name the owner was using to find that work, and only they
know whether they still need it.

Skip any in-scope repo with no branches to clean and nothing to pull; say so in one line
rather than reporting per-repo no-ops.

**Worktrees count as checkouts.** Read `git worktree list` first: a branch checked out
in another worktree cannot be deleted from here, and a stale worktree is usually what
is pinning it. Offer to remove worktrees whose branch is merged — `git worktree remove`
(add `--force` only for install churn like a modified `package-lock.json`; inspect the
diff first and never force past real source edits). Then delete the branch normally.

# Part 0 — Explainer of the merged work

Run this part first. Part A deletes the branch and Part C deletes the scratch files. The
explainer reads both.

**1. Record the source, per in-scope repo.** Write down the branch name, its tip SHA,
`git log --format='%h %s' origin/<default>..<branch>`, and the CR id and description when
the session has them. The tip SHA keeps the commits readable after Part A deletes the name.

**2. Call the `explain` skill in session scope.** Pass the recorded source. When this
session did the work, the transcript is the main source and the commits support it. When
an earlier session did the work, the commits and the CR description are the only source.
Say so in the call, so `explain` does not describe a session it cannot see.

**3. Ask for a file.** The explainer must survive the session, so `explain` writes an HTML
file and saves it by its own location rule. `explain` chooses the content and the visuals.

**4. Let `explain` apply its complexity bar.** When the work does not clear the bar, write
no file. Report one line that names the reason, and continue to Part A.

**5. Do not commit the file.** When the docs folder is tracked, give the path and ask the
user whether to commit it. A doc in a team repo reaches other people.

# Part A — Branches

## Per repo

**1. Resolve the default branch — don't assume.** In order: `git symbolic-ref
refs/remotes/origin/HEAD`, else whichever of `mainline` / `main` / `master` exists on
the remote.

**2. Refuse to touch a dirty tree.** `git status --porcelain`. Uncommitted changes →
report the repo and its dirty files, do nothing else to it, and continue with the
others. Never stash, reset, or check out over someone's work. (Pre-existing *untracked*
files that predate the session are not "someone's work in progress" — they don't block
a branch switch; note them and move on.)

**3. `git fetch origin --prune`.** Prune matters: it drops remote-tracking refs for
branches deleted upstream, which is what makes "already merged" resolvable.

**4. Switch to the default branch and pull** (fast-forward only — `git pull --ff-only`).
A pull that would need a merge means the local default branch has its own commits;
report that instead of merging.

**5. Classify every other local branch before deleting anything.** A branch is safe
to delete when its work is provably upstream. **Squash and rebase merges rewrite the
SHA**, which is how most review tools land changes — so ancestry alone will call
merged work unmerged. Use two independent proofs and require both:

- **Patch equivalence:** `git cherry -v origin/<default> <branch>`. Every line must
  start with `-` (an equivalent patch exists upstream). Any `+` is real unmerged work.
- **Subject match in upstream history** — the check that survives SHA divergence:
  ```bash
  git log --format='%s' origin/<default>..<branch> | while IFS= read -r subj; do
    hit=$(git log --format='%h %s' origin/<default> --fixed-strings --grep="$subj" | head -1)
    [ -n "$hit" ] && echo "  OK  $hit" || echo "  MISSING  $subj"
  done
  ```
  `--fixed-strings` matters: subjects contain regex metacharacters (`(`, `[`, `.`).

A squash-merge is the common split verdict: `cherry` shows `+` (the SHA and combined
diff differ) while subject-match hits an upstream commit with the same subject and file
set. Subject-match is the SHA-divergence-surviving proof — trust it, and confirm with
`git show --stat` that the upstream commit's files match the branch's. `git branch
--merged origin/<default>` is still worth reading, but treat it as a
sufficient-not-necessary signal.

Anything not proven upstream is **unmerged** — list it with its unmerged commit count
and leave it alone.

Do NOT use a plain `git diff origin/<default>...<branch>` emptiness test. The
three-dot form diffs against the merge base, so it still shows the branch's own
changes after the branch has merged — it never goes empty and proves nothing.

**6. Delete the proven-merged branches** with `git branch -d`. Never delete the branch
currently checked out (in ANY worktree — check `git worktree list`), or the default
branch itself.

`-d` judges by **ancestry only**, so it will refuse every squash- or rebase-merged
branch even when the content is provably upstream. That refusal is expected, not a
counter-proof. When it happens:
- Re-verify with `git cherry -v origin/<default> <branch>` and **show the full output**
  — every line must start with `-`. A single `+` means real unmerged work: keep the
  branch.
- Then **ask the user before force-deleting**, listing the branches and pasting that
  evidence. `-D` on a branch with no upstream copy is unrecoverable except via reflog,
  so it is the user's call, not the skill's. Never run `-D` in a loop that mixes
  verified and unverified branches.

**7. Do not delete remote branches** unless the user explicitly asks. `git push
origin --delete` affects other people and any open CR.

# Part B — Docs the merge made stale

Only worth running when the merged work **changed observable behavior a doc could
describe** — a config/wire shape, an API signature, a flag's values, a CLI, an
architecture flow. Pure internal refactors, comment/test-only changes, and renames with
no external surface rarely strand a doc; say "no doc surface" and skip. This part edits
files, so hold it to the same bar as branch deletion: change a doc only where it
provably describes the old behavior, and prove that first.

**1. Derive what actually changed.** From the merged commits (`git show`, or the CR
description), name the concrete before→after facts a doc might repeat: renamed/removed
symbols, old vs new config JSON shape, changed enum values, moved endpoints. This list
is the search key for step 2 — be specific (the *old* token is what's now stale in
prose).

**2. Find docs mentioning the OLD facts.** Grep the repo's doc surfaces — `docs/`,
`README`/`*.md`, design docs, and any doc path the project conventions name — for the
**old** identifiers and shapes. `rg -l -i "<oldToken>" docs/ **/*.md`. Every hit is a
candidate; most are false positives (substring matches, unrelated context). Read each
hit in context before believing it — never edit on a grep line alone.

**3. Classify each real hit before touching it:**
- **Living spec** (describes current behavior as fact — an API reference, a config
  example, an architecture doc) → **edit in place** to the new behavior. This is the
  case that matters; a spec that lies is worse than no spec.
- **Dated log / spike / decision record / changelog** (a timestamped account of what
  was true then) → **do NOT rewrite history.** Append a dated note at the top pointing
  to the new shape and naming the CR, and leave the historical body intact. Rewriting a
  log to match the present erases the record and reads as dishonest.
- **Already correct, or only incidentally mentions the token** → leave it; say why in
  one line so the skip is deliberate, not missed.

**4. Make the minimal edit.** Match the doc's existing structure, formatting, and voice
(same as editing code to match its file). Update the stale fact and nothing else — do
not restyle the surrounding doc. If a code path the doc names moved, update the path.

**5. Respect version control.** If the doc tree is **not** under version control (some
projects keep `docs/` out of git — check), edits stand on disk and need no commit;
say so. If it **is** tracked, the doc lives in some repo under Part A's scope — stage
and commit it there with a short message (`docs: sync <doc> to <new behavior>`), per
that repo's commit conventions. Do not sweep unrelated doc edits into the commit.

If the change genuinely stranded no doc, say so plainly rather than inventing edits —
the same rule as reporting a clean branch sweep.

# Part C — Scratch files and build scaffolding

A session leaves data behind: downloaded artifacts, decompressed feeds, file copies taken
before a mutation test, and any scaffolding built to run a gate outside the repo. When
`/tmp` is a small tmpfs, a forgotten several-hundred-MB artifact fills memory. The local
rules name the scratch directory and the tmpfs size when the machine has them.

**Only remove what this session created.** Someone else's scratch file looks identical to
yours. Read the scope off the session transcript, not off a timestamp: if you cannot name
the command that wrote a file, leave it and say so.

**1. Prefer a scratch directory over bare `/tmp` while working.** Write session data to
the scratch directory that the local rules name, else to one directory per topic on a
disk volume. One directory makes Part C a single removal instead of a hunt, and it keeps
`/tmp` free. Never write a decompressed multi-hundred-MB feed to `/tmp` at all — stream
it (`gunzip -c … | awk …`).

**2. Report `/tmp` before and after when it is a tmpfs.** `df -h /tmp`. A number makes
the reclaim verifiable and shows when the pressure came from somewhere else.

**3. Sweep these, in order:**
- The session's scratch directory, once its contents are no longer referenced.
- Loose files this session wrote to `/tmp` — downloaded payloads, `*-backup.*` copies taken
  for a mutation test, briefs written for a subagent fleet.
- **Synthetic workspace roots.** Some build systems need a second root around a worktree
  to run a gate. The local rules describe what such a root holds. Once Part A removes the
  worktrees, that root is an empty shell around build output.

**4. Two checks before removing a synthetic root.** Confirm the root holds no worktree
and the tree contains no `.git`, so nothing with history is inside. Then **unlink each
symlink at the top level explicitly** before recursing:

```bash
find "$R" -maxdepth 1 -type l -exec rm -f {} +   # drop the links, never the shared targets
rm -rf "$R"
```

`rm -rf` on the directory would unlink each symlink rather than follow it, but removing
them first makes the intent explicit and survives someone later copying the command.

**5. Then `git worktree prune`** in each in-scope repo, so no registration outlives the
directory.

Keep a scratch file when a named follow-up still needs it, and say which follow-up. A live
artifact re-read costs a download; a wrong deletion costs the read that proved a finding.

# Report

Open with one line naming the scope and why it is that: which repo merged, and how many
repos in the tree you therefore left alone. A report that lists only what you touched hides
the scope decision, which is the one an over-wide sweep gets wrong.

Then one Part 0 line: the absolute path of the explainer, or the reason no file was
written.

Then one compact table for Part A — repo, default branch, pulled (commits or "up to date"),
branches deleted, branches kept. Then, only if non-empty:
- **Kept (unmerged)** — branch, commits ahead, and why it was kept.
- **Blocked** — repos skipped for a dirty tree or a non-fast-forward default branch,
  with the exact reason.

Print each deleted branch with its tip SHA (`Deleted branch <name> (was <sha>)`), so the
name can be restored with `git branch <name> <sha>` without digging through a reflog.

Then a short Part B line per doc touched — file, living-spec-edited vs log-annotated,
and the stale fact fixed. If a candidate was read and left alone, say so in one line.

Then one Part C line per path removed, with what it held and how much it reclaimed, plus
`df -h /tmp` before and after. Name anything kept and the follow-up that needs it.

State plainly if nothing needed doing in a part. Don't pad the report with per-repo,
per-doc or per-file detail when the answer is "already clean".
