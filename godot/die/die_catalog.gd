@tool
extends Resource
class_name DieCatalog
## Native, Inspector-editable visual definitions shared by all dice.

# --- Member variables ---

## Reusable body, outline, and pip scene.
@export var model: PackedScene
## Shared immutable body geometry used to protect the upward face from VFX.
@export var body_mesh: ArrayMesh
## Preset order includes the disabled effect's activation definition.
@export var effects: Array[DieEffectDefinition] = []
