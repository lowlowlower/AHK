#Requires AutoHotkey v2.0
#Warn VarUnset, Off

; ======================================================================
; =================== DeepSeek JSON 编码测试脚本 ===================
; ======================================================================

; --- 1. 配置 ---
; 请在此处填入您的 API 密钥
global DEEPSEEK_API_KEY := "sk-78a9fd015e054281a3eb0a0712d5e6d0"

; --- 2. 运行测试 ---
RunDeepSeekTest()

; --- 3. 测试主函数 ---
RunDeepSeekTest()
{
    global DEEPSEEK_API_KEY
    
    ; 模拟一段包含中文和特殊符号的、可能导致问题的文本
    testPrompt := '你好 "DeepSeek"！`n这是一个测试。'
    
    escapedPrompt := JsonEscape(testPrompt)
    body := '{"model": "deepseek-chat", "messages": [{"role": "user", "content": "' . escapedPrompt . '"}]}'
    
    ; --- 使用临时文件保证 UTF-8 编码正确性 (无 BOM) ---
    tempRequestFile := A_Temp . "\ahk_ai_request.json"
    tempResponseFile := A_Temp . "\ahk_ai_response.txt"
    try {
        file := FileOpen(tempRequestFile, "w", "UTF-8-RAW")
        file.Write(body)
        file.Close()
    } catch {
        MsgBox "无法写入临时请求文件: " . tempRequestFile
        ExitApp
    }
    
    url := "https://api.deepseek.com/chat/completions"
    cmd := 'curl.exe -s -X POST "' . url . '" -H "Content-Type: application/json" -H "Authorization: Bearer ' . DEEPSEEK_API_KEY . '" --data-binary "@' . tempRequestFile . '"'

    Shell := ComObject("WScript.Shell")
    returnCode := Shell.Run(A_ComSpec ' /c "' cmd ' > "' . tempResponseFile . '" 2>&1"', 0, true)
    
    stdout := ""
    if FileExist(tempResponseFile)
    {
        stdout := FileRead(tempResponseFile, "UTF-8")
    }

    FileDelete tempRequestFile
    FileDelete tempResponseFile
    
    ; --- 4. 构建并显示结果 ---
    resultText := ""
    resultText .= "----------- 我们发送的 JSON ----------`n"
    resultText .= body . "`n`n"
    resultText .= "----------- 服务器返回的原始内容 (从文件读取) -----------`n"
    resultText .= "【文件内容】:`n" . stdout . "`n`n"

    MsgBox resultText, "测试结果"
    ExitApp
}


; --- 5. 辅助函数 (与主脚本中完全相同) ---
JsonEscape(str) {
    str := StrReplace(str, "\", "\\")
    str := StrReplace(str, '"', '\"')
    str := StrReplace(str, "`n", "\n")
    str := StrReplace(str, "`r", "\r")
    str := StrReplace(str, "`t", "\t")
    str := StrReplace(str, "`b", "\b")
    str := StrReplace(str, "`f", "\f")
    return str
} 