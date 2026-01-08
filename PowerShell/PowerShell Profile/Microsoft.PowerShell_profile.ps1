# ==========================================================
# REMOTE POWERSHELL PROFILE (GitHub-hosted)
# VMware / VCF PowerCLI–focused
# ==========================================================

# --------------------------
# Profile Metadata
# --------------------------
$ProfileMetadata = @{
    Name        = "Joel PowerShell Profile"
    Version     = "2.0.2"
    Branch      = "main"
    Commit      = "vmware-load-fix"
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
    param([Parameter(Mandatory)][string]$Name)

    $m = Get-Module -ListAvailable -Name $Name | Sort-Object Version -Descending | Select-Object -First 1
    if ($m) { return $m.Version.ToString() }
    return "not found"
}

# ==========================================================
# Ensure-Module (install if missing, then import with real error output)
# ==========================================================
function Ensure-Module {
    param([Parameter(Mandatory)][string]$Name)

    $available = Get-Module -ListAvailable -Name $Name | Sort-Object Version -Descending | Select-Object -First 1

    if (-not $available) {
        Write-Host "📦 [$Name] Not found. Installing..." -ForegroundColor Yellow
        try {
            Install-Module -Name $Name -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
        }
        catch {
            Write-Host "❌ [$Name] Install failed: $($_.Exception.Message)" -ForegroundColor Red
            return
        }

        $available = Get-Module -ListAvailable -Name $Name | Sort-Object Version -Descending | Select-Object -First 1
        if (-not $available) {
            Write-Host "❌ [$Name] Still not found after install." -ForegroundColor Red
            return
        }
    }

    Write-Host "⏳ Loading [$Name] (available: $($available.Version))..." -ForegroundColor Cyan

    try {
        # Import and get the actual module object imported
        $imported = Import-Module -Name $Name -Force -PassThru -ErrorAction Stop

        # Some modules return multiple objects; take first
        $imp = $imported | Select-Object -First 1
        $impVer = if ($imp -and $imp.Version) { $imp.Version.ToString() } else { $available.Version.ToString() }

        Write-Host "✅ [$Name] Loaded (imported: $impVer)" -ForegroundColor Green

        # Apply PowerCLI preferences only after a successful import
        if ($Name -eq "VMware.PowerCLI") {
            try {
                Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
                Set-PowerCLIConfiguration -Scope User -InvalidCertificateAction Ignore -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
                Write-Host "🔧 [VMware.PowerCLI] Preferences applied (CEIP off, invalid certs ignored)" -ForegroundColor DarkGray
            }
            catch {
                # Don’t fail the session if preferences can't be applied
                Write-Host "⚠ [VMware.PowerCLI] Loaded, but could not apply preferences: $($_.Exception.Message)" -ForegroundColor DarkYellow
            }
        }
    }
    catch {
        Write-Host "❌ [$Name] Import failed: $($_.Exception.Message)" -ForegroundColor Red

        # Extra hint for common cause: PS edition compatibility
        if ($_.Exception.Message -match "not supported" -or $_.Exception.Message -match "edition") {
            Write-Host "ℹ Hint: This can happen if the module isn't compatible with your PowerShell edition/version." -ForegroundColor DarkGray
        }
    }
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
# Module Load Menu (VMware-only) - UPDATED ORDER
# ==========================================================
function Invoke-ModuleLoadPrompt {
    if ($global:ModuleLoadChoice) { return }

    Write-Host ""
    Write-Host "📦 Module Load Options:" -ForegroundColor Cyan
    Write-Host "1) Load ALL modules (VMware + VCF)"
    Write-Host "2) Select modules"
    Write-Host "3) FAST MODE"
    Write-Host "4) Load NO modules"
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
            Write-Host "[2] VMware.PowerCLI  $vmwVer (heavy)" -ForegroundColor Yellow
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
            $global:FastModeEnabled = $true
            Write-Host "⚡ FAST MODE enabled for this session." -ForegroundColor Yellow
        }

        "4" {
            Write-Host "⏭ Skipping module load." -ForegroundColor DarkGray
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
