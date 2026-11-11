extends PanelContainer
class_name CatalogEntry
## Read-only rule card. Its text comes directly from the mechanics definition.

# --- Member variables ---

## Stable identity remains visible when translated names change.
var definition_id: StringName
## Cached text supports search without evaluating rules every keystroke.
var search_text: String
## Authored name and authored rule paragraphs wrap with the card width.
@onready var _title: Label = $Content/Header/Copy/Title
## Diagnostic identity is deliberately secondary to the display name.
@onready var _identity: Label = $Content/Header/Copy/Identity
## Full authored description includes upgrade face layouts.
@onready var _description: KeywordText = $Content/Description

## Stable top-right image slot for bonus and Joker artwork.
@onready var _artwork: TextureRect = $Content/Header/Artwork
## Isolated animated die preview; hidden for illustrated definitions.
@onready var _preview: SubViewportContainer = $Content/Header/Preview
## Native die owns its materials and particle state independently of every other card.
@onready var _die: ParoliDie = $Content/Header/Preview/Viewport/Die

# --- Member functions ---

## Stop simulation when cards are hidden by search or a parent view.
func _ready() -> void:
	visibility_changed.connect(_sync_preview)


## Bind only after entering the tree; no ownership or gameplay state is created.
func configure(definition: BuildDefinition, words: KeywordCatalog, locale: String) -> void:
	definition_id = definition.id
	_artwork.texture = null
	_artwork.visible = definition is IllustratedDefinition
	_preview.visible = definition is UpgradeDefinition
	if definition is IllustratedDefinition:
		_artwork.texture = (definition as IllustratedDefinition).load_artwork()
	elif definition is UpgradeDefinition:
		var upgrade: UpgradeDefinition = definition as UpgradeDefinition
		_die.palette_color = String(upgrade.palette_color)
		_die.effect = String(upgrade.vfx_id)
		_die.effect_enabled = true
		_die.face_value = upgrade.faces[0] if not upgrade.faces.is_empty() else 6
	_sync_preview()
	_title.text = words.render(String(definition.name_keyword), {}, locale)
	_identity.text = String(definition.id)
	_description.configure(definition.describe_rich(words, locale), definition.describe(words, locale), words, locale)
	search_text = (_title.text + " " + _identity.text + " " + _description.plain_text).to_lower()


## Preview particles animate freely here; gameplay eligibility belongs to UpgradePresentation.
func _sync_preview() -> void:
	_die.set_process(is_visible_in_tree() and _preview.visible)
