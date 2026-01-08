# ==========================================================
# REMOTE POWERSHELL PROFILE (GitHub-hosted)
# - Branch-colored version banner + load timing
# - Fast Mode
# - Session-remembered module loading
# - Option 2 includes a second mode: User-installed only vs All installed
# - Heavy modules include VCF.PowerCLI
# ==========================================================

# --------------------------
# Profile Metadata (MANUAL)
# --------------------------
$ProfileMetadata = @{
    Name        = "Joel PowerShell Profile"
    Version     = "2.0.4"
    Branch      = "main"           # main = PROD, anything else = DEV
    Commit      = "update-me"      # short SHA recommended
    LastUpdated = "2026-01-08"     # YYYY-MM-DD
}

# --------------------------
# Profile Load Timing
# --------------------------
$script:ProfileLoadStart = Get-Date

# --------------------------
# Session State
# --------------------------
if (-not $global:SessionStartTime) { $global:SessionStartTime = Get-Date }

$global:ModuleLoadChoice = $null
$global:FastModeEnabled  = $false
$global:OhMyPoshEnabled  = $false

# --------------------------
# Heavy Modules (highlighted)
# --------------------------
$HeavyModules = @(
    "VMware.PowerCLI",
    "VCF.PowerCLI",
    "Az",
    "Microsoft.Graph",
    "ExchangeOnlineManagement",
    "SqlServer"
)

