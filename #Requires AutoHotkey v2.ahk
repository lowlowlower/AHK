#Requires AutoHotkey v2.0
#Warn
SendMode "Input"
SetWorkingDir A_ScriptDir

; 测试脚本配置
MyGeminiKey := "AIzaSyApuy_ax9jhGXpUdlgI6w_0H5aZ7XiY9vU" ; 请替换为有效的 API Key
TestPrompt := "测试连接到 Gemini API 的脚本。" ; 测试用的内容

; 测试函数
TestGeminiAPI() {
    global MyGeminiKey, TestPrompt
    local jsonBody := '{"contents": [{"parts":[{"text": "' . TestPrompt . '"}]}]}'
    local url := "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite-preview-06-17:generateContent?key=" . MyGeminiKey
    try {
        local whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("POST", url, true)
        whr.SetRequestHeader("Content-Type", "application/json")
        whr.Send(jsonBody)
        whr.WaitForResponse()
        local responseText := whr.ResponseText
        MsgBox "API 返回内容：`n" . responseText
    } 
}

; 运行测试
TestGeminiAPI()