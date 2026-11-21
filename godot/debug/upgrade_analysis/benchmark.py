"""Run Godot route comparisons in independent seed batches and report cumulative clear rates."""
import argparse
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
import gzip
import hashlib
import json
import math
import os
from pathlib import Path
import subprocess
import sys
import tempfile

HERE = Path(__file__).resolve().parent
PROJECT = HERE.parents[1]
HANDS = "flexible single pair two_pairs three_of_a_kind short_straight full_house long_straight four_of_a_kind five_of_a_kind".split()
THEMES = "held odd even ones sixes diversity sum15 save_rolls spend_rolls repeat switch tempo economy refresh portfolio".split()
CANDIDATES = {"one-man-band": "single", "double-date": "two_pairs", "house-builder": "full_house"}


# Within a row, remove one effect at a time. Permanent upgrade faces still roll normally.
ABLATIONS = {
    "held": "guardian power-reserve bench-warmers me-time lazy-bones",
    "odd": "odd-master odd-squad", "even": "even-master even-squad",
    "ones": "one-or-nothing", "sixes": "six-addict", "sum15": "bean-counter",
    "diversity": "rainbow pick-n-mix", "save_rolls": "first-instinct",
    "spend_rolls": "relentless loyalty-card last-straw do-over",
    "repeat": "deja-vu echo broken-record", "switch": "alternator plot-twist",
    "tempo": "crescendo opening-act grand-finale snowball overtime",
    "economy": "golden-touch payday stonks", "refresh": "roulette side-hustle",
    "portfolio": "nest-egg paid-leave",
}


def cases(suite):
    if suite == "chase":
        return [("five_of_a_kind", "draft", v) for v in ("current", "chase-four")]
    if suite == "broad":
        return [(route, "draft", v) for route in HANDS + ["held", "economy", "portfolio", "refresh"]
                for v in ("current", "reduce-nest-egg", "reduce-opening-act")]
    if suite == "first-pass":
        return [(route, mode, "first-pass") for route in HANDS for mode in ("supplied", "draft")]
    if suite == "slots":
        return [(route, "supplied", v) for route in HANDS[1:] for v in ("current", "swap-opening-act", "swap-nest-egg")]
    if suite == "followups":
        return [("held", "draft", v) for v in ("first-pass", "trial-guardian", "trial-bench-warmers", "trial-power-reserve", "trial-held-package", "trial-lazy-bones", "trial-held-support")] + [
            ("pair", "draft", "first-pass"), ("pair", "draft", "trial-lovebirds")]
    if suite == "ablations":
        return [(route, "supplied", variant) for route, items in ABLATIONS.items()
                for variant in ["current", *("without-" + item for item in items.split())]]
    if suite == "themes":
        return [(route, mode, "current") for route in ["flexible", *THEMES] for mode in ("supplied", "draft")]
    if suite == "candidates":
        targets = [(route, mode, variant) for candidate, route in CANDIDATES.items()
                   for mode in ("supplied", "draft") for variant in ("baseline", candidate)]
        broad = [(route, "draft", variant) for route in HANDS for variant in ("baseline", "opening-act", "nest-egg")]
        return list(dict.fromkeys(targets + broad))
    return [(route, mode, "current") for route in HANDS for mode in ("supplied", "draft")]


