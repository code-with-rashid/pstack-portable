#!/usr/bin/env python3
import pathlib
import re
import sys

TOKEN_PATTERN = re.compile(
    r"<transcripts-root>|<transcripts-dir>|<project-skills>|<user-skills>"
    r"|<plugins-dir>|<worktrees-dir>|<project-config>"
    r"|pstack:(?:judgment|precise-code|fast-code|alt-judgment)"
    r"|the ask-user tool|subagent-spawn tool|~/\.config/pstack/models\.md"
)

ALWAYS_INJECT = {
    "skills/poteto-mode/SKILL.md",
    "agents/poteto-agent.md",
    "agents/comment-sicko.md",
}


def insert_after_frontmatter(text, preamble):
    if not text.startswith("---\n"):
        return preamble + "\n" + text
    closing = text.find("\n---\n", 4)
    if closing == -1:
        return preamble + "\n" + text
    split_at = closing + len("\n---\n")
    return text[:split_at] + "\n" + preamble + text[split_at:]


def main():
    preamble_path, target_dir = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
    preamble = preamble_path.read_text().rstrip() + "\n"
    injected = 0

    for path in sorted(target_dir.rglob("*.md")):
        relative = path.relative_to(target_dir).as_posix()
        text = path.read_text()
        if relative not in ALWAYS_INJECT and not TOKEN_PATTERN.search(text):
            continue
        path.write_text(insert_after_frontmatter(text, preamble))
        injected += 1

    print(f"  injected the portability preamble into {injected} files")


if __name__ == "__main__":
    main()
