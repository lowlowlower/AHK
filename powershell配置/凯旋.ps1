

function chg {
    $chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
     & $chromePath --profile-directory="Default" "https://gemini.google.com/app"
}
function ghs {
   $chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
    # 注意看，我們不再使用 $profile 變數，而是把 "Default" 直接寫在命令裡
    & $chromePath --profile-directory="Default" "https://github.com/"
}
function xy {
   $chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
    # 注意看，我們不再使用 $profile 變數，而是把 "Default" 直接寫在命令裡
    & $chromePath --profile-directory="Default" "https://www.goofish.com/"
}
function bi {
   $chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
    # 注意看，我們不再使用 $profile 變數，而是把 "Default" 直接寫在命令裡
    & $chromePath --profile-directory="Default" "https://www.bilibili.com/"
}
Set-Location -Path "D:\SDevolpment\github"
