import wave
import random
import math
import struct
import os

os.makedirs('assets/sounds', exist_ok=True)

def generate_trash_sound():
    with wave.open('assets/sounds/trash.wav', 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(44100)
        frames = []
        # Paper crumple: random noise with decreasing amplitude and bursts
        for i in range(44100 // 2):  # 0.5 seconds
            env = math.exp(-i / 10000.0) * (0.5 + 0.5 * math.sin(i / 1000.0))
            val = int(random.uniform(-32767, 32767) * env * 0.3)
            frames.append(struct.pack('<h', val))
        w.writeframes(b''.join(frames))

def generate_copy_sound():
    with wave.open('assets/sounds/copy.wav', 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(44100)
        frames = []
        # Swoosh up
        for i in range(44100 // 3):  # 0.33 seconds
            freq = 400 + (i / 14700) * 800
            val = int(math.sin(2 * math.pi * freq * (i / 44100.0)) * 10000 * math.exp(-i / 10000.0))
            frames.append(struct.pack('<h', val))
        w.writeframes(b''.join(frames))

generate_trash_sound()
generate_copy_sound()
