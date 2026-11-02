---
name: setup-pstack
description: Configure which models pstack uses per role and at what reasoning budget. Detects your available models and writes an always-applied rule that overrides the skill defaults. Use for /setup-pstack, "configure pstack models", "pstack budget", or changing pstack's model choices.
---

> **Portable build.** Environment-specific values appear as tokens: paths like
> `<transcripts-dir>`, model roles like `pstack:judgment`, and generic tool names. Resolve them
> from `HARNESS.md` at the root of this plugin the first time you need one, and re-read it
> before any step that names a capability your harness may lack. When a role has no configured
> model, omit the subagent `model` field rather than guessing a slug.

# Setup pstack

Write pstack's model settings, one model per role:

- **Claude Code:** `~/.claude/rules/pstack-models.md`. Claude Code loads every file in `~/.claude/rules/` into each new session.
- **Every other harness** (Codex, Pi, OpenCode, and others): `~/.agents/pstack-models.md`. These harnesses don't load it on their own, so pstack skills read this file when they pick a model.

"The settings file" below means the file for your harness. In Claude Code, if that file is missing, read `~/.agents/pstack-models.md` instead, where older versions of this skill wrote it. In any harness, if neither exists, read `~/.config/pstack/models.md`, where older portable builds wrote it, and carry its choices over.

## Steps

### 1. Detect available models

Enumerate the model slugs you can pass to a subagent in this session (Claude Code `Agent`, OpenCode `task`, Codex `spawn_agent`). That is the dependable source. If your harness also has a command that lists the user's models, prefer it for completeness (for example `opencode models` or `pi --list-models`). If you cannot detect any, ask the user to paste the slugs they have access to. Never write a real slug you have not confirmed is available. The aliases `inherit-parent` and `auto` are always valid even though they are not detected slugs.

### 2. Load current state

The default role-to-model mapping is the rule shape shown in step 5 below. If the settings file already exists, read it and treat its `# budget` line and its role values as the current choices. Otherwise start from those defaults. A line whose role is not in step 5, such as `how critics`, is from a retired role. Drop it.

### 3. Budget, map, and confirm

**(a) Ask for a budget.** Prefer your structured-question tool (`AskUserQuestion` in Claude Code, `question` in OpenCode) over free text. Offer these four options with these exact labels, and name the current budget when the rule records one. With no rule, say that `large` matches the skill defaults.

- `unlimited — max reasoning`
- `large — xhigh reasoning`
- `medium — high reasoning`
- `small — medium reasoning`

**(b) Apply it.** Build the working table from the skill defaults, and on a re-run keep any role you changed by family, list, or alias (`inherit-parent`, `auto`). `unlimited`, `large`, `medium`, and `small` set the effort token of every real slug, panel entries included, to `max`, `xhigh`, `high`, or `medium`. The effort token is the last token, or the one before a trailing `fast`, on the ladder `max` > `xhigh` > `high` > `medium` > `low`. If the result is not a detected slug, use the same family's detected slug with the highest effort at or below the target, else mark the role as needing a choice. `inherit-parent` and `auto` do not change. In Cursor, for example, `unlimited` raises the Opus default from `xhigh` to `max`, Grok stays at `xhigh` because that is its top, `large` keeps both defaults, and `small` lowers both to `medium`. Where model identifiers carry no effort token, as in Claude Code, the budget leaves every identifier unchanged; still record it on the `# budget` line.

**(c) Show the roles and confirm.** Show every role with its model, marking any real slug not in the detected set as needing a choice. Also list each line step 2 dropped. Ask whether to accept as-is or change specific roles, offering the detected models plus `inherit-parent` and `auto` (both mean: this role runs on the parent chat model, which is how Auto users stay on Auto) as the options. Prefer your structured-question tool over free text. For panel roles (arena runners, architect runners, interrogate reviewers) the value is a list, and one subagent runs per entry, alias entries included, so the list length sets the count. `arena cross-judge pool` is also a list, but Arena runs one judge. It tries only values from a family other than the parent's, in list order, so order it by preference. An `inherit-parent` or `auto` value never judges. `swarm workers` is the default model for every worker unless a race or comparison assigns another model per arm.

### 4. Validate

Every real slug written must be in the detected set. `inherit-parent` and `auto` always pass. If a chosen real slug is not available, stop and ask again.

### 5. Write the rule

Write the settings file with a `# budget` line with the chosen label and its target effort, and one line per role, using the same labels poteto-mode uses. In Cursor, include the frontmatter below with `alwaysApply: true`. In other harnesses, write the settings file without the frontmatter (start at the first `#` line). Overwrite the whole file so re-runs stay idempotent. Write real model identifiers, never the `pstack:` role tokens in the shape below; resolve each token through `HARNESS.md`. Shape:

```
---
description: pstack per-role model choices (overrides skill defaults)
alwaysApply: true
---
# pstack model configuration. One line per role. Delete a line to fall back to the skill default.
# `inherit-parent` or `auto` as a value: the role runs on the parent chat model (omit the subagent `model`). Alias entries in a panel list still count toward its fan-out.
# budget: large (xhigh)
feature, refactoring: pstack:fast-code
bug-fix: pstack:fast-code
perf-issue: pstack:fast-code
hillclimb: pstack:fast-code
judgment and prose: pstack:judgment
hardest tasks: pstack:judgment
how explorer: pstack:fast-code
how explainer: pstack:judgment
why investigators: pstack:fast-code
why synthesizer: pstack:judgment
reflect tooling: pstack:fast-code
reflect judgment, divergent, synthesizer: pstack:judgment
arena runners: pstack:judgment, pstack:fast-code
arena cross-judge pool: pstack:judgment, pstack:fast-code
swarm workers: pstack:fast-code
architect runners: pstack:judgment, pstack:fast-code
interrogate reviewers: pstack:judgment, pstack:fast-code
```

### 6. Confirm

Tell the user which file was written. In Cursor and Claude Code, it applies to new sessions. In other harnesses, pstack skills read `~/.agents/pstack-models.md` when they pick a model. Re-running this skill updates it.

### 7. Offer a verification skill (optional)

Check whether the project has a way to drive the real app for proof (a `verify-*` skill, or an existing harness). If not, offer once: "want a project-local verification skill, so agents can drive the app the way a user does and prove changes work? I can generate one with /create-verification-skill." On yes, invoke `/create-verification-skill` (resolves wherever pstack is installed: workspace, user, or plugin). On no, move on without pushing.

### 8. Offer a formal verification skill (optional)

Check whether the project already has a formal verification skill (a project skill that runs a model checker, a proof, or another verifier against the code). If not, offer once: "want a formal verification skill, so agents can prove a key property of your code holds in every case in scope, not only the cases tests reach? I can generate one with /create-formal-verification-skill." On yes, invoke `/create-formal-verification-skill` (resolves wherever pstack is installed: workspace, user, or plugin). On no, move on without pushing.
