# -*- coding: utf-8 -*-
import sys
import requests
import json
import tkinter as tk
from tkinter import ttk, scrolledtext, filedialog, font
import threading
import queue
import logging
import re

# --- 0. 日志设置 ---

# 创建一个队列处理器，用于将日志记录从工作线程安全地传递到GUI线程
class QueueHandler(logging.Handler):
    def __init__(self, log_queue):
        super().__init__()
        self.log_queue = log_queue

    def emit(self, record):
        self.log_queue.put(self.format(record))

# --- 1. 配置 (与 AHK 脚本中的保持一致) ---
DEEPSEEK_API_KEY = "sk-78a9fd015e054281a3eb0a0712d5e6d0"
GEMINI_API_KEY = "AIzaSyDmfaMC3pHdY6BYCvL_1pWZF5NLLkh28QU"
AI_MODELS = ["DeepSeek V3", "Gemini 2.5 Pro", "gemini-2.5-flash-lite-preview-06-17"]

# --- 1.1 可编辑的快捷指令模板 ---
# 在这里添加或修改你常用的指令, ""前是显示在菜单里的名字, ""后是实际加在问题前面的文字.
PROMPT_TEMPLATES = {
    "润色文本": "请帮我润色以下文本，使其更流畅、专业，并修正语法错误和不当之处：\n\n",
    "翻译成英文": "请将以下文本翻译成地道的英文：\n\n",
    "代码解释": "请逐行解释以下代码的功能和逻辑，并指出可优化的地方：\n\n",
    "总结要点": "请将以下内容总结为几个关键要点，使用列表形式呈现：\n\n",
    "查找语法错误": "请检查以下文本中是否存在语法错误，并直接给出修正后的版本：\n\n"
}

# --- 2. API 调用函数 (全部改为非流式) ---

# 定义一个哨兵对象，用于在队列中标记任务完成
_sentinel = object()

def call_deepseek_non_stream(prompt, result_queue):
    """使用 requests 库常规调用 DeepSeek API, 并将结果放入队列"""
    logging.info("正在调用 DeepSeek API (非流式)...")
    url = "https://api.deepseek.com/chat/completions"
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {DEEPSEEK_API_KEY}"
    }
    data = {
        "model": "deepseek-chat",
        "messages": [{"role": "user", "content": prompt}]
    }
    try:
        response = requests.post(url, headers=headers, json=data, timeout=60)
        response.raise_for_status()
        logging.info("成功接收到 DeepSeek API 的完整响应。")
        logging.debug(f"原始响应文本: {response.text}")
        result = response.json()
        
        choices = result.get('choices', [])
        if not choices:
            error_msg = f"解析 DeepSeek 响应失败: 'choices' 字段不存在或为空。\n响应内容: {response.text}"
            logging.error(error_msg)
            result_queue.put(error_msg)
            return

        message = choices[0].get('message', {})
        if not message:
            error_msg = f"解析 DeepSeek 响应失败: 'message' 字段不存在于 'choices' 中。\n响应内容: {response.text}"
            logging.error(error_msg)
            result_queue.put(error_msg)
            return

        content = message.get('content')
        if content is not None:
            logging.debug(f"解析到的内容 (前100字符): {content[:100]}...")
            result_queue.put(content)
        else:
            result_queue.put("")
            logging.warning(f"解析 DeepSeek 响应: 'content' 字段不存在或为 null。")

    except requests.exceptions.RequestException as e:
        error_msg = f"\n\n--- DeepSeek API 请求失败 ---\n{e}"
        logging.error(error_msg)
        result_queue.put(error_msg)
    except json.JSONDecodeError as e:
        error_msg = f"解析 DeepSeek JSON 响应失败: {e}\n响应内容: {response.text}"
        logging.error(error_msg)
        result_queue.put(error_msg)
    finally:
        logging.info("DeepSeek API 调用结束。")
        result_queue.put(_sentinel)

