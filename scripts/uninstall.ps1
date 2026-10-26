param(
    [string]$InstallDir = (Join-Path $env:USERPROFILE "ClaudeProfiles"),
    [string]$ShortcutDir = [Environment]::GetFolderPath("Desktop")
)

foreach ($name in "Claude Personal.lnk", "Claude Work.lnk", "Claude Work - First login.lnk") {
    Remove-Item (Join-Path $ShortcutDir $name) -ErrorAction SilentlyContinue
}

$identity = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if ($identity.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Remove-ItemProperty -Path "HKLM:\Software\RegisteredApplications" -Name "ClaudeRelay" -ErrorAction SilentlyContinue
    Remove-Item -Path "HKLM:\Software\ClaudeRelay" -Recurse -ErrorAction SilentlyContinue
    Remove-Item -Path "HKLM:\Software\Classes\ClaudeRelay.Url" -Recurse -ErrorAction SilentlyContinue
    Write-Host "Removed the Claude Relay registry entries."
}
else {
    Write-Host "Not elevated: the Claude Relay registry entries were left in place."
    Write-Host "Before removing them, set the default app for 'claude' links back to Claude."
}

Remove-Item $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Removed shortcuts and $InstallDir."
Write-Host "Your work profile data folder was not touched."