# ==========================================================
# Ensure-Module (install if missing, then import)
# ==========================================================
function Ensure-Module {
    param (
        [Parameter(Mandatory)][string]$Name
    )

    # VMware.PowerCLI tuning (safe no-op if module isn't installed yet)
    if ($Name -eq "VMware.PowerCLI") {
        Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
        Set-PowerCLIConfiguration -Scope User -InvalidCertificateAction Ignore -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
    }

    $exists = Get-Module -ListAvailable -Name $Name | Select-Object -First 1

    if (-not $exists) {
        Write-Host "📦 Installing $Name..." -ForegroundColor Yellow
        Install-Module -Name $Name -Scope CurrentUser -Force -AllowClobber -ErrorAction SilentlyContinue
    }

    Import-Module $Name -ErrorAction SilentlyContinue
    Write-Host "✅ $Name loaded" -ForegroundColor Green
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
# Module Inventory Helpers
# ==========================================================
function Get-UserModuleBasePaths {
    $paths = @()
    if ($HOME) {
        $paths += (Join-Path $HOME "Documents\PowerShell\Modules")
        $paths += (Join-Path $HOME "Documents\WindowsPowerShell\Modules")
    }

    $paths |
        Where-Object { $_ -and (Test-Path $_) } |
        Select-Object -Unique
}

function Get-AllInstalledModulesClean {
    Get-Module -ListAvailable |
        Group-Object Name |
        ForEach-Object { $_.Group | Sort-Object Version -Descending | Select-Object -First 1 } |
        Sort-Object Name
}

function Get-UserInstalledModulesClean {
    $basePaths = Get-UserModuleBasePaths

    if (-not $basePaths -or $basePaths.Count -eq 0) {
        return @()
    }

    $mods =
        Get-Module -ListAvailable |
        Where-Object {
            $p = $_.ModuleBase
            $p -and ($basePaths | Where-Object { $p -like "$_*" })
        } |
        Group-Object Name |
        ForEach-Object { $_.Group | Sort-Object Version -Descending | Select-Object -First 1 } |
        Sort-Object Name

    # Collapse VMware/VCF component modules into entry points only
    $collapsed = New-Object System.Collections.Generic.List[object]
    $seen = New-Object 'System.Collections.Generic.HashSet[string]'

    foreach ($m in $mods) {
        $name = $m.Name

        if ($name -like "VMware.*" -or $name -like "VCF.*") {
            if (($name -ne "VMware.PowerCLI") -and ($name -ne "VCF.PowerCLI")) {
                continue
            }
        }

        if (-not $seen.Add($name)) { continue }
        $collapsed.Add($m) | Out-Null
    }

    return $collapsed
}

function Select-ModuleInventoryMode {
    # Returns "User" or "All"
    Write-Host ""
    Write-Host "📚 Module inventory mode:" -ForegroundColor Cyan
    Write-Host "1) User-installed only (recommended)"
    Write-Host "2) All installed (includes inbox/built-in)"
    Write-Host ""
    $mode = Read-Host "Choose a mode (1/2)"

    if ($mode -eq "2") { return "All" }
    return "User"
}

function Show-ModuleListAndLoadSelection {
    param (
        [Parameter(Mandatory)][ValidateSet("User","All")] [string]$Mode
    )

    $mods = @()
    if ($Mode -eq "All") { $mods = Get-AllInstalledModulesClean }
    else { $mods = Get-UserInstalledModulesClean }

    if (-not $mods -or $mods.Count -eq 0) {
        if ($Mode -eq "User") {
            Write-Host "⚠ No user-installed modules found under your Documents module paths." -ForegroundColor DarkYellow
        } else {
            Write-Host "⚠ No modules found." -ForegroundColor DarkYellow
        }
        return
    }

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

function Load-AllFromMode {
    param (
        [Parameter(Mandatory)][ValidateSet("User","All")] [string]$Mode
    )

    $mods = @()
    if ($Mode -eq "All") { $mods = Get-AllInstalledModulesClean }
    else { $mods = Get-UserInstalledModulesClean }

    if (-not $mods -or $mods.Count -eq 0) {
        if ($Mode -eq "User") {
            Write-Host "⚠ No user-installed modules found under your Documents module paths." -ForegroundColor DarkYellow
        } else {
            Write-Host "⚠ No modules found." -ForegroundColor DarkYellow
        }
        return
    }

    foreach ($m in $mods) {
        Ensure-Module -Name $m.Name
    }
}

# ==========================================================
# Version Banner (branch-colored + timing)
# ==========================================================
function Show-ProfileVersionBanner {
    if ($global:FastModeEnabled) { return }

    if ($ProfileMetadata.Branch -eq "main" -or $ProfileMetadata.Branch -eq "prod") {
        $envLabel = "PROD"
        $envColor = "Green"
    } else {
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
    $global:OhMyPoshEnabled = $true
    Write-Host "✨ oh-my-posh enabled" -ForegroundColor Green
}

# ==========================================================
# Profile Health Diagnostics (uses $global:ProfileHealth from local bootstrap)
# ==========================================================
function Show-ProfileHealth {
    if (-not $global:ProfileHealth) {
        Write-Host "ℹ Profile health data not available (bootstrap not providing it)." -ForegroundColor DarkGray
        return
    }

    Write-Host ""
    Write-Host "=========== PROFILE HEALTH (REMOTE) ===========" -ForegroundColor DarkGray
    foreach ($key in $global:ProfileHealth.Keys) {
        $value = $global:ProfileHealth[$key]
        if ($value -eq $true) {
            Write-Host (" {0,-16}: {1}" -f $key, $value) -ForegroundColor Green
        }
        elseif ($value -eq $false) {
            Write-Host (" {0,-16}: {1}" -f $key, $value) -ForegroundColor Yellow
        }
        else {
            Write-Host (" {0,-16}: {1}" -f $key, $value) -ForegroundColor Gray
        }
    }
    Write-Host "==============================================" -ForegroundColor DarkGray
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
    Write-Host "4) FAST MODE"
    Write-Host "5) Enable oh-my-posh"
    Write-Host ""

    $choice = Read-Host "Choose an option (1–5)"
    $global:ModuleLoadChoice = $choice

    switch ($choice) {

        "1" {
            $mode = Select-ModuleInventoryMode
            Load-AllFromMode -Mode $mode
        }

        "2" {
            $mode = Select-ModuleInventoryMode
            Show-ModuleListAndLoadSelection -Mode $mode
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
    if ($global:FastModeEnabled) { return "❯ " }

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
