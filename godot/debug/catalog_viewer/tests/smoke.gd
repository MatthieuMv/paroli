extends SceneTree
## Verify catalog coverage, generated copy, filtering, locale changes, and responsive cards.

# --- Constants ---

## Standalone viewer under test; no gameplay scene is required.
const VIEWER: PackedScene = preload("res://debug/catalog_viewer/catalog_viewer.tscn")

# --- Member functions ---

## Defer construction until the root viewport is ready.
func _initialize() -> void:
	_run.call_deferred()

## Exercise each catalog family and capture both orientations when a display is available.
func _run() -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(1280, 900)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var viewer: CatalogViewer = VIEWER.instantiate() as CatalogViewer
	viewport.add_child(viewer)
	await _settle()
	var cards: GridContainer = viewer.get_node("Margin/Layout/Scroll/Cards") as GridContainer
	var catalog: EffectsCatalog = EffectsCatalog.new()
	assert(catalog.artwork_errors().is_empty())
	var missing: BonusDefinition = BonusDefinition.new(&"missing_art_fixture")
	assert(missing.artwork_errors().size() == 1)
	assert("missing_art_fixture.svg" in missing.artwork_errors()[0])
	var words: KeywordCatalog = GameKeywords.new()
	var expected: Array[int] = [14, 29, 28]
	for family: int in 3:
		viewer._select_family(family)
		await _settle()
		assert(cards.get_child_count() == expected[family])
		for entry: CatalogEntry in cards.get_children():
			var definition: BuildDefinition
			match family:
				0:
					definition = catalog.upgrade(entry.definition_id)
				1:
					definition = catalog.bonus(entry.definition_id)
				2:
					definition = catalog.joker(entry.definition_id)
			assert(entry._description.plain_text == definition.describe(words, "en"))
			assert(not entry._title.text.is_empty())
			if definition is IllustratedDefinition:
				assert(entry._artwork.texture != null and entry._artwork.visible)
				assert(not entry._preview.visible and not entry._die.is_processing())
				assert(entry._artwork.texture.resource_path == (definition as IllustratedDefinition).artwork_path())
			else:
				var upgrade: UpgradeDefinition = definition as UpgradeDefinition
				assert(entry._preview.visible and not entry._artwork.visible)
				assert(entry._die.palette_color == String(upgrade.palette_color))
				assert(entry._die.effect == String(upgrade.vfx_id) and entry._die.effect_enabled)
			assert(entry.visible, "Empty search must show every card")
			assert(entry._description.size.y >= entry._description.get_minimum_size().y)
		if "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			viewport.get_texture().get_image().save_png("/tmp/paroli-catalog-family-%d.png" % family)
	viewer._select_family(0)
	viewer._filter("rainbow")
	var matches: int = 0
	for entry: CatalogEntry in cards.get_children():
		if entry.visible:
			matches += 1
			assert(entry.definition_id == &"rainbow")
	assert(matches == 1)
	viewer._filter("no_such_effect")
	assert("No matches" in viewer._count.text)
	viewer._select_language(1)
	var first: CatalogEntry = cards.get_child(0) as CatalogEntry
	assert(first._description.plain_text == catalog.upgrades[0].describe(words, "fr"))
	viewer._select_language(0)
	for dimensions: Vector2i in [Vector2i(1280, 900), Vector2i(390, 844)]:
		viewport.size = dimensions
		await _settle()
		assert(cards.columns == (3 if dimensions.x > 1000 else 1))
		assert(viewer.size.x == dimensions.x, "Content widened the viewport")
		assert(cards.size.x <= viewer._scroll.size.x)
		for entry: CatalogEntry in cards.get_children():
			assert(entry._preview.size.x == 112.0)
			assert(entry._title.size.x > 80.0)
			assert(entry._description.position.y >= (entry.get_node("Content/Header") as Control).size.y)
		if "--capture" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			var capture: Image = viewport.get_texture().get_image()
			capture.save_png("/tmp/paroli-catalog-%d.png" % dimensions.x)
	viewer.queue_free()
	viewport.queue_free()
	await process_frame
	print("PASS: catalog families, generated descriptions, search, locales, and responsive layout")
	quit()

## Allow containers and wrapped-label minima to converge after resizing.
func _settle() -> void:
	for frame: int in 12:
		await process_frame
