# Round interface sound studies

`synth_sfx.py` synthesizes the 23 placeholder cues used by the round interface
prototype. Every cue is original additive or filtered-noise synthesis; no samples
or third-party audio are involved. Output goes to
`godot/round_interface/audio/sfx/`, which is the runtime source of truth.

```sh
python3 docs/audio_explorations/round_sfx/synth_sfx.py
godot --headless --path godot --import
```

Direction: warm, soft, toy-like. Wooden bars and small bells for score ticks,
felt knocks for dice, short pops for keep and release. Pitched ticks share a C5
root; `RoundAudio` raises `pitch_scale` along a major pentatonic ladder so a
scoring chain climbs without sour intervals.

These were tuned by waveform inspection (level, duration, spectrum), not by ear.
Treat them as stand-ins to be auditioned and replaced.
