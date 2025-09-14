#Requires AutoHotkey v2.0
#Warn
SendMode "Input"
SetWorkingDir A_ScriptDir

; ######################################################################################################################
; ++ 用戶配置區 ++
; ######################################################################################################################
MyGeminiKey := "AIzaSyDmfaMC3pHdY6BYCvL_1pWZF5NLLkh28QU" ; <--- 記得換成你自己的金鑰
MyPrompt := "請將以下內容翻譯成英文：``{1}``" ; <--- 修正了反引號

; ######################################################################################################################
; ++ 快捷鍵設置 ++
; ######################################################################################################################
^!g::{
    MsgBox "檢查點 1: 快捷鍵已觸發。"

    local clipSaved := ClipboardAll()
    A_Clipboard := ""
    Send "^c"
    if !ClipWait(1) {
        MsgBox "錯誤：複製文本失敗或超時。請確認你是否已選中文本。"
        A_Clipboard := clipSaved
        return
    }

    local selectedText := A_Clipboard
    MsgBox "檢查點 2: 已成功複製文本。`n`n內容為：`n" . selectedText

    if (selectedText = "") {
        MsgBox "錯誤：複製到的內容為空。"
        A_Clipboard := clipSaved
        return
    }

    MsgBox "檢查點 3: 準備呼叫 Gemini API..."
    local geminiResponse := CallGeminiAPI(selectedText)
    
    MsgBox "檢查點 4: API 已返回結果。`n`n內容為：`n" . geminiResponse

    if (geminiResponse != "") {
        SendInput geminiResponse
    } else {
        MsgBox "錯誤：API 返回結果為空或呼叫失敗。請檢查 API 金鑰和網路連線。"
    }

    A_Clipboard := clipSaved
}

; ######################################################################################################################
; ++ 主要 API 函數 ++
; ######################################################################################################################
CallGeminiAPI(text) {
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
        
        ; 顯示完整響應用於調試
        MsgBox "完整API響應：`n" . responseText
        
        ; 使用更簡單的正則表達式
        if (match := RegExMatch(responseText, '""text""\s*:\s*""(.*?)""')) {
            local result := JsonUnescape(match[1])
            MsgBox "解析成功！提取的文本：`n" . result
            return result
        } else {
            MsgBox "解析失敗！嘗試其他方法..."
            
            ; 備用解析方法 - 查找第一個包含實際內容的text字段
            if (match := RegExMatch(responseText, '""text""\s*:\s*""([^""]+)""')) {
                local result := JsonUnescape(match[1])
                MsgBox "備用方法解析成功！結果：`n" . result
                return result
            } else {
                return "錯誤：無法解析 API 返回的內容。返回原文為：" . responseText
            }
        }
    } catch Error as e {
        return "API 調用失敗：`n" . e.Message
    }
}

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

; ######################################################################################################################
; ++ 測試快捷鍵 ++
; ######################################################################################################################
; Ctrl+Alt+T: 測試網路連接
^!t::{
    try {
        local whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", "https://www.google.com", true)
        whr.Send()
        whr.WaitForResponse()
        if (whr.Status = 200) {
            MsgBox "網路連接正常！"
        } else {
            MsgBox "網路連接異常，狀態碼：" . whr.Status
        }
    } catch Error as e {
        MsgBox "網路連接測試失敗：`n" . e.Message
    }
}

; Ctrl+Alt+Y: 測試 API 調用
^!y::{
    global MyGeminiKey
    local testPrompt := "Hello, this is a test message."
    local jsonBody := '{"contents": [{"parts":[{"text": "' . testPrompt . '"}]}]}'
    local url := "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite-preview-06-17:generateContent?key=" . MyGeminiKey
    
    try {
        local whr := ComObject("WinHttp.WinHttpRequest.5.1")
        whr.Open("POST", url, true)
        whr.SetRequestHeader("Content-Type", "application/json")
        whr.Send(jsonBody)
        whr.WaitForResponse()
        local responseText := whr.ResponseText
        
        MsgBox "API 測試響應：`n" . responseText
        
        ; 使用簡單的正則表達式
        if (match := RegExMatch(responseText, '""text""\s*:\s*""(.*?)""')) {
            local result := JsonUnescape(match[1])
            MsgBox "測試成功！結果：`n" . result
        } else {
            MsgBox "測試失敗！無法解析響應。"
        }
    } catch Error as e {
        MsgBox "API 測試失敗：`n" . e.Message
    }
}
