"""Generate VASC's original sliding-door cue (no sampled game audio)."""
from pathlib import Path
import math
import random
import struct
import wave

RATE = 22050
DURATION = .38
rng = random.Random(5718)
low = previous = 0.0
samples = []
for i in range(round(RATE * DURATION)):
    t = i / RATE
    u = t / DURATION
    noise = rng.uniform(-1, 1)
    low += .16 * (noise - low)
    band = low - previous
    previous += .045 * (low - previous)
    envelope = min(1, t / .025) * max(0, min(1, (DURATION - t) / .09))
    servo = math.sin(2 * math.pi * (340 * t - 150 * t * t))
    glide = envelope * (.70 * band + .035 * servo)
    latch = 0.0
    if .305 <= t < .35:
        dt = t - .305
        latch = .065 * math.exp(-dt * 130) * math.sin(2 * math.pi * 1250 * dt)
    samples.append(glide + latch)
peak = max(abs(x) for x in samples)
path = Path(__file__).resolve().parents[1] / 'assets/audio/glass-door.wav'
with wave.open(str(path), 'wb') as out:
    out.setparams((1, 2, RATE, len(samples), 'NONE', 'not compressed'))
    out.writeframes(b''.join(struct.pack('<h', round(x / peak * .65 * 32767)) for x in samples))
print(path)
