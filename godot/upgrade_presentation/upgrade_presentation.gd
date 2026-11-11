extends RefCounted
class_name UpgradePresentation
## Bridge between pure mechanics and native dice. The host owns identities and refresh timing.
## Refresh after rolls, selection, equipment, and history changes; never grants rewards.

# --- Static functions ---

## Keep identity colors visible; show particles only for contributions to the pending play.
## An empty selection suppresses previews during rolls/transfers or blocked game phases.
static func refresh(run: MechanicsRun, selected: Array[StringName], views: Dictionary[StringName, ParoliDie]) -> void:
	var active: Array[StringName] = run.preview_active_upgrades(selected)
	var upgrades: Dictionary[StringName, UpgradeDefinition] = {}
	for item: OwnedDefinition in run.owned:
		if item.definition is UpgradeDefinition:
			upgrades[item.die_id] = item.definition as UpgradeDefinition
	for id: StringName in views:
		var die: ParoliDie = views[id]
		var upgrade: UpgradeDefinition = upgrades.get(id)
		var color: String = String(upgrade.palette_color) if upgrade else "Chalk"
		var effect: String = String(upgrade.vfx_id) if upgrade else "none"
		# Avoid resetting the native animation when selection alone changes.
		if die.palette_color != color:
			die.palette_color = color
		if die.effect != effect:
			die.effect = effect
		die.effect_enabled = id in active and not die.is_rolling() and not die.is_consumed()
