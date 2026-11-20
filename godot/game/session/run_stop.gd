extends RefCounted
class_name RunStop
## One stop on a run's route: an upgrade choice, a round, or a shop visit, with what the
## host needs to present it. Stops are built once per run and never change.

# --- Types ---

## What happens at a stop.
enum Kind { UPGRADE, ROUND, SHOP }

# --- Member variables ---

## What happens here.
var kind: Kind = Kind.ROUND
## Biome this stop belongs to, counted from 1.
var biome: int = 1
## For a round, its number across the whole run, counted from 1. For an upgrade choice or
## a shop, the number of the round that follows it.
var round_number: int = 1
## For a round, whether it is its biome's boss. For a shop, whether the boss comes next.
var boss: bool = false
## Points the round must reach; zero for upgrade choices and shops.
var target: float = 0.0

# --- Member functions ---

## Declare a stop in one readable expression.
func _init(kind_: Kind = Kind.ROUND, biome_: int = 1, round_number_: int = 1, boss_: bool = false, target_: float = 0.0) -> void:
	kind = kind_
	biome = biome_
	round_number = round_number_
	boss = boss_
	target = target_
