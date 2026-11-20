extends RefCounted
class_name GameSettings
## Player preferences shared by every screen: sound and language. One instance lives for the
## whole session (`shared()`); screens read it when they open and follow `changed`.
## Only the app's entry point loads the saved file, so checks never depend on a player's
## choices; any change is written back to the same file.

# --- Signals ---

## Sound or language changed; screens apply the new values.
signal changed

# --- Constants ---

## Languages the glossary is written in, in the order the settings offer them.
const LOCALES: PackedStringArray = ["fr", "en"]
## Each language's own name, so a player can always find theirs.
const LOCALE_NAMES: Dictionary[String, String] = {"fr": "Français", "en": "English"}
## Where preferences are kept between sessions.
const STORAGE: String = "user://settings.cfg"

# --- Member variables ---

## Session-wide instance, created on first use.
static var _shared: GameSettings
## Whether sound effects play.
var sound_enabled: bool = true
## Chosen language; empty follows the device.
var locale: String = ""
## File the preferences are loaded from and saved to; empty keeps them in memory only.
var storage_path: String = STORAGE

# --- Static functions ---

## Session-wide preferences.
static func shared() -> GameSettings:
	if not _shared:
		_shared = GameSettings.new()
	return _shared

# --- Member functions ---

## Read the saved preferences, if any, and apply the language. Called once by the app.
func load_saved() -> void:
	if storage_path.is_empty():
		return
	var file: ConfigFile = ConfigFile.new()
	if file.load(storage_path) != OK:
		return
	sound_enabled = bool(file.get_value("audio", "sound_enabled", true))
	locale = String(file.get_value("language", "locale", ""))
	_apply_locale()
	changed.emit()

## Turn sound effects on or off.
func set_sound_enabled(enabled: bool) -> void:
	if enabled == sound_enabled:
		return
	sound_enabled = enabled
	_save()
	changed.emit()

## Switch the game to one of `LOCALES`; empty follows the device again.
func set_locale(code: String) -> void:
	if code == locale:
		return
	locale = code
	_apply_locale()
	_save()
	changed.emit()

## Language the game currently speaks, as one of `LOCALES`; others read as English, the
## glossary's fallback.
func active_locale() -> String:
	var language: String = TranslationServer.get_locale().get_slice("_", 0)
	return language if language in LOCALES else "en"

## Point the translation server at the chosen language, or back at the device's.
func _apply_locale() -> void:
	TranslationServer.set_locale(locale if not locale.is_empty() else OS.get_locale())

## Write the preferences; failures only cost persistence.
func _save() -> void:
	if storage_path.is_empty():
		return
	var file: ConfigFile = ConfigFile.new()
	file.set_value("audio", "sound_enabled", sound_enabled)
	file.set_value("language", "locale", locale)
	file.save(storage_path)
