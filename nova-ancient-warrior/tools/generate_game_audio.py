#!/usr/bin/env python3
"""Generate original procedural sound effects for Nova Ancient Warrior using only the Python stdlib."""
import argparse
import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
DURATIONS = {
    "sword_swing": 0.28, "heavy_swing": 0.46, "impact": 0.24,
    "parry": 0.38, "footstep": 0.12, "dodge": 0.22,
    "jump": 0.14, "hurt": 0.22, "boss_roar": 0.72,
    "hazard_warning": 0.42, "hazard_burst": 0.48,
    "victory": 0.96, "upgrade": 0.38
}


def envelope(t, duration, attack=0.008, release=0.12):
    if t < 0.0 or t >= duration:
        return 0.0
    return min(1.0, t / max(attack, 0.0001)) * min(1.0, max(0.0, (duration - t) / max(release, 0.0001)))


def render(name, duration, seed):
    rng = random.Random(seed)
    count = int(RATE * duration)
    out = []
    previous_noise = 0.0
    phase_a = 0.0
    phase_b = 0.0
    for i in range(count):
        t = i / RATE
        noise = rng.uniform(-1.0, 1.0)
        high = noise - previous_noise * 0.72
        previous_noise = noise
        value = 0.0
        env = 1.0

        if name in ("sword_swing", "heavy_swing", "dodge", "jump"):
            env = envelope(t, duration, 0.012, duration * 0.68)
            if name == "sword_swing":
                freq, noise_gain, tone_gain = 980.0 - 620.0 * t / duration, 0.23, 0.12
            elif name == "heavy_swing":
                freq, noise_gain, tone_gain = 430.0 - 210.0 * t / duration, 0.28, 0.18
            elif name == "dodge":
                freq, noise_gain, tone_gain = 720.0 - 430.0 * t / duration, 0.24, 0.07
            else:
                freq, noise_gain, tone_gain = 240.0 + 510.0 * t / duration, 0.08, 0.20
            phase_a += 2.0 * math.pi * freq / RATE
            value = math.sin(phase_a) * tone_gain + high * noise_gain
            if name == "heavy_swing" and t > duration * 0.66:
                value += math.sin(phase_a * 2.0) * 0.12 * math.exp(-(t - duration * 0.66) * 19.0)
        elif name == "impact":
            env = math.exp(-t * 23.0)
            phase_a += 2.0 * math.pi * 82.0 / RATE
            phase_b += 2.0 * math.pi * 173.0 / RATE
            value = high * 0.34 * math.exp(-t * 38.0) + math.sin(phase_a) * 0.28 * env + math.sin(phase_b) * 0.13 * env
        elif name == "parry":
            env = math.exp(-t * 8.5)
            phase_a += 2.0 * math.pi * 1040.0 / RATE
            phase_b += 2.0 * math.pi * 1540.0 / RATE
            value = (math.sin(phase_a) * 0.23 + math.sin(phase_b) * 0.12 + high * 0.10) * env
        elif name == "footstep":
            env = envelope(t, duration, 0.002, 0.075)
            phase_a += 2.0 * math.pi * (78.0 - 18.0 * t / duration) / RATE
            value = math.sin(phase_a) * 0.30 + high * 0.12 * math.exp(-t * 48.0)
        elif name == "hurt":
            env = math.exp(-t * 17.0)
            phase_a += 2.0 * math.pi * (118.0 - 34.0 * t / duration) / RATE
            value = math.sin(phase_a) * 0.30 + high * 0.13 * env
        elif name == "boss_roar":
            env = envelope(t, duration, 0.035, 0.30)
            wobble = 1.0 + 0.10 * math.sin(2.0 * math.pi * 5.5 * t)
            freq = (74.0 + 23.0 * math.sin(2.0 * math.pi * 2.1 * t)) * wobble
            phase_a += 2.0 * math.pi * freq / RATE
            phase_b += 2.0 * math.pi * freq * 1.49 / RATE
            value = math.sin(phase_a) * 0.26 + math.sin(phase_b) * 0.10 + high * 0.10
        elif name == "hazard_warning":
            pulse = sum(envelope(t - start, 0.10, 0.002, 0.08) for start in (0.0, 0.14, 0.28))
            phase_a += 2.0 * math.pi * 720.0 / RATE
            value = math.sin(phase_a) * 0.28 * pulse
        elif name == "hazard_burst":
            env = math.exp(-t * 8.0)
            phase_a += 2.0 * math.pi * 56.0 / RATE
            phase_b += 2.0 * math.pi * 119.0 / RATE
            value = (math.sin(phase_a) * 0.34 + math.sin(phase_b) * 0.13 + high * 0.28) * env
        elif name == "victory":
            notes = (523.25, 659.25, 783.99)
            index = min(2, int(t / (duration / 3.0)))
            local_t = t - index * duration / 3.0
            env = envelope(local_t, duration / 3.0, 0.008, 0.22)
            phase_a += 2.0 * math.pi * notes[index] / RATE
            phase_b += 2.0 * math.pi * notes[index] * 2.0 / RATE
            value = math.sin(phase_a) * 0.22 + math.sin(phase_b) * 0.06
        elif name == "upgrade":
            freq = 880.0 if t < duration * 0.48 else 1174.66
            local_t = t if t < duration * 0.48 else t - duration * 0.48
            env = envelope(local_t, duration * 0.52, 0.006, 0.16)
            phase_a += 2.0 * math.pi * freq / RATE
            value = math.sin(phase_a) * 0.22 + math.sin(phase_a * 2.0) * 0.045
        else:
            raise ValueError("Unknown sound " + name)

        out.append(int(max(-0.92, min(0.92, value * env)) * 32767.0))
    return out


