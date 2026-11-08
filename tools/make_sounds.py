#!/usr/bin/env python3
"""Syntetiserar Wakers medföljande larmljud (egna verk, CC0).

    python3 tools/make_sounds.py      # skriver sounds/*.ogg (kräver numpy + ffmpeg med libvorbis)

Indikatorn spelar larmljud i loop, så varje fil är ett kort mönster som
loopar sömlöst (tystnad i slutet).
"""
import pathlib
import subprocess
import tempfile
import wave

import numpy as np

SR = 44100
OUT = pathlib.Path(__file__).resolve().parent.parent / "sounds"


def t(sec):
    return np.arange(int(sec * SR)) / SR


def env(n, attack=0.01, release=0.3, sec=None):
    """Enkel attack/exponentiell avklingning."""
    x = np.arange(n) / SR
    a = np.clip(x / attack, 0, 1)
    d = np.exp(-x / release)
    return a * d


def bell(freq, sec, release=0.9, harmonics=((1, 1.0), (2.0, 0.35), (3.01, 0.18), (4.2, 0.08))):
    x = t(sec)
    sig = sum(amp * np.sin(2 * np.pi * freq * mul * x) for mul, amp in harmonics)
    return sig * env(len(x), 0.005, release)


def place(track, clip, at):
    i = int(at * SR)
    end = min(len(track), i + len(clip))
    track[i:end] += clip[: end - i]


def normalize(sig, peak=0.85):
    return sig / np.max(np.abs(sig)) * peak


def dawn():
    """Gryning: mjukt stigande arpeggio som blir tydligare mot slutet."""
    length = 8.0
    track = np.zeros(int(length * SR))
    notes = [523.25, 659.25, 783.99, 1046.5, 783.99, 659.25, 880.0, 1046.5]  # C-dur-ish
    for i, f in enumerate(notes):
        place(track, bell(f, 2.5, 1.1) * (0.55 + 0.06 * i), i * 0.75)
    place(track, bell(1318.5, 2.0, 1.0) * 0.5, 6.0)
    return normalize(track)


def classic():
    """Klassisk: fyra snabba pip, paus, upprepa (mjukade fyrkantsvågor)."""
    length = 2.0
    track = np.zeros(int(length * SR))
    x = t(0.09)
    tone = np.sign(np.sin(2 * np.pi * 1760 * x)) * 0.5 + np.sin(2 * np.pi * 880 * x) * 0.5
    tone *= np.minimum(1, np.minimum(x / 0.004, (x[-1] - x) / 0.004 + 1e-9))
    for k in range(4):
        place(track, tone, 0.1 + k * 0.16)
    return normalize(track, 0.8)


def pulse():
    """Puls: mjukt pulserande ackord som växer i styrka."""
    length = 6.0
    x = t(length)
    chord = sum(np.sin(2 * np.pi * f * x) for f in (220.0, 277.18, 329.63, 440.0))
    trem = 0.5 + 0.5 * np.sin(2 * np.pi * 2.0 * x - np.pi / 2)  # 2 Hz puls
    swell = 0.45 + 0.55 * (x / length)
    fade = np.minimum(1, (length - x) / 0.25)  # sömlös loop
    return normalize(chord * trem ** 2 * swell * fade)


def write_ogg(name, sig):
    OUT.mkdir(exist_ok=True)
    pcm = (np.clip(sig, -1, 1) * 32767).astype("<i2")
    with tempfile.NamedTemporaryFile(suffix=".wav") as tmp:
        with wave.open(tmp.name, "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes(pcm.tobytes())
        dst = OUT / f"{name}.ogg"
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", tmp.name,
                        "-c:a", "libvorbis", "-q:a", "4", str(dst)], check=True)
    print(dst)


if __name__ == "__main__":
    write_ogg("Dawn", dawn())
    write_ogg("Classic", classic())
    write_ogg("Pulse", pulse())
