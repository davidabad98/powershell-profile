# Technical Reference

This document covers how the profile works internally, the full override system, startup performance, troubleshooting, and day-2 workflows.

---

## The two files

| File | Path (PS 7) | Owned by | Overwritten? | Purpose |
|---|---|---|---|---|
| `Microsoft.PowerShell_profile.ps1` | `~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1` | This repo | **Yes** | The engine. Auto-updates from the fork. Do not edit. |
| `profile.ps1` | `~/Documents/PowerShell/profile.ps1` | You | **No** | Your customizations. All `_Override` hooks go here. |

PowerShell loads `profile.ps1` **first**, then `Microsoft.PowerShell_profile.ps1`. This is why overrides defined in your file are already in memory when the base profile runs.

---

## Override hooks

Define any of these in your `profile.ps1` to change default behavior without touching the base file.

### Variables

| Variable | Default | Purpose |
|---|---|---|
| `$EDITOR_Override` | auto-detected | Editor used by `Edit-Profile` and `vim` alias |
| `$debug_Override` | `$false` | Enable debug mode (skips update checks) |
| `$repo_root_Override` | `https://raw.githubusercontent.com/davidabad98` | Source for auto-updates |
| `$timeFilePath_Override` | `~/Documents/PowerShell/LastExecutionTime.txt` | Where the update timestamp is stored |
| `$updateInterval_Override` | `7` | Days between update checks; `-1` = always check |

### Functions

| Function | What it replaces |
|---|---|
| `Debug-Message_Override` | Custom debug banner |
| `Update-Profile_Override` | Profile update logic |
| `Update-PowerShell_Override` | PowerShell upgrade logic |
| `Clear-Cache_Override` | Cache clearing behavior |
| `Get-Theme_Override` | oh-my-posh init |
| `WinUtilDev_Override` | `winutildev` command |
| `Set-PredictionSource_Override` | PSReadLine prediction settings |

> Do not call the original function from its override — that creates infinite recursion.

---

## How auto-updates work

On startup (when the update interval has elapsed), `Update-Profile` does:

1. Downloads the remote `Microsoft.PowerShell_profile.ps1` to `%TEMP%`.
2. Computes SHA256 of the remote file and the local file.
3. If hashes differ, replaces the local file with the remote version.
4. Writes today's date to `LastExecutionTime.txt`.

`Update-PowerShell` similarly checks the GitHub API for the latest PowerShell release and runs `winget upgrade` if a newer version is available. The default override in `profileoverrides.ps1` replaces this with a notification-only message.

To force an update immediately:

```powershell
Update-Profile
```

To point updates at your fork, set in `profile.ps1`:

```powershell
$repo_root_Override = "https://raw.githubusercontent.com/davidabad98"
```

The base file also hardcodes this fork as the default `$repo_root`, so this override is redundant unless you point to a different fork.

---

## Startup performance

The profile is optimized for fast startup. Key techniques used:

| Technique | Savings |
|---|---|
| Terminal-Icons loaded via `Register-EngineEvent -SourceIdentifier PowerShell.OnIdle` | ~870ms |
| oh-my-posh pointed at a local theme file instead of a remote URL | ~230ms |
| GitHub connectivity check runs in a background `Start-ThreadJob` | ~87ms |

### oh-my-posh local theme

`Get-Theme_Override` in `profileoverrides.ps1` / `profile.ps1` handles this:

1. Checks for the theme at `~/.config/oh-my-posh/cobalt2.override.omp.json`.
2. If missing (new machine), downloads it once from the fork.
3. Every subsequent session loads from the local file — no network call.

To reset the cached theme (e.g. after updating it in the fork):

```powershell
Remove-Item "$HOME\.config\oh-my-posh\cobalt2.override.omp.json"
# Restart the terminal — it will re-download automatically.
```

### Terminal-Icons lazy load

Terminal-Icons is registered to load on `PowerShell.OnIdle` — after the prompt renders. Icons will appear from your first command, not before it. This is intentional.

---

## Setting up on a new machine

1. Run the setup script (elevated):

    ```powershell
    irm "https://raw.githubusercontent.com/davidabad98/powershell-profile/main/setup.ps1" | iex
    ```

2. Copy `profileoverrides.ps1` from this repo to your override file:

    ```powershell
    Copy-Item profileoverrides.ps1 "$HOME\Documents\PowerShell\profile.ps1"
    ```

3. Open a new terminal window. The profile loads, and the oh-my-posh theme is downloaded automatically on first run.

4. Install a Nerd Font:

    ```powershell
    oh-my-posh font install
    ```

5. Set the font in Windows Terminal (Settings → your profile → Font face).

