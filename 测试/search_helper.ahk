; search_helper.ahk (AutoHotkey v2)

#SingleInstance force

; 设置 Python 解释器的路径和脚本的路径
python_path := "python.exe" ; 确保 python 在你的系统路径中，或者提供完整路径
script_path := A_ScriptDir . "\search_handler.py"

!f1::
{
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
