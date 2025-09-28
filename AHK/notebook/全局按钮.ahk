#Requires AutoHotkey v2.0
#Warn VarUnset, Off

!f1::
{
    python_path := "python.exe" ; 确保 python 在你的系统路径中，或者提供完整路径
    script_path := A_ScriptDir . "\search_handler.py"
    ; 保存当前剪贴板的文本内容
    ClipboardOld := A_Clipboard
    A_Clipboard := "" ; 清空剪贴板以确保能获取到选中的文本

    ; 发送 Ctrl+C 复制选中的文本
    Send "^c"
    if !ClipWait(0.5) ; 等待0.5秒让剪贴板获取内容
    {
        MsgBox("未能复制选中的文本。", "错误", "Icon!")
        A_Clipboard := ClipboardOld ; 恢复原始剪贴板内容
        return
    }

    selected_text := A_Clipboard
    A_Clipboard := ClipboardOld ; 恢复原始剪贴板内容

    ; 弹出输入框让用户选择搜索引擎
    ib := InputBox("请输入搜索引擎代码 (例如: g for Google):", "搜索引擎", "w280 h150")
    if (ib.Result != "OK" or ib.Value = "")
        return ; 如果用户取消或者没有输入，则退出

    user_input := ib.Value
    
    ; 运行 Python 脚本并传递参数
    Run('"' python_path '" "' script_path '" "' selected_text '" "' user_input '"')
}

; 使用 Ctrl + Alt + m 快捷键：启动、激活或切换 Windows Terminal
; 使用 Ctrl + Alt + P 快捷键：启动、激活或切换 Windows Terminal
!x::
{
    winClass := "ahk_exe Typora.exe"
    exePath := "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Typora\Typora.lnk"

    ; 获取所有窗口的列表 (按 Z 顺序，最近激活的在前)
    windowList := WinGetList(winClass)

    ; 情况1: 没有窗口 -> 启动它
    if windowList.Length = 0
    {
        Run exePath
        return
    }

    ; 情况2: 窗口已在最前 -> 循环切换或最小化
    if WinActive(winClass)
    {
        ; 如果只有一个窗口，则最小化它
        if windowList.Length = 1
        {
            WinMinimize winClass
            return
        }
        
        ; 激活 Z 顺序中最后一个窗口，以实现循环切换
        WinActivate "ahk_id " . windowList[windowList.Length]
    }
    ; 情况3: 有窗口, 但不在最前 -> 激活它
    else
    {
        ; 激活最近使用的那个 (列表中的第一个)
        WinActivate "ahk_id " . windowList[1]
    }
} 
!F2::
{
    winClass := "ahk_exe miro.exe"
    exePath := "C:\Users\admin\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Miro.lnk"

    ; 获取所有窗口的列表 (按 Z 顺序，最近激活的在前)
    windowList := WinGetList(winClass)

    ; 情况1: 没有窗口 -> 启动它
    if windowList.Length = 0
    {
        Run exePath
        return
    }

    ; 情况2: 窗口已在最前 -> 循环切换或最小化
    if WinActive(winClass)
    {
        ; 如果只有一个窗口，则最小化它
        if windowList.Length = 1
        {
            WinMinimize winClass
            return
        }
        
        ; 激活 Z 顺序中最后一个窗口，以实现循环切换
        WinActivate "ahk_id " . windowList[windowList.Length]
    }
    ; 情况3: 有窗口, 但不在最前 -> 激活它
    else
    {
        ; 激活最近使用的那个 (列表中的第一个)
        WinActivate "ahk_id " . windowList[1]
    }
} 
^!p::
{
    winClass := "ahk_exe WindowsTerminal.exe ahk_class CASCADIA_HOSTING_WINDOW_CLASS"
    exePath := "wt.exe" ; 使用 wt.exe 命令确保正确启动 Windows Terminal

    ; 获取所有窗口的列表 (按 Z 顺序，最近激活的在前)
    windowList := WinGetList(winClass)

    ; 情况1: 没有窗口 -> 启动它
    if windowList.Length = 0
    {
        Run exePath
        return
    }

    ; 情况2: 窗口已在最前 -> 循环切换或最小化
    if WinActive(winClass)
    {
        ; 如果只有一个窗口，则最小化它
        if windowList.Length = 1
        {
            WinMinimize winClass
            return
        }
        
        ; 激活 Z 顺序中最后一个窗口，以实现循环切换
        WinActivate "ahk_id " . windowList[windowList.Length]
    }
    ; 情况3: 有窗口, 但不在最前 -> 激活它
    else
    {
        ; 激活最近使用的那个 (列表中的第一个)
        WinActivate "ahk_id " . windowList[1]
    }
} 

