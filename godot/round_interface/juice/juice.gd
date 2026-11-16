extends RefCounted
class_name Juice
## Shared presentation feel: springy punches, die hops, and number formatting.
## Stateless helpers; every tween belongs to the node it animates.

# --- Static functions ---

## Squash a control outward and let it spring back to rest around its center.
## Rest is scale one: never punch a node the HUD lays out with its own scale; punch a child.
static func punch(control: Control, strength: float = 0.2, seconds: float = 0.4, twist: float = 0.0) -> void:
	control.pivot_offset = control.size * 0.5
	control.scale = Vector2(1.0 + strength, 1.0 - strength * 0.5)
	control.rotation = twist
	var tween: Tween = control.create_tween().set_parallel(true)
	tween.tween_property(control, "scale", Vector2.ONE, seconds).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "rotation", 0.0, seconds).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

## Pop a control in from nothing with a small overshoot.
static func pop_in(control: Control, seconds: float = 0.28) -> void:
	control.pivot_offset = control.size * 0.5
	control.scale = Vector2.ONE * 0.4
	control.show()
	control.create_tween().tween_property(control, "scale", Vector2.ONE, seconds).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Floor-anchored squash and stretch for a die; scale is free because holds only move position.
static func hop(die: Node3D, strength: float = 1.0) -> void:
	var squash: Vector3 = Vector3(1.0 + 0.16 * strength, 1.0 - 0.2 * strength, 1.0 + 0.16 * strength)
	var stretch: Vector3 = Vector3(1.0 - 0.07 * strength, 1.0 + 0.16 * strength, 1.0 - 0.07 * strength)
	die.scale = squash
	var tween: Tween = die.create_tween()
	tween.tween_property(die, "scale", stretch, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(die, "scale", Vector3.ONE, 0.34).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

## Group thousands with thin spaces and keep at most two meaningful decimals.
static func number(value: float) -> String:
	var parts: PackedStringArray = String.num(absf(value), 2).split(".")
	var digits: String = parts[0]
	var grouped: String = ""
	for index: int in digits.length():
		if index > 0 and (digits.length() - index) % 3 == 0:
			grouped += " "
		grouped += digits[index]
	if parts.size() > 1:
		var fraction: String = parts[1].rstrip("0")
		if not fraction.is_empty():
			grouped += "." + fraction
	return ("−" if value < 0.0 and grouped != "0" else "") + grouped

## Signed variant for increments.
static func signed(value: float) -> String:
	return ("+" if value >= 0.0 else "") + number(value)

## Shrink a label's font until its text fits the label width; never grows past `largest`.
static func fit(label: Label, largest: int, smallest: int = 14) -> void:
	var font: Font = label.get_theme_font("font")
	var font_size: int = largest
	while font_size > smallest and font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > label.size.x:
		font_size -= 1
	label.add_theme_font_size_override("font_size", font_size)
