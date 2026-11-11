#!/usr/bin/env python3
"""Enforce Paroli's structural GDScript conventions without external packages.

Godot remains the type checker. This complementary check covers source layout,
documentation, explicit declarations, and the scene/module dependency boundary.
"""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MESH_BOUNDARY = Path("die/effects/die_effects.gd")
FORBIDDEN_ROOTS = ("scripts", "assets", "shaders", "scenes")


def split_parameters(text: str) -> list[str]:
    """Split parameters without splitting typed dictionary/array arguments."""
    return split_balanced(text, ",")


def split_balanced(text: str, delimiter: str) -> list[str]:
    """Respect nested brackets and quoted defaults while scanning a signature."""
    depth = 0
    quote = ""
    escaped = False
    start = 0
    parts: list[str] = []
    for index, char in enumerate(text):
        if quote:
            if char == quote and not escaped:
                quote = ""
            escaped = char == "\\" and not escaped
            continue
        if char in "\"'":
            quote = char
        elif char in "([{":
            depth += 1
        elif char in ")]}":
            depth -= 1
        elif char == delimiter and depth == 0:
            parts.append(text[start:index].strip())
            start = index + 1
    parts.append(text[start:].strip())
    return [part for part in parts if part]


def check_source(relative: Path, source: str) -> list[str]:
    """Return source-level convention violations for a single GDScript file."""
    errors: list[str] = []
    lines = source.splitlines()
    for index, line in enumerate(lines):
        text = line.strip()
        if not text or text.startswith("#"):
            continue
        prefix = f"{relative}:{index + 1}: "
        declaration = re.search(r"\b(?:var|const)\s+(\w+)\s*(.*)", text)
        if declaration and not re.match(r":\s*[A-Za-z_]", declaration[2]):
            errors.append(prefix + "use an explicit declaration type")
        loop = re.match(r"for\s+(\w+)\s*(.*?)\s+in\b", text)
        if loop and not loop[2].startswith(":"):
            errors.append(prefix + "type the loop variable")

        function = re.search(r"\bfunc(?:\s+\w+)?\s*\(", text)
        if function:
            # Signatures can span lines, but their parentheses must balance.
            tail = "\n".join(lines[index:])
            opening = tail.find("(", tail.find("func"))
            depth = 1
            closing = opening + 1
            while closing < len(tail) and depth:
                depth += (tail[closing] == "(") - (tail[closing] == ")")
                closing += 1
            for parameter in split_parameters(tail[opening + 1:closing - 1]):
                if not re.match(r"\w+\s*:\s*\w", parameter):
                    errors.append(prefix + "type every function/lambda parameter")
            if not re.match(r"\s*->\s*\w", tail[closing:]):
                errors.append(prefix + "declare the function/lambda return type")
            if re.match(r"(?:static\s+)?func\s+\w+", text):
                previous = next((s.strip() for s in reversed(lines[:index]) if s.strip()), "")
                if not previous.startswith("##"):
                    errors.append(prefix + "document the method with ##")

        if re.search(r"\bVariant\b", text):
            errors.append(prefix + "use explicit domain types")
        if re.search(r":\s*(Array|Dictionary)\s*(?:=|$)", text):
            mesh_array = relative == MESH_BOUNDARY and "var arrays: Array =" in text
            if not mesh_array:
                errors.append(prefix + "use a typed collection")
        if re.search(r"\.(?:call|get|set)\(", text) and not re.search(r"\.(?:get)\(", text):
            errors.append(prefix + "use a typed method/property instead of dynamic dispatch")

    if "# --- " not in source:
        errors.append(f"{relative}: use documented section headings")
    if relative.parts[0] == "die" and ("res://debug/" in source or "DieViewer" in source):
        errors.append(f"{relative}: reusable die must not depend on debug modules")
    if relative.parts[0] == "debug" and re.search(r"\b_die\._", source):
        errors.append(f"{relative}: viewer must use the die's public API")
    return errors


def main() -> int:
    """Check the tree and fail CI when convention violations are introduced."""
    errors: list[str] = []
    for folder in FORBIDDEN_ROOTS:
        if (ROOT / folder).exists():
            errors.append(f"{folder}/: use feature-owned folders")
    for path in sorted(ROOT.rglob("*.gd")):
        if ".godot" not in path.parts:
            errors.extend(check_source(path.relative_to(ROOT), path.read_text()))
    for path in ROOT.rglob("*.tscn"):
        # Each scene's behavior script must live in its own feature directory.
        source = path.read_text()
        for target in re.findall(r'type="Script" path="res://([^\"]+)"', source):
            if Path(target).parts[0] != path.relative_to(ROOT).parts[0]:
                errors.append(f"{path.relative_to(ROOT)}: instance an external feature scene instead of its script")
    if errors:
        print("\n".join(errors))
        return 1
    print("PASS: explicit types, documented methods, feature ownership, module boundaries.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
