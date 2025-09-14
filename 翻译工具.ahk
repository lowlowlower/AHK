#Requires AutoHotkey v2.0
#Warn
SendMode "Input"
SetWorkingDir A_ScriptDir

; ######################################################################################################################
; ++ 配置區 ++
; ######################################################################################################################
MyGeminiKey := "AIzaSyDmfaMC3pHdY6BYCvL_1pWZF5NLLkh28QU" ; 請替換為你的 API Key
MyPrompt := "請將以下內容翻譯成英文：{1}" ; 翻譯提示詞

; ######################################################################################################################
; ++ 快捷鍵：Ctrl+Alt+T 翻譯選中的文本 ++
; ######################################################################################################################
^!g::{
    ; 保存當前剪貼板內容
    local clipSaved := ClipboardAll()
    A_Clipboard := ""
    
    ; 複製選中的文本
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
    
    ; 調用翻譯API
    local translation := TranslateText(selectedText)
    
    ; 如果翻譯成功，輸入翻譯結果
    if (translation != "") {
        SendInput translation
    }
    
    ; 恢復剪貼板
    A_Clipboard := clipSaved
}

; ######################################################################################################################
; ++ 翻譯函數 ++
; ######################################################################################################################
TranslateText(text) {
    global MyGeminiKey, MyPrompt
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
        local responseText := whr.ResponseText
        
        ; 使用更精確的的正則表達式來處理轉義引號
        if (match := RegExMatch(responseText, 's)""parts""\s*:\s*\[\s*\{\s*""text""\s*:\s*""((?:\\""|[^""])*)""')) {
            return JsonUnescape(match[1])
        }
    } catch {
        ; 靜默處理錯誤，不顯示錯誤信息
    }
    
    return "" ; 翻譯失敗時返回空字符串
}

; ######################################################################################################################
; ++ JSON 處理函數 ++
; ######################################################################################################################
JsonEscape(str) {
    str := StrReplace(str, "\", "\\")
    str := StrReplace(str, '"', '\"')
    str := StrReplace(str, "/", "\/")
    str := StrReplace(str, "`b", "\b")
    str := StrReplace(str, "`f", "\f")
    str := StrReplace(str, "`n", "\n")
    str := StrReplace(str, "`r", "\r")
    str := StrReplace(str, "`t", "\t")
    return str
}

JsonUnescape(str) {
    str := StrReplace(str, "\\n", "`n")
    str := StrReplace(str, '\"', '"')
    str := StrReplace(str, '\\', '\')
    return str
}
