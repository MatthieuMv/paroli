#!/usr/bin/env python3
"""Synthesize the round interface's placeholder sound effects.

Every cue is original additive/noise synthesis (no samples), written as 16-bit
mono WAV into godot/round_interface/audio/sfx/. The WAV files are the runtime
source of truth; rerun this script only to revise the studies, then let Godot
reimport. Pitched ticks share a C5 root so the game can raise `pitch_scale`
along a pentatonic ladder during a scoring chain.

    python3 docs/audio_explorations/round_sfx/synth_sfx.py
"""
from __future__ import annotations

import wave
from pathlib import Path

import numpy as np

SR = 44100
OUT = Path(__file__).resolve().parents[3] / "godot" / "round_interface" / "audio" / "sfx"
C5 = 523.25


def note(semitones: float, root: float = C5) -> float:
    """Equal-tempered frequency relative to the shared root."""
    return root * 2.0 ** (semitones / 12.0)


def clock(duration: float) -> np.ndarray:
    """Sample times in seconds."""
    return np.arange(int(SR * duration)) / SR


def partials(freq: float, duration: float, spec: list[tuple[float, float, float]]) -> np.ndarray:
    """Sum exponentially decaying sine partials: (ratio, amplitude, decay seconds)."""
    t = clock(duration)
    out = np.zeros_like(t)
    for ratio, amp, decay in spec:
        out += amp * np.sin(2 * np.pi * freq * ratio * t) * np.exp(-t / decay)
    return out


def sweep(start: float, end: float, duration: float, decay: float, harmonics: tuple[float, ...] = (1.0,)) -> np.ndarray:
    """Exponential pitch glide with a decaying envelope and optional harmonic weights."""
    t = clock(duration)
    freq = start * (end / start) ** (t / duration)
    phase = 2 * np.pi * np.cumsum(freq) / SR
    out = np.zeros_like(t)
    for index, amp in enumerate(harmonics):
        out += amp * np.sin(phase * (index + 1))
    return out * np.exp(-t / decay)


def noise(duration: float, seed: int) -> np.ndarray:
    """Deterministic white noise so regenerated files stay identical."""
    return np.random.default_rng(seed).uniform(-1.0, 1.0, int(SR * duration))


def bandpass(signal: np.ndarray, start: float, end: float, q: float = 1.2) -> np.ndarray:
    """State-variable band-pass whose center glides from start to end hertz."""
    out = np.zeros_like(signal)
    low = 0.0
    band = 0.0
    count = len(signal)
    for index in range(count):
        cutoff = start * (end / start) ** (index / max(count - 1, 1))
        f = 2.0 * np.sin(np.pi * min(cutoff, SR / 6.5) / SR)
        high = signal[index] - low - band / q
        band += f * high
        low += f * band
        out[index] = band
    return out


def airy(signal: np.ndarray, start: float, end: float, q: float = 1.2) -> np.ndarray:
    """Two cascaded band-passes: a soft breath of air without broadband hiss."""
    return bandpass(bandpass(signal, start, end, q), start, end, q)


def decay(signal: np.ndarray, seconds: float) -> np.ndarray:
    """Apply an exponential tail."""
    return signal * np.exp(-clock(len(signal) / SR)[: len(signal)] / seconds)


def mix(length: float, layers: list[tuple[float, np.ndarray]]) -> np.ndarray:
    """Place layers at their start offsets in seconds."""
    out = np.zeros(int(SR * length))
    for start, layer in layers:
        begin = int(SR * start)
        end = min(len(out), begin + len(layer))
        out[begin:end] += layer[: end - begin]
    return out


def marimba(freq: float, duration: float = 0.3, body: float = 0.15) -> np.ndarray:
    """Warm wooden bar: strong fundamental, tuned fourth partial, soft mallet tick."""
    tone = partials(freq, duration, [(1.0, 1.0, body), (3.98, 0.26, body * 0.3), (9.6, 0.07, body * 0.12)])
    tick = decay(bandpass(noise(0.012, 7), 1800, 2600), 0.003) * 0.5
    return mix(duration, [(0.0, tone), (0.0, tick)])


def bell(freq: float, duration: float = 0.5, ring: float = 0.26) -> np.ndarray:
    """Small glockenspiel bar with slightly inharmonic overtones."""
    return partials(freq, duration, [(1.0, 1.0, ring), (2.0, 0.34, ring * 0.7), (3.01, 0.2, ring * 0.5), (4.2, 0.11, ring * 0.32), (5.43, 0.07, ring * 0.22)])


def thump(start: float, end: float, seconds: float) -> np.ndarray:
    """Soft felt impact body."""
    return sweep(start, end, seconds * 4.0, seconds)


def clack(seed: int, pitch: float) -> np.ndarray:
    """Chunky die landing on felt: low body, mid knock, and a short bright edge."""
    body = thump(190 * pitch, 118 * pitch, 0.034) * 0.9
    knock = decay(bandpass(noise(0.07, seed), 1250 * pitch, 760 * pitch, 2.4), 0.014) * 0.9
    edge = decay(bandpass(noise(0.02, seed + 1), 3400, 2800, 0.9), 0.004) * 0.35
    return mix(0.16, [(0.0, body), (0.0, knock), (0.0, edge)])


def chord(notes: list[float], maker, **kwargs) -> np.ndarray:
    """Sum simultaneous voices."""
    voices = [maker(freq, **kwargs) for freq in notes]
    return np.sum(voices, axis=0) / np.sqrt(len(voices))


