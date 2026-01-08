# ==========================================================
# REMOTE POWERSHELL PROFILE (GitHub-hosted)
# VMware / VCF PowerCLI–focused
# ==========================================================

# --------------------------
# Profile Metadata
# --------------------------
$ProfileMetadata = @{
    Name        = "Joel PowerShell Profile"
    Version     = "2.0.1"
    Branch      = "main"
    Commit      = "vmware-selector-fix"
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

# --------------------------
# VMware Modules (authoritative list)
# --------------------------
$VmwareModules = @(
    "VCF.PowerCLI",
    "VMware.PowerCLI"
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

    if (Get-Module -Name $Name) {
        Write-Host "✅ $Name loaded" -ForegroundColor Green
    }
    else {
        Write-Host "⚠ Failed to load $Name" -ForegroundColor DarkYellow
    }
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

function Get-ModuleVersionSafe {
    param ([string]$Name)
    (Get-Module -ListAvailable -Name $Name |
        Sort-Object Version -Descending |
        Select-Object -First 1).Version
}

# ==========================================================
# Banner
# ==========================================================
function Show-ProfileVersionBanner {
    if ($global:FastModeEnabled) { return }

    $isProd = $ProfileMetadata.Branch -in @("main","prod")
    $envLabel = if ($isProd) { "PROD" } else { "DEV" }
    $envColor = if ($isProd) { "Green" } else { "Yellow" }
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
# Module Load Menu (VMware-only)
# ==========================================================
function Invoke-ModuleLoadPrompt {
    if ($global:ModuleLoadChoice) { return }

    Write-Host ""
    Write-Host "📦 Module Load Options:" -ForegroundColor Cyan
    Write-Host "1) Load ALL modules (VMware + VCF)"
    Write-Host "2) Select modules"
    Write-Host "3) Load NO modules"
    Write-Host "4) FAST MODE"
    Write-Host ""

    $choice = Read-Host "Choose an option (1–4)"
    $global:ModuleLoadChoice = $choice

    switch ($choice) {

        "1" {
            foreach ($m in $VmwareModules) {
                Ensure-Module $m
            }
        }

        "2" {
            $vcfVer = Get-ModuleVersionSafe "VCF.PowerCLI"
            $vmwVer = Get-ModuleVersionSafe "VMware.PowerCLI"

            Write-Host ""
            Write-Host "Select VMware modules to load:" -ForegroundColor Cyan
            Write-Host "[1] VCF.PowerCLI     $vcfVer (heavy)" -ForegroundColor Yellow
            Write-Host "[2] VMware.PowerCLI $vmwVer (heavy)" -ForegroundColor Yellow
            Write-Host "[3] Both"
            Write-Host ""

            switch (Read-Host "Choose (1–3)") {
                "1" { Ensure-Module "VCF.PowerCLI" }
                "2" { Ensure-Module "VMware.PowerCLI" }
                "3" {
                    Ensure-Module "VCF.PowerCLI"
                    Ensure-Module "VMware.PowerCLI"
                }
                default {
                    Write-Host "⏭ No modules selected." -ForegroundColor DarkGray
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
    Write-Host "`n[$($now.ToString("hh:mm:ss tt"))] ⏳ $(Get-SessionUptime)" -ForegroundColor DarkGray
    Write-Host "❯ $((Get-Location).Path)>" -NoNewline -ForegroundColor Cyan
    return " "
}

# ==========================================================
# Startup Order
# ==========================================================
Show-ProfileVersionBanner
Show-WelcomeMessage
Invoke-ModuleLoadPrompt
