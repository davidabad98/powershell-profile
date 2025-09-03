# 1) What this profile does (high level)

**Auto-update plumbing**

* Writes a date file at `Documents\PowerShell\LastExecutionTime.txt`.
* Every 7 days (configurable), it:

  * **Updates this profile** by downloading `Microsoft.PowerShell_profile.ps1` from the repo and replacing your local file if the hash changed.
  * **Optionally upgrades PowerShell** using `winget upgrade Microsoft.PowerShell`.
* You can point updates at a **fork** via `$repo_root_Override`.

**“Do not edit me” pattern**

* You’re expected to put customizations in a *separate* file, `Documents\PowerShell\profile.ps1`, and implement variables/functions with an `_Override` suffix to change behavior **without touching the base file**.

**Modules, cosmetics, and helpers**

* Installs & imports **Terminal-Icons** automatically if missing.
* Imports **Chocolatey** profile if available.
* Sets a simplified **prompt** (`[path] $` vs `#` when elevated) and window title including `[ADMIN]`.
* Defines **EDITOR** preference and a `vim` alias that actually launches your chosen editor (nvim, VS Code, etc.).
* Adds a bunch of **Unix-ish helpers** (`grep`, `sed`, `which`, `head`, `tail`, `mkcd`, `nf`, `trash`, etc.).
* Adds **git shortcuts** (`gs`, `ga`, `gc`, `lazyg`, …).
* **PSReadLine** tuning: pastel colors, history de-dupe, list-view predictions, key-bindings (Ctrl+W, Ctrl+D, etc.), and enables `HistoryAndPlugin` predictions.
* Registers **completions** for `git`, `npm`, `deno`, and `dotnet complete`.
* Initializes **oh-my-posh** with the remote *cobalt2* theme (assumes `oh-my-posh` is installed; if not, this line will error unless you override it).
* Tries to ensure **zoxide** is installed (auto-installs via `winget` if missing).
* Adds **winutil / winutildev** commands that run remote scripts from Chris Titus Tech (`irm … | iex`).
* **Clear-Cache** function deletes Prefetch, Windows temp, user temp, and IE cache.
* A simple **uptime**, **sysinfo**, **Get-PubIP**, **admin** (spawn elevated PowerShell in Windows Terminal), clipboard helpers, etc.
* Displays a built-in **Show-Help** banner summarizing commands.

---

# 2) Why the “DO NOT MODIFY” warning?

The `Update-Profile` function compares the hash of your local `$PROFILE` (which, in PowerShell 7+, is `…\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`) to the remote file. If different, it **overwrites your local file**.

So any edits **inside** `Microsoft.PowerShell_profile.ps1` won’t stick. The intended model is:

* Keep that file pristine (auto-managed).
* Put your customizations in `…\Documents\PowerShell\profile.ps1`.
* To *override*, define variables/functions with an `_Override` suffix listed in the header. The main profile checks for those and uses them instead.

---

# 3) Safe adoption plan (step-by-step)

Follow this once, and you’ll have a clean, upgrade-proof setup.

### A. Back up whatever you have now

```powershell
# See all profile paths
$PROFILE | Format-List * 

# Back up current files if they exist
if (Test-Path $PROFILE)              { Copy-Item $PROFILE "$PROFILE.bak-$(Get-Date -f yyyyMMddHHmmss)" }
if (Test-Path $PROFILE.CurrentUserAllHosts) { Copy-Item $PROFILE.CurrentUserAllHosts "$($PROFILE.CurrentUserAllHosts).bak-$(Get-Date -f yyyyMMddHHmmss)" }
```

### B. Put Chris’ base file in the correct place

* The file you pasted is meant to live at **PowerShell 7**’s current-host profile:

  * `C:\Users\<you>\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`
* Ensure the folder exists:

```powershell
New-Item -Type Directory -Force (Split-Path $PROFILE) | Out-Null
# Then save the provided content to: $PROFILE
```