def batch(cache, growth, case, start, count):
    """Publish a batch atomically after every consecutive seed has completed."""
    route, mode, variant = case
    path = cache / f"{route}.{mode}.{variant}.{start}.{count}.jsonl.gz"
    if path.exists():
        return path
    args = ["godot", "--headless", "--path", str(PROJECT), "--script",
            "res://debug/upgrade_analysis/run_benchmark.gd", "--", route, mode, variant,
            str(start), str(count)]
    if growth is not None:
        args.append(str(growth))
    with tempfile.TemporaryDirectory() as data:
        proc = subprocess.run(args, env=dict(os.environ, XDG_DATA_HOME=data), capture_output=True,
                              text=True, timeout=120 + 30 * count)
    if proc.returncode or "ERROR:" in proc.stderr or "SCRIPT ERROR" in proc.stdout:
        log = "\n".join(line for line in (proc.stdout + proc.stderr).splitlines() if not line.startswith("{"))
        raise RuntimeError(f"{case}, seeds {start}–{start+count-1}: {log[-2000:]}")
    lines = [line for line in proc.stdout.splitlines() if line.startswith("{")]
    if [json.loads(line)["seed"] for line in lines] != list(range(start, start + count)):
        raise RuntimeError(f"Incomplete seed batch for {case}")
    with tempfile.NamedTemporaryFile(dir=cache, delete=False) as tmp:
        with gzip.open(tmp, "wt") as output:
            output.writelines(line + "\n" for line in lines)
    Path(tmp.name).replace(path)
    return path


def interval(wins, count, z=1.96):
    """95% Wilson interval, including zero-win cells."""
    p = wins / count
    center = p + z*z / (2*count)
    radius = z * math.sqrt(p*(1-p)/count + z*z/(4*count*count))
    return [(center + sign*radius)/(1+z*z/count) for sign in (-1, 1)]


class Cohort:
    """Outcomes ordered by seed, plus diagnostics from those same trajectories."""

    def __init__(self, paths):
        self.stats = Counter()
        self.late = Counter()
        self.clears = {}
        for path in paths:
            with gzip.open(path, "rt") as raw:
                for line in raw:
                    row = json.loads(line)
                    seed = row["seed"]
                    if seed in self.clears:
                        raise ValueError(f"Overlapping batches at seed {seed}")
                    self.clears[seed] = row["stats"].get("cleared", 0)
                    self.stats.update(row["stats"])
                    self.late.update(row["late"])

    def summary(self, route):
        count = len(self.clears)
        bosses = [sum(c >= level for c in self.clears.values()) for level in (3, 6, 9, 12, 15)]
        lo, hi = interval(bosses[-1], count)
        stats = " | ".join(f"{100*n/count:.1f}" for n in bosses)
        signature = "— | —"
        if route in HANDS[1:]:
            share = 100*self.late[route]/sum(self.late.values()) if self.late else 0
            signature = f"{share:.1f} | {self.stats['signature_clears']/count:.2f}"
        return f"{stats} | {100*lo:.1f}–{100*hi:.1f} | {signature}"

    def paired(self, control):
        """Paired percentage-point differences with a conservative joint Wilson bound."""
        if self.clears.keys() != control.clears.keys():
            raise ValueError("Paired controls require identical seeds")
        count = len(self.clears)
        gaps = []
        for boss in (3, 6, 9, 12, 15):
            gained = sum(c >= boss > control.clears[s] for s, c in self.clears.items())
            lost = sum(c < boss <= control.clears[s] for s, c in self.clears.items())
            gaps.append(100*(gained-lost)/count)
        gain_lo, gain_hi = interval(gained, count, z=2.2414)
        loss_lo, loss_hi = interval(lost, count, z=2.2414)
        return gaps, 100*(gain_lo-loss_hi), 100*(gain_hi-loss_lo)


def print_diagnostics(cohorts):
    print("\n| Route | Access | Rules | Rerolls/run | Effect coins/run | Purchases/run | Refreshes/run | Failed four-match chase % | Failed despite five % |")
    print("|---|---|---|---:|---:|---:|---:|---:|---:|")
    for case, cohort in cohorts.items():
        t = cohort.stats
        count = len(cohort.clears)
        buys = sum(v for k, v in t.items() if k.startswith("buy_"))
        means = [t["rerolls"], t["income"], buys, t["refreshes"]]
        values = " | ".join(f"{v/count:.2f}" for v in means)
        chase = f"{100*t['failed_chase']/count:.1f} | {100*t['failed_after_five']/count:.1f}" if case[0] == "five_of_a_kind" else "— | —"
        print(f"| {' | '.join(case)} | {values} | {chase} |")


