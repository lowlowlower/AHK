#Requires AutoHotkey v2.0
#Warn ; 推薦啟用，幫助捕捉常見錯誤
SendMode "Input" ; 使用更可靠的發送模式
SetWorkingDir A_ScriptDir ; 確保腳本在當前文件夾下運行

; ######################################################################################################################
; ++ 用戶配置區 ++
; ######################################################################################################################

; 1. 在此處貼上你的 Gemini API 金鑰
MyGeminiKey := "AIzaSyDmfaMC3pHdY6BYCvL_1pWZF5NLLkh28QU"

; 2. 自定義你的指令 (Prompt)。"{1}" 將會被替換為你選中的文本。
;    v2 中推薦使用 Format() 函數來格式化字符串，比 v1 的 %s% 更強大。
MyPrompt := "請將以下內容翻譯成英文：``{1}``"
; MyPrompt := "請用條列式總結以下內容的重點：`{1}`"
; MyPrompt := "請用更正式、更專業的語氣改寫這段話：`{1}`"
; MyPrompt := "Explain what this code does in Traditional Chinese: `{1}`"

; ######################################################################################################################
; ++ 快捷鍵設置 ++
; ######################################################################################################################

^!c::{ ; Ctrl+Alt+T
    ; -- 備份剪貼板 --
    local clipSaved := ClipboardAll()

    ; -- 複製選中的文本 --
    A_Clipboard := "" ; 清空剪貼板
    Send "^c"
    if !ClipWait(1) { ; ClipWait 現在是一個函數，返回 1 (true) 或 0 (false)
        MsgBox "複製文本失敗或沒有選中文本。"
        A_Clipboard := clipSaved ; 恢復剪貼板
        return
    }

    local selectedText := A_Clipboard

    ; -- 調用 Gemini API --
    local geminiResponse := CallGeminiAPI(selectedText)

    if (geminiResponse != "") {
        ; -- 在光標位置輸入結果 --
        SendInput geminiResponse ; v2 中可以直接發送變量，無需百分號
    } else {
        MsgBox "調用 Gemini API 失敗，請檢查網絡、API 金鑰或腳本錯誤。"
    }

    ; -- 恢復剪貼板 --
    A_Clipboard := clipSaved
}

; ======================================================================================================================
; ++ 調用 Gemini API 的函數 ++
; ======================================================================================================================
CallGeminiAPI(text) {
    global MyGeminiKey, MyPrompt ; 聲明我們要使用文件頂層定義的全局變量

    ; -- 構造完整的請求指令 --
    local fullPrompt := Format(MyPrompt, text)
    
    ; -- 準備請求體 (JSON Body) --
    local escapedPrompt := JsonEscape(fullPrompt)
    local jsonBody := '{"contents": [{"parts":[{"text": "' . escapedPrompt . '"}]}]}'

    ; -- 準備 URL --
    local url := "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite-preview-06-17:generateContent?key=" . MyGeminiKey

    try {
        ; 創建 HTTP 請求對象
        local whr := ComObject("WinHttp.WinHttpRequest.5.1")
        
        ; 設置請求參數
        whr.Open("POST", url, true)
        whr.SetRequestHeader("Content-Type", "application/json")
        
        ; 發送請求
        whr.Send(jsonBody)
        whr.WaitForResponse()

        ; -- 解析返回的 JSON 數據 --
        local responseText := whr.ResponseText
        ; v2 的 RegExMatch 返回一個匹配對象 (Match Object)
        if (match := RegExMatch(responseText, 's)""text""\s*:\s*""(.*?)""')) {
            ; 匹配到的第一個子模式在 match[1] 中
            return JsonUnescape(match[1])
        } else {
            return "錯誤：無法解析 API 返回的內容。返回原文為：" . responseText
        }
    } catch {
        return "" ; 如果請求過程出錯，返回空
    }
}

; ======================================================================================================================
; ++ 輔助函數 ++
; ======================================================================================================================

; -- 對字符串進行 JSON 轉義 --
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

; -- 還原 Gemini 返回文本中的轉義字符 --
JsonUnescape(str) {
    str := StrReplace(str, "\\n", "`n")
    str := StrReplace(str, '\"', '"')
    str := StrReplace(str, '\\', '\')
    return str
}