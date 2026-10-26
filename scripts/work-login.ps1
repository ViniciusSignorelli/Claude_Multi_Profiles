$flagFile = Join-Path $PSScriptRoot "work-login.flag"
$workProfile = (Get-Content (Join-Path $PSScriptRoot "work-profile.txt") -Raw).Trim()
$launcher = Join-Path $env:LOCALAPPDATA "Microsoft\WindowsApps\claude-desktop.exe"

Set-Content -Path $flagFile -Value (Get-Date -Format s)

try {
    Start-Process $launcher -ArgumentList "--user-data-dir=`"$workProfile`""
    Write-Host "Opening the work window..."
    Write-Host ""
    Write-Host "Sign in inside the WORK window."
    Write-Host "The browser callback will be routed to it."
    Write-Host ""
    Read-Host "Once you are signed in, press Enter here to go back to normal mode"
}
finally {
    Remove-Item $flagFile -ErrorAction SilentlyContinue
    Write-Host "claude:// links go to the personal profile again."
}
