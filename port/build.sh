#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT_DIR="$REPO_ROOT/port"
OUT_DIR="$REPO_ROOT/portable"
LOCK_FILE="$PORT_DIR/overrides.lock"
RELOCK="${1:-}"

hash_of() { shasum -a 256 "$1" | cut -d' ' -f1; }

echo "==> pstack portable build"

echo "-- staging pristine upstream"
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"
cp -R "$REPO_ROOT/skills" "$OUT_DIR/skills"
cp -R "$REPO_ROOT/agents" "$OUT_DIR/agents"

echo "-- applying overrides"
: >"$LOCK_FILE.new"
override_root="$PORT_DIR/overrides"
if [ -d "$override_root" ]; then
  while IFS= read -r override; do
    relative="${override#"$override_root"/}"
    upstream="$REPO_ROOT/$relative"
    if [ ! -f "$upstream" ]; then
      echo "  ERROR: override has no upstream counterpart: $relative" >&2
      exit 1
    fi
    current_hash="$(hash_of "$upstream")"
    recorded_hash="$(grep -F "  $relative" "$LOCK_FILE" 2>/dev/null | cut -d' ' -f1 || true)"
    if [ -n "$recorded_hash" ] && [ "$recorded_hash" != "$current_hash" ]; then
      echo "  STALE OVERRIDE: upstream changed since this override was written: $relative"
      echo "                  reconcile it, then re-run with --relock"
    fi
    echo "$current_hash  $relative" >>"$LOCK_FILE.new"
    cp "$override" "$OUT_DIR/$relative"
    echo "  overrode $relative"
  done < <(find "$override_root" -type f)
fi
if [ "$RELOCK" = "--relock" ] || [ ! -f "$LOCK_FILE" ]; then
  mv "$LOCK_FILE.new" "$LOCK_FILE"
else
  rm -f "$LOCK_FILE.new"
fi

echo "-- rewriting harness-specific references"
python3 "$PORT_DIR/apply.py" "$PORT_DIR/mappings.json" "$OUT_DIR" md

echo "-- injecting the portability preamble"
python3 "$PORT_DIR/inject.py" "$PORT_DIR/preamble.md" "$OUT_DIR"

echo "-- writing HARNESS.md and the plugin manifest"
cp "$PORT_DIR/harness.md" "$OUT_DIR/HARNESS.md"
mkdir -p "$OUT_DIR/.claude-plugin"
python3 - "$REPO_ROOT/.cursor-plugin/plugin.json" "$OUT_DIR/.claude-plugin/plugin.json" <<'PYTHON'
import json, sys
source, destination = sys.argv[1], sys.argv[2]
upstream = json.load(open(source))
manifest = {
    "name": "pstack",
    "description": upstream["description"],
    "version": upstream["version"],
    "author": upstream["author"],
    "homepage": upstream["homepage"],
    "repository": upstream["repository"],
    "license": upstream["license"],
    "keywords": upstream["keywords"],
}
with open(destination, "w") as handle:
    json.dump(manifest, handle, indent=2)
    handle.write("\n")
print(f"  plugin.json at version {upstream['version']}")
PYTHON

echo "-- drift check"
FORBIDDEN='\.cursor/|~/\.cursor|AskQuestion|generalPurpose|agent-transcripts|claude-fable-5-thinking-max|gpt-5\.6-sol-max|grok-4\.6-fast-xhigh|claude-opus-5-thinking-xhigh|\.mdc'
drift="$(grep -rnE "$FORBIDDEN" "$OUT_DIR" \
  --include='*.md' --include='*.sh' --include='*.ts' --include='*.json' \
  --exclude='HARNESS.md' --exclude='bun.lock' \
  | grep -vE -f "$PORT_DIR/allowlist.txt" || true)"
if [ -n "$drift" ]; then
  echo
  echo "BUILD FAILED: unmapped harness-specific references in the generated tree." >&2
  echo "Add a rule to port/mappings.json, or allow the line in port/allowlist.txt." >&2
  echo >&2
  echo "$drift" | sed "s|$OUT_DIR/||" >&2
  exit 1
fi
echo "  clean"

echo
echo "==> built $(find "$OUT_DIR" -name '*.md' | wc -l | tr -d ' ') markdown files into portable/"
