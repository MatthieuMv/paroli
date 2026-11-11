extends BuildDefinition
class_name IllustratedDefinition
## Shared artwork contract for bonus/Joker definitions; no scene dependency or mutable visual state.

# --- Member functions ---

## Subclasses supply the family directory; filenames always follow the stable definition ID.
func artwork_path() -> String:
	return ""

## Resolve imported SVG textures lazily; ResourceLoader owns the shared texture cache.
func load_artwork() -> Texture2D:
	var errors: PackedStringArray = artwork_errors()
	if not errors.is_empty():
		for message: String in errors:
			push_error(message)
		return null
	return load(artwork_path()) as Texture2D

## Content verification is separate from rule validation so synthetic rule fixtures need no art.
func artwork_errors() -> PackedStringArray:
	var path: String = artwork_path()
	if not ResourceLoader.exists(path, "Texture2D"):
		return ["Missing artwork for %s: %s" % [id, path]]
	if not load(path) is Texture2D:
		return ["Invalid artwork texture for %s: %s" % [id, path]]
	return []