> If you also use Windows PowerShell 5.1, it has a different path (`Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`). This script targets PowerShell 7 (it uses `$PSStyle` and other 7.x niceties), so keep 5.1 separate.

### C. Create **your** profile for overrides

This one is **not** overwritten:
`C:\Users\<you>\Documents\PowerShell\profile.ps1`  → `$PROFILE.CurrentUserAllHosts`

Create it:

```powershell
if (-not (Test-Path $PROFILE.CurrentUserAllHosts)) {
  New-Item -Type File -Force $PROFILE.CurrentUserAllHosts | Out-Null
}
```

Drop in a **starter** override file. Adjust to taste:

```powershell
# =========================
# profile.ps1 (YOUR file)
# =========================

# --- Global knobs ---
# Check for upstream updates monthly (or set to a giant number to “almost never”)
$updateInterval_Override = 30
# Or completely disable the update/upgrade logic by replacing the functions:
function Update-Profile_Override { Write-Host "Update-Profile: disabled by override." -ForegroundColor DarkYellow }
function Update-PowerShell_Override {
    Write-Host "A new PowerShell may be available. Run this manually if desired:" -ForegroundColor DarkYellow
    Write-Host "  winget upgrade --id Microsoft.PowerShell --accept-source-agreements --accept-package-agreements"
}

# Optional: pin to your fork (so you can remove pieces you don’t like upstream)
# $repo_root_Override = "https://raw.githubusercontent.com/<your-user-or-org>"

# --- Editor preference ---
$EDITOR_Override = "code"   # or 'nvim', 'vim', etc.

# --- Theme init (safer) ---
function Get-Theme_Override {
    if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
        # Use a local theme file instead of pulling from the internet every session
        $localTheme = "$HOME\AppData\Local\Programs\oh-my-posh\themes\cobalt2.omp.json"
        if (Test-Path $localTheme) {
            oh-my-posh init pwsh --config $localTheme | Invoke-Expression
        } else {
            # Fallback to a built-in minimal prompt if the theme isn’t present
            oh-my-posh init pwsh | Invoke-Expression
        }
    } else {
        Write-Host "oh-my-posh not installed. Skipping fancy prompt." -ForegroundColor DarkYellow
    }
}

# --- Safer cache cleaning ---
function Clear-Cache_Override {
    Write-Host "Clearing user TEMP only (safer override)..." -ForegroundColor Cyan
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    # Avoid deleting Prefetch or system-wide TEMP. It doesn’t “speed Windows up”.
}

# --- Prediction tuning ---
function Set-PredictionSource_Override {
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin
    Set-PSReadLineOption -MaximumHistoryCount 20000
    # Example: opt out of storing sensitive patterns
    Set-PSReadLineOption -AddToHistoryHandler {
        param($line)
        $deny = 'password|secret|token|apikey|connectionstring'
        return ($line -notmatch $deny)
    }
}

# --- Kill the remote winutil starters if you don’t want them ---
function WinUtilDev_Override  { Write-Host "winutildev disabled by override." -ForegroundColor DarkYellow }
Set-Alias -Name winutil -Value WinUtilDev_Override  # optional: alias 'winutil' to the disabled version too

# --- Environment hardening & QoL ---
# Always opt out of PowerShell telemetry for current user
[System.Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', 'true', 'User')

# Don’t auto-install zoxide; initialize only if present
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init --cmd z powershell | Out-String) })
} else {
    # No-op instead of winget install from the base file
    # (If you want zoxide, install it once:  winget install -e --id ajeetdsouza.zoxide)
}

# Example: change prompt symbol, keep admin #[…]
function prompt_Override {
    if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
        ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        "[" + (Get-Location) + "] # "
    } else {
        "[" + (Get-Location) + "] λ "
    }
}
```

> Anything in the base file that offers an `_Override` hook can be changed this way, **without editing** the auto-updated file.

