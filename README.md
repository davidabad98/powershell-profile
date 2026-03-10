# PowerShell Profile

A fast, customizable PowerShell 7 profile that sets up a great terminal experience in under a minute on any new machine.

## Install

Run in an elevated PowerShell window:

```powershell
irm "https://raw.githubusercontent.com/davidabad98/powershell-profile/main/setup.ps1" | iex
```

Then install a [Nerd Font](https://www.nerdfonts.com/) so icons render correctly:

```powershell
oh-my-posh font install
```

Set the installed font in your terminal emulator (Windows Terminal → Settings → Profile → Font face).

## What you get

- **oh-my-posh** prompt (cobalt2 theme)
- **Terminal Icons** in directory listings
- **zoxide** smart `cd`
- **fzf** fuzzy file/history search (`ff`, `vf`, `fh`, `fkill`)
- **PSReadLine** with history predictions and key bindings
- Unix-style helpers: `grep`, `sed`, `which`, `head`, `tail`, `mkcd`, `trash`, `nf`, etc.
- Git shortcuts: `gs`, `ga`, `gc`, `gcom`, `lazyg`, `gpush`, `gpull`
- Auto-updates itself from this fork every 7 days

Run `Show-Help` in any session to see all available commands.

## Customize

**Do not edit `Microsoft.PowerShell_profile.ps1`** — it is auto-updated from this repo and your changes will be overwritten.

Your customizations go in a separate file that is never touched by updates:

```
~/Documents/PowerShell/profile.ps1   (PS 7)
```

Open it with:

```powershell
Edit-Profile
```

Override any behavior by defining variables or functions with an `_Override` suffix. For example:

```powershell
# profile.ps1

$EDITOR_Override         = "code"
$updateInterval_Override = 7        # days between update checks; -1 = always

function Update-PowerShell_Override {
    Write-Host "Run manually: winget upgrade Microsoft.PowerShell" -ForegroundColor DarkYellow
}

function Clear-Cache_Override {
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
}
```

See [TECHNICAL.md](TECHNICAL.md) for the full list of override hooks, how auto-updates work, and troubleshooting.

## Reload after editing

```powershell
. $PROFILE.CurrentUserAllHosts   # load your overrides
& $PROFILE                       # load the base profile
```
