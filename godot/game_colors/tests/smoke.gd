extends SceneTree
## Guard palette migration against order, color, ownership, and keyword-tone regressions.

# --- Constants ---

## Independent baseline from the original catalog, in its authored display order.
const EXPECTED_HEX: PackedStringArray = ["f48665", "edcc63", "93b99b", "b7a3d7", "f4eddc", "f29fbe", "e77984", "efa05b", "dcb34e", "bed17d", "68bbb2", "8bbfdf", "929cdd", "c995d2", "bc9683"]
const EXPECTED_NAMES: PackedStringArray = ["Peach", "Butter", "Mint", "Lavender", "Chalk", "Bubblegum", "Cherry", "Tangerine", "Honey", "Pistachio", "Lagoon", "Sky", "Periwinkle", "Lilac", "Cocoa"]

# --- Member functions ---

## Check the shared palette and compatibility API without needing any rendered scenes.
func _initialize() -> void:
	var palette: Dictionary[String, Color] = GameColors.palette()
	assert(palette.size() == 15)
	assert(PackedStringArray(palette.keys()) == EXPECTED_NAMES)
	assert(PackedStringArray(DieLibrary.palette().keys()) == EXPECTED_NAMES)
	assert(GameColors.PALETTE.is_read_only() and GameColors.PALETTE_ORDER.is_read_only())
	for index: int in EXPECTED_NAMES.size():
		var name: String = EXPECTED_NAMES[index]
		assert(palette[name] == Color(EXPECTED_HEX[index]))
		assert(DieLibrary.palette()[name] == palette[name])
	palette["Peach"] = Color.BLACK
	palette.erase("Butter")
	assert(GameColors.palette()["Peach"] == Color("f48665"))
	assert(DieLibrary.palette().size() == 15)
	assert(KeywordColors.PALETTE[&"points"] == GameColors.SKY)
	assert(KeywordColors.PALETTE[&"mult"] == GameColors.CHERRY)
	assert(KeywordColors.for_role(&"points").is_equal_approx(Color("8bbfdf").lerp(Color("30223d"), 0.5)))
	assert(KeywordColors.for_role(&"unknown") == GameColors.INK)
	print("PASS: original palette values/order, immutable constants, caller isolation, die API, keyword tones.")
	quit()
