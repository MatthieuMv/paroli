extends Control
class_name CatalogViewer
## Standalone searchable catalog; previews definitions without installing or activating them.

# --- Constants ---

## Only catalog-dependent cards are instantiated at runtime.
const ENTRY: PackedScene = preload("res://debug/catalog_viewer/catalog_entry.tscn")

# --- Member variables ---

## Each viewer owns its catalog; shared Resources are never mutated.
var _catalog: EffectsCatalog = EffectsCatalog.new()
## Locale is explicit, leaving the game's global translation setting unchanged.
var _words: KeywordCatalog = GameKeywords.new()
## Selected family follows the authored button order: upgrades, bonuses, Jokers.
var _family: int = 0
## Current player-text locale.
var _locale: String = "en"
## Authored family buttons adapt to narrow windows through a flow container.
@onready var _families: HFlowContainer = $Margin/Layout/Families
## Search includes localized names, stable IDs, and authored rule text.
@onready var _search: LineEdit = $Margin/Layout/Search
## Local language switch.
@onready var _language: OptionButton = $Margin/Layout/Header/Language
## Responsive card grid is owned by the scroll area.
@onready var _cards: GridContainer = $Margin/Layout/Scroll/Cards
## Vertical scroll preserves readable type on small screens.
@onready var _scroll: ScrollContainer = $Margin/Layout/Scroll
## Result count also communicates an empty search.
@onready var _count: Label = $Margin/Layout/Count

# --- Member functions ---

## Connect authored controls once, then show the first content family.
func _ready() -> void:
	for message: String in _catalog.artwork_errors():
		push_error(message)
	for index: int in _families.get_child_count():
		var button: Button = _families.get_child(index) as Button
		button.pressed.connect(_select_family.bind(index))
	_search.text_changed.connect(_filter)
	_language.item_selected.connect(_select_language)
	_scroll.resized.connect(_resize_cards)
	_rebuild()

## Tab changes preserve search and locale, and return to the top.
func _select_family(index: int) -> void:
	_family = index
	_rebuild()

## Render descriptions from the same definitions in the selected language.
func _select_language(index: int) -> void:
	_language.select(index)
	_locale = "en" if index == 0 else "fr"
	_rebuild()

## Replace only data-dependent entries; controls and card structure remain scene-authored.
func _rebuild() -> void:
	var french: bool = _locale == "fr"
	($Margin/Layout/Header/Title as Label).text = "Catalogue" if french else "Catalog"
	_search.placeholder_text = "Rechercher un nom, un ID ou un effet…" if french else "Search name, ID, or effect…"
	var labels: PackedStringArray = ["Améliorations", "Bonus", "Jokers"] if french else ["Upgrades", "Bonuses", "Jokers"]
	for index: int in _families.get_child_count():
		(_families.get_child(index) as Button).text = labels[index]
	for child: Node in _cards.get_children():
		_cards.remove_child(child)
		child.queue_free()
	var definitions: Array[BuildDefinition] = []
	match _family:
		0:
			definitions.append_array(_catalog.upgrades)
		1:
			definitions.append_array(_catalog.bonuses)
		2:
			definitions.append_array(_catalog.jokers)
	for definition: BuildDefinition in definitions:
		var entry: CatalogEntry = ENTRY.instantiate() as CatalogEntry
		_cards.add_child(entry)
		entry.configure(definition, _words, _locale)
	for index: int in _families.get_child_count():
		(_families.get_child(index) as Button).set_pressed_no_signal(index == _family)
	_scroll.scroll_vertical = 0
	_filter(_search.text)
	_resize_cards()

## Filter in place so typing never rebuilds rules or steals input focus.
func _filter(query: String) -> void:
	var count: int = 0
	var needle: String = query.strip_edges().to_lower()
	for entry: CatalogEntry in _cards.get_children():
		entry.visible = needle.is_empty() or needle in entry.search_text
		if entry.visible:
			count += 1
	_count.text = "%d / %d · %s" % [count, _cards.get_child_count(), ("Aucun résultat" if _locale == "fr" else "No matches") if count == 0 else ("Survolez ou touchez les mots colorés" if _locale == "fr" else "Hover or tap colored keywords")]

## Maintain readable card widths; portrait becomes a single scrolling column.
func _resize_cards() -> void:
	_cards.columns = clampi(int((_scroll.size.x - 16.0) / 340.0), 1, 3)
