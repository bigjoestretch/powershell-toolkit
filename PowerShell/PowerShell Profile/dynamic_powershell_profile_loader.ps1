# ==============================
# Bootstrap: Pull & Load PowerShell profile from GitHub
# ==============================

if (-not $env:PS_FAST_MODE) {

    $remoteProfile = 'https://raw.githubusercontent.com/bigjoestretch/public/main/PowerShell/PowerShell%20Profile/Microsoft.PowerShell_profile.ps1'
    $tempProfile   = Join-Path $env:TEMP 'remote_profile.ps1'

    try {
        Invoke-RestMethod -Uri $remoteProfile -OutFile $tempProfile -ErrorAction Stop
        . $tempProfile
        Write-Host "✅ Remote PowerShell profile loaded from bigjoestretch's GitHub" -ForegroundColor Green
    }
    catch {
        Write-Warning "⚠ Failed to load remote PowerShell profile: $_"
    }
}
