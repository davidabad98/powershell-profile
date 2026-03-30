# ===== david's overrides (Profile.ps1) =====

# Use my fork for auto-updates (raw domain, no trailing slash)
$repo_root_Override = "https://raw.githubusercontent.com/davidabad98"

# Where the updater stores its last-run timestamp (5.1 lives under WindowsPowerShell)
# $timeFilePath_Override = "$HOME\Documents\WindowsPowerShell\LastExecutionTime.txt"

# How often to check (days). -1 = always check
$updateInterval_Override = 7

# Preferred editor for Edit-Profile, etc.
$EDITOR_Override = "code"

# oh-my-posh theme: use a local copy to avoid fetching from GitHub every session.
# The theme is auto-downloaded once to ~/.config/oh-my-posh/ and reused from there.
function Get-Theme_Override {
    if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
        Write-Host "oh-my-posh not installed. Skipping fancy prompt." -ForegroundColor DarkYellow
        return
    }

    $themeDir   = "$HOME\.config\oh-my-posh"
    $localTheme = "$themeDir\cobalt2.override.omp.json"
    $remoteTheme = "https://raw.githubusercontent.com/davidabad98/powershell-profile/refs/heads/main/oh-my-posh/themes/cobalt2.override.omp.json"

    # Download once if the local copy is missing
    if (-not (Test-Path $localTheme)) {
        if (-not (Test-Path $themeDir)) {
            New-Item -ItemType Directory -Path $themeDir -Force | Out-Null
        }
        try {
            Invoke-RestMethod -Uri $remoteTheme -OutFile $localTheme -ErrorAction Stop
        } catch {
            Write-Host "Could not download oh-my-posh theme; using remote URL as fallback." -ForegroundColor DarkYellow
            oh-my-posh init pwsh --config $remoteTheme | Invoke-Expression
            return
        }
    }

    # Cache the oh-my-posh init output so we don't spawn oh-my-posh.exe every
    # session. The cache is invalidated whenever the theme file changes (via MD5).
    $ompCacheDir  = "$env:LOCALAPPDATA\powershell-profile"
    $ompCache     = "$ompCacheDir\omp-init.ps1"
    $ompCacheHash = "$ompCacheDir\omp-init.ps1.hash"

    $themeHash   = (Get-FileHash $localTheme -Algorithm MD5).Hash
    $storedHash  = if (Test-Path $ompCacheHash) { (Get-Content $ompCacheHash -Raw).Trim() } else { '' }

    if (-not (Test-Path $ompCache) -or $themeHash -ne $storedHash) {
        if (-not (Test-Path $ompCacheDir)) { New-Item -ItemType Directory -Path $ompCacheDir -Force | Out-Null }
        oh-my-posh init pwsh --config $localTheme | Out-File $ompCache -Encoding utf8
        $themeHash | Out-File $ompCacheHash -Encoding utf8
    }

    . $ompCache
}

# (Optional) disable auto profile/PowerShell updates and just notify
#function Update-Profile_Override { Write-Host "Update-Profile: disabled by override." -ForegroundColor DarkYellow }
function Update-PowerShell_Override {
    Write-Host "A newer PowerShell may be available. Run manually:" -ForegroundColor DarkYellow
    Write-Host "  winget upgrade Microsoft.PowerShell --accept-source-agreements --accept-package-agreements"
}

# Safer Clear-Cache (skip Prefetch/system Temp)
function Clear-Cache_Override {
    Write-Host "Clearing only user TEMP..." -ForegroundColor Cyan
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    # Avoid deleting Prefetch or system-wide TEMP. It doesn’t “speed Windows up”.
}

# Don’t auto-run remote WinUtil; block or point to your own
#function WinUtilDev_Override { Write-Host "winutildev disabled by override." -ForegroundColor DarkYellow }
#Set-Alias -Name winutil -Value WinUtilDev_Override  # optional: neutralize winutil too

# --- Environment hardening & QoL ---
# Opt out of PowerShell telemetry for the current user.
# Guard: only write to the registry when the value isn't already correct.
# Writing 'User'-scoped env vars broadcasts WM_SETTINGCHANGE to all windows,
# which can stall PowerShell startup by 8+ seconds on some machines.
if ([System.Environment]::GetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', 'User') -ne 'true') {
    [System.Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', 'true', 'User')
}

# Example: change prompt symbol, keep admin #[…]
# function prompt_Override {
#     if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
#         ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
#         "[" + (Get-Location) + "] # "
#     } else {
#         "[" + (Get-Location) + "] λ "
#     }
# }
