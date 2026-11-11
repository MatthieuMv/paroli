#!/usr/bin/env python3
"""Check the human-authored catalog's names, families, and faces against EFFECTS.md."""
from pathlib import Path
import ast
import re
import json

ROOT = Path(__file__).resolve().parents[2]
DOCUMENT = ROOT.parent / "docs" / "EFFECTS.md"
CATALOG = ROOT / "mechanics" / "definitions" / "effects_catalog.gd"


def localized_names() -> dict[str, str]:
    """Display names may change without renaming stable gameplay/save identities."""
    source = (ROOT / "mechanics/localization/game_keywords.gd").read_text()
    names = {}
    for match in re.finditer(r'KeywordDefinition.new\(&?"name\.([^" ]+)", (\{.*?\})\)', source):
        english = json.loads(match[2])["en"]
        assert english.casefold() not in names, f"Duplicate display name: {english}"
        names[english.casefold()] = match[1]
    return names


def identity(name: str) -> str:
    """Resolve documented names through the actual localized catalog."""
    names = localized_names()
    assert name.casefold() in names, f"Unknown documented name: {name}"
    return names[name.casefold()]


def main() -> None:
    """Fail on missing/extra content, family drift, duplicate IDs, or changed physical faces."""
    expected: dict[str, tuple[str, list[int] | None]] = {}
    combination = False
    for line in DOCUMENT.read_text().splitlines():
        if line.startswith("| Combination |"):
            combination = True
            continue
        if line.startswith("## "):
            combination = False
        if not line.startswith("|"):
            continue
        cells = [cell.strip() for cell in line.strip("|").split("|")]
        if combination and len(cells) == 5 and cells[2].startswith("+"):
            expected[identity(cells[1])] = ("Bonus", None)
            expected[identity(cells[3])] = ("Joker", None)
        elif len(cells) == 4 and cells[1] in {"Upgrade", "Bonus", "Joker"}:
            faces = [int(value) for value in cells[2].split(",")] if cells[1] == "Upgrade" else None
            expected[identity(cells[0])] = (cells[1], faces)

    actual: dict[str, tuple[str, list[int] | None]] = {}
    for match in re.finditer(r'(Upgrade|Bonus|Joker)Definition[.]new[(]&"([^"]+)"(.*)', CATALOG.read_text()):
        family, id_, tail = match.groups()
        assert id_ not in actual, f"Duplicate catalog ID: {id_}"
        faces = ast.literal_eval("[" + tail.split("[", 1)[1].split("]", 1)[0] + "]") if family == "Upgrade" else None
        actual[id_] = (family, faces)
    assert expected, "No effects found in the document"
    assert actual.keys() == expected.keys(), f"Missing: {expected.keys() - actual.keys()}; extra: {actual.keys() - expected.keys()}"
    for id_, declaration in expected.items():
        assert actual[id_] == declaration, f"{id_}: expected {declaration}, got {actual[id_]}"
    for id_, (family, _) in actual.items():
        if family in {"Bonus", "Joker"}:
            directory = "bonuses" if family == "Bonus" else "jokers"
            artwork = ROOT / "mechanics/definitions/artwork" / directory / f"{id_}.svg"
            assert artwork.is_file(), f"Missing {family} artwork: {artwork}"
    print(f"PASS: all {len(expected)} documented names, families, and face layouts match the class-authored catalog.")


if __name__ == "__main__":
    main()
