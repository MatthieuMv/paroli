"""Exact chance to select each hand before the first play with five ordinary dice."""
from collections import Counter
from functools import cache
from itertools import combinations, combinations_with_replacement
import json
from math import factorial, prod
from pathlib import Path
import subprocess

HERE = Path(__file__).resolve().parent


@cache
def rolls(size):
    """Unordered rolls with their integer physical multiplicities."""
    return {hand: factorial(size) // prod(factorial(n) for n in Counter(hand).values())
            for hand in combinations_with_replacement(range(1, 7), size)}


def main():
    # Take category names and precedence directly from the game's ordinary replay records.
    sql = """SELECT played_faces, category FROM '*_outcomes.parquet'
             WHERE effect='plain' AND state='fresh'"""
    rows = json.loads(subprocess.check_output(["duckdb", "-no-agent", "-json", "-c", sql], cwd=HERE))
    categories = {tuple(row["played_faces"]): row["category"] for row in rows}
    hands = rolls(5)
    selections = {hand: {sub for n in range(6) for sub in combinations(hand, n)} for hand in hands}
    if categories.keys() != {sub for subsets in selections.values() for sub in subsets if sub}:
        raise ValueError("Rebuild all nine category reports before computing selection odds")

    # From any kept subset, fresh dice have the same distribution irrespective of the discarded faces.
    transitions = {keep: [(tuple(sorted(keep + new)), ways / 6**(5-len(keep)))
                          for new, ways in rolls(5-len(keep)).items()]
                   for n in range(5) for keep in rolls(n)}
    print("| Hand | Opening | ≤1 reroll | ≤2 rerolls | ≤3 rerolls |")
    print("|---|---:|---:|---:|---:|")
    for category in dict.fromkeys(categories[sub] for n in range(1, 6) for sub in rolls(n)):
        value = {hand: float(any(categories.get(sub) == category for sub in selections[hand])) for hand in hands}
        odds = []
        for remaining in range(4):
            odds.append(sum(hands[h]*value[h] for h in hands)/6**5)
            if remaining < 3:
                expected = {keep: sum(p*value[h] for h, p in next_hands) for keep, next_hands in transitions.items()}
                value = {h: max(value[h], max(expected[s] for s in selections[h] if len(s) < 5)) for h in hands}
        print(f"| {category} | " + " | ".join(f"{100*p:.2f}%" for p in odds) + " |")


if __name__ == "__main__":
    main()
