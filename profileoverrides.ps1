# ===== david's overrides (Profile.ps1) =====

# Use my fork for auto-updates (raw domain, no trailing slash)
$repo_root_Override = "https://raw.githubusercontent.com/davidabad98"

# Where the updater stores its last-run timestamp (5.1 lives under WindowsPowerShell)
# $timeFilePath_Override = "$HOME\Documents\WindowsPowerShell\LastExecutionTime.txt"

# How often to check (days). -1 = always check
$updateInterval_Override = 7

# Preferred editor for Edit-Profile, etc.
$EDITOR_Override = "code"

# Make oh-my-posh init not depend on a remote theme fetch each start
# --- Theme init (safer) ---
function Get-Theme_Override {
    if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
        # Use a local theme file instead of pulling from the internet every session
        $localTheme = "$HOME\AppData\Local\Programs\oh-my-posh\themes\cobalt2.override.omp.json"
        if (Test-Path $localTheme) {
            oh-my-posh init pwsh --config $localTheme | Invoke-Expression
        }
        else {
            # Fallback to a override theme from Github
            oh-my-posh init pwsh --config https://raw.githubusercontent.com/davidabad98/powershell-profile/refs/heads/main/oh-my-posh/themes/cobalt2.override.omp.json | Invoke-Expression
        }
    }
    else {
        Write-Host "oh-my-posh not installed. Skipping fancy prompt." -ForegroundColor DarkYellow
    }
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
# Always opt out of PowerShell telemetry for current user
[System.Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', 'true', 'User')

# Example: change prompt symbol, keep admin #[…]
# function prompt_Override {
#     if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
#         ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
#         "[" + (Get-Location) + "] # "
#     } else {
#         "[" + (Get-Location) + "] λ "
#     }
# }
