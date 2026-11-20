extends "res://debug/upgrade_analysis/combination_analysis.gd"
## Original entry point for listing plain High Die hands.

# --- Member functions ---

## Keep the standalone hand listing and its column names.
func _initialize() -> void:
	analyze("high_die", true)
