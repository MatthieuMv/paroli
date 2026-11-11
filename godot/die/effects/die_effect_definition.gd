@tool
extends Resource
class_name DieEffectDefinition
## Editable native definition for one particle preset and its consume animation.

# --- Member variables ---

## Stable preset identifier exposed by the die Inspector and viewer.
@export var id: String = "none"
## Scene owns mesh placement, palette roles, and local-to-scene materials.
@export var scene: PackedScene
## Scalar parameters consumed by the typed analytic motion functions.
@export var recipe: Dictionary[String, float] = {}
## Native linear value tracks preserve the existing die activation curves.
@export var activation: Animation