def render_ambient_music():
    """Bake a 4-chord ambient loop so runtime playback needs no generator buffer."""
    sample_rate = RATE
    beat_seconds = 0.82
    roots = (55.0, 65.41, 73.42, 49.0)
    intensity = 0.22
    duration = beat_seconds * 4.0 * len(roots)
    count = int(sample_rate * duration)
    edge_frames = int(sample_rate * 0.04)
    out = []
    for i in range(count):
        t = i / sample_rate
        bar = int(t / (beat_seconds * 4.0))
        chord = roots[bar % len(roots)]
        beat_phase = math.fmod(t, beat_seconds)
        pad = math.sin(2.0 * math.pi * chord * t) * 0.105
        pad += math.sin(2.0 * math.pi * chord * 1.5 * t) * 0.052
        pad += math.sin(2.0 * math.pi * chord * 2.0 * t) * 0.024
        upper = math.sin(2.0 * math.pi * chord * 3.0 * t + 0.3) * 0.018
        kick = math.sin(2.0 * math.pi * 48.0 * beat_phase) * math.exp(-beat_phase * 17.0) * 0.10 * intensity
        pulse = math.sin(2.0 * math.pi * (chord * 0.5) * t) * 0.012 * intensity
        value = (pad + upper + kick + pulse) * (0.55 + intensity * 0.45)
        if i < edge_frames:
            value *= i / max(1, edge_frames)
        elif i >= count - edge_frames:
            value *= (count - 1 - i) / max(1, edge_frames)
        out.append(int(max(-0.65, min(0.65, value)) * 32767.0))
    return out


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=Path("nova-ancient-warrior/audio/generated"))
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    total = 0
    for index, (name, duration) in enumerate(DURATIONS.items(), start=1):
        pcm = render(name, duration, 20261107 + index)
        path = args.output / (name + ".wav")
        with wave.open(str(path), "wb") as wav:
            wav.setnchannels(1)
            wav.setsampwidth(2)
            wav.setframerate(RATE)
            wav.writeframes(struct.pack("<%dh" % len(pcm), *pcm))
        total += path.stat().st_size
    music_pcm = render_ambient_music()
    music_path = args.output / "ambient_music.wav"
    with wave.open(str(music_path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(struct.pack("<%dh" % len(music_pcm), *music_pcm))
    total += music_path.stat().st_size
    print("Generated %d original SFX WAV files and 1 ambient music loop (%d bytes) at %s" % (len(DURATIONS), total, args.output))


if __name__ == "__main__":
    main()
