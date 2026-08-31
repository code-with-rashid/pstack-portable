# port/ — the harness portability layer

`portable/` is generated. Never edit it by hand; edit the inputs here and rebuild.

The rule that makes upstream syncs painless: **the tree at the repo root stays byte-identical
to upstream.** Because no upstream file is ever modified, `git merge upstream/main` can never
conflict, even though the mirror ships squashed snapshots rather than a usable commit series.
All divergence lives in this directory.

## Build

```bash
./port/build.sh
```

Pass `--relock` after deliberately reconciling an override with a new upstream version.

## Sync ritual

```bash
git fetch upstream && git merge upstream/main
./port/build.sh
git diff portable/
git push origin main
```

`origin` is this fork; `upstream` is `backnotprop/pstack`, itself a mirror of the `pstack`
subdirectory of `cursor/plugins`. The mirror ships squashed snapshots, so a merge brings one
bulk commit rather than a readable series — which is exactly why nothing here depends on
reading upstream history to resolve a conflict.

The build has two gates, both fail-closed. **Name validation** rejects any skill whose `name`
is not lowercase-hyphenated and equal to its directory — upstream ships a Cursor display name
(`Poteto Mode`) that harnesses following the Agent Skills rule reject outright, which makes the
skill silently unregisterable. **The drift check** rejects any harness-specific reference that no
mapping covers.

If the build fails on drift, upstream introduced a reference no rule covers. The error names the
file and line. Add a rule to `mappings.json`, or allow the line in
`allowlist.txt` when the reference is a deliberate Cursor-only mention, then rebuild.

## Inputs

| file | what it is |
|---|---|
| `mappings.json` | ordered literal substitutions applied to every `.md` in the generated tree |
| `harness.md` | the adapter table; becomes `portable/HARNESS.md` and defines every token the mappings introduce |
| `preamble.md` | injected after frontmatter into files that ended up containing a token |
| `overrides/` | whole-file replacements, mirroring the upstream path, for skills that need real rewrites |
| `overrides.lock` | upstream hash per override, so the build warns when an override goes stale |
| `allowlist.txt` | line patterns the drift check tolerates |
| `apply.py`, `inject.py`, `build.sh` | the generator |

## Why some things are overrides rather than mappings

A mapping survives upstream prose edits; an override freezes the file. Prefer a mapping. Reach
for an override only when the portable version has to say something structurally different from
upstream — currently just `setup-pstack`, which writes a plain config file to
`~/.config/pstack/models.md` instead of a Cursor always-applied rule, and has to explain model
roles rather than name Cursor router slugs.

The build warns when an overridden file changed upstream, because that is the one place
divergence is real and needs a human decision.

## The one upstream file this fork modifies

`README.md` carries a short fork note at the top, because GitHub renders it as the landing page
and a fork that cannot explain itself is a bad fork. It is the only file outside `port/`,
`portable/`, and `.claude-plugin/` that diverges from upstream, so it is the only place a sync
can conflict — and the conflict is always the same isolated block at the top of the file.

## Not ported

`docs/` and `automations/` stay Cursor-flavored and are excluded from `portable/`. The guide is
narrative prose that needs rewriting rather than token substitution, and the benny automation
pack is a dormant Cursor-specific integration. `HARNESS.md`'s token table is enough to read the
upstream guide against this build.