def build() -> dict[str, np.ndarray]:
    """Author every cue; names are the stable identifiers used by RoundAudio."""
    cues: dict[str, np.ndarray] = {}
    cues["die_clack_1"] = clack(11, 1.0)
    cues["die_clack_2"] = clack(23, 0.9)
    cues["die_clack_3"] = clack(37, 1.12)
    cues["die_hold"] = mix(0.22, [(0.0, sweep(392, 600, 0.2, 0.06, (1.0, 0.25))), (0.0, decay(bandpass(noise(0.01, 3), 2400, 2000), 0.003) * 0.3)])
    cues["die_release"] = mix(0.22, [(0.0, sweep(600, 380, 0.2, 0.06, (1.0, 0.25)))])
    cues["hover"] = partials(note(19), 0.05, [(1.0, 1.0, 0.012), (2.0, 0.2, 0.006)])
    cues["button"] = mix(0.2, [(0.0, thump(170, 105, 0.04)), (0.0, decay(bandpass(noise(0.03, 5), 2200, 1500, 1.5), 0.006) * 0.55), (0.035, marimba(note(-5), 0.15, 0.05) * 0.35)])
    cues["roll"] = decay(airy(noise(0.34, 9), 500, 1500, 1.1), 0.16) * np.minimum(clock(0.34) / 0.06, 1.0)
    cues["tick_points"] = marimba(C5)
    cues["tick_mult"] = bell(C5, 0.5, 0.2)
    cues["tick_percent"] = mix(0.6, [(0.0, bell(C5, 0.5, 0.22)), (0.035, bell(note(7), 0.45, 0.2) * 0.7), (0.07, bell(note(12), 0.45, 0.24) * 0.6)])
    cues["coin"] = mix(0.5, [(0.0, partials(note(11), 0.09, [(1.0, 1.0, 0.05), (3.0, 0.22, 0.03), (5.0, 0.1, 0.02)])), (0.07, partials(note(16), 0.42, [(1.0, 1.0, 0.16), (3.0, 0.2, 0.08), (5.0, 0.08, 0.05)]))])
    cues["combo"] = mix(0.42, [(0.0, marimba(note(7), 0.3, 0.12) * 0.8), (0.045, marimba(note(12), 0.36, 0.16))])
    cues["count"] = partials(note(12), 0.04, [(1.0, 1.0, 0.008), (2.0, 0.3, 0.004)])
    cues["pip"] = sweep(880, 620, 0.1, 0.03, (1.0, 0.2))
    cues["fly"] = decay(airy(noise(0.36, 13), 420, 2200, 1.4), 0.2) * np.minimum(clock(0.36) / 0.1, 1.0)
    cues["total"] = mix(0.9, [(0.0, thump(110, 62, 0.11) * 1.2), (0.0, decay(bandpass(noise(0.08, 15), 900, 500, 1.0), 0.02) * 0.5), (0.0, chord([C5, note(4), note(7), note(12)], bell, duration=0.85, ring=0.34) * 0.9)])
    cues["bank"] = mix(0.75, [(0.0, bell(note(7), 0.7, 0.3)), (0.06, bell(note(12), 0.68, 0.34) * 0.9)])
    cues["stamp"] = mix(0.3, [(0.0, thump(150, 70, 0.07) * 1.2), (0.0, decay(bandpass(noise(0.1, 17), 1600, 600, 0.8), 0.025) * 0.8)])
    cues["consume"] = mix(0.34, [(0.0, decay(airy(noise(0.32, 19), 2400, 380, 1.0), 0.09)), (0.0, sweep(520, 210, 0.2, 0.05) * 0.5)])
    cues["womp"] = sweep(330, 160, 0.42, 0.2, (1.0, 0.0, 0.3)) * (1.0 + 0.12 * np.sin(2 * np.pi * 11 * clock(0.42)))
    arpeggio = [0, 4, 7, 12, 16, 19]
    win_layers = [(index * 0.085, (marimba(note(step), 0.4, 0.18) + bell(note(step), 0.4, 0.2) * 0.5) * 0.8) for index, step in enumerate(arpeggio)]
    win_layers.append((len(arpeggio) * 0.085 + 0.03, chord([note(12), note(16), note(19), note(24)], bell, duration=1.1, ring=0.5)))
    cues["win"] = mix(1.75, win_layers)
    lose_steps = [4, 2, 0, -3]
    cues["lose"] = mix(1.3, [(index * 0.19, partials(note(step - 12), 0.6, [(1.0, 1.0, 0.24), (3.0, 0.12, 0.1)])) for index, step in enumerate(lose_steps)])
    return cues


def write(name: str, signal: np.ndarray) -> None:
    """Normalize, add click-free edges, and save 16-bit mono PCM."""
    signal = signal / max(np.max(np.abs(signal)), 1e-9) * 0.85
    attack = int(SR * 0.001)
    release = min(len(signal) // 2, int(SR * 0.004))
    signal[:attack] *= np.linspace(0.0, 1.0, attack)
    signal[-release:] *= np.linspace(1.0, 0.0, release)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as file:
        file.setnchannels(1)
        file.setsampwidth(2)
        file.setframerate(SR)
        file.writeframes((signal * 32767).astype("<i2").tobytes())


def main() -> None:
    """Regenerate all cues and report their durations for review."""
    OUT.mkdir(parents=True, exist_ok=True)
    for name, signal in build().items():
        write(name, signal)
        print(f"{name:14s} {len(signal) / SR * 1000:6.0f} ms")


if __name__ == "__main__":
    main()