def print_comparisons(cohorts):
    shown = False
    for (route, mode, variant), cohort in cohorts.items():
        ref = (route, mode, "baseline") if variant != "current" else ("flexible", mode, "current")
        if variant.startswith("trial-"):
            ref = (route, mode, "first-pass")
        if variant == "chase-four" or variant.startswith(("without-", "swap-", "reduce-")):
            ref = (route, mode, "current")
        if ref not in cohorts or cohorts[ref] is cohort:
            continue
        if not shown:
            print("\n| Route | Access | Rules | Reference | Win Δ pp | Paired 95% CI | First boss beyond ±10 pp |")
            print("|---|---|---|---|---:|---|---|")
            shown = True
        gaps, lo, hi = cohort.paired(cohorts[ref])
        first = next((str(b) for b, gap in enumerate(gaps, 1) if abs(gap) > 10), "—")
        print(f"| {route} | {mode} | {variant} | {ref[0]} {ref[2]} | {gaps[-1]:+.1f} | {lo:+.1f} to {hi:+.1f} | {first} |")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("suite", choices=["hands", "themes", "candidates", "ablations", "followups", "slots", "first-pass", "broad", "chase"])
    parser.add_argument("--seeds", type=int, default=2000)
    parser.add_argument("--first", type=int, default=1)
    parser.add_argument("--jobs", type=int, default=4)
    parser.add_argument("--batch", type=int, default=50)
    parser.add_argument("--growth", type=float, help="override target growth in the experiment")
    parser.add_argument("--route", action="append", help="restrict to one or more named routes")
    parser.add_argument("--mode", choices=["draft", "supplied"])
    args = parser.parse_args()
    if min(args.seeds, args.first, args.jobs, args.batch) < 1:
        parser.error("seeds, first, jobs and batch must be positive")
    if args.growth is not None and not (1 <= args.growth <= 3):
        parser.error("growth must be between 1 and 3")
    selected = [c for c in cases(args.suite) if (not args.route or c[0] in args.route) and (not args.mode or c[1] == args.mode)]
    if not selected:
        parser.error("no matching comparisons")
    # Hash game logic and fixtures so cached measurements never silently cross rule changes.
    digest = hashlib.sha256(subprocess.check_output(["godot", "--version"]))
    folders = [PROJECT / p for p in ("mechanics", "game/session", "shop_interface/session", "round_interface/session")]
    sources = [p for folder in folders for p in sorted(folder.rglob("*.gd")) if "tests" not in p.parts]
    sources += [HERE/"run_benchmark.gd", HERE/"run_policy.gd", HERE/"run_trials.gd",
                PROJECT/"game/session/run_rules.tres", PROJECT/"shop_interface/session/shop_rules.tres"]
    for path in sources:
        digest.update(path.read_bytes())
    cache = PROJECT.parent / "build/balance" / digest.hexdigest()[:12] / str(args.growth or "game")
    cache.mkdir(parents=True, exist_ok=True)
    print(f"Seed records in {cache}", file=sys.stderr, flush=True)
    print("| Route | Access | Rules | Boss 1 % | Boss 2 % | Boss 3 % | Boss 4 % | Win % | Win 95% CI | Late signature score % | Decisive clears/run |")
    print("|---|---|---|---:|---:|---:|---:|---:|---|---:|---:|")
    with ThreadPoolExecutor(args.jobs) as pool:
        jobs = {case: [] for case in selected}
        for start in range(args.first, args.first + args.seeds, args.batch):
            for case in selected:
                size = min(args.batch, args.first + args.seeds - start)
                jobs[case].append(pool.submit(batch, cache, args.growth, case, start, size))
        cohorts = {}
        for case, futures in jobs.items():
            cohort = Cohort([f.result() for f in futures])
            cohorts[case] = cohort
            print("| " + " | ".join(case) + " | " + cohort.summary(case[0]) + " |", flush=True)
    print_comparisons(cohorts)
    print_diagnostics(cohorts)


if __name__ == "__main__":
    main()
