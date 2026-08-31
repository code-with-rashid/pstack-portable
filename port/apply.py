#!/usr/bin/env python3
import json
import pathlib
import sys


def load_rules(mappings_path):
    with open(mappings_path) as handle:
        return json.load(handle)["rules"]


def apply_rules(text, rules, hit_counter):
    for index, rule in enumerate(rules):
        occurrences = text.count(rule["find"])
        if occurrences:
            text = text.replace(rule["find"], rule["replace"])
            hit_counter[index] += occurrences
    return text


def rewritable_files(target_dir, extensions):
    for extension in extensions:
        yield from sorted(target_dir.rglob(f"*.{extension}"))


def main():
    mappings_path, target_dir = sys.argv[1], pathlib.Path(sys.argv[2])
    extensions = sys.argv[3].split(",") if len(sys.argv) > 3 else ["md"]
    rules = load_rules(mappings_path)
    hit_counter = [0] * len(rules)
    changed_files = 0

    for path in rewritable_files(target_dir, extensions):
        original = path.read_text()
        rewritten = apply_rules(original, rules, hit_counter)
        if rewritten != original:
            path.write_text(rewritten)
            changed_files += 1

    total = sum(hit_counter)
    print(f"  rewrote {total} references across {changed_files} files")

    for index, count in enumerate(hit_counter):
        if count == 0 and not rules[index].get("safetyNet"):
            print(f"  STALE RULE (0 matches, upstream may have dropped it): {rules[index]['find']!r}")

    by_group = {}
    for index, rule in enumerate(rules):
        by_group[rule["group"]] = by_group.get(rule["group"], 0) + hit_counter[index]
    for group, count in sorted(by_group.items(), key=lambda pair: -pair[1]):
        print(f"    {group}: {count}")


if __name__ == "__main__":
    main()
