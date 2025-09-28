import sys
import webbrowser
import json
from urllib.parse import quote

def search(query, engine_code):
    try:
        with open('search_engines.json', 'r', encoding='utf-8') as f:
            engines = json.load(f)
    except FileNotFoundError:
        print("错误: search_engines.json 文件未找到。")
        return
    except json.JSONDecodeError:
        print("错误: search_engines.json 文件格式不正确。")
        return

    engine_url = engines.get(engine_code)

    if not engine_url:
        print(f"错误: 未找到代码为 '{engine_code}' 的搜索引擎。")
        return

    encoded_query = quote(query)
    search_url = engine_url.format(query=encoded_query)
    webbrowser.open(search_url)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("使用方法: python search_handler.py \"<搜索内容>\" <搜索引擎代码>")
    else:
        search_query = sys.argv[1]
        search_engine = sys.argv[2]
        search(search_query, search_engine)
