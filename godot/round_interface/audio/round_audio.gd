extends Node
class_name RoundAudio
## One-shot sound effects for the table screens (round and shop), played through a small voice pool.
## Pitched cues share a C5 root, so chains climb a pentatonic ladder via `pitch_scale`.
## Plain players and WAV streams keep this compatible with the single-threaded Web export.

# --- Constants ---

## Major pentatonic degrees in semitones; chains never land on a sour interval.
const LADDER: PackedInt32Array = [0, 2, 4, 7, 9, 12, 14, 16, 19, 21, 24]
## Simultaneous voices; the oldest voice is reused when every player is busy.
const VOICES: int = 14
## Synthesized placeholder cues; see docs/audio_explorations/round_sfx.
const CUES: Dictionary[StringName, AudioStream] = {
	&"bank": preload("res://round_interface/audio/sfx/bank.wav"),
	&"button": preload("res://round_interface/audio/sfx/button.wav"),
	&"coin": preload("res://round_interface/audio/sfx/coin.wav"),
	&"combo": preload("res://round_interface/audio/sfx/combo.wav"),
	&"consume": preload("res://round_interface/audio/sfx/consume.wav"),
	&"count": preload("res://round_interface/audio/sfx/count.wav"),
	&"die_clack_1": preload("res://round_interface/audio/sfx/die_clack_1.wav"),
	&"die_clack_2": preload("res://round_interface/audio/sfx/die_clack_2.wav"),
	&"die_clack_3": preload("res://round_interface/audio/sfx/die_clack_3.wav"),
	&"die_hold": preload("res://round_interface/audio/sfx/die_hold.wav"),
	&"die_release": preload("res://round_interface/audio/sfx/die_release.wav"),
	&"fly": preload("res://round_interface/audio/sfx/fly.wav"),
	&"hover": preload("res://round_interface/audio/sfx/hover.wav"),
	&"lose": preload("res://round_interface/audio/sfx/lose.wav"),
	&"pip": preload("res://round_interface/audio/sfx/pip.wav"),
	&"roll": preload("res://round_interface/audio/sfx/roll.wav"),
	&"stamp": preload("res://round_interface/audio/sfx/stamp.wav"),
	&"tick_mult": preload("res://round_interface/audio/sfx/tick_mult.wav"),
	&"tick_percent": preload("res://round_interface/audio/sfx/tick_percent.wav"),
	&"tick_points": preload("res://round_interface/audio/sfx/tick_points.wav"),
	&"total": preload("res://round_interface/audio/sfx/total.wav"),
	&"win": preload("res://round_interface/audio/sfx/win.wav"),
	&"womp": preload("res://round_interface/audio/sfx/womp.wav"),
	&"reveal": preload("res://round_interface/audio/sfx/reveal.wav"),
	&"refresh": preload("res://round_interface/audio/sfx/refresh.wav"),
	&"place": preload("res://round_interface/audio/sfx/place.wav"),
	&"pickup": preload("res://round_interface/audio/sfx/pickup.wav"),
	&"deny": preload("res://round_interface/audio/sfx/deny.wav"),
	&"deal": preload("res://round_interface/audio/sfx/deal.wav"),
	&"buy": preload("res://round_interface/audio/sfx/buy.wav"),
}
## Per-cue mix in decibels, relative to `volume_db`; unlisted cues play at zero.
const MIX: Dictionary[StringName, float] = {
	&"hover": -16.0,
	&"count": -12.0,
	&"die_clack_1": -4.0,
	&"die_clack_2": -4.0,
	&"die_clack_3": -4.0,
	&"roll": -9.0,
	&"fly": -8.0,
	&"consume": -7.0,
	&"button": -4.0,
	&"pip": -8.0,
	&"die_hold": -5.0,
	&"die_release": -5.0,
	&"tick_points": -3.0,
	&"tick_mult": -3.0,
	&"tick_percent": -3.0,
	&"coin": -6.0,
	&"combo": -5.0,
	&"bank": -3.0,
	&"womp": -5.0,
	&"buy": -4.0,
	&"deny": -6.0,
	&"pickup": -8.0,
	&"place": -5.0,
	&"deal": -9.0,
	&"refresh": -6.0,
	&"reveal": -5.0,
}

# --- Member variables ---

## Silences every cue without stopping the presentation that triggers them.
@export var muted: bool = false
## Overall effects level in decibels.
@export_range(-40.0, 6.0, 0.5) var volume_db: float = -7.0
## Pool created once at ready; players are reused, never freed, during play.
var _voices: Array[AudioStreamPlayer] = []
## Next pool slot to try, so reuse walks the pool instead of cutting the newest voice.
var _cursor: int = 0
## Private generator for humanizing pitch; never touches gameplay randomness.
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

# --- Member functions ---

## Ready callback: build the fixed voice pool.
func _ready() -> void:
	for index: int in VOICES:
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(voice)
		_voices.append(voice)

## Play a cue. `ladder_step` climbs the pentatonic ladder; `jitter` humanizes pitch by ± that ratio.
func play(cue: StringName, ladder_step: int = 0, gain_db: float = 0.0, jitter: float = 0.0) -> void:
	if muted or not CUES.has(cue):
		return
	var voice: AudioStreamPlayer = _free_voice()
	voice.stream = CUES[cue]
	voice.volume_db = volume_db + MIX.get(cue, 0.0) + gain_db
	voice.pitch_scale = pitch_for(ladder_step) * (1.0 + _rng.randf_range(-jitter, jitter))
	voice.play()

## One die impact; three recorded variants and a little pitch drift avoid machine-gun repeats.
func play_clack(gain_db: float = 0.0) -> void:
	play(StringName("die_clack_%d" % _rng.randi_range(1, 3)), 0, gain_db, 0.08)

## Pitch ratio for a ladder step; steps past the top stay on the highest rung.
func pitch_for(ladder_step: int) -> float:
	var semitones: int = LADDER[clampi(ladder_step, 0, LADDER.size() - 1)]
	return pow(2.0, float(semitones) / 12.0)

## Prefer an idle player; otherwise reuse the next one in rotation.
func _free_voice() -> AudioStreamPlayer:
	for offset: int in VOICES:
		var voice: AudioStreamPlayer = _voices[(_cursor + offset) % VOICES]
		if not voice.playing:
			_cursor = (_cursor + offset + 1) % VOICES
			return voice
	_cursor = (_cursor + 1) % VOICES
	return _voices[_cursor]
