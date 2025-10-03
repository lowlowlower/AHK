; ======================================================================================================================
; 这个脚本使用 Chrome.ahk 库来对 Chrome 标签页进行高级控制.
;
; !! 前提条件 !!
; 1. 下载 Chrome.ahk 库:
;    请从 GitHub 下载 Chrome.ahk 文件并将其放置在脚本目录下的 "lib" 文件夹中.
;    例如: D:\github\AHK\lib\Chrome.ahk
;
; 2. 以调试模式启动 Chrome:
;    你需要创建一个 Chrome 的快捷方式, 并在其 "目标" 字段中添加启动参数.
;    "C:\Program Files\Google\Chrome\Application\chrome.exe" --remote-debugging-port=9222
;    每次使用此脚本前, 都需要通过这个快捷方式来启动 Chrome.
; ======================================================================================================================

#Include <Chrome> ; 从 lib 文件夹加载 Chrome.ahk 库

#SingleInstance, Force
SetTitleMatchMode, 2



; --- 配置区 ---
; 在这里定义你想要快速访问的网站
; 格式: Hotkey::NavigateToTab("URL Substring", "Full URL")

; 示例:
; Alt + G -> Gmail
!g::NavigateToTab("mail.google.com", "https://mail.google.com")

; Alt + H -> GitHub
!h::NavigateToTab("github.com", "https://github.com")

; Alt + Y -> YouTube
!y::NavigateToTab("youtube.com", "https://www.youtube.com")

MsgBox, 智能标签页导航脚本 (Chrome.ahk 版) 已加载.`n`n快捷键示例:`nAlt+G: Gmail`nAlt+H: GitHub`nAlt+Y: YouTube
return ; 结束自动执行区域

; --- 核心功能函数 ---

NavigateToTab(urlSubstring, fullUrl) {
    local Chrome, Page
    try {
        ; 连接到正在运行的 Chrome 实例
        Chrome := new Chrome()
    } catch e {
        ; 如果连接失败 (很可能是 Chrome 没有以调试模式启动)
        MsgBox, 48, 错误, 无法连接到 Chrome 实例.`n`n请确保:`n1. Chrome 正在运行.`n2. Chrome 是通过 --remote-debugging-port=9222 参数启动的.
        Run, chrome.exe "%fullUrl%" ; 作为备用方案, 直接打开
        return
    }

    ; 获取所有已打开的标签页
    Pages := Chrome.GetPages()
    for index, page in Pages
    {
        ; 检查 URL 是否包含我们想要的子字符串
        if InStr(page.url, urlSubstring)
        {
            ; 如果找到了匹配的标签页, 激活它然后返回
            page.Activate()
            return
        }
    }

    ; 如果循环结束还没有找到, 就打开一个新的标签页
    try {
        Page := Chrome.NewTab()
        Page.Navigate(fullUrl)
    } catch e {
        MsgBox, 48, 错误, 创建或导航到新标签页时出错.
    }
}
