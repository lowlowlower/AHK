#Requires AutoHotkey v2.0


; 使用 Ctrl + Alt + P 快捷键：启动、激活或最小化 Windows Terminal
^!p::
{
    winTitle := "ahk_exe WindowsTerminal.exe"
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
        Run "powershell.exe"
    }
} 

; 使用 Ctrl + Alt + C 快捷键：启动、激活或最小化 Chrome
^!c::
{
    winTitle := "ahk_exe chrome.exe"
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
        Run "chrome.exe"
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