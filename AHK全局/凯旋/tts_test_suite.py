import asyncio
import os
import tempfile
import pyttsx3
from gtts import gTTS
import edge_tts
from playsound import playsound

# --- 1. Google TTS Engine ---
def speak_gtts(text, lang='zh-cn'):
    """Uses gTTS to speak the text."""
    tmp_filename = None
    try:
        print("\n[Google TTS] 正在生成语音...")
        with tempfile.NamedTemporaryFile(delete=False, suffix='.mp3') as fp:
            tts = gTTS(text=text, lang=lang)
            tts.save(fp.name)
            tmp_filename = fp.name
        print(f"[Google TTS] 正在播放...")
        playsound(tmp_filename)
    except Exception as e:
        print(f"[错误] Google TTS 失败: {e}")
    finally:
        if tmp_filename and os.path.exists(tmp_filename):
            os.remove(tmp_filename)

# --- 2. System (SAPI5) TTS Engine ---
def speak_sapi(text, voice_id=None):
    """Uses pyttsx3 to speak the text with a specific system voice."""
    try:
        print("\n[System TTS] 正在生成语音并播放...")
        engine = pyttsx3.init()
        if voice_id:
            engine.setProperty('voice', voice_id)
        engine.say(text)
        engine.runAndWait()
    except Exception as e:
        print(f"[错误] System TTS 失败: {e}")

def list_sapi_voices():
    """Lists all available SAPI5 voices on the system."""
    engine = pyttsx3.init()
    voices = engine.getProperty('voices')
    print("\n--- 可用的系统 (SAPI5) 语音 ---")
    for i, voice in enumerate(voices):
        print(f"{i+1}: ID: {voice.id}")
        print(f"   名称: {voice.name}")
        print(f"   语言: {voice.languages}")
    return voices

# --- 3. Edge TTS Engine ---
# List of high-quality Chinese voices from Edge TTS
EDGE_VOICES = [
    "zh-CN-XiaoxiaoNeural",
    "zh-CN-XiaoyiNeural",
    "zh-CN-YunjianNeural",
    "zh-CN-YunxiNeural",
    "zh-CN-YunxiaNeural",
    "zh-CN-YunyangNeural",
    "zh-HK-HiuGaaiNeural",
    "zh-HK-HiuMaanNeural",
    "zh-TW-HsiaoChenNeural",
    "zh-TW-HsiaoYuNeural",
]

async def _edge_tts_async(text, voice):
    """Async helper for Edge TTS."""
    tmp_filename = None
    try:
        print(f"\n[Edge TTS - {voice}] 正在生成语音...")
        communicate = edge_tts.Communicate(text, voice)
        with tempfile.NamedTemporaryFile(delete=False, suffix='.mp3') as fp:
            tmp_filename = fp.name
            await communicate.save(tmp_filename)
        print(f"[Edge TTS - {voice}] 正在播放...")
        playsound(tmp_filename)
    except Exception as e:
        print(f"[错误] Edge TTS 失败: {e}")
    finally:
        if tmp_filename and os.path.exists(tmp_filename):
            os.remove(tmp_filename)

def speak_edge(text, voice):
    """Main function to run async Edge TTS."""
    asyncio.run(_edge_tts_async(text, voice))

# --- Main Test Suite UI ---
def main():
    """The main interactive loop for testing TTS engines."""
    text_to_speak = "你好，这是一个语音测试。Hello, this is a voice test."

    while True:
        print("\n======================================")
        print("          语音测试工具箱")
        print("======================================")
        print(f"当前测试文本: \"{text_to_speak}\"")
        print("\n--- 请选择要使用的语音引擎 ---")
        print("1. Google TTS (在线, gTTS)")
        print("2. System TTS (离线, SAPI5)")
        print("3. Edge TTS (在线, 高质量)")
        print("t. 修改测试文本")
        print("q. 退出")

        choice = input("请输入选项: ").lower()

        if choice == '1':
            speak_gtts(text_to_speak)

        elif choice == '2':
            sapi_voices = list_sapi_voices()
            try:
                voice_choice = int(input("请选择要使用的系统语音编号: ")) - 1
                if 0 <= voice_choice < len(sapi_voices):
                    speak_sapi(text_to_speak, sapi_voices[voice_choice].id)
                else:
                    print("无效的编号。")
            except ValueError:
                print("请输入数字。")

        elif choice == '3':
            print("\n--- 可用的 Edge TTS 中文语音 ---")
            for i, v_name in enumerate(EDGE_VOICES):
                print(f"{i+1}: {v_name}")
            try:
                voice_choice = int(input("请选择要使用的 Edge 语音编号: ")) - 1
                if 0 <= voice_choice < len(EDGE_VOICES):
                    speak_edge(text_to_speak, EDGE_VOICES[voice_choice])
                else:
                    print("无效的编号。")
            except ValueError:
                print("请输入数字。")

        elif choice == 't':
            new_text = input("请输入新的测试文本: ")
            if new_text:
                text_to_speak = new_text
        
        elif choice == 'q':
            print("再见！")
            break
        
        else:
            print("无效的输入，请重试。")

if __name__ == "__main__":
    main()