### D. Install the things the base file assumes you have

Run these once (elevate if needed):

```powershell
# PSReadLine (PowerShell 7 already ships with it, but ensure latest)
Install-Module PSReadLine -Scope CurrentUser -Force -SkipPublisherCheck

# oh-my-posh (optional but recommended for the prompt)
winget install JanDeDobbeleer.OhMyPosh -e

# Terminal-Icons: the base file will auto-install it, but you can do it explicitly:
Install-Module Terminal-Icons -Scope CurrentUser -Force -SkipPublisherCheck

# zoxide (only if you want it)
winget install ajeetdsouza.zoxide -e

# Git (if missing)
winget install Git.Git -e
```

### E. Reload and test

```powershell
# reload current session
& $PROFILE
# or
reload-profile

# check overrides took effect
Show-Help
Update-Profile      # should print “disabled by override” if you disabled it
Clear-Cache         # should only clear user TEMP (override)
```

---

## What I’d keep vs modify (opinionated, safe defaults)

* ✅ **Keep**: PSReadLine tuning, history + key-bindings, git shortcuts, editor alias, `admin` launcher, `trash`, `mkcd`, `nf`, argument completers, `zoxide` init (but don’t auto-install inside your profile; install once with winget).
* ⚠️ **Tame**:

  * **Auto-updating the profile & auto-upgrading PowerShell** — I prefer overrides that **notify** rather than change my runtime automatically. (See `Update-Profile_Override` and `Update-PowerShell_Override` above.)
  * **oh-my-posh** — use a **local** theme file via `Get-Theme_Override` to avoid fetching a remote theme every shell start.
* ❌ **Disable/Replace**:

  * **`Clear-Cache` deleting Prefetch** — that usually *hurts* performance; keep only user TEMP cleanup.
  * **`winutil` / `winutildev`** remote one-liners (`irm … | iex`). If you want them, keep, but be explicit about running remote code.
  * **Force installing modules in your profile** — prefer one-time installs you control.

---

## Removing or changing things that **don’t** have an override

A few early actions (like auto-installing Terminal-Icons) don’t offer `_Override`. You have two options:

1. **Pre-install** the thing once (harmless and keeps startup fast), or
2. **Fork** the repo, remove what you don’t want in *your* copy, then point updates at your fork:

```powershell
# in your profile.ps1
$repo_root_Override = "https://raw.githubusercontent.com/<you>"
```

This way, the base auto-update still works — but from *your* curated source.

---

## A couple of gotchas

* **PowerShell 5.1 vs 7**: `$PSStyle` and some features are 7+. Keep separate profiles (`WindowsPowerShell\…` vs `PowerShell\…`).
* **oh-my-posh not found**: without the override, the base file will try to run it and error. Add `Get-Theme_Override` as shown.
* **zoxide freshly installed**: its `init` only takes effect in a new session; that’s expected.
* **Winget upgrade of PowerShell** may require elevation or a restart. If you disabled auto-upgrade, just run the winget command manually when you want.

---

If you want, paste what you specifically want to *remove* and I’ll hand you the minimal `profile.ps1` overrides to get exactly that behavior.

---

Perfect — you’ve got the right instincts. Let’s break this into four parts:

1. what `setup.ps1` does (and the sharp edges),
2. why a `tree/main` link won’t work + how Chris’ hash comparison actually works,
3. exactly how to run this from **your fork** with automatic updates (no accidental re-pointing back to upstream),
4. a ready-to-paste `profile.ps1` (your overrides) and the minimal edits to `setup.ps1`.

---

# 1) What `setup.ps1` does

**Summary**

* Requires **Administrator** (fonts, winget, choco).
* Verifies internet.
* **Creates or replaces** your `$PROFILE` file with the remote `Microsoft.PowerShell_profile.ps1` from Chris’ repo.
* Installs **oh-my-posh**, **CaskaydiaCove NF** font, **Chocolatey**, **Terminal-Icons**, **zoxide**.