def call_gemini_non_stream(prompt, model_name, result_queue):
    """使用 requests 库常规调用 Gemini API, 并将结果放入队列"""
    logging.info(f"正在调用 Gemini API (非流式)，模型: {model_name}...")
    model_map = {
        "Gemini 2.5 Pro": "gemini-1.5-pro-latest",
        "gemini-2.5-flash-lite-preview-06-17": "gemini-1.5-flash-latest"
    }
    api_model_name = model_map.get(model_name)
    if not api_model_name:
        error_msg = f"错误: 未知的 Gemini 模型 '{model_name}'"
        logging.error(error_msg)
        result_queue.put(error_msg)
        result_queue.put(_sentinel)
        return

    # Bug修复：修正URL中的拼写错误
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{api_model_name}:generateContent?key={GEMINI_API_KEY}"
    headers = {"Content-Type": "application/json"}
    data = {"contents": [{"parts": [{"text": prompt}]}]}

    try:
        response = requests.post(url, headers=headers, json=data, timeout=60)
        response.raise_for_status()
        logging.info("成功接收到 Gemini API 的完整响应。")
        logging.debug(f"原始响应文本: {response.text}")
        result = response.json()
        
        # 健壮的解析逻辑
        candidates = result.get('candidates', [])
        if not candidates:
            error_msg = f"解析 Gemini 响应失败: 'candidates' 字段不存在或为空。\n响应内容: {response.text}"
            logging.error(error_msg)
            result_queue.put(error_msg)
            return

        content = candidates[0].get('content', {})
        parts = content.get('parts', [])
        if not parts:
            error_msg = f"解析 Gemini 响应失败: 'parts' 字段不存在或为空。\n响应内容: {response.text}"
            logging.error(error_msg)
            result_queue.put(error_msg)
            return

        text = parts[0].get('text')
        if text is not None:
             result_queue.put(text)
        else:
            result_queue.put("")
            logging.warning(f"解析 Gemini 响应: 'text' 字段不存在或为 null。")

    except requests.exceptions.RequestException as e:
        error_msg = f"\n\n--- Gemini API 请求失败 ---\n{e}"
        logging.error(error_msg)
        result_queue.put(error_msg)
    except json.JSONDecodeError as e:
        error_msg = f"解析 Gemini JSON 响应失败: {e}\n响应内容: {response.text}"
        logging.error(error_msg)
        result_queue.put(error_msg)
    finally:
        logging.info("Gemini API 调用结束。")
        result_queue.put(_sentinel)


# --- 3. GUI 应用 ---

