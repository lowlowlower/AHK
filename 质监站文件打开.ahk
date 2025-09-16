#Requires AutoHotkey v2.0


; 使用 Ctrl + Alt + Q 快捷键打开或激活 "质监站" 文件夹窗口
^!q::
{
    ; !! 重要 !!
    ; !! 请将下面的路径替换为 "质监站" 文件夹的实际完整路径
    folderPath := "D:\质监站"

    ; 尝试激活已存在的窗口，"质监站" 是窗口标题的一部分
    if WinExist("质监站 ahk_exe explorer.exe")
    {
        WinActivate "质监站 ahk_exe explorer.exe"
    }
    else
    {
        ; 如果窗口不存在，则尝试打开文件夹
        if DirExist(folderPath)
        {
            Run folderPath
        }
        else
        {
            MsgBox "错误: 文件夹路径不存在或未在脚本中设置。`n`n请右键编辑脚本文件，并设置正确的 folderPath 变量。"
        }
    }
}