**Details to note**

* It seeds the *host-specific* profile (`Microsoft.PowerShell_profile.ps1`) at the correct location for your PowerShell edition:

  * PS 7+: `~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1`
  * PS 5.1: `~/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1`
* It **backs up** your old profile to `oldprofile.ps1` if one exists.
* It does **not** create your per-user, all-hosts `profile.ps1` (the place you put overrides). We’ll add that.
* Minor bug: the final success check reads `$fontFamilies` that only exists inside the font function scope. Ignore that; the install either worked or didn’t.

---

# 2) Why `tree/main` won’t work + how the hash check works

* `Invoke-RestMethod` must fetch the **raw file bytes**.

  * ✅ Correct: `https://raw.githubusercontent.com/<user>/<repo>/main/<path to file>`
  * ❌ Wrong: `https://github.com/<user>/<repo>/tree/main/...` → that’s an **HTML** listing page, not the raw file. You’d end up downloading HTML into your profile and PowerShell will choke on it.

**Hash comparison (in `Microsoft.PowerShell_profile.ps1`)**

```powershell
$url = "$repo_root/powershell-profile/main/Microsoft.PowerShell_profile.ps1"
$oldhash = Get-FileHash $PROFILE
Invoke-RestMethod $url -OutFile "$env:temp/Microsoft.PowerShell_profile.ps1"
$newhash = Get-FileHash "$env:temp/Microsoft.PowerShell_profile.ps1"
if ($newhash.Hash -ne $oldhash.Hash) {
  Copy-Item "$env:temp/Microsoft.PowerShell_profile.ps1" $PROFILE -Force
}
```

* `Get-FileHash` defaults to SHA256.
* If **content differs**, it overwrites your local profile with the remote one.
* The base profile constructs `$url` from `$repo_root`; by default that’s `"https://raw.githubusercontent.com/ChrisTitusTech"`.
  You override it by setting **`$repo_root_Override = "https://raw.githubusercontent.com/<you>"`** in your own `profile.ps1`.

---

# 3) Run the whole thing from **your fork** with auto-updates

You want:

* First-time install pulls **your** `Microsoft.PowerShell_profile.ps1`.
* Every session, the profile’s built-in updater fetches **your** copy (not Chris’).
* Your customizations live in `profile.ps1` and persist across updates.

## A. Edit your fork to host both files

Your fork should contain at least:

```
/setup.ps1
/Microsoft.PowerShell_profile.ps1   <-- you can keep this identical to upstream for now
```

## B. Change the URLs in **your** `setup.ps1`

Replace both hardcoded Chris URLs with your raw links:

```powershell
# OLD (twice in file):
# Invoke-RestMethod https://github.com/ChrisTitusTech/powershell-profile/raw/main/Microsoft.PowerShell_profile.ps1 -OutFile $PROFILE

# NEW:
Invoke-RestMethod https://raw.githubusercontent.com/davidabad98/powershell-profile/main/Microsoft.PowerShell_profile.ps1 -OutFile $PROFILE
```

> Note the domain: **raw\.githubusercontent.com** (not `github.com/.../raw/…`, which usually works but the raw domain is cleaner and consistent with the updater).

## C. Make `setup.ps1` also create your **override** profile

Add this block near the end of your `setup.ps1` (after it writes `$PROFILE`), to ensure overrides exist **before** the base profile runs:

