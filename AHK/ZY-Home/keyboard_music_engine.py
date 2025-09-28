# keyboard_music_engine.py
import pygame
import numpy as np
import sys
import threading
import time

# --- Configuration ---
SAMPLE_RATE = 44100
AMPLITUDE = 6000  # Lowered amplitude to allow more headroom for multiple notes
BUFFER_SIZE = 512

# --- Note Frequency Mapping ---
# This is a duplicate of the AHK map for internal use.
KEY_FREQUENCIES = {
    "q": 262, "w": 277, "e": 294, "r": 311, "t": 330, "y": 349, "u": 370, "i": 392, "o": 415, "p": 440,
    "a": 466, "s": 494, "d": 523, "f": 554, "g": 587, "h": 622, "j": 659, "k": 698, "l": 740,
    "z": 784, "x": 831, "c": 880, "v": 932, "b": 988, "n": 1047, "m": 1109
}

class AudioEngine:
    def __init__(self):
        pygame.mixer.pre_init(SAMPLE_RATE, -16, 2, BUFFER_SIZE)
        pygame.init()
        self.active_frequencies = set()
        self.lock = threading.Lock()
        self.sound = None
        self.is_playing = False
        self.timbre = 'sine' # 新增：默认音色为正弦波

    def generate_wave(self):
        with self.lock:
            if not self.active_frequencies:
                return None
            
            duration = 2.0 
            num_samples = int(duration * SAMPLE_RATE)
            time_arr = np.linspace(0, duration, num_samples, endpoint=False)
            
            # 核心改动：根据当前音色选择不同的波形生成函数
            mixed_wave = np.zeros(num_samples)
            wave_function = {
                'sine': np.sin,
                'square': lambda x: np.sign(np.sin(x)),
                'sawtooth': lambda x: 2 * ((x / (2 * np.pi)) - np.floor(0.5 + (x / (2 * np.pi)))),
                'triangle': lambda x: 2 * np.abs(2 * ((x / (2 * np.pi)) - np.floor((x / (2 * np.pi)) + 0.5))) - 1
            }.get(self.timbre, np.sin)

            for freq in self.active_frequencies:
                angular_freq_arr = 2 * np.pi * freq * time_arr
                mixed_wave += wave_function(angular_freq_arr)
            
            # Normalize to prevent clipping, considering the number of active notes
            num_notes = len(self.active_frequencies)
            if num_notes > 0:
                mixed_wave /= num_notes
            
            pcm_wave = (mixed_wave * AMPLITUDE).astype(np.int16)
            stereo_wave = np.repeat(pcm_wave.reshape(num_samples, 1), 2, axis=1)
            return stereo_wave

    def update_sound(self):
        wave_data = self.generate_wave()
        
        if self.sound and self.is_playing:
            self.sound.stop()
            self.is_playing = False

        if wave_data is not None:
            self.sound = pygame.sndarray.make_sound(wave_data)
            self.sound.play(loops=-1)
            self.is_playing = True

    def add_note(self, key):
        freq = KEY_FREQUENCIES.get(key)
        if freq:
            with self.lock:
                if freq not in self.active_frequencies:
                    self.active_frequencies.add(freq)
                    needs_update = True
                else:
                    needs_update = False
            if needs_update:
                self.update_sound()

    def remove_note(self, key):
        freq = KEY_FREQUENCIES.get(key)
        if freq:
            with self.lock:
                if freq in self.active_frequencies:
                    self.active_frequencies.remove(freq)
                    needs_update = True
                else:
                    needs_update = False
            if needs_update:
                self.update_sound()

    def set_timbre(self, new_timbre):
        valid_timbres = ['sine', 'square', 'sawtooth', 'triangle']
        if new_timbre in valid_timbres:
            with self.lock:
                self.timbre = new_timbre
            # 如果当前正在播放，则立即更新声音
            if self.is_playing:
                self.update_sound()

def listen_for_commands(engine):
    for line in sys.stdin:
        try:
            parts = line.strip().split()
            if not parts:
                continue
            
            command = parts[0].upper()

            if command == "ADD" and len(parts) > 1:
                engine.add_note(parts[1])
            elif command == "REMOVE" and len(parts) > 1:
                engine.remove_note(parts[1])
            elif command == "TIMBRE" and len(parts) > 1:
                engine.set_timbre(parts[1].lower())

        except Exception:
            # Ignore malformed commands
            pass

if __name__ == "__main__":
    engine = AudioEngine()
    
    # Run the command listener in a separate thread
    command_thread = threading.Thread(target=listen_for_commands, args=(engine,), daemon=True)
    command_thread.start()
    
    # Keep the main thread alive
    while True:
        time.sleep(1) 