; --- Chrome (Default Profile) 智能热键 ---
; 使用全局变量来存储特定 Chrome 实例的进程 ID (PID)
global chromeDefaultPid := 0

#!c::
{
    ; 1. 检查我们之前记录的 PID 是否还存在于一个窗口上
    if WinExist("ahk_pid " . chromeDefaultPid)
    {
        ; --- 窗口存在 -> 激活或最小化 ---
        if WinActive("ahk_pid " . chromeDefaultPid)
        {
            WinMinimize "ahk_pid " . chromeDefaultPid
        }
        else
        {
            WinActivate "ahk_pid " . chromeDefaultPid
        }
    }
    else
    {
        ; --- 窗口不存在 -> 启动新实例并记录 PID ---
        Run 'chrome.exe --profile-directory="Default"',,, &newPid
        chromeDefaultPid := newPid ; 将新的 PID 存储到全局变量中
    }
}

; 使用 Ctrl + Alt + Q 快捷键：打开、激活或最小化 "质监站" 文件夹窗口
^!q::
{
    folderPath := "D:\质监站"
    winTitle := "质监站 ahk_exe explorer.exe"

    ; 如果窗口是当前活动窗口，则最小化它
    if WinActive(winTitle)
    {
        WinMinimize winTitle
    }
    ; 如果窗口存在但不是活动窗口，则激活它
    else if WinExist(winTitle)
    {
        WinActivate winTitle
    }
    ; 如果窗口不存在，则尝试打开文件夹
    else
    {
        if DirExist(folderPath)
        {
            Run folderPath
        }
        else
        {
            MsgBox "错误: 文件夹路径不存在。`n`n请检查 folderPath 变量: " . folderPath
        }
    }
}
; 使用 Ctrl + Alt + X 快捷键：启动、激活或最小化文件资源管理器
^!x::
{
    winClass := "ahk_exe explorer.exe ahk_class CabinetWClass"
    exePath := "explorer.exe"

    ; 获取所有窗口的列表 (按 Z 顺序，最近激活的在前)
    windowList := WinGetList(winClass)

    ; 情况1: 没有窗口 -> 启动它
    if windowList.Length = 0
    {
        Run exePath
        return
    }

    ; 情况2: 窗口已在最前 -> 循环切换或最小化
    if WinActive(winClass)
    {
        ; 如果只有一个窗口，则最小化它
        if windowList.Length = 1
        {
            WinMinimize winClass
            return
        }
        
        ; 激活 Z 顺序中最后一个窗口，以实现循环切换
        WinActivate "ahk_id " . windowList[windowList.Length]
    }
    ; 情况3: 有窗口, 但不在最前 -> 激活它
    else
    {
        ; 激活最近使用的那个 (列表中的第一个)
        WinActivate "ahk_id " . windowList[1]
    }
}
; 使用 Ctrl + Alt + E 快捷键：启动、激活或最小化 Cursor
^!e::
{
    winClass := "ahk_exe Cursor.exe"
    exePath := "Cursor.exe"

    ; 获取所有窗口的列表 (按 Z 顺序，最近激活的在前)
    windowList := WinGetList(winClass)

    ; 情况1: 没有窗口 -> 启动它
    if windowList.Length = 0
    {
        Run exePath
        return
    }

    ; 情况2: 窗口已在最前 -> 循环切换或最小化
    if WinActive(winClass)
    {
        ; 如果只有一个窗口，则最小化它
        if windowList.Length = 1
        {
            WinMinimize winClass
            return
        }
        
        ; 激活 Z 顺序中最后一个窗口，以实现循环切换
        WinActivate "ahk_id " . windowList[windowList.Length]
    }
    ; 情况3: 有窗口, 但不在最前 -> 激活它
    else
    {
        ; 激活最近使用的那个 (列表中的第一个)
        WinActivate "ahk_id " . windowList[1]
    }
}
; 使用 Ctrl + Alt + 1 快捷键：启动、激活或最小化 Word
^!1::
{
    winClass := "ahk_exe winword.exe"
    exePath := "winword.exe"

    ; 获取所有窗口的列表 (按 Z 顺序，最近激活的在前)
    windowList := WinGetList(winClass)

    ; 情况1: 没有窗口 -> 启动它
    if windowList.Length = 0
    {
        Run exePath
        return
    }

    ; 情况2: 窗口已在最前 -> 循环切换或最小化
    if WinActive(winClass)
    {
        ; 如果只有一个窗口，则最小化它
        if windowList.Length = 1
        {
            WinMinimize winClass
            return
        }
        
        ; 激活 Z 顺序中最后一个窗口，以实现循环切换
        WinActivate "ahk_id " . windowList[windowList.Length]
    }
    ; 情况3: 有窗口, 但不在最前 -> 激活它
    else
    {
        ; 激活最近使用的那个 (列表中的第一个)
        WinActivate "ahk_id " . windowList[1]
    }
}
; 使用 Ctrl + Alt + A 快捷键：启动、激活或最小化 MuseScore
!a::
{
    winClass := "ahk_exe MuseScore4.exe"
    exePath := "C:\Program Files\MuseScore 4\bin\MuseScore4.exe"

    ; 获取所有窗口的列表 (按 Z 顺序，最近激活的在前)
    windowList := WinGetList(winClass)

    ; 情况1: 没有窗口 -> 启动它
    if windowList.Length = 0
    {
        Run exePath
        return
    }

    ; 情况2: 窗口已在最前 -> 循环切换或最小化
    if WinActive(winClass)
    {
        ; 如果只有一个窗口，则最小化它
        if windowList.Length = 1
        {
            WinMinimize winClass
            return
        }
        
        ; 激活 Z 顺序中最后一个窗口，以实现循环切换
        WinActivate "ahk_id " . windowList[windowList.Length]
    }
    ; 情况3: 有窗口, 但不在最前 -> 激活它
    else
    {
        ; 激活最近使用的那个 (列表中的第一个)
        WinActivate "ahk_id " . windowList[1]
    }
}

