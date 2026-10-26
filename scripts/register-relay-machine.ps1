param(
    [string]$InstallDir = (Join-Path $env:USERPROFILE "ClaudeProfiles")
)

$identity = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $identity.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Run this script from an elevated PowerShell (Run as administrator)."
}

$relayExe = Join-Path $InstallDir "ClaudeRelay.exe"
$iconPath = Join-Path $InstallDir "icons\claude-work.ico"
if (-not (Test-Path $relayExe)) { throw "ClaudeRelay.exe not found in $InstallDir. Run install.ps1 first." }

$command = '"{0}" "%1"' -f $relayExe

$progIdKey = "HKLM:\Software\Classes\ClaudeRelay.Url"
New-Item -Path $progIdKey -Force | Out-Null
Set-ItemProperty -Path $progIdKey -Name '(default)' -Value "URL:Claude Relay"
Set-ItemProperty -Path $progIdKey -Name "URL Protocol" -Value ""
New-Item -Path "$progIdKey\DefaultIcon" -Force | Out-Null
Set-ItemProperty -Path "$progIdKey\DefaultIcon" -Name '(default)' -Value $iconPath
New-Item -Path "$progIdKey\shell\open\command" -Force | Out-Null
Set-ItemProperty -Path "$progIdKey\shell\open\command" -Name '(default)' -Value $command

$capabilitiesKey = "HKLM:\Software\ClaudeRelay\Capabilities"
New-Item -Path $capabilitiesKey -Force | Out-Null
Set-ItemProperty -Path $capabilitiesKey -Name "ApplicationName" -Value "Claude Relay"
Set-ItemProperty -Path $capabilitiesKey -Name "ApplicationDescription" -Value "Routes claude:// links to the personal or work Claude Desktop profile"
Set-ItemProperty -Path $capabilitiesKey -Name "ApplicationIcon" -Value $iconPath
New-Item -Path "$capabilitiesKey\URLAssociations" -Force | Out-Null
Set-ItemProperty -Path "$capabilitiesKey\URLAssociations" -Name "claude" -Value "ClaudeRelay.Url"

Set-ItemProperty -Path "HKLM:\Software\RegisteredApplications" -Name "ClaudeRelay" -Value "Software\ClaudeRelay\Capabilities"

Write-Host "Registered. Open Settings > Apps > Default apps, search for 'claude',"
Write-Host "open the 'claude' link type and pick 'Claude Relay'."
