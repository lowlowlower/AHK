Import-Module PSFzf
function OpenGeminiProfile4 {
    start-process -FilePath "chrome.exe" -ArgumentList '--profile-directory="Profile 4"', "https://gemini.google.com/app"
}
function githubStars {
    start-process -FilePath "chrome.exe" -ArgumentList '--profile-directory="Profile 4"', "https://github.com/lowlowlower?tab=stars"
}
function googledriver {
    start-process -FilePath "chrome.exe" -ArgumentList '--profile-directory="Profile 4"', "https://drive.google.com/drive/my-drive"
}
function supabase1 {
    start-process -FilePath "chrome.exe" -ArgumentList '--profile-directory="Default"', "https://supabase.com/dashboard/project/urfibhtfqgffpanpsjds/editor/86162?schema=public"
}
function bi {
    start-process -FilePath "chrome.exe" -ArgumentList '--profile-directory="Profile 4"', "https://space.bilibili.com/675652672/favlist?fid=1051841572&ftype=create"
}
Set-Location -Path "D:\github"
Set-Alias -Name ty -Value "C:\Program Files\Typora\Typora.exe"
Set-Alias -Name dc -Value "C:\Program Files\Docker\Docker\Docker Desktop.exe"
Set-Alias -Name ch -Value "C:\Program Files\Google\Chrome\Application\chrome.exe"
Set-Alias -Name chg -Value OpenGeminiProfile4
Set-Alias -Name ghs -Value githubStars
Set-Alias -Name chd -Value googledriver
Set-Alias -Name sup -Value supabase1
Set-Alias -Name bif -Value bi



