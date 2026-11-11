extends BuildDefinition
class_name UpgradeDefinition
## Permanent die-bound identity. Slot order, immutability, and application are host policies.

# --- Member variables ---

## Optional permanent layout; empty preserves the original six positions.
@export var faces: PackedInt32Array = []
## Visual references are identifiers only; mechanics never loads rendering scenes.
@export var palette_color: StringName = &"Chalk"
## Distinct from EffectDefinition: this ID names a visual particle preset.
@export var vfx_id: StringName = &"none"

# --- Member functions ---

## Declare identity, physical faces, and rules together, followed by optional visual IDs.
func _init(id_: StringName = &"", faces_: PackedInt32Array = [], effects_: Array[EffectDefinition] = [], palette_color_: StringName = &"Chalk", vfx_id_: StringName = &"none") -> void:
	id = id_
	faces = faces_
	effects = effects_
	palette_color = palette_color_
	vfx_id = vfx_id_


## Validate permanent faces without embedding mutable installation state.
func local_errors() -> PackedStringArray:
	var errors: PackedStringArray = super.local_errors()
	if not faces.is_empty() and faces.size() != 6:
		errors.append("An upgrade layout needs six positions")
	for value: int in faces:
		if value < 1:
			errors.append("Face values must be positive")
	return errors

## Include face changes in generated text so an upgrade cannot hide altered odds.
func describe(words: KeywordCatalog, locale: String = "") -> String:
	if not validate_keywords(words).is_empty():
		return words.render("invalid", {}, locale)
	var effects_text: String = super.describe(words, locale)
	if faces.is_empty():
		return effects_text
	var values: PackedStringArray = []
	for value: int in faces:
		values.append(words.number(value, locale))
	var layout: String = words.render("upgrade.faces", {"faces": words.join(values, "list.sequence", locale)}, locale)
	return layout + ("\n" + effects_text if not effects_text.is_empty() else "")

## Face layouts add grammar dependencies to the common build-name dependencies.
func keyword_ids() -> Array[StringName]:
	var result: Array[StringName] = super.keyword_ids()
	result.append_array([&"upgrade.faces", &"list.sequence"])
	return result

## Keep physical faces beside authored prose in rich views as well as plain search text.
func describe_rich(words: KeywordCatalog, locale: String = "") -> String:
	var body: String = super.describe_rich(words, locale)
	if not description or faces.is_empty():
		return body
	var values: PackedStringArray = []
	for value: int in faces:
		values.append(words.number(value, locale))
	return words.render("upgrade.faces", {"faces": words.join(values, "list.sequence", locale)}, locale).replace("[", "[lb]") + "\n" + body