```powershell
# Ensure your override profile (CurrentUserAllHosts) exists and points updates at YOUR fork
$allHostsProfile = $PROFILE.CurrentUserAllHosts
$allHostsDir = Split-Path -Parent $allHostsProfile
if (-not (Test-Path $allHostsDir)) { New-Item -ItemType Directory -Path $allHostsDir | Out-Null }

if (-not (Test-Path $allHostsProfile)) {
@'
# ====== profile.ps1 (Overrides) ======
# Point updater at my fork (raw domain, no trailing slash)
$repo_root_Override = "https://raw.githubusercontent.com/davidabad98"

# Optional: slow down update checks (days) or disable auto-update logic
$updateInterval_Override = 7
# function Update-Profile_Override { Write-Host "Update-Profile disabled by override." -ForegroundColor DarkYellow }
# function Update-PowerShell_Override { Write-Host "Manual PS update: winget upgrade Microsoft.PowerShell" -ForegroundColor DarkYellow }

# Prefer VS Code as editor (or 'nvim', etc.)
$EDITOR_Override = "code"

# Make theme init resilient (no network dependency each shell start)
function Get-Theme_Override {
  if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh | Invoke-Expression
  } else {
    Write-Host "oh-my-posh not installed; skipping prompt." -ForegroundColor DarkYellow
  }
}
'@ | Set-Content -Encoding UTF8 $allHostsProfile
    Write-Host "Created override profile at [$allHostsProfile]"
} else {
    Write-Host "Override profile already exists at [$allHostsProfile]"
}
```

Why this matters: PowerShell loads `CurrentUserAllHosts` **before** it loads `Microsoft.PowerShell_profile.ps1`.
So your `$repo_root_Override` is in memory when the base profile runs, and the updater will target **your** fork.

## D. (Optional) If you want to hard-point the base file to your fork too

You don’t have to (the override already does it), but if you prefer belt-and-suspenders, in your fork’s `Microsoft.PowerShell_profile.ps1` change the **default**:

```powershell
# OLD default
$repo_root = "https://raw.githubusercontent.com/ChrisTitusTech"

# NEW default (safe; override still wins if present)
$repo_root = "https://raw.githubusercontent.com/davidabad98"
```

This makes the base file “self-hosted” even if someone doesn’t have your `profile.ps1` overrides.

## E. Install using your fork

From an elevated PowerShell:

```powershell
irm "https://raw.githubusercontent.com/davidabad98/powershell-profile/main/setup.ps1" | iex
```

Restart your terminal.

## F. Verify you’re really pulling from your fork

1. Make a trivial change in your fork’s `Microsoft.PowerShell_profile.ps1` (e.g., tweak a comment near the top).
2. In a new session, run:

```powershell
Update-Profile
```

You should see “Profile has been updated…”.
Open `$PROFILE` and confirm the header comment reflects your change.

---

# 4) Ready-to-use `profile.ps1` overrides (you can paste & adjust)

If you want a more complete override set like we discussed earlier (safer cache, resilient theme, no auto-install), here’s a solid starting point:

```powershell
# ===== profile.ps1 (YOUR overrides) =====

# 1) Point auto-updater at YOUR fork
$repo_root_Override = "https://raw.githubusercontent.com/davidabad98"

# 2) Update cadence (days). Set -1 to always check, or a big number to “rarely”.
$updateInterval_Override = 7

# 3) Editor preference + alias
$EDITOR_Override = "code"

# 4) Safer theme init (no network fetch each session)
function Get-Theme_Override {
  if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh | Invoke-Expression
  } else {
    Write-Host "oh-my-posh not installed; skipping prompt." -ForegroundColor DarkYellow
  }
}

# 5) (Optional) disable auto profile/PowerShell updates and just notify
# function Update-Profile_Override { Write-Host "Update-Profile: disabled by override." -ForegroundColor DarkYellow }
# function Update-PowerShell_Override {
#   Write-Host "A newer PowerShell may be available. Run manually:" -ForegroundColor DarkYellow
#   Write-Host "  winget upgrade Microsoft.PowerShell --accept-source-agreements --accept-package-agreements"
# }

# 6) Safer Clear-Cache (avoid Prefetch/system-wide)
function Clear-Cache_Override {
  Write-Host "Clearing only user TEMP..." -ForegroundColor Cyan
  Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
}

# 7) Prediction tuning + sensitive command filtering
function Set-PredictionSource_Override {
  Set-PSReadLineOption -PredictionSource HistoryAndPlugin
  Set-PSReadLineOption -MaximumHistoryCount 20000
  Set-PSReadLineOption -AddToHistoryHandler {
    param($line)
    return ($line -notmatch 'password|secret|token|apikey|connectionstring')
  }
}

# 8) Don’t auto-run remote WinUtil; block or point to your own
function WinUtilDev_Override { Write-Host "winutildev disabled by override." -ForegroundColor DarkYellow }
Set-Alias -Name winutil -Value WinUtilDev_Override  # optional: neutralize winutil too

# 9) Telemetry opt-out for current user (non-admin-safe)
[System.Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT','true','User')

# 10) zoxide: init only if installed (don’t install from profile)
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
  Invoke-Expression (& { (zoxide init --cmd z powershell | Out-String) })
}
```

