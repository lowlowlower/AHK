import sys
import os
import tempfile
import asyncio
import edge_tts
from playsound import playsound

# --- 用户配置 ---
# 您选择的 Edge TTS 语音
VOICE = "zh-CN-XiaoyiNeural"

async def main() -> None:
    """
    The main asynchronous function that handles TTS generation and playback.
    """
    if len(sys.argv) < 2:
        # No text provided, exit silently.
        return

    text = " ".join(sys.argv[1:])
    tmp_filename = None
    
    try:
        # Generate the speech and save it to a temporary MP3 file
        communicate = edge_tts.Communicate(text, VOICE)
        with tempfile.NamedTemporaryFile(delete=False, suffix='.mp3') as fp:
            tmp_filename = fp.name
            await communicate.save(tmp_filename)

        # Play the generated audio file
        playsound(tmp_filename)

    except Exception:
        # In a production script called by AHK, it's better to fail silently.
        # For debugging, you could log the error to a file.
        # with open("tts_error_log.txt", "a") as f:
        #     f.write(f"Error: {e}\n")
        pass

    finally:
        # Clean up the temporary file
        if tmp_filename and os.path.exists(tmp_filename):
            os.remove(tmp_filename)

if __name__ == "__main__":
    # The script is designed to be called from the command line.
    # It takes text as arguments and speaks it out.
    asyncio.run(main())
