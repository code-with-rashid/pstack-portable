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

`<slug>` is the absolute workspace path. Cursor drops the leading slash and turns every `/`
into `-` (`Users-you-proj`). Claude Code turns every character that is not a letter or digit
into `-`, leading slash included (`-Users-you-proj`).

**If your harness exposes no transcripts**, the skills that mine them (`/recall`, `/reflect`,
`/automate-me`, `/show-me-your-work`, and the eval and session-pickup playbooks) cannot run
their evidence step. Say so and fall back to what the current session already holds, rather
than inventing a substitute source.

## Model roles

Upstream hard-codes Cursor router slugs as its defaults. This build replaces them with role
tokens:

| role token | what it is for | Cursor | Claude Code |
|---|---|---|---|
| `pstack:judgment` | prose, judgment, the hardest reasoning | `claude-opus-5-5-xhigh` | `opus` |
| `pstack:fast-code` | code, exploration, swarm workers | `grok-4.7-xhigh-fast` | `sonnet` |

Resolution order for any role:

1. The matching line in the pstack settings file, if it exists: `~/.claude/rules/pstack-models.md`
   in Claude Code, `~/.agents/pstack-models.md` in other harnesses. `/setup-pstack` writes it.
2. The column above for your harness.
3. **Omit the subagent `model` field entirely**, so the subagent inherits the parent model.

Step 3 is the important one. Never pass a model string you have not confirmed the harness
accepts — an unknown slug fails the spawn, and a whole delegation step dies with it.

Claude Code loads `~/.claude/rules/` into every new session. Other harnesses do not load
`~/.agents/pstack-models.md` on their own: read it the first time a skill needs a role, then
reuse it for the session.

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
- **`disable-model-invocation`.** Marks a skill explicit-invocation-only. Upstream sets it on 39
  of the 44 skills, `poteto-mode` included, so on a harness that honours it (Claude Code does)
  those skills never self-trigger and run only when the user names them. Only `how`, `why`,
  `unslop`, `typescript-best-practices`, and `setup-pstack` can fire from prose. A harness that
  ignores the key instead auto-triggers all 44 more eagerly than upstream intends.
- **Skill naming.** The Agent Skills rule is `^[a-z0-9]+(-[a-z0-9]+)*$`, matching the skill's
  directory. Cursor also accepts a display name, and upstream uses one (`name: Poteto Mode`); a
  harness enforcing the rule rejects that skill outright and it silently never registers. This
  build normalizes names and fails its own build if any name violates the rule.