---

## Common Qs / Gotchas

* **“Do I have to edit `Microsoft.PowerShell_profile.ps1`?”**
  No. The clean pattern is: keep the base file as-is; do everything in `profile.ps1` via `_Override`. Changing the base default `$repo_root` to your fork is optional but harmless.

* **“Can I use GitHub’s `/raw/` path instead of `raw.githubusercontent.com`?”**
  Sometimes yes, but stick to `raw.githubusercontent.com` — that’s exactly what the updater uses.

* **“Will this touch my Windows PowerShell 5.1 profile?”**
  Only if you run the setup from 5.1. PS 7 writes to `~/Documents/PowerShell/…`, 5.1 uses `~/Documents/WindowsPowerShell/…`. Keep them separate.

* **“First run still updated from Chris’ repo!”**
  That happens if your `profile.ps1` didn’t exist before the base file ran. Fix: make sure your `setup.ps1` **creates** `profile.ps1` (with `$repo_root_Override`) before your next session — see step 3C.

---

PowerShell profiles are confusing the first time. Here’s the simple mental model and the exact steps you need.


# The 2 files you care about

Think of it like this:

| File              | Path (PS 7)                                               | Path (WinPS 5.1)                                                 | Who owns it?                 | Overwritten by updates? | Purpose                                                            |
| ----------------- | --------------------------------------------------------- | ---------------------------------------------------------------- | ---------------------------- | ----------------------- | ------------------------------------------------------------------ |
| **Host profile**  | `~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1` | `~/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1` | Chris’ script (or your fork) | **Yes**                 | The “engine”. It auto-updates itself from a repo. Don’t edit this. |
| **Your override** | `~/Documents/PowerShell/Profile.ps1`                      | `~/Documents/WindowsPowerShell/Profile.ps1`                      | **You**                      | **No**                  | Your custom settings. Put `_Override` variables/functions here.    |

PowerShell loads *both* on startup, and it loads **your override (Profile.ps1) first**.
The host profile then checks “do you have `*_Override` things defined? If yes, use those instead of my defaults.”

That’s why Chris says “run `Edit-Profile`”: it opens **your override** file so you can add your customizations.

---

# Where do overrides go?

**All overrides go in `Profile.ps1`**, i.e. `$PROFILE.CurrentUserAllHosts`.
That’s exactly the file `Edit-Profile` opens:

```powershell
function Edit-Profile { vim $PROFILE.CurrentUserAllHosts }
```

> `vim` is an alias that points to whatever `$EDITOR` was detected (nvim, VS Code, Notepad, …). If you don’t have those, you can just open the file with Notepad manually (shown below).

---

# Your situation (today)

From your log:

```
C:\Users\david\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
```

You ran the installer from **Windows PowerShell 5.1** (“Desktop”). So:

* Your **host profile** is in `WindowsPowerShell\Microsoft.PowerShell_profile.ps1` (auto-updated).
* Your **override** should be `WindowsPowerShell\Profile.ps1` (that’s the one you edit and keep).