; 使用 Ctrl + Alt + R 快捷键：启动、激活或最小化 scrcpy 手机窗口
^!r::
{
    winTitle := "ahk_exe scrcpy.exe ahk_class SDL_app"
    scrcpyPath := "C:\Users\admin\Downloads\scrcpy-win64-v3.3.2\scrcpy-win64-v3.3.2\scrcpy.exe"
    
    ; 如果窗口是当前活动窗口，则最小化它
    if WinActive(winTitle)
    {
        WinMinimize winTitle
    }
    ; 如果窗口存在但不是活动窗口，则激活它
    else if WinExist(winTitle)
    {
        WinActivate winTitle
    }
    ; 如果窗口不存在，则运行它
    else
    {
        Run scrcpyPath
    }
}

; 使用 Win + Alt + 1/2/3 快捷键，在 Chrome Profile 4 中打开 Bilibili 收藏夹
#!q::
{
    url := "https://space.bilibili.com/675652672/favlist?fid=3666331972&ftype=create"
    Run 'chrome.exe --profile-directory="Profile 4" "' . url . '"'
}

#!w::
{
    url := "https://space.bilibili.com/675652672/favlist?fid=3716534672&ftype=create"
    Run 'chrome.exe --profile-directory="Profile 4" "' . url . '"'
}

#!e::
{
    url := "https://space.bilibili.com/675652672/favlist?fid=3713550472&ftype=create"
    Run 'chrome.exe --profile-directory="Profile 4" "' . url . '"'
}

; 使用 Ctrl + Alt + Y 快捷键：启动、激活或最小化 AHK Window Spy
^!y::
{
    winTitle := "Window Spy ahk_exe AutoHotkeyUX.exe"
    spyPath := '"C:\Program Files\AutoHotkey\UX\AutoHotkeyUX.exe" "C:\Program Files\AutoHotkey\UX\WindowSpy.ahk"'
    
    ; 如果窗口是当前活动窗口，则最小化它
    if WinActive(winTitle)
    {
        WinMinimize winTitle
    }
    ; 如果窗口存在但不是活动窗口，则激活它
    else if WinExist(winTitle)
    {
        WinActivate winTitle
    }
    ; 如果窗口不存在，则运行它
    else
    {
        Run spyPath
    }
}

; ======================================================================
; ======================= 决策大师框架 (Decision Master) =======================
; ======================================================================

; 使用 Ctrl + Alt + D 快捷键，呼出决策菜单
^!d::
{
    DecisionMenu.Show()
}

; --- 1. 创建主菜单和子菜单 ---
DecisionMenu := Menu()
WorkMenu := Menu()
RelaxMenu := Menu()
SystemMenu := Menu()

; --- 2. 将子菜单添加到主菜单 ---
DecisionMenu.Add("进入工作状态", WorkMenu)
DecisionMenu.Add("放松一下", RelaxMenu)
DecisionMenu.Add() ; 添加一条分隔线
DecisionMenu.Add("系统工具", SystemMenu)

; --- 3. 填充菜单项 ---
; Menu.Add("显示的名称", 回调函数)
WorkMenu.Add("写代码 (Cursor)", ActivateCursor)
WorkMenu.Add("处理文档 (Word)", ActivateWord)
WorkMenu.Add("命令行 (Terminal)", ActivateTerminal)
WorkMenu.Add("质监站文件夹", OpenZJZFolder)

RelaxMenu.Add("浏览网页 (Chrome)", ActivateChrome)
RelaxMenu.Add("玩音乐 (MuseScore)", ActivateMuseScore)

