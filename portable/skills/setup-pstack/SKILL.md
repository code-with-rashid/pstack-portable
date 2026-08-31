---
name: setup-pstack
description: Configure which models pstack uses per role. Detects your available models and writes a config file that overrides the skill defaults. Use for /setup-pstack, "configure pstack models", or changing pstack's model choices.
---

> **Portable build.** Environment-specific values appear as tokens: paths like
> `<transcripts-dir>`, model roles like `pstack:judgment`, and generic tool names. Resolve them
> from `HARNESS.md` at the root of this plugin the first time you need one, and re-read it
> before any step that names a capability your harness may lack. When a role has no configured
> model, omit the subagent `model` field rather than guessing a slug.

# Setup pstack

Write `~/.config/pstack/models.md`, a plain config file that sets pstack's model per role. The
skills read it and fall back to the `HARNESS.md` defaults when a line is absent, so this is an
override layer, not a requirement.

## Steps

### 1. Identify the harness

Read `HARNESS.md` at the root of this plugin and note which harness you are running in, since
it decides the fallback models and whether transcripts and cloud subagents exist at all. If the
harness is not listed there, use the "Any harness" column and tell the user which assumptions
you made.

### 2. Detect available models

Enumerate the model identifiers you can pass when spawning a subagent in this session; that is
the dependable source. If the harness exposes a models API or CLI that lists entitled models,
prefer it for completeness. If you cannot detect any, ask the user to paste the identifiers they
have access to. Never write an identifier you have not confirmed is available. The aliases
`inherit-parent` and `auto` are always valid even though they are not detected identifiers.

On a single-provider harness, say so plainly: the panel roles below will run without model
diversity, and that limitation belongs in every panel writeup.

### 3. Load current state

The default role-to-model mapping is the `HARNESS.md` model-roles table. If
`~/.config/pstack/models.md` already exists, read it and treat its values as the current
choices. Otherwise start from those defaults.

### 4. Map and confirm

Show every role with its current model, marking any identifier not in the detected set as
needing a choice. Ask whether to accept as-is or change specific roles, offering the detected
models plus `inherit-parent` and `auto` (both mean: this role runs on the parent chat model) as
the options. Prefer a structured multi-choice question over free text. For panel roles (how
critics, arena runners, architect runners, interrogate reviewers) the value is a list, and one
subagent runs per entry, alias entries included, so the list length sets the count.
`arena cross-judge pool` is also a list, but Arena selects one value from it whose model family
differs from the parent's when possible. `swarm workers` is the default model for every worker
unless a race or comparison assigns another model per arm.

### 5. Validate

Every real identifier written must be in the detected set; `inherit-parent` and `auto` always
pass. If a chosen identifier is not available, stop and ask again. A config pointing at a model
the user cannot use breaks every delegation that reads it.

### 6. Write the config

Write `~/.config/pstack/models.md`, creating `~/.config/pstack/` if needed. Overwrite the whole
file so re-runs stay idempotent. Shape:

```
# pstack model configuration. One line per role. Delete a line to fall back to the HARNESS.md default.
# `inherit-parent` or `auto` as a value: the role runs on the parent chat model (omit the subagent
# `model` field). Alias entries in a panel list still count toward its fan-out.
feature, refactoring: <fast-code model>
bug-fix: <precise-code model>
perf-issue: <precise-code model>
hillclimb: <precise-code model>
judgment and prose: <judgment model>
hardest tasks: <judgment model>
how explorer: <fast-code model>
how explainer: <judgment model>
how critics: <judgment model>, <precise-code model>, <fast-code model>, <alt-judgment model>
why investigators: <fast-code model>
why synthesizer: <judgment model>
reflect tooling: <precise-code model>
reflect judgment, divergent, synthesizer: <judgment model>
arena runners: <judgment model>, <precise-code model>, <fast-code model>, <alt-judgment model>
arena cross-judge pool: <judgment model>, <precise-code model>, <fast-code model>, <alt-judgment model>
swarm workers: <fast-code model>
architect runners: <judgment model>, <precise-code model>, <fast-code model>, <alt-judgment model>
interrogate reviewers: <judgment model>, <precise-code model>, <fast-code model>, <alt-judgment model>
```

Substitute confirmed model identifiers for the `<...>` placeholders. Write no placeholder into
the file; a role you could not resolve gets `inherit-parent` instead.

### 7. Register the config for auto-loading, where that exists

Cursor loads `~/.cursor/rules/*.mdc` into every session; most harnesses do not auto-load
anything equivalent. If yours has an always-loaded instruction file (for example `CLAUDE.md`),
offer to add one line pointing at `~/.config/pstack/models.md`. Otherwise tell the user the
skills will read the file on demand, which needs no registration.

### 8. Confirm

Tell the user where the config was written and whether it applies immediately or to new sessions
only. Re-running this skill updates it.

### 9. Offer a verification skill (optional)

Check whether the project has a way to drive the real app for proof (a `verify-*` skill, or an
existing harness). If not, offer once: "want a project-local verification skill, so agents can
drive the app the way a user does and prove changes work? I can generate one with
/create-verification-skill." On yes, invoke `/create-verification-skill`. On no, move on without
pushing.
