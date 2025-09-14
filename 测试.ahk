#Requires AutoHotkey v2.0
#Warn
SendMode "Input"
SetWorkingDir A_ScriptDir

; ######################################################################################################################
; ++ 用戶配置區 ++
; ######################################################################################################################
MyGeminiKey := "AIzaSyDmfaMC3pHdY6BYCvL_1pWZF5NLLkh28QU" ; <--- 記得換成你自己的金鑰
MyPrompt := "請將以下內容翻譯成英文：``{1}``" ; <--- 修正了反引號

; JSON 解析器對象
global JSON_Parser := (doc := ComObject("HTMLFile"), doc.write("<meta http-equiv='X-UA-Compatible' content='IE=Edge'>"), doc.parentWindow.JSON)

; ######################################################################################################################
; ++ 快捷鍵設置 ++  天空
; ######################################################################################################################
^!g::{
    local clipSaved := ClipboardAll()
    A_Clipboard := ""
    Send "^c"
    if !ClipWait(1) {
        A_Clipboard := clipSaved
        return
    }
    local selectedText := A_Clipboard
    if (selectedText = "") {
        A_Clipboard := clipSaved
        return
    }
    local geminiResponse := CallGeminiAPI(selectedText)
    MsgBox "解析后的内容：`n" . geminiResponse ; 调试：显示解析后的内容
    
    if (geminiResponse != "") {
        SendInput geminiResponse
    }
    A_Clipboard := clipSaved
}

; (下方的 CallGeminiAPI, JsonEscape, JsonUnescape 函數保持不變)
CallGeminiAPI(text) {
    global MyGeminiKey, MyPrompt, JSON_Parser
    local fullPrompt := Format(MyPrompt, text)
    local escapedPrompt := JsonEscape(fullPrompt)
    local jsonBody := '{"contents": [{"parts":[{"text": "' . escapedPrompt . '"}]}]}'
    local url := "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite-preview-06-17:generateContent?key=" . MyGeminiKey
    try {
        local whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("POST", url, true)
        whr.SetRequestHeader("Content-Type", "application/json")
        whr.Send(jsonBody)
        whr.WaitForResponse()
        
        ; 首先檢查 HTTP 狀態碼
        if (whr.Status != 200) {
            return "錯誤：API 请求失败，HTTP 状态码：" . whr.Status . "`n`n返回内容：`n" . whr.ResponseText
        }
        
        ; 切换到 ResponseBody 并手动进行 UTF-8 解码，以避免乱码
        local responseBody := whr.ResponseBody
        local responseText := StrGet(responseBody.Ptr, "UTF-8")

        MsgBox "API 返回原文：`n" . responseText ; 调试：显示API的原始返回内容
        
        try {
            ; 使用 JSON 解析器對象
            local jsonObj := JSON_Parser.parse(responseText)
            local parsedText := jsonObj.candidates[0].content.parts[0].text
            return JsonUnescape(parsedText)
        } catch as e {
            return "錯誤：JSON 解析失敗。`n" e.Message "`n`n返回原文為：" . responseText
        }
    } catch as e {
        return "错误：API 请求失败。`n" e.Message
    }
}
JsonEscape(str) {
    str := StrReplace(str, "\", "\\"), str := StrReplace(str, '"', '\"'), str := StrReplace(str, "/", "\/"), str := StrReplace(str, "`b", "\b"), str := StrReplace(str, "`f", "\f"), str := StrReplace(str, "`n", "\n"), str := StrReplace(str, "`r", "\r"), str := StrReplace(str, "`t", "\t")
    return str
}
JsonUnescape(str) {
    str := StrReplace(str, "\\n", "`n"), str := StrReplace(str, '\"', '"'), str := StrReplace(str, '\\', '\')
    return str
    ;绿草
}