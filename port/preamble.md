> **Portable build.** Environment-specific values appear as tokens: paths like
> `<transcripts-dir>`, model roles like `pstack:judgment`, and generic tool names. Resolve them
> from `HARNESS.md` at the root of this plugin the first time you need one, and re-read it
> before any step that names a capability your harness may lack. When a role has no configured
> model, omit the subagent `model` field rather than guessing a slug.
