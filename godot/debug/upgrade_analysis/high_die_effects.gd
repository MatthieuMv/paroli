extends "res://debug/upgrade_analysis/combination_analysis.gd"
## Original entry point for the weighted High Die reports.

# --- Member functions ---

## Use the shared combination runner with the historical report names.
func _initialize() -> void:
	analyze("high_die", false)