---

## Execution policy errors

If PowerShell refuses to load the profiles because they were downloaded from the internet:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
Unblock-File "$HOME\Documents\PowerShell\profile.ps1"
Unblock-File "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
```

Then open a new terminal window.

---

## Windows PowerShell 5.1

The profile targets **PowerShell 7 (Core)**. Some features do not work on 5.1:

- `Test-Connection -TimeoutSeconds` — PS7 only.
- `Set-PSReadLineOption -PredictionSource` — requires PSReadLine 2.1+, which ships with PS7.
- `$PSStyle` — PS7 only.

**Recommendation:** use PS7. Install it with:

```powershell
winget install --id Microsoft.PowerShell -e
```

Set it as your default profile in Windows Terminal (Settings → Default profile → PowerShell).

If you must stay on 5.1, the fix is in the fork's `Microsoft.PowerShell_profile.ps1`:
- Replace `Test-Connection -TimeoutSeconds` with a `System.Net.NetworkInformation.Ping` call.
- Guard `Set-PSReadLineOption -PredictionSource` behind a `$PSVersionTable.PSEdition -eq 'Core'` check.

---

## Forking and customizing the base profile

The `profileoverrides.ps1` file in this repo is the reference for `profile.ps1` — it contains the recommended overrides for this fork. It is **not** auto-deployed; copy it manually to `~/Documents/PowerShell/profile.ps1` on each machine.

If you want to change behavior that has no `_Override` hook (e.g. remove a function from the base file entirely), fork the repo and edit `Microsoft.PowerShell_profile.ps1` directly in your fork. Then set:

```powershell
$repo_root_Override = "https://raw.githubusercontent.com/<your-username>"
```

Any change you push to your fork (including whitespace) changes the SHA256 hash, which triggers `Update-Profile` to pull the new version on next startup.

---

## All commands

| Command | Description |
|---|---|
| `Show-Help` | Print this command reference |
| `Edit-Profile` / `ep` | Open `profile.ps1` in your editor |
| `Update-Profile` | Force pull the latest profile from the fork |
| `Update-PowerShell` | Check for and install a newer PowerShell version |
| `reload-profile` | Re-run the current profile in this session |
| `admin` / `su` | Open an elevated terminal (or run a command elevated) |
| `uptime` | Show system uptime |
| `sysinfo` | Show full system info |
| `Get-PubIP` | Show public IP address |
| `flushdns` | Clear the DNS cache |
| `winutil` | Run Chris Titus WinUtil (full release) |
| `winutildev` | Run Chris Titus WinUtil (dev release) |
| **Navigation** | |
| `docs` | `cd` to Documents |
| `dtop` | `cd` to Desktop |
| `mkcd <dir>` | Create directory and `cd` into it |
| `z <dir>` | Smart `cd` via zoxide |
| **Files** | |
| `nf <name>` | Create new file |
| `touch <file>` | Create empty file |
| `unzip <file>` | Extract zip to current directory |
| `trash <path>` | Move file/folder to Recycle Bin |
| `hb <file>` | Upload file to hastebin, copy URL to clipboard |
| **Search (fzf)** | |
| `ff [dir]` | Fuzzy find file, print path |
| `vf [dir]` | Fuzzy find file, open in editor |
| `cdf [dir]` | Fuzzy find directory, `cd` into it |
| `fp [dir]` | Fuzzy pick file with bat preview |
| `fh` | Fuzzy search shell history |
| `fkill` | Fuzzy pick and kill a process |
| **Unix helpers** | |
| `grep <regex> [dir]` | Search files by regex |
| `sed <file> <find> <replace>` | Replace text in file |
| `which <name>` | Show command path |
| `head <path> [n]` | First n lines of file (default 10) |
| `tail <path> [n]` | Last n lines of file (default 10) |
| `df` | Show disk volumes |
| `export <name> <value>` | Set environment variable |
| `pkill <name>` | Kill process by name |
| `pgrep <name>` | List processes by name |
| `k9 <name>` | Kill process by name (alias) |
| **Git** | |
| `gs` | `git status` |
| `ga` | `git add .` |
| `gc <msg>` | `git commit -m` |
| `gpush` | `git push` |
| `gpull` | `git pull` |
| `gcl <url>` | `git clone` |
| `gcom <msg>` | `git add . && git commit -m` |
| `lazyg <msg>` | `git add . && git commit -m && git push` |
| **Clipboard** | |
| `cpy <text>` | Copy to clipboard |
| `pst` | Paste from clipboard |
| **Cache** | |
| `Clear-Cache` | Clear user TEMP (override version) |
