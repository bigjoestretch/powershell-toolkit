# ==========================================================
# REMOTE POWERSHELL PROFILE (GitHub-hosted)
# ==========================================================

# --------------------------
# Profile Metadata (MANUAL)
# --------------------------
$ProfileMetadata = @{
    Name        = "Joel PowerShell Profile"
    Version     = "1.9.1"
    Branch      = "main"
    Commit      = "remove-omp-option"
    LastUpdated = "2026-01-08"
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
# Heavy Modules
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
# Ensure-Module
# ==========================================================
function Ensure-Module {
    param ([Parameter(Mandatory)][string]$Name)

    if ($Name -eq "VMware.PowerCLI") {
        Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
        Set-PowerCLIConfiguration -Scope User -InvalidCertificateAction Ignore -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
    }

    if (-not (Get-Module -ListAvailable -Name $Name)) {
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
    $h = (Get-Date).Hour
    if ($h -lt 6) { "🌙" } elseif ($h -lt 12) { "☀️" } elseif ($h -lt 18) { "🌤️" } else { "🌆" }
}

function Get-SessionUptime {
    "{0}m" -f [math]::Floor(((Get-Date) - $global:SessionStartTime).TotalMinutes)
}

# ==========================================================
# Module Inventory
# ==========================================================
function Get-UserModuleBasePaths {
    @(
        Join-Path $HOME "Documents\PowerShell\Modules"
        Join-Path $HOME "Documents\WindowsPowerShell\Modules"
    ) | Where-Object { Test-Path $_ }
}

function Get-AllInstalledModulesClean {
    Get-Module -ListAvailable |
        Group-Object Name |
        ForEach-Object { $_.Group | Sort-Object Version -Descending | Select-Object -First 1 } |
        Sort-Object Name
}

function Get-UserInstalledModulesClean {
    $paths = Get-UserModuleBasePaths
    if (-not $paths) { return @() }

    $mods =
        Get-Module -ListAvailable |
        Where-Object {
            $p = $_.ModuleBase
            $p -and ($paths | Where-Object { $p -like "$_*" })
        } |
        Group-Object Name |
        ForEach-Object { $_.Group | Sort-Object Version -Descending | Select-Object -First 1 } |
        Sort-Object Name

    $out = @()
    foreach ($m in $mods) {
        if ($m.Name -like "VMware.*" -or $m.Name -like "VCF.*") {
            if ($m.Name -notin @("VMware.PowerCLI","VCF.PowerCLI")) { continue }
        }
        $out += $m
    }
    $out
}

function Select-ModuleInventoryMode {
    Write-Host ""
    Write-Host "📚 Module inventory mode:" -ForegroundColor Cyan
    Write-Host "1) User-installed only (recommended)"
    Write-Host "2) All installed"
    Write-Host ""
    if ((Read-Host "Choose a mode (1/2)") -eq "2") { "All" } else { "User" }
}

function Show-ModuleListAndLoadSelection {
    param ([ValidateSet("User","All")]$Mode)

    $mods = if ($Mode -eq "All") { Get-AllInstalledModulesClean } else { Get-UserInstalledModulesClean }
    if (-not $mods) {
        Write-Host "⚠ No modules found for mode [$Mode]" -ForegroundColor DarkYellow
        return
    }

    $map = @{}
    $i = 1
    Write-Host ""
    foreach ($m in $mods) {
        $map[$i] = $m.Name
        if ($HeavyModules -contains $m.Name) {
            Write-Host "[$i] $($m.Name)  $($m.Version)  (heavy)" -ForegroundColor Yellow
        } else {
            Write-Host "[$i] $($m.Name)  $($m.Version)" -ForegroundColor Gray
        }
        $i++
    }

    Write-Host ""
    foreach ($n in (Read-Host "Enter numbers (comma-separated)" -split ",")) {
        if ($map.ContainsKey([int]$n)) {
            Ensure-Module $map[[int]$n]
        }
    }
}

function Load-AllFromMode {
    param ([ValidateSet("User","All")]$Mode)
    foreach ($m in (if ($Mode -eq "All") { Get-AllInstalledModulesClean } else { Get-UserInstalledModulesClean })) {
        Ensure-Module $m.Name
    }
}

# ==========================================================
# Banner + Welcome
# ==========================================================
function Show-ProfileVersionBanner {
    if ($global:FastModeEnabled) { return }

    $envColor = if ($ProfileMetadata.Branch -in @("main","prod")) { "Green" } else { "Yellow" }
    $envLabel = if ($envColor -eq "Green") { "PROD" } else { "DEV" }
    $ms = [math]::Round(((Get-Date) - $script:ProfileLoadStart).TotalMilliseconds)

    Write-Host ""
    Write-Host "==========================================" -ForegroundColor DarkGray
    Write-Host " PowerShell Profile v$($ProfileMetadata.Version)" -ForegroundColor Cyan
    Write-Host " Environment : $envLabel ($($ProfileMetadata.Branch))" -ForegroundColor $envColor
    Write-Host " Commit      : $($ProfileMetadata.Commit)" -ForegroundColor Gray
    Write-Host " Updated     : $($ProfileMetadata.LastUpdated)" -ForegroundColor Gray
    Write-Host " Load Time   : ${ms}ms" -ForegroundColor Gray
    Write-Host "==========================================" -ForegroundColor DarkGray
}

function Show-WelcomeMessage {
    if ($global:FastModeEnabled) { return }

    Write-Host ""
    Write-Host "==========================================" -ForegroundColor DarkGray
    Write-Host "Good afternoon Joel $(Get-TimeIcon)" -ForegroundColor Green
    Write-Host "Welcome to PowerShell! Create your future." -ForegroundColor Magenta
    Write-Host "==========================================" -ForegroundColor DarkGray
}

# ==========================================================
# Module Load Menu
# ==========================================================
function Invoke-ModuleLoadPrompt {
    if ($global:ModuleLoadChoice) { return }

    Write-Host ""
    Write-Host "📦 Module Load Options:" -ForegroundColor Cyan
    Write-Host "1) Load ALL modules"
    Write-Host "2) Select modules"
    Write-Host "3) Load NO modules"
    Write-Host "4) FAST MODE"
    Write-Host ""

    $choice = Read-Host "Choose an option (1–4)"
    $global:ModuleLoadChoice = $choice

    switch ($choice) {
        "1" { Load-AllFromMode (Select-ModuleInventoryMode) }
        "2" { Show-ModuleListAndLoadSelection (Select-ModuleInventoryMode) }
        "3" { Write-Host "⏭ Skipping module load." -ForegroundColor DarkGray }
        "4" {
            $global:FastModeEnabled = $true
            Write-Host "⚡ FAST MODE enabled for this session." -ForegroundColor Yellow
        }
        default {
            Write-Host "⚠ Invalid selection." -ForegroundColor Red
        }
    }
}

# ==========================================================
# Prompt
# ==========================================================
function prompt {
    if ($global:FastModeEnabled) { return "❯ " }

    $now = Get-Date
    $path = Get-Location
    Write-Host "`n[$($now.ToString("hh:mm:ss tt"))] ⏳ $(Get-SessionUptime)" -ForegroundColor DarkGray
    Write-Host "❯ $($path.Path)>" -NoNewline -ForegroundColor Cyan
    return " "
}

# ==========================================================
# Startup Order
# ==========================================================
Show-ProfileVersionBanner
Show-WelcomeMessage
Invoke-ModuleLoadPrompt
