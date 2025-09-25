import winsound
import sys

def play_sound(frequency, duration=30000):
    """
    Plays a long beep sound that can be terminated externally.
    """
    try:
        # The duration is set to a very long value (30 seconds)
        # to simulate a continuous sound. The AHK script will
        # terminate this process to stop the sound.
        winsound.Beep(int(frequency), int(duration))
    except Exception:
        # Fails silently if something goes wrong.
        pass

if __name__ == "__main__":
    if len(sys.argv) > 1:
        frequency_arg = sys.argv[1]
        play_sound(frequency_arg) 