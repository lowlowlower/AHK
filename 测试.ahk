#Requires AutoHotkey v2.0
#Warn
SendMode "Input"
SetWorkingDir A_ScriptDir

; ######################################################################################################################
; ++ 腳本初始化：創建全局 JSON 解析器 ++
; ######################################################################################################################
global JSON_Parser := (doc := ComObject("HTMLFile"), doc.write("<meta http-equiv='X-UA-Compatible' content='IE=Edge'>"), doc.parentWindow.JSON)


; ######################################################################################################################
; ++ 用戶配置區 ++
; ######################################################################################################################
MyGeminiKey := "AIzaSyDmfaMC3pHdY6BYCvL_1pWZF5NLLkh28QU" ; <--- 記得換成你自己的金鑰
MyPrompt := "請將以下內容翻譯成英文：``{1}``" ; <--- 修正了反引號

; ######################################################################################################################
; ++ 快捷鍵設置 ++  天空
; ######################################################################################################################
^!g::{
    MsgBox "检查点 1: 快捷键已触发。"
    local clipSaved := ClipboardAll()
    A_Clipboard := ""
    Send "^c"
    if !ClipWait(1) {
        MsgBox "错误: 复制文本超时或失败。请确保已选中文本。"
        A_Clipboard := clipSaved
        return
    }
    local selectedText := A_Clipboard
    if (selectedText = "") {
        MsgBox "错误: 复制的文本为空。"
        A_Clipboard := clipSaved
        return
    }
    MsgBox "检查点 2: 已复制文本内容：`n--内容开始--`n" . selectedText . "`n--内容结束--"
    
    MsgBox "检查点 3: 准备调用 Gemini API..."
    local geminiResponse := CallGeminiAPI(selectedText)
    MsgBox "检查点 4: API 调用完成。`n最终拿到的内容是：`n" . geminiResponse
    
    if (geminiResponse != "" and !InStr(geminiResponse, "錯誤：") and !InStr(geminiResponse, "错误：")) {
        MsgBox "检查点 5: 内容看起来没问题，准备输入到光标位置..."
        SendInput geminiResponse
    } else {
        MsgBox "最终结果是错误信息或为空，不执行输入操作。`n`n内容：`n" . geminiResponse
    }
    A_Clipboard := clipSaved
}

; (下方的 CallGeminiAPI, JsonEscape, JsonUnescape 函數保持不變)
CallGeminiAPI(text) {
    global MyGeminiKey, MyPrompt, JSON_Parser
    local fullPrompt := Format(MyPrompt, text)
    local escapedPrompt := JsonEscape(fullPrompt)
    local jsonBody := '{"contents": [{"parts":[{"text": "' . escapedPrompt . '"}]}]}'
    ; 更新为更稳定的 gemini-1.5-flash-latest 模型
    local url := "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=" . MyGeminiKey
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
        local size := responseBody.MaxIndex() + 1
        if (size = 0) {
            return "错误：API 返回了空内容。"
        }
        ; 必须明确提供长度，因为 ResponseBody 不是 null 结尾的字符串
        local responseText := StrGet(responseBody.Ptr, size, "UTF-8")

        MsgBox "API 返回原文：`n" . responseText ; 调试：显示API的原始返回内容
        
        try {
            ; 使用 JSON 解析器對象
            local jsonObj := JSON_Parser.parse(responseText)
            
            ; 检查是否存在错误信息
            if (jsonObj.HasOwnProp("error")) {
                return "错误：API 返回错误。`nDetails: " . jsonObj.error.message
            }
            
            ; 检查 'candidates' 是否存在且为数组
            if (!jsonObj.HasOwnProp("candidates") || jsonObj.candidates.Length = 0) {
                return "错误：API 返回的数据中不包含 'candidates'。`n返回原文为：" . responseText
            }

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