class AiAssistantApp:
    def __init__(self, root, initial_prompt):
        self.root = root
        self.last_template_text = ""
        self.current_font_size = 10
        self.fullscreen_window = None
        self.root.title("Python AI 助手 (终极版)")
        self.root.attributes('-topmost', True)
        self.root.geometry("800x800")

        # --- 设置日志 ---
        self.log_queue = queue.Queue()
        self.queue_handler = QueueHandler(self.log_queue)
        formatter = logging.Formatter('%(asctime)s: %(levelname)s: %(message)s')
        self.queue_handler.setFormatter(formatter)
        logging.getLogger().addHandler(self.queue_handler)
        logging.getLogger().setLevel(logging.INFO) # 默认级别

        # --- 创建主Notebook (标签页) ---
        self.notebook = ttk.Notebook(root)
        self.notebook.pack(expand=True, fill='both', padx=5, pady=5)
        assistant_tab = ttk.Frame(self.notebook, padding=10)
        log_tab = ttk.Frame(self.notebook, padding=10)
        self.notebook.add(assistant_tab, text='AI 助手 (Alt+1)')
        self.notebook.add(log_tab, text='日志 (Alt+2)')

        # --- 初始化字体和风格 ---
        self.initialize_fonts()
        self.apply_styles()

        # --- 布局 ---
        self.setup_assistant_tab(assistant_tab, initial_prompt)
        self.setup_log_tab(log_tab)
        self.setup_keyboard_shortcuts()
        
        # --- 启动 ---
        self.root.after(100, self.poll_log_queue)
        logging.info("应用初始化完成。")

    def initialize_fonts(self):
        # 定义动态字体对象
        self.default_font = font.Font(family='Microsoft YaHei UI', size=self.current_font_size)
        self.code_font = font.Font(family='Consolas', size=self.current_font_size)
        self.h1_font = font.Font(family='Microsoft YaHei UI', size=self.current_font_size + 6, weight='bold')
        self.h2_font = font.Font(family='Microsoft YaHei UI', size=self.current_font_size + 4, weight='bold')
        self.h3_font = font.Font(family='Microsoft YaHei UI', size=self.current_font_size + 2, weight='bold')
        self.bold_font = font.Font(family='Microsoft YaHei UI', size=self.current_font_size, weight='bold')
        self.italic_font = font.Font(family='Microsoft YaHei UI', size=self.current_font_size, slant='italic')

    def apply_styles(self):
        # 应用字体到ttk控件和Text组件的tag
        style = ttk.Style()
        style.theme_use('vista')
        style.configure("TButton", padding=5, font=self.default_font)
        style.configure("TLabel", font=self.default_font)
        style.configure("TCombobox", font=self.default_font)
        style.configure("TNotebook.Tab", padding=(10, 5), font=self.default_font)
        
        text_widgets = [getattr(self, w, None) for w in ('prompt_text', 'answer_text', 'log_text')]
        if all(text_widgets):
            self.prompt_text.config(font=self.default_font)
            self.answer_text.config(font=self.default_font)
            self.log_text.config(font=self.code_font)

            for text_widget in (self.answer_text, getattr(self, 'fullscreen_text', None)):
                 if not text_widget: continue
                 text_widget.tag_configure("h1", font=self.h1_font)
                 text_widget.tag_configure("h2", font=self.h2_font)
                 text_widget.tag_configure("h3", font=self.h3_font)
                 text_widget.tag_configure("bold", font=self.bold_font)
                 text_widget.tag_configure("italic", font=self.italic_font)
                 text_widget.tag_configure("code_block", font=self.code_font, background="#f0f0f0")
                 text_widget.tag_configure("hidden", elide=True)

    def change_font_size(self, delta):
        new_size = self.current_font_size + delta
        if 5 <= new_size <= 30: # 限制字体大小范围
            self.current_font_size = new_size
            logging.info(f"字体大小调整为: {self.current_font_size}")
            self.initialize_fonts()
            self.apply_styles()
            self.render_markdown(self.answer_text)
            if self.fullscreen_window and self.fullscreen_window.winfo_exists():
                self.fullscreen_text.config(font=self.default_font)
                self.render_markdown(self.fullscreen_text)

    def setup_assistant_tab(self, parent_tab, initial_prompt):
        # --- 提问区 ---
        question_frame = ttk.Frame(parent_tab)
        question_frame.pack(fill="x", pady=(0, 5))
        ttk.Label(question_frame, text="您的问题 (Ctrl+P):").pack(anchor="w")
        self.prompt_text = scrolledtext.ScrolledText(question_frame, height=8, wrap=tk.WORD)
        self.prompt_text.insert(tk.END, initial_prompt)
        self.prompt_text.pack(fill="x", expand=True, pady=(5,0))

        # --- 模板与模型区 ---
        controls_frame = ttk.Frame(parent_tab)
        controls_frame.pack(fill="x", pady=5)
        controls_frame.columnconfigure(1, weight=1)
        controls_frame.columnconfigure(3, weight=1)

        ttk.Label(controls_frame, text="模板 (Ctrl+T):").grid(row=0, column=0, sticky="w", padx=(0,5))
        self.template_var = tk.StringVar()
        template_names = ["-- 无模板 --"] + list(PROMPT_TEMPLATES.keys())
        self.template_dropdown = ttk.Combobox(controls_frame, textvariable=self.template_var, values=template_names, state="readonly")
        self.template_dropdown.grid(row=0, column=1, sticky="ew")
        self.template_dropdown.current(0)
        self.template_dropdown.bind("<<ComboboxSelected>>", self.apply_template)

        ttk.Label(controls_frame, text="模型 (Ctrl+M):").grid(row=0, column=2, sticky="w", padx=(10,5))
        self.model_var = tk.StringVar()
        self.model_dropdown = ttk.Combobox(controls_frame, textvariable=self.model_var, values=AI_MODELS, state="readonly")
        self.model_dropdown.grid(row=0, column=3, sticky="ew")
        self.model_dropdown.current(0)
        
        # --- 操作区 ---
        action_frame = ttk.Frame(parent_tab)
        action_frame.pack(fill="x", pady=5)
        self.submit_button = ttk.Button(action_frame, text="提问 (Ctrl+Enter)", command=self.submit_question)
        self.submit_button.pack(side="right")

        # --- 回答区 ---
        answer_frame = ttk.Frame(parent_tab)
        answer_frame.pack(fill="both", expand=True, pady=(5,0))

        answer_header_frame = ttk.Frame(answer_frame)
        answer_header_frame.pack(fill="x", pady=(0,5))
        ttk.Label(answer_header_frame, text="AI 的回答 (Ctrl+A, F 全屏):").pack(side="left", anchor="w")

        action_buttons_frame = ttk.Frame(answer_header_frame)
        action_buttons_frame.pack(side="right")
        
        font_minus_button = ttk.Button(action_buttons_frame, text="A-", command=lambda: self.change_font_size(-1), width=4)
        font_minus_button.pack(side="left", padx=(0, 5))
        font_plus_button = ttk.Button(action_buttons_frame, text="A+", command=lambda: self.change_font_size(1), width=4)
        font_plus_button.pack(side="left", padx=(0, 10))

        self.copy_button = ttk.Button(action_buttons_frame, text="复制 (Ctrl+Shift+C)", command=self.copy_to_clipboard)
        self.copy_button.pack(side="left", padx=(0, 5))
        self.save_button = ttk.Button(action_buttons_frame, text="保存 (Ctrl+S)", command=self.save_to_file)
        self.save_button.pack(side="left")

        self.answer_text = scrolledtext.ScrolledText(answer_frame, height=15, wrap=tk.WORD)
        self.answer_text.pack(fill="both", expand=True)
        self.answer_text.tag_configure("current_line", background="#e8f2ff")
        
    def setup_log_tab(self, parent_tab):
        log_controls_frame = ttk.Frame(parent_tab)
        log_controls_frame.pack(fill="x", pady=(0,5))
        
        ttk.Label(log_controls_frame, text="日志级别:").pack(side="left", padx=(0,5))
        
        self.log_level_var = tk.StringVar(value='INFO')
        log_levels = ['DEBUG', 'INFO', 'WARNING', 'ERROR']
        self.log_level_combo = ttk.Combobox(log_controls_frame, textvariable=self.log_level_var, values=log_levels, state="readonly", width=10)
        self.log_level_combo.pack(side="left")
        self.log_level_combo.bind("<<ComboboxSelected>>", self.change_log_level)

        ttk.Label(parent_tab, text="程序运行日志:").pack(anchor="w", pady=(0,5))
        self.log_text = scrolledtext.ScrolledText(parent_tab, height=15, wrap=tk.WORD, state='disabled')
        self.log_text.pack(fill="both", expand=True)
        
    def change_log_level(self, event=None):
        level_name = self.log_level_var.get()
        level = getattr(logging, level_name.upper(), logging.INFO)
        logging.getLogger().setLevel(level)
        logging.info(f"日志级别已更改为: {level_name}")

    def setup_keyboard_shortcuts(self):
        # 提交
        self.prompt_text.bind("<Control-Return>", lambda e: self.submit_question())
        # 字体
        self.root.bind("<Control-plus>", lambda e: self.change_font_size(1))
        self.root.bind("<Control-equal>", lambda e: self.change_font_size(1)) # for keyboards without numpad
        self.root.bind("<Control-minus>", lambda e: self.change_font_size(-1))
        # 标签页
        self.root.bind("<Alt-1>", lambda e: self.notebook.select(0))
        self.root.bind("<Alt-2>", lambda e: self.notebook.select(1))
        # 保存与复制
        self.root.bind("<Control-s>", lambda e: self.save_to_file())
        self.root.bind("<Control-Shift-C>", lambda e: self.copy_to_clipboard())
        # 焦点跳转
        self.root.bind("<Control-p>", lambda e: self.prompt_text.focus_set())
        self.root.bind("<Control-a>", lambda e: self.answer_text.focus_set())
        self.root.bind("<Control-t>", lambda e: self.template_dropdown.focus_set())
        self.root.bind("<Control-m>", lambda e: self.model_dropdown.focus_set())
        # 阅读尺 (光标行高亮)
        self.answer_text.bind("<KeyRelease>", self.highlight_current_line)
        self.answer_text.bind("<ButtonRelease-1>", self.highlight_current_line)
        # 全屏
        self.root.bind("<F>", self.toggle_fullscreen_answer)
        self.root.bind("<Escape>", self.exit_fullscreen)
        
    def highlight_current_line(self, event=None):
        self.answer_text.tag_remove("current_line", "1.0", tk.END)
        cursor_pos = self.answer_text.index(tk.INSERT)
        self.answer_text.tag_add("current_line", f"{cursor_pos} linestart", f"{cursor_pos} lineend+1c")

    def poll_log_queue(self):
        while True:
            try:
                record = self.log_queue.get(block=False)
            except queue.Empty:
                break
            else:
                self.log_text.config(state='normal')
                self.log_text.insert(tk.END, record + '\n')
                self.log_text.config(state='disabled')
                self.log_text.see(tk.END)
        self.root.after(100, self.poll_log_queue)

    def apply_template(self, event=None):
        selected_template_name = self.template_var.get()
        logging.info(f"应用模板: {selected_template_name}")
        current_text = self.prompt_text.get("1.0", "end-1c")
        content_part = current_text
        if self.last_template_text and content_part.startswith(self.last_template_text):
            content_part = content_part[len(self.last_template_text):]
        if selected_template_name == "-- 无模板 --":
            new_template_text = ""
        else:
            new_template_text = PROMPT_TEMPLATES.get(selected_template_name, "")
        new_full_text = new_template_text + content_part.lstrip()
        self.prompt_text.delete("1.0", tk.END)
        self.prompt_text.insert(tk.END, new_full_text)
        self.last_template_text = new_template_text

    def submit_question(self):
        selected_model = self.model_var.get()
        prompt = self.prompt_text.get("1.0", tk.END).strip()
        if not selected_model or not prompt:
            logging.warning("提交被取消: 模型或问题为空。")
            return
        logging.info(f"提交问题到模型: {selected_model}")
        self.answer_text.delete("1.0", tk.END)
        self.submit_button.config(state="disabled")
        self.result_queue = queue.Queue()
        selected_model_lower = selected_model.lower()
        if "deepseek" in selected_model_lower:
            thread = threading.Thread(target=call_deepseek_non_stream, args=(prompt, self.result_queue), daemon=True)
        elif "gemini" in selected_model_lower:
            thread = threading.Thread(target=call_gemini_non_stream, args=(prompt, selected_model, self.result_queue), daemon=True)
        else:
            error_msg = f"错误: 无效的模型选择 '{selected_model}'。"
            logging.error(error_msg)
            self.answer_text.insert(tk.END, error_msg)
            self.submit_button.config(state="normal")
            return
        thread.start()
        self.root.after(100, self.process_queue)

    def process_queue(self):
        try:
            is_done = False
            while not self.result_queue.empty():
                item = self.result_queue.get_nowait()
                logging.debug(f"从队列中取出: {str(item)[:100]}...")
                if item is _sentinel:
                    is_done = True
                    break
                else:
                    self.answer_text.insert(tk.END, item)
                    self.answer_text.see(tk.END)
            
            if is_done:
                self.submit_button.config(state="normal")
                self.render_markdown(self.answer_text)
                self.answer_text.focus_set()
                logging.info("AI回答完成，焦点自动移至回答框。")
            else:
                self.root.after(100, self.process_queue)

        except queue.Empty:
            if self.submit_button['state'] == 'disabled':
                self.root.after(100, self.process_queue)

    def render_markdown(self, text_widget):
        logging.info("开始渲染Markdown格式...")
        text_content = text_widget.get("1.0", tk.END)

        # 清除旧标签
        for tag in ["h1", "h2", "h3", "bold", "italic", "code_block", "hidden"]:
            text_widget.tag_remove(tag, "1.0", tk.END)

        # 优先级: 代码块 > 标题 > 粗体 > 斜体
        # 1. 代码块
        for match in re.finditer(r"```(.*?)```", text_content, re.DOTALL):
            text_widget.tag_add("code_block", f"1.0+{match.start()}c", f"1.0+{match.end()}c")

        # 2. 标题
        for level, pattern in enumerate([r"^# (.*)", r"^## (.*)", r"^### (.*)"], 1):
            for match in re.finditer(pattern, text_content, re.MULTILINE):
                start_pos = f"1.0+{match.start()}c"
                if "code_block" in text_widget.tag_names(start_pos): continue
                text_widget.tag_add(f"h{level}", start_pos, f"1.0+{match.end()}c")
                text_widget.tag_add("hidden", start_pos, f"1.0+{match.start(1)}c")

        # 3. 粗体
        for match in re.finditer(r"\*\*(.*?)\*\*", text_content):
            start_pos = f"1.0+{match.start()}c"
            if "code_block" in text_widget.tag_names(start_pos): continue
            text_widget.tag_add("bold", f"1.0+{match.start(1)}c", f"1.0+{match.end(1)}c")
            text_widget.tag_add("hidden", start_pos, f"1.0+{match.start(1)}c")
            text_widget.tag_add("hidden", f"1.0+{match.end(1)}c", f"1.0+{match.end()}c")

        # 4. 斜体 (避免匹配到粗体内的*)
        for match in re.finditer(r"(?<!\*)\*(?!\*)(.*?)(?<!\*)\*(?!\*)", text_content):
            start_pos = f"1.0+{match.start()}c"
            if any(tag in text_widget.tag_names(start_pos) for tag in ["code_block", "bold"]): continue
            text_widget.tag_add("italic", f"1.0+{match.start(1)}c", f"1.0+{match.end(1)}c")
            text_widget.tag_add("hidden", start_pos, f"1.0+{match.start(1)}c")
            text_widget.tag_add("hidden", f"1.0+{match.end(1)}c", f"1.0+{match.end()}c")

        logging.info("Markdown渲染完成。")

    def toggle_fullscreen_answer(self, event=None):
        if self.fullscreen_window and self.fullscreen_window.winfo_exists():
            self.exit_fullscreen()
            return

        logging.info("进入全屏模式。")
        self.fullscreen_window = tk.Toplevel(self.root)
        self.fullscreen_window.attributes('-fullscreen', True)
        self.fullscreen_window.attributes('-topmost', True)
        
        self.fullscreen_text = scrolledtext.ScrolledText(self.fullscreen_window, wrap=tk.WORD, font=self.default_font)
        self.fullscreen_text.pack(expand=True, fill='both')
        
        content = self.answer_text.get("1.0", tk.END)
        self.fullscreen_text.insert("1.0", content)
        
        self.apply_styles() # 确保新窗口的tag被配置
        self.render_markdown(self.fullscreen_text)
        
        self.fullscreen_text.config(state="disabled")
        
        self.fullscreen_window.bind("<F>", self.exit_fullscreen)
        self.fullscreen_window.bind("<Escape>", self.exit_fullscreen)
        self.fullscreen_window.focus_set()

    def exit_fullscreen(self, event=None):
        if self.fullscreen_window and self.fullscreen_window.winfo_exists():
            logging.info("退出全屏模式。")
            self.fullscreen_window.destroy()
            self.fullscreen_window = None

    def copy_to_clipboard(self, event=None):
        try:
            text_to_copy = self.answer_text.get("1.0", tk.END).strip()
            if text_to_copy:
                self.root.clipboard_clear()
                self.root.clipboard_append(text_to_copy)
                original_text = self.copy_button.cget("text")
                self.copy_button.config(text="已复制!")
                self.root.after(1500, lambda: self.copy_button.config(text=original_text))
        except tk.TclError:
            logging.warning("复制到剪贴板失败，可能正被占用。")
            pass

    def save_to_file(self, event=None):
        try:
            text_to_save = self.answer_text.get("1.0", tk.END).strip()
            if not text_to_save:
                return
            file_path = filedialog.asksaveasfilename(
                defaultextension=".txt",
                filetypes=[("Text Files", "*.txt"), ("Markdown Files", "*.md"), ("All Files", "*.*")],
                title="保存 AI 回答"
            )
            if file_path:
                with open(file_path, "w", encoding="utf-8") as f:
                    f.write(text_to_save)
                original_text = self.save_button.cget("text")
                self.save_button.config(text="已保存!")
                self.root.after(1500, lambda: self.save_button.config(text=original_text))
                logging.info(f"回答已保存到文件: {file_path}")
        except Exception as e:
            logging.error(f"保存文件时出错: {e}")

# --- 4. 主程序入口 ---
if __name__ == "__main__":
    # 如果AHK传来文本，就用它；否则，使用默认提示。
    initial_prompt = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1].strip() else ""
    
    root = tk.Tk()
    app = AiAssistantApp(root, initial_prompt)
    root.mainloop() 