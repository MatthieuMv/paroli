extends RefCounted
class_name KeywordColors
## Readable text tones derived from the existing object palette and plum ink.

# --- Constants ---

## Existing outline color darkens pastel body colors for cream text surfaces.
const INK: Color = GameColors.INK
## Existing Sky, Cherry, Lavender, Honey, Lagoon, and Tangerine palette colors.
const PALETTE: Dictionary[StringName, Color] = {
	&"points": GameColors.SKY,
	&"mult": GameColors.CHERRY,
	&"combination": GameColors.LAVENDER,
	&"coins": GameColors.HONEY,
	&"selection": GameColors.LAGOON,
	&"tempo": GameColors.TANGERINE,
}

# --- Static functions ---

## Mix existing colors with ink rather than adding unrelated saturated UI colors.
static func for_role(role: StringName) -> Color:
	return PALETTE[role].lerp(INK, 0.5) if PALETTE.has(role) else INK