SystemMenu.Add("窗口探测 (Spy)", ActivateWindowSpy)


; --- 4. 定义回调函数 ---
; 每个菜单项对应一个函数，函数名可以自定义

ActivateCursor(*) {
    ActivateOrRun("ahk_exe Cursor.exe", "Cursor.exe")
}

ActivateWord(*) {
    ActivateOrRun("ahk_exe winword.exe", "winword.exe")
}

ActivateTerminal(*) {
    ActivateOrRun("ahk_exe WindowsTerminal.exe", "powershell.exe")
}

OpenZJZFolder(*) {
    ActivateOrRun("质监站 ahk_exe explorer.exe", "D:\质监站")
}

ActivateChrome(*) {
    ActivateOrRun("ahk_exe chrome.exe", "chrome.exe")
}

ActivateMuseScore(*) {
    ActivateOrRun("ahk_exe MuseScore4.exe", "C:\Program Files\MuseScore 4\bin\MuseScore4.exe")
}

ActivateWindowSpy(*) {
    ActivateOrRun("Window Spy ahk_exe AutoHotkeyUX.exe", '"C:\Program Files\AutoHotkey\UX\AutoHotkeyUX.exe" "C:\Program Files\AutoHotkey\UX\WindowSpy.ahk"')
}


; --- 5. 核心通用函数：激活或运行 ---
; 这个函数整合了我们之前所有的 "if-else" 逻辑，可以被所有程序调用
ActivateOrRun(winTitle, path)
{
    ; 尝试激活窗口
    if WinExist(winTitle)
    {
        WinActivate winTitle
    }
    ; 如果窗口不存在，则运行它
    else
    {
        Run path
    }
}

; ======================================================================
; ================= AI 助手 (通过 Python 实现) =================
; ======================================================================

; --- 依赖说明 ---
; 1. 请确保您已安装 Python: https://www.python.org/
; 2. ai_helper.py 和 prompts.json 文件需要和本脚本在同一个文件夹内。

; --- 快捷键定义 ---
; 选中任意文本后，按 Alt+Z 触发
!z::
{
    ; 智能逻辑: 通过是否选中文本来判断用户意图
    ; 意图1: 如果选中文本 -> 发起新查询
    ; 意图2: 如果未选中文本 -> 管理现有窗口

    ToolTip("正在获取文本...")
    selectedText := GetSelectedText()
    ToolTip()

    winTitle := "Python AI 助手 (终极版) ahk_class TkTopLevel"

    if (selectedText != "")
    {
        ; --- 意图1: 发起新查询 ---
        try
        {
            jsonPath := A_ScriptDir . "\prompts.json"
            jsonContent := FileRead(jsonPath, "UTF-8")
            
            aiMenu := Menu()
            
            pos := 1
            while RegExMatch(jsonContent, '(?<=")([^"]+)(?="\s*:)', &match, pos)
            {
                key := match[1]
                if (key != "")
                {
                    aiMenu.Add(key, MenuClickHandler.Bind(key, selectedText))
                }
                pos := match.Pos + match.Len
            }
        }
        catch
        {
            MsgBox("读取或解析 prompts.json 失败！", "AI 助手错误", "Icon!")
            return
        }
        aiMenu.Show()
    }
    else
    {
        ; --- 意图2: 管理现有窗口 ---
        if WinExist(winTitle)
        {
            if WinActive(winTitle)
                WinMinimize(winTitle)
            else
                WinActivate(winTitle)
        }
        ; 如果窗口不存在且没有选中文本，则不执行任何操作
    }
}

; --- 菜单项点击处理函数 ---
MenuClickHandler(templateName, textToSend, *)
{
    ; 检查 Python 服务窗口是否已存在
    winTitle := "Python AI 助手 (终极版) ahk_class TkTopLevel"
    if WinExist(winTitle)
    {
        ; 如果存在，先关闭旧窗口，避免多开
        WinClose(winTitle)
        Sleep(200) ; 等待一小段时间确保窗口关闭
    }

    ; 运行 Python 脚本，传递文本和模板名
    ; 使用 pythonw.exe 在后台无窗口启动
    pythonExe := "pythonw.exe"
    scriptPath := A_ScriptDir . '\ai_helper.py'
    Run('"' pythonExe '" "' scriptPath '" "' textToSend '" "' templateName '"')
}

; --- 核心功能函数 ---

; 通过模拟 Ctrl+C 获取当前选中的文本
GetSelectedText() {
    oldClipboard := ClipboardAll()
    A_Clipboard := ""
    SendInput "^c"
    if !ClipWait(0.1) ; 优化：将等待时间缩短为 0.1 秒
    {
        A_Clipboard := oldClipboard
        return ""
    }
    selectedText := A_Clipboard
    A_Clipboard := oldClipboard
    return selectedText
}