You can set up PowerShell 7 later in the parallel `Documents\PowerShell` folder with the exact same pattern.

---

# Step-by-step: create overrides, point to your fork, and verify

> Run the following inside **Windows PowerShell 5.1** (the same shell you used to install).

### 1) Create (or open) your override file

```powershell
# Show the paths so you know where things are
$PROFILE
$PROFILE.CurrentUserAllHosts

# Ensure the folder/file exist for your overrides (WinPS 5.1 path)
$override = $PROFILE.CurrentUserAllHosts  # -> ...\WindowsPowerShell\Profile.ps1
$dir = Split-Path $override
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
if (-not (Test-Path $override)) { New-Item -ItemType File -Path $override | Out-Null }

# Open it (pick one)
notepad $override
# or, if Edit-Profile works for you:
# Edit-Profile
```

### 2) Paste this **minimal** override content

> This points updates at **your** fork and fixes the timestamp path for WinPS 5.1.

```powershell
# ===== david's overrides (Profile.ps1) =====

# Use my fork for auto-updates (raw domain, no trailing slash)
$repo_root_Override = "https://raw.githubusercontent.com/davidabad98"

# Where the updater stores its last-run timestamp (5.1 lives under WindowsPowerShell)
$timeFilePath_Override = "$HOME\Documents\WindowsPowerShell\LastExecutionTime.txt"

# How often to check (days). -1 = always check
$updateInterval_Override = 7

# Preferred editor for Edit-Profile, etc.
$EDITOR_Override = "code"

# Make oh-my-posh init not depend on a remote theme fetch each start
function Get-Theme_Override {
  if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh | Invoke-Expression
  } else {
    Write-Host "oh-my-posh not installed; skipping prompt." -ForegroundColor DarkYellow
  }
}

# Safer Clear-Cache (skip Prefetch/system Temp)
function Clear-Cache_Override {
  Write-Host "Clearing only user TEMP..." -ForegroundColor Cyan
  Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
}
```

Save the file.

### 3) Reload profiles in this session (or just open a new window)

```powershell
. $PROFILE.CurrentUserAllHosts   # dot-source your overrides first
& $PROFILE                       # then run the host profile
```

### 4) Confirm the updater will use your fork

```powershell
$url = "$repo_root/powershell-profile/main/Microsoft.PowerShell_profile.ps1"
$url
# Should print: https://raw.githubusercontent.com/davidabad98/powershell-profile/main/Microsoft.PowerShell_profile.ps1
```

### 5) Force an update now (pulls your fork)

```powershell
Update-Profile
```

You should see “Profile has been updated…”. From now on, changes you push to your fork’s `Microsoft.PowerShell_profile.ps1` are the ones that get synced.

> How does it know to update? The script downloads your remote profile to `%TEMP%`, computes its **SHA256** with `Get-FileHash`, compares to your local file’s hash, and if different, overwrites the local file. Any content change in your fork (even whitespace) changes the hash → update happens.

---

# Day-2 workflow (what you do later)

1. **You change files in your fork** (usually `Microsoft.PowerShell_profile.ps1`). Commit & push.
2. Next time you open a PowerShell window:

   * The host profile runs, sees your `_Override` values (because your `Profile.ps1` loaded first),
   * It checks `$repo_root` (now your fork), downloads that file, compares hashes, and updates if changed.
3. Or run `Update-Profile` manually anytime to force it.

---

# Using PowerShell 7 too? (Optional)

If you also want this in **PowerShell 7 (pwsh)**:

1. Open **pwsh**.
2. Repeat the same steps, but the paths will be:

   * Host profile: `~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1`
   * Overrides:     `~/Documents/PowerShell/Profile.ps1`
3. In your pwsh **Profile.ps1**, you can keep the same override content, but consider:

   ```powershell
   $timeFilePath_Override = "$HOME\Documents\PowerShell\LastExecutionTime.txt"
   ```

