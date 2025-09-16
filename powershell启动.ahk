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
; 使用 Ctrl + Alt + E 快捷键：启动、激活或最小化 Cursor
^!e::
{
    ; !! 重要 !! 如果 Cursor.exe 不在系统路径 (PATH) 中，请在此处填写它的完整路径
    ; 例如: cursorPath := A_LocalAppData . "\Programs\Cursor\Cursor.exe"
    cursorPath := "Cursor.exe"
    winClass := "ahk_exe Cursor.exe"

    ; 获取所有 Cursor 窗口的列表 (按 Z 顺序，最近激活的在前)
    cursorWindows := WinGetList(winClass)

    ; 情况1: 没有 Cursor 窗口 -> 启动它
    if cursorWindows.Length = 0
    {
        Run cursorPath
        return
    }

    ; 情况2: Cursor 窗口已在最前 -> 循环切换或最小化
    if WinActive(winClass)
    {
        ; 如果只有一个窗口，则最小化它
        if cursorWindows.Length = 1
        {
            WinMinimize winClass
            return
        }
        
        ; 如果有多个窗口，则循环到下一个
        activeId := WinActive("A")
        
        nextIndex := 1 ; 默认激活第一个
        for i, hwnd in cursorWindows
        {
            if hwnd = activeId
            {
                ; 找到了当前窗口, 目标设为下一个
                nextIndex := i + 1
                break
            }
        }

        ; 如果当前是列表里最后一个, 则循环回第一个
        if (nextIndex > cursorWindows.Length)
        {
            nextIndex := 1
        }
        
        WinActivate "ahk_id " . cursorWindows[nextIndex]
    }
    ; 情况3: 有 Cursor 窗口, 但不在最前 -> 激活它
    else
    {
        ; 激活最近使用的那个 (列表中的第一个)
        WinActivate "ahk_id " . cursorWindows[1]
    }
}