# HARNESS.md — resolving pstack's environment tokens

This tree is the harness-portable build of pstack. Upstream pstack is written for Cursor;
the generator replaced every Cursor-specific path, tool name, and model slug with a token
defined here. Resolve a token the first time a skill uses it in a session.

If your harness is not listed, use the **Any harness** column and adapt.

## Path tokens

| token | Cursor | Claude Code | Any harness |
|---|---|---|---|
| `<transcripts-root>` | `~/.cursor/projects` | `~/.claude/projects` | wherever session transcripts are stored, if anywhere |
| `<transcripts-dir>` | `<transcripts-root>/<slug>/agent-transcripts` | `<transcripts-root>/<slug>` | the current workspace's transcript directory |
| `<project-skills>` | `.cursor/skills` | `.claude/skills` | the repo-local skills directory |
| `<user-skills>` | `~/.cursor/skills` | `~/.claude/skills` | the personal skills directory |
| `<project-config>` | `.cursor` | `.claude` | the repo-local agent config directory |
| `<plugins-dir>` | `~/.cursor/plugins` | `~/.claude/plugins` | where installed plugins live |
| `<worktrees-dir>` | `.cursor/worktrees` | `.git/worktrees` or your own convention | where agent worktrees are created |

`<slug>` is the absolute workspace path with the leading slash dropped and every `/` turned
into `-`, in both Cursor and Claude Code.

**If your harness exposes no transcripts**, the skills that mine them (`/recall`, `/reflect`,
`/automate-me`, `/show-me-your-work`, and the eval and session-pickup playbooks) cannot run
their evidence step. Say so and fall back to what the current session already holds, rather
than inventing a substitute source.

## Model roles

Upstream hard-codes Cursor router slugs. This build replaces them with role tokens:

| role token | what it is for | Cursor | Claude Code |
|---|---|---|---|
| `pstack:judgment` | prose, judgment, the hardest reasoning | `claude-fable-5-thinking-max` | `claude-fable-5` |
| `pstack:precise-code` | precisely-specified code, bug fixes, perf | `gpt-5.6-sol-max` | `claude-opus-5` |
| `pstack:fast-code` | fast mechanical code, exploration, swarm workers | `grok-4.6-fast-xhigh` | `claude-sonnet-5` |
| `pstack:alt-judgment` | a second strong reasoner, for panel diversity | `claude-opus-5-thinking-xhigh` | `claude-opus-5` |

Resolution order for any role:

1. The matching line in `~/.config/pstack/models.md`, if the file exists.
2. The column above for your harness.
3. **Omit the subagent `model` field entirely**, so the subagent inherits the parent model.

Step 3 is the important one. Never pass a model string you have not confirmed the harness
accepts — an unknown slug fails the spawn, and a whole delegation step dies with it.

Unlike Cursor, most harnesses do not auto-load `~/.config/pstack/models.md` into context.
Read the file explicitly the first time a skill needs a role, then reuse it for the session.

### Single-provider harnesses

`/arena`, `/interrogate`, `/how` critics, and `/architect` runners are panels that assume
several model families. With one provider available, run the panel anyway: the value that
survives is independent attempts under different prompts, not vendor diversity. State plainly
in the writeup that the panel ran single-family, so nobody reads more independence into the
result than it earned.

## Tool and agent names

| this build says | Cursor | Claude Code |
|---|---|---|
| the ask-user tool | `AskQuestion` | `AskUserQuestion` |
| subagent-spawn tool | `Task` | `Agent` |
| `subagent_type: general-purpose` | `generalPurpose` | `general-purpose` |
| `subagent_type: poteto-agent` | `poteto-agent` | `poteto-agent` (from `agents/`) |

`poteto-agent` and `Comment Sicko` require a harness that registers custom subagents from
`agents/*.md`. Where it does not, spawn a general-purpose subagent and tell it to read
`skills/poteto-mode/SKILL.md` in full first — that read is the whole point of the custom agent.

## Capabilities that may be absent

Guard each of these; skip the step and say you skipped it rather than faking the evidence.

- **Cloud / background subagents.** Upstream passes `environment: "cloud"`. Omit the field
  where it does not exist and run locally.
- **`cursor-team-kit` skills.** `/deslop`, `control-cli`, and `control-ui` are a separate
  Cursor plugin. Without them, `/unslop` covers the prose lane; runtime UI and CLI verification
  needs a project-local `verify-*` skill instead (`/create-verification-skill` generates one).
- **`/create-skill`.** A Cursor built-in. Elsewhere, write the `SKILL.md` directly.
- **Sticky mode.** Upstream's frontmatter (`mode: true`, `reminder:`) keeps `/poteto-mode`
  applied across turns in Cursor. Other harnesses ignore those keys, so the mode applies to
  the invocation only. Re-invoke it, or ask the agent to stay in it for the conversation.
- **`disable-model-invocation`.** Cursor uses it to make a skill explicit-invocation-only.
  Harnesses that ignore it may auto-trigger these skills more eagerly than upstream intends.