---

# TL;DR

* **Don’t edit** `Microsoft.PowerShell_profile.ps1`.
* **Do edit** `Profile.ps1` (your override). That’s what `Edit-Profile` opens.
* Put this in `Profile.ps1`:

  * `$repo_root_Override = "https://raw.githubusercontent.com/davidabad98"`
  * (Optionally) `$timeFilePath_Override`, `$updateInterval_Override`, `$EDITOR_Override`, and any `*_Override` functions you want.
* Reload, verify with:

  ```powershell
  "$repo_root/powershell-profile/main/Microsoft.PowerShell_profile.ps1"
  ```
* Run `Update-Profile` to pull from your fork immediately.



---

You’ve got it: that error means the **base profile** (the file that defines `Edit-Profile`) hasn’t been loaded into your *current* session yet — or you’re in the wrong shell (pwsh vs Windows PowerShell).

`Edit-Profile` is defined inside `Microsoft.PowerShell_profile.ps1`, so you need that file loaded first. PowerShell loads it automatically **on a new window**, but if you just created/changed things, you can load it manually.

Here’s the quickest way to fix it, step by step.

---

## 0) Make sure you’re in the right shell

You installed into **Windows PowerShell 5.1** (since your path is `…\WindowsPowerShell\`).

Run:

```powershell
$PSVersionTable.PSEdition
```

* If it prints `Desktop` → you’re in Windows PowerShell (correct).
* If it prints `Core` → you’re in PowerShell 7 (pwsh). Open **Windows PowerShell** instead and run the steps below there.

---

## 1) See your profile paths

```powershell
$PROFILE
$PROFILE.CurrentUserAllHosts
```

You should see something like:

* `$PROFILE` → `C:\Users\david\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`
* `$PROFILE.CurrentUserAllHosts` → `C:\Users\david\Documents\WindowsPowerShell\Profile.ps1`

---

## 2) Load both profiles **into this session**

> Order matters: load your overrides first, then the host profile.

```powershell
. $PROFILE.CurrentUserAllHosts   # dot-source your Profile.ps1 (overrides)
. $PROFILE                       # dot-source the base Microsoft.PowerShell_profile.ps1
```

> The leading dot + space **dot-sources** the file, which defines its functions (like `Edit-Profile`) in the current session.

If you get “running scripts is disabled”, run:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
Unblock-File $PROFILE
Unblock-File $PROFILE.CurrentUserAllHosts
```

Then repeat step 2.

---

## 3) Verify the function exists, then use it

```powershell
Get-Command Edit-Profile
Edit-Profile
```

That should open your `Profile.ps1` (your override file) in whatever editor the profile sets (`vim` alias → usually VS Code or Notepad as fallback).

> Manual fallback if you prefer:
> `notepad $PROFILE.CurrentUserAllHosts`

---

## 4) TL;DR of the normal flow

* **Normally you don’t “run” the base file manually**; opening a **new** Windows PowerShell window auto-loads:

  1. `Profile.ps1` (your overrides), then
  2. `Microsoft.PowerShell_profile.ps1` (the engine; defines `Edit-Profile`, etc.).

* If you edit either file and want changes **immediately**, dot-source them as in step 2.

---

## 5) Bonus: quick “reload” alias for later

Since `reload-profile` is also defined in the base profile (and won’t work until it’s loaded), you can add a tiny helper to your overrides so you always have a reload command:

In `Profile.ps1`, add:

```powershell
function Reload-Profiles {
  . $PROFILE.CurrentUserAllHosts
  . $PROFILE
}
Set-Alias rp Reload-Profiles
```

Then you can run `rp` any time to reload both.

---

If `Get-Command Edit-Profile` still fails after dot-sourcing, paste the output of:

```powershell
Test-Path $PROFILE
Get-Content $PROFILE -Head 20
```

and we’ll sanity-check that the base file on disk is the one you expect.
