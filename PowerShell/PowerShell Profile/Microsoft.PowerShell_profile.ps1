# ==========================================================
# Profile Metadata (MANUAL – update when you commit)
# ==========================================================
$ProfileMetadata = @{
    Name        = "Joel PowerShell Profile"
    Version     = "2.0.0"
    Branch      = "main"          # main = PROD, anything else = DEV
    Commit      = "a3f92c1"       # short SHA from GitHub
    LastUpdated = "2026-01-07"    # YYYY-MM-DD
}

# ==========================================================
# Profile Load Timing
# ==========================================================
$script:ProfileLoadStart = Get-Date

# ==========================================================
# Session State
# ==========================================================
if (-not $global:SessionStartTime) {
    $global:SessionStartTime = Get-Date
}

$global:ModuleLoadChoice = $null
$global:FastModeEnabled  = $false
$global:OhMyPoshEnabled  = $false

# ==========================================================
# Heavy Modules (highlighted in selector)
# ==========================================================
$HeavyModules = @(
    "VMware.PowerCLI",
    "Az",
    "Microsoft.Graph",
    "ExchangeOnlineManagement",
    "SqlServer"
)

# ==========================================================
# Ensure-Module (install + import)
# ==========================================================
function Ensure-Module {
    param (
        [Parameter(Mandatory)][string]$Name
    )

    if ($Name -eq "VMware.PowerCLI") {
        Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
        Set-PowerCLIConfiguration -Scope User -InvalidCertificateAction Ignore -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
    }

    $installed = Get-Module -ListAvailable -Name $Name |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if (-not $installed) {
        Write-Host "📦 Installing $Name..." -ForegroundColor Yellow
        Install-Module -Name $Name -Scope CurrentUser -Force -AllowClobber -ErrorAction SilentlyContinue
    }

    Import-Module $Name -ErrorAction SilentlyContinue
    Write-Host "✅ $Name loaded successfully" -ForegroundColor Green
}

# ==========================================================
# Utilities
# ==========================================================
function Get-TimeIcon {
    switch ((Get-Date).Hour) {
        { $_ -lt 6 }  { "🌙" }
        { $_ -lt 12 } { "☀️" }
        { $_ -lt 18 } { "🌤️" }
        default       { "🌆" }
    }
}

function Get-SessionUptime {
    "{0}m" -f [math]::Floor(((Get-Date) - $global:SessionStartTime).TotalMinutes)
}

# ==========================================================
# Installed Modules (deduped + sorted)
# ==========================================================
function Get-InstalledModulesClean {
    Get-Module -ListAvailable |
        Group-Object Name |
        ForEach-Object {
            $_.Group | Sort-Object Version -Descending | Select-Object -First 1
        } |
        Sort-Object Name
}

# ==========================================================
# Profile Version Banner (branch-aware + timing)
# ==========================================================
function Show-ProfileVersionBanner {

    if ($global:FastModeEnabled) { return }

    switch ($ProfileMetadata.Branch.ToLower()) {
        "main" { $envLabel = "PROD"; $envColor = "Green" }
        "prod" { $envLabel = "PROD"; $envColor = "Green" }
        default { $envLabel = "DEV"; $envColor = "Yellow" }
    }

    $loadTimeMs = [math]::Round(((Get-Date) - $script:ProfileLoadStart).TotalMilliseconds)

    Write-Host ""
    Write-Host "==========================================" -ForegroundColor DarkGray
    Write-Host " PowerShell Profile v$($ProfileMetadata.Version)" -ForegroundColor Cyan
    Write-Host " Environment : $envLabel ($($ProfileMetadata.Branch))" -ForegroundColor $envColor
    Write-Host " Commit      : $($ProfileMetadata.Commit)" -ForegroundColor Gray
    Write-Host " Updated     : $($ProfileMetadata.LastUpdated)" -ForegroundColor Gray
    Write-Host " Load Time   : ${loadTimeMs}ms" -ForegroundColor Gray
    Write-Host "==========================================" -ForegroundColor DarkGray
}

# ==========================================================
# Welcome Message
# ==========================================================
function Show-WelcomeMessage {

    if ($global:FastModeEnabled) { return }

    $icon = Get-TimeIcon

    Write-Host ""
    Write-Host "==========================================" -ForegroundColor DarkGray
    Write-Host "Good afternoon Joel $icon" -ForegroundColor Green
    Write-Host "Welcome to PowerShell! Create your future." -ForegroundColor Magenta
    Write-Host "==========================================" -ForegroundColor DarkGray
}

# ==========================================================
# oh-my-posh Toggle
# ==========================================================
function Enable-OhMyPosh {

    if ($global:FastModeEnabled) {
        Write-Host "⚡ Fast Mode active. oh-my-posh skipped." -ForegroundColor DarkYellow
        return
    }

    if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
        Write-Host "⚠ oh-my-posh not installed." -ForegroundColor DarkYellow
        return
    }

    oh-my-posh init pwsh | Invoke-Expression
    $global:OhMyPoshEnabled = $true

    Write-Host "✨ oh-my-posh enabled" -ForegroundColor Green
}

# ==========================================================
# Module Load Menu (session-remembered)
# ==========================================================
function Invoke-ModuleLoadPrompt {

    if ($global:ModuleLoadChoice) { return }

    Write-Host ""
    Write-Host "📦 Module Load Options:" -ForegroundColor Cyan
    Write-Host "1) Load ALL modules"
    Write-Host "2) Select modules"
    Write-Host "3) Load NO modules"
    Write-Host "4) FAST MODE (skip everything)" -ForegroundColor Yellow
    Write-Host "5) Enable oh-my-posh"
    Write-Host ""

    $choice = Read-Host "Choose an option (1–5)"
    $global:ModuleLoadChoice = $choice

    switch ($choice) {

        "1" {
            Get-InstalledModulesClean | ForEach-Object {
                Ensure-Module -Name $_.Name
            }
        }

        "2" {
            $mods = Get-InstalledModulesClean

            Write-Host "`n📦 Installed PowerShell Modules:`n" -ForegroundColor Cyan

            for ($i = 0; $i -lt $m
