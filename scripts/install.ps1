param(
    [string]$InstallDir = (Join-Path $env:USERPROFILE "ClaudeProfiles"),
    [string]$WorkProfileDir = (Join-Path $env:APPDATA "Claude-Work"),
    [string]$ShortcutDir = [Environment]::GetFolderPath("Desktop")
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$repoRoot = Split-Path $PSScriptRoot -Parent
$launcher = Join-Path $env:LOCALAPPDATA "Microsoft\WindowsApps\claude-desktop.exe"
$csc = Join-Path $env:WINDIR "Microsoft.NET\Framework64\v4.0.30319\csc.exe"
$package = Get-AppxPackage | Where-Object Name -eq "Claude" | Select-Object -First 1

if (-not $package) { throw "Claude Desktop (MSIX / Microsoft Store build) was not found." }
if (-not (Test-Path $launcher)) { throw "Execution alias not found: $launcher" }
if (-not (Test-Path $csc)) { throw ".NET Framework compiler not found: $csc" }

$sourcePng = Join-Path $package.InstallLocation "Assets\Square44x44Logo.targetsize-256.png"
$iconDir = Join-Path $InstallDir "icons"
New-Item -ItemType Directory -Force $iconDir | Out-Null

function Save-IcoFromBitmap($bitmap, $path) {
    $ms = New-Object System.IO.MemoryStream
    $bitmap.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $png = $ms.ToArray()
    $fs = [System.IO.File]::Create($path)
    $bw = New-Object System.IO.BinaryWriter($fs)
    $bw.Write([uint16]0); $bw.Write([uint16]1); $bw.Write([uint16]1)
    $bw.Write([byte]0); $bw.Write([byte]0); $bw.Write([byte]0); $bw.Write([byte]0)
    $bw.Write([uint16]1); $bw.Write([uint16]32)
    $bw.Write([uint32]$png.Length); $bw.Write([uint32]22)
    $bw.Write($png)
    $bw.Close(); $fs.Close()
}

$original = New-Object System.Drawing.Bitmap($sourcePng)
$blue = New-Object System.Drawing.Bitmap($original.Width, $original.Height)
for ($x = 0; $x -lt $original.Width; $x++) {
    for ($y = 0; $y -lt $original.Height; $y++) {
        $p = $original.GetPixel($x, $y)
        $blue.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($p.A, $p.B, $p.G, $p.R))
    }
}
$workIcon = Join-Path $iconDir "claude-work.ico"
$personalIcon = Join-Path $iconDir "claude-personal.ico"
Save-IcoFromBitmap $original $workIcon
Save-IcoFromBitmap $blue $personalIcon
$original.Dispose(); $blue.Dispose()

$relayExe = Join-Path $InstallDir "ClaudeRelay.exe"
& $csc /nologo /target:winexe /out:$relayExe /win32icon:$workIcon (Join-Path $repoRoot "src\ClaudeRelay.cs")
if (-not (Test-Path $relayExe)) {
    & $csc /nologo /target:winexe /out:$relayExe (Join-Path $repoRoot "src\ClaudeRelay.cs")
}
if (-not (Test-Path $relayExe)) { throw "Failed to compile ClaudeRelay.exe" }

Set-Content -Path (Join-Path $InstallDir "work-profile.txt") -Value $WorkProfileDir
Copy-Item (Join-Path $PSScriptRoot "work-login.ps1") (Join-Path $InstallDir "work-login.ps1") -Force

$shell = New-Object -ComObject WScript.Shell

$personal = $shell.CreateShortcut((Join-Path $ShortcutDir "Claude Personal.lnk"))
$personal.TargetPath = $launcher
$personal.IconLocation = $personalIcon
$personal.Save()

$work = $shell.CreateShortcut((Join-Path $ShortcutDir "Claude Work.lnk"))
$work.TargetPath = $launcher
$work.Arguments = "--user-data-dir=`"$WorkProfileDir`""
$work.IconLocation = $workIcon
$work.Save()

$firstLogin = $shell.CreateShortcut((Join-Path $ShortcutDir "Claude Work - First login.lnk"))
$firstLogin.TargetPath = "powershell.exe"
$firstLogin.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$(Join-Path $InstallDir 'work-login.ps1')`""
$firstLogin.IconLocation = $workIcon
$firstLogin.Save()

Write-Host "Installed to $InstallDir"
Write-Host "Shortcuts created in $ShortcutDir"
Write-Host ""
Write-Host "Next: run scripts\register-relay-machine.ps1 from an elevated PowerShell,"
Write-Host "then set 'Claude Relay' as the default app for the 'claude' link type."
