# Using pstack outside Cursor

Upstream pstack is a Cursor plugin. This build makes the same skills work in Claude Code and
other harnesses. This page is the end-to-end path: install, configure, invoke, and what behaves
differently from upstream.

If you are on Cursor, ignore this file and use the upstream README — the root of this repo is
unmodified upstream.

## 1. Install

From a terminal, whether or not Claude Code is running:

```bash
claude plugin marketplace add code-with-rashid/pstack-portable
claude plugin install pstack@pstack-portable
```

If you are already inside a Claude Code session, the same thing through the interactive panel:

```
/plugin marketplace add code-with-rashid/pstack-portable
/plugin install pstack@pstack-portable
```

Both default to user scope, so they install to the same place. The slash form opens a panel and
therefore does not work in `claude -p`; the CLI form works everywhere, including scripts and CI.

Note `pstack@pstack-portable`, not bare `pstack` — the part after `@` names the marketplace the
plugin comes from.

Confirm it landed:

```bash
claude plugin details pstack
```

You should see 44 skills and 2 agents. Start a new session before using them.

## 2. Configure models, once

```
/pstack:setup-pstack
```

It detects which models you can actually spawn, asks which one handles each role, and writes
`~/.config/pstack/models.md`. Roles are things like judgment, precise code, fast code, and the
review panels.

**You can skip this.** Every skill falls back to the per-harness defaults in
[`HARNESS.md`](./HARNESS.md), and where a role has no model at all the skill omits the model
field so the subagent inherits your current one. Skipping costs you the multi-model split, not
correctness.

Unlike Cursor, most harnesses do not auto-load this config. Skills read it on demand, so no
registration step is needed.

## 3. How to invoke a skill

Skills are namespaced by plugin. You type:

```
/pstack:poteto-mode fix the retry bug in the exporter. repro first, then verify.
```

Two invocation paths exist, and the difference matters:

| | which skills | how it fires |
|---|---|---|
| **You type it** | all 44 | `/pstack:<name>` |
| **The agent picks it** | only 5 | matched from your prose, no slash needed |

Only `how`, `why`, `unslop`, `typescript-best-practices`, and `setup-pstack` can self-trigger.
The other 39 — **including `poteto-mode`** — carry `disable-model-invocation: true`, meaning
they run only when you ask for them by name. That is upstream's design, not a limitation of this
build: these workflows spawn subagent panels, and nobody wants that firing off a keyword match.

The practical consequence: `/pstack:poteto-mode` is not sticky here the way it is in Cursor.
Type it at the start of each task, or tell the agent to stay in it for the conversation.

If you are unsure of a name, type `/pstack:` and let autocomplete list them.

Names are lowercase and hyphenated, matching the skill's directory: `/pstack:poteto-mode`, not
`/pstack:Poteto` or `/pstack:Poteto Mode`. Upstream sets a display name (`Poteto Mode`) in that
skill's frontmatter, which Cursor accepts; this build rewrites it, because a name that isn't
lowercase-hyphenated is rejected outright and the skill then never appears as a command at all.

### If a skill isn't recognized

1. **Check the name.** Lowercase, hyphenated, prefixed: `/pstack:poteto-mode`.
2. **Check you are current.** Installs made before this fix shipped carry the broken name.
   `claude plugin marketplace update pstack-portable` then
   `claude plugin install pstack@pstack-portable`, and start a new session.
3. **Check your surface.** Plugin slash commands are most reliable in the Claude Code terminal.
   Desktop, web, and IDE surfaces may not expose all of them, and report
   "Some commands only work in the Claude Code terminal."

Where slash commands are unavailable, the same behaviour is reachable through the subagent:
ask for `subagent_type: pstack:poteto-agent`. It reads `poteto-mode`'s `SKILL.md` in full,
principles index included, before doing any work — which is the whole point of the mode.

## 4. Your first real task

Give it a goal and a way to check the goal, in your own words. You do not need to name a
playbook — `poteto-mode` matches one from how you phrase the request.

```
/pstack:poteto-mode the export writes duplicate rows when a retry lands mid-run.
repro first, then fix and verify.
```

"repro first" and a checkable outcome are the whole routing signal. It opens a todo list whose
first item is reading its principles, copies the matched playbook's steps in, and calls the other
skills as those steps fire.

## 5. Skills worth reaching for directly

| skill | use it when |
|---|---|
| `/pstack:poteto-mode` | default entry point for any non-trivial task |
| `/pstack:how` | you want a walkthrough of how a subsystem works |
| `/pstack:why` | you want to know why something was built this way |
| `/pstack:architect` | you're about to write code crossing a function boundary |
| `/pstack:interrogate` | you have a diff and want several reviewers to break it |
| `/pstack:arena` | you want N parallel attempts, then the best parts of each |
| `/pstack:tdd` | you're fixing a bug with a cheap local test path |
| `/pstack:unslop` | you're cleaning up writing and want the AI tells gone |
| `/pstack:no-comments` | strip narrative comments before review |
| `/pstack:teach` | you want to actually understand a change, not have it summarized |

The full list is in the upstream README's skills table, and `claude plugin details pstack` prints
every name.

## 6. What behaves differently from Cursor

None of these break the skills; they degrade a step and should say so when they do.

- **Sticky mode is gone.** Cursor keeps `poteto-mode` applied across turns via frontmatter other
  harnesses ignore. Re-invoke it per task.
- **`cursor-team-kit` skills are absent.** `/deslop`, `control-cli`, and `control-ui` ship in a
  separate Cursor plugin. `/pstack:unslop` covers the prose lane; for runtime UI and CLI proof,
  generate a project-local verifier with `/pstack:create-verification-skill`.
- **No cloud subagents.** Steps that pass `environment: "cloud"` run locally instead.
- **Transcript mining is harness-dependent.** `/pstack:recall`, `/pstack:reflect`,
  `/pstack:automate-me`, and `/pstack:show-me-your-work` read past sessions.
  [`HARNESS.md`](./HARNESS.md) maps where those live; on a harness with no transcripts, those
  skills lose their evidence step and should tell you rather than invent a substitute.
- **Single-provider panels lose model diversity.** `/pstack:arena`, `/pstack:interrogate`, and
  the `how` critics assume several model families. On one provider they still run as independent
  attempts, and should label the result as single-family.

## 7. Updating and removing

```bash
claude plugin marketplace update pstack-portable
claude plugin install pstack@pstack-portable
```

To remove it:

```bash
claude plugin uninstall pstack
```

## 8. If something looks wrong

The likely cause is a harness-specific reference this build did not translate. Every such
reference should resolve through [`HARNESS.md`](./HARNESS.md); a literal `~/.cursor/...` path or a
Cursor model slug appearing in a skill is a bug in the port layer, not in upstream. Open an issue
on `code-with-rashid/pstack-portable` with the skill name and the line.
