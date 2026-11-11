@tool
extends RefCounted
class_name GameColors
## Shared sRGB authoring colors. No autoload, scene, or die catalog dependency.

# --- Constants ---

## Peach palette token, authored as sRGB.
const PEACH: Color = Color("f48665")
## Butter palette token, authored as sRGB.
const BUTTER: Color = Color("edcc63")
## Mint palette token, authored as sRGB.
const MINT: Color = Color("93b99b")
## Lavender palette token, authored as sRGB.
const LAVENDER: Color = Color("b7a3d7")
## Chalk palette token, authored as sRGB.
const CHALK: Color = Color("f4eddc")
## Bubblegum palette token, authored as sRGB.
const BUBBLEGUM: Color = Color("f29fbe")
## Cherry palette token, authored as sRGB.
const CHERRY: Color = Color("e77984")
## Tangerine palette token, authored as sRGB.
const TANGERINE: Color = Color("efa05b")
## Honey palette token, authored as sRGB.
const HONEY: Color = Color("dcb34e")
## Pistachio palette token, authored as sRGB.
const PISTACHIO: Color = Color("bed17d")
## Lagoon palette token, authored as sRGB.
const LAGOON: Color = Color("68bbb2")
## Sky palette token, authored as sRGB.
const SKY: Color = Color("8bbfdf")
## Periwinkle palette token, authored as sRGB.
const PERIWINKLE: Color = Color("929cdd")
## Lilac palette token, authored as sRGB.
const LILAC: Color = Color("c995d2")
## Cocoa palette token, authored as sRGB.
const COCOA: Color = Color("bc9683")
## Ink palette token, authored as sRGB.
const INK: Color = Color("30223d")
## Background palette token, authored as sRGB.
const BACKGROUND: Color = Color("eee9e2")
## Control surface palette token, authored as sRGB.
const CONTROL_SURFACE: Color = Color("fffaf0")
## Control emphasis palette token, authored as sRGB.
const CONTROL_EMPHASIS: Color = Color("e7d9ed")
## Existing die highlight tint, retained independently from cream UI surfaces.
const SHINE: Color = Color(1.0, 0.97, 0.90)
## Explicit display order, independent of resource dictionary serialization.
const PALETTE_ORDER: Array[String] = [
	"Peach",
	"Butter",
	"Mint",
	"Lavender",
	"Chalk",
	"Bubblegum",
	"Cherry",
	"Tangerine",
	"Honey",
	"Pistachio",
	"Lagoon",
	"Sky",
	"Periwinkle",
	"Lilac",
	"Cocoa",
]
## Immutable named object colors; semantic UI roles belong to KeywordColors.
const PALETTE: Dictionary[String, Color] = {
	"Peach": PEACH,
	"Butter": BUTTER,
	"Mint": MINT,
	"Lavender": LAVENDER,
	"Chalk": CHALK,
	"Bubblegum": BUBBLEGUM,
	"Cherry": CHERRY,
	"Tangerine": TANGERINE,
	"Honey": HONEY,
	"Pistachio": PISTACHIO,
	"Lagoon": LAGOON,
	"Sky": SKY,
	"Periwinkle": PERIWINKLE,
	"Lilac": LILAC,
	"Cocoa": COCOA,
}

# --- Static functions ---

## Return an ordered, caller-owned dictionary so local edits cannot mutate the palette.
static func palette() -> Dictionary[String, Color]:
	var result: Dictionary[String, Color] = {}
	for color_name: String in PALETTE_ORDER:
		result[color_name] = PALETTE[color_name]
	return result
