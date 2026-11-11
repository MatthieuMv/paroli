@tool
extends MeshInstance3D
class_name DiePaletteMesh
## An editor-authored mesh with a palette role and instance-local material.

# --- Member variables ---

## Color relationship used when the owning die changes its palette.
@export_enum("base", "light", "deep", "star", "ink", "white") var tone: String = "base"
## Baseline opacity before landing or activation fades are applied.
@export_range(0.0, 1.0) var opacity: float = 1.0
