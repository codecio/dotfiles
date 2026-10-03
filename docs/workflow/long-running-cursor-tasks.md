# How to run a long Cursor task across sessions

Treat the chat as a disposable driver. Keep the work on disk: a branch, commits, a checkable done condition, and a short resume note.

This how-to uses the personal `/handoff` skill (`~/.cursor/skills/handoff/SKILL.md`), Cursor `/loop`, and pstack (`/poteto-mode`, `/recall`, `/show-me-your-work`).

## Pick the scale

| Scale | What to run | Stop when |
|---|---|---|
| One task one agent can finish | `/poteto-mode` autonomous run plus `/loop` | A checkable predicate is true |
| Several PRs, still one program | Multi-phase plan, then autopilot-stack or autopilot-full | Plan boxes and live or perf evidence exist |
| Multi-day, many stacked PRs, you check in twice a day | Orchestrate | Countable units are merged and ledger-verified |
| Context is dying, or you walk away mid-edit | Pause safely plus `/handoff` | Resume note is in `/tmp` and a `wip:` commit exists |

Do not start orchestrate for work one agent can finish in a session. Do not give `/loop` a duration instead of a predicate. "Work for 4 hours" produces motion, not a result.

## Compact a session into a new chat

In the current chat, name what the next session will do:

```text
/handoff continue the parser migration; next session picks up at the last failing fixture
```

`/handoff` writes a compact doc in the OS temp directory (on macOS, `/tmp`), not in the repo. The doc should:

- Summarize only what a fresh agent needs
- Point at specs, plans, ADRs, issues, commits, and diffs instead of copying them
- Include a suggested-skills section
- Redact secrets and PII

In the new chat, attach or `@` that file and start work. If you use pstack, prefix with `/poteto-mode` so it can route to session pickup.

### Incoming vs outgoing

| Intent | Command |
|---|---|
| Compact this chat for a new one | `/handoff` |
| Stop mid-implementation cleanly | `/poteto-mode` pause safely |
| New chat, no handoff file | `/recall` |
| New chat taking over one specific prior agent | `/poteto-mode` session pickup |

`/recall` rebuilds a tight capsule from recent transcripts: goal, decisions, open threads, next move. Session pickup reads that transcript or branch and continues. It should not re-derive completed work.

### Do not dump session state here

- **Rules** (`.cursor/rules/`) apply to every future chat. One-off session state does not belong there.
- **`workflow-from-chats`** extracts durable preferences. It does not summarize chats.
- **`/share`** backs up the project, not the conversation.
- **`/goal`** persists only inside the current conversation.

## Run one long task overnight

Use this when the target is known and one agent can drive it: migrate callers, land a stack, keep CI green until a predicate passes.

### 1. Isolate the work

Open a fresh worktree and one chat. Durable state lives on the branch, in commits, and in `decisions.tsv`.

### 2. Arm the contract

Give goal, finish condition, permissions, and an escape hatch:

```text
/poteto-mode i'm going to bed. migrate every caller to the new parser
in a fresh worktree off main.

done means: zero imports of oldParser, all parser fixtures pass,
old api deleted, typecheck green.

keep a decision log at decisions.tsv.
don't ask me before committing.
/loop until done. if you're truly stuck after a few hours, stop and write up why.
```

`/loop` is Cursor's wake mechanism. `/poteto-mode` routes to autonomous run. It should design phases and the decision log before it writes code.

### 3. What each tick does

- Make the smallest change the evidence justifies.
- Verify against the predicate (fixtures, import grep, typecheck).
- Commit if it advanced. Revert if it did not.
- Append one row to `decisions.tsv`: time, phase, decision, why, evidence pointer, result.
- Repeat. A plateau is a pivot, not a stop. Only a real dead end stops.

### 4. Audit in the morning

Same chat or a new one:

```text
/show-me-your-work catch me up on what you did last night
```

Read the Attention section first (cross-model review of the trail). Then follow the log rows it points at. Audit decisions. Do not re-read the whole night.

## Pause when context fills up

Do not paste a novel into a new chat. In the old chat:

```text
/poteto-mode pause. /handoff finish the parser migration; remaining callers are in billing/
```

Pause-safely:

1. Finish the current atomic step or back it out. Do not stop mid-edit in a broken tree.
2. Make a `wip:` commit on the current branch. If the tree is broken, say so in the commit body in one line.
3. Write a resume note at `/tmp/<slug>-resume.md`: intent, progress, what is verified, current state, next steps, key files, gotchas.
4. Do not open a PR or push unless you already had one out.

New chat:

```text
/poteto-mode session pickup. resume from /tmp/<slug>-resume.md
done still means zero oldParser imports, fixtures pass, old api deleted.
```

Use `/recall` only if you lost the resume file and need a capsule from transcripts.

## Scale up when one agent is not enough

**Several PRs.** Write a multi-phase plan (one PR per verifiable unit). Start execution only after you say go. Arm `/loop` on a 30-minute audit tick that re-reads the playbook and posts PR, owner, SHA, and blockers.

**A program that outlives one coordinator.** Use orchestrate: standing orders in `preferences.md`, briefs with GOAL, SCOPE, ACCEPTANCE, and VERIFY, workers in cloud. The coordinator authors briefs and lands verified units. It does not write feature code.

The durable pieces stay the same: predicate, isolated tree, commits, decision log, resume file.

## Example prompts you can copy

Overnight one-task run:

```text
/poteto-mode i'm going to bed. <task> in a fresh worktree off <base>.
done means: <checkable predicate>.
keep a decision log. don't ask me before committing.
/loop until done. if you're truly stuck after a few hours, stop and write up why.
```

Handoff to a new session:

```text
/handoff <what the next session will focus on>
```

Resume:

```text
/poteto-mode session pickup. resume from /tmp/<slug>-resume.md
```

Catch-up without a file:

```text
/recall where did I leave off on <topic>
```
