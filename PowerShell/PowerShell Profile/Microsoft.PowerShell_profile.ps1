# ==========================================================
# Profile Metadata (MANUAL)
# ==========================================================
$ProfileMetadata = @{
    Name        = "Joel PowerShell Profile"
    Version     = "2.0.2"
    Branch      = "main"          # main = PROD, anything else = DEV
    Commit      = "profile-fix"
    LastUpdated = "2026-01-07"
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
# Heavy Modules (highlighted)
# ==========================================================
$HeavyModules = @(
    "VMware.PowerCLI",
    "Az",
    "Microsoft.Graph",
    "ExchangeOnlineManagement",
    "SqlServer"
)

# ==========================================================
# Ensure-Module
# ==========================================================
function Ensure-Module {
    param (
        [Parameter(Mandatory)][string]$Name
    )

    if ($Name -eq "VMware.PowerCLI") {
        Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
        Set-PowerCLIConfiguration -Scope User -InvalidCertificateAction Ignore -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
    }

    if (-not (Get-Module -ListAvailable -Name $Name)) {
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
    $hour = (Get-Date).Hour
    if ($hour -lt 6) { "🌙" }
    elseif ($hour -lt 12) { "☀️" }
    elseif ($hour -lt 18) { "🌤️" }
    else { "🌆" }
}

function Get-SessionUptime {
    "{0}m" -f [math]::Floor(((Get-Date) - $global:SessionStartTime).TotalMinutes)
}

# ==========================================================
# Installed Modules (safe enumeration)
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
# Profile Version Banner (branch-aware)
# ==========================================================
function Show-ProfileVersionBanner {

    if ($global:FastModeEnabled) { return }

    if ($ProfileMetadata.Branch -eq "main") {
        $envLabel = "PROD"
        $envColor = "Green"
    }
    else {
        $envLabel = "DEV"
        $envColor = "Yellow"
    }

    $loadMs = [math]::Round(((Get-Date) - $script:ProfileLoadStart).TotalMilliseconds)

    Write-Host ""
    Write-Host "==========================================" -ForegroundColor DarkGray
    Write-Host " PowerShell Profile v$($ProfileMetadata.Version)" -ForegroundColor Cyan
    Write-Host " Environment : $envLabel ($($ProfileMetadata.Branch))" -ForegroundColor $envColor
    Write-Host " Commit      : $($ProfileMetadata.Commit)" -ForegroundColor Gray
    Write-Host " Updated     : $($ProfileMetadata.LastUpdated)" -ForegroundColor Gray
    Write-Host " Load Time   : ${loadMs}ms" -ForegroundColor Gray
    Write-Host "==========================================" -ForegroundColor DarkGray
}

# ==========================================================
# Welcome Message
# ==========================================================
function Show-WelcomeMessage {

    if ($global:FastModeEnabled) { return }

    Write-Host ""
    Write-Host "==========================================" -ForegroundColor DarkGray
    Write-Host "Good afternoon Joel $(Get-TimeIcon)" -ForegroundColor Green
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
    Write-Host "✨ oh-my-posh enabled" -ForegroundColor Green
}

# ==========================================================
# Module Load Menu (SYNTAX SAFE)
# ==========================================================
function Invoke-ModuleLoadPrompt {

    if ($global:ModuleLoadChoice) { return }

    Write-Host ""
    Write-Host "📦 Module Load Options:" -ForegroundColor Cyan
    Write-Host "1) Load ALL modules"
    Write-Host "2) Select modules"
    Write-Host "3) Load NO modules"
    Write-Host "4) FAST MODE"
    Write-Host "5) Enable oh-my-posh"
    Write-Host ""

    $choice = Read-Host "Choose an option (1–5)"
    $global:ModuleLoadChoice = $choice

    switch ($choice) {

        "1" {
            foreach ($m in Get-InstalledModulesClean) {
                Ensure-Module -Name $m.Name
            }
        }

        "2" {
            $mods = Get-InstalledModulesClean
            $indexMap = @{}
            $i = 1

            Write-Host ""
            foreach ($m in $mods) {
                $indexMap[$i] = $m.Name

                if ($HeavyModules -contains $m.Name) {
                    Write-Host "[$i] $($m.Name)  $($m.Version)  (heavy)" -ForegroundColor Yellow
                }
                else {
                    Write-Host "[$i] $($m.Name)  $($m.Version)" -ForegroundColor Gray
                }

                $i++
            }

            Write-Host ""
            $selection = Read-Host "Enter numbers (comma-separated)"

            foreach ($s in $selection -split ",") {
                $n = $s -as [int]
                if ($indexMap.ContainsKey($n)) {
                    Ensure-Module -Name $indexMap[$n]
                }
            }
        }

        "3" {
            Write-Host "⏭ Skipping module load." -ForegroundColor DarkGray
        }

        "4" {
            $global:FastModeEnabled = $true
            Write-Host "⚡ FAST MODE enabled for this session." -ForegroundColor Yellow
        }

        "5" {
            Enable-OhMyPosh
        }

        default {
            Write-Host "⚠ Invalid selection. No modules loaded." -ForegroundColor Red
        }
    }
}

# ==========================================================
# Prompt
# ==========================================================
function prompt {

    if ($global:FastModeEnabled) {
        return "❯ "
    }

    $now  = Get-Date
    $path = (Get-Location).Path
    $base = Split-Path $path -Parent
    $leaf = Split-Path $path -Leaf

    Write-Host "`n[$($now.ToString("hh:mm:ss tt"))] ⏳ $(Get-SessionUptime)" -ForegroundColor DarkGray
    Write-Host "❯ $base\" -NoNewline -ForegroundColor DarkGray
    Write-Host "$leaf>" -NoNewline -ForegroundColor Cyan

    return " "
}

# ==========================================================
# Startup Order
# ==========================================================
Show-ProfileVersionBanner
Show-WelcomeMessage
Invoke-ModuleLoadPrompt
