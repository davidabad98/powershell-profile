# 🎨 PowerShell Profile (Pretty PowerShell)

A stylish and functional PowerShell profile that looks and feels almost as good as a Linux terminal.

## ⚡ One Line Install (Elevated PowerShell Recommended)

Execute the following command in an elevated PowerShell window to install the PowerShell profile:

```
irm "https://raw.githubusercontent.com/davidabad98/powershell-profile/main/setup.ps1" | iex

```

### Reload profiles in this session (or just open a new window)

```powershell
. $PROFILE.CurrentUserAllHosts   # dot-source your overrides first
& $PROFILE                       # then run the host profile
```

## 🛠️ Fix the Missing Font

After running the script, you'll have two options for installing a font patched to support icons in PowerShell:

### 1) You will find a downloaded `cove.zip` file in the folder you executed the script from. Follow these steps to install the patched `Caskaydia Cove` nerd font family:

1. Extract the `cove.zip` file.
2. Locate and install the nerd fonts.

### 2) With `oh-my-posh` (loaded automatically through the PowerShell profile script hosted on this repo):
1. Run the command `oh-my-posh font install`
2. A list of Nerd Fonts will appear like so:
<pre>
PS> oh-my-posh font install

   Select font

  > 0xProto
    3270
    Agave
    AnonymousPro
    Arimo
    AurulentSansMono
    BigBlueTerminal
    BitstreamVeraSansMono

    •••••••••
    ↑/k up • ↓/j down • q quit • ? more</pre>
3. With the up/down arrow keys, select the font you would like to install and press <kbd>ENTER</kbd>
4. DONE!
   
## Customize this profile

**Do not make any changes to the `Microsoft.PowerShell_profile.ps1` file**, since it's hashed and automatically overwritten by any commits to this repository.

After the profile is installed and active, run the `Edit-Profile` function to create a separate profile file [`profile.ps1`] for your current user. Add any custom code, and/or override VARIABLES/FUNCTIONS in `Microsoft.PowerShell_profile.ps1` by adding any of the following Variable or Function names:

THE FOLLOWING VARIABLES RESPECT _Override:
<pre>
$EDITOR_Override
$debug_Override
$repo_root_Override  [To point to a fork, for example]
$timeFilePath_Override
$updateInterval_Override
</pre>

THE FOLLOWING FUNCTIONS RESPECT _Override: _(do not call the original function from your override function, or you'll create an infinite loop)_
<pre>
Debug-Message_Override
Update-Profile_Override
Update-PowerShell_Override
Clear-Cache_Override
Get-Theme_Override
WinUtilDev_Override [To call a fork, for example]
</pre>

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

# Step-by-step: create overrides, point to your fork, and verify

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

# Workflow (what you do later)

1. **You change files in your fork** (usually `Microsoft.PowerShell_profile.ps1`). Commit & push.
2. Next time you open a PowerShell window:

   * The host profile runs, sees your `_Override` values (because your `Profile.ps1` loaded first),
   * It checks `$repo_root` (now your fork), downloads that file, compares hashes, and updates if changed.
3. Or run `Update-Profile` manually anytime to force it.

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

# Error with Windows PowerShell’s execution policy.

## What happened

* Your two profile scripts (`profile.ps1` and `Microsoft.PowerShell_profile.ps1`) were downloaded from the internet, so Windows tagged them as “from the web.”
* With a strict policy, PowerShell refuses to load unsigned/blocked scripts at startup.

## Fix it (Windows PowerShell 5.1)

Run these in the same console that showed the error:

```powershell
# 1) See your current policies (just to know what's set)
Get-ExecutionPolicy -List

# 2) Allow local scripts + unblocked downloaded scripts for YOUR user
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force

# 3) Remove the "downloaded from internet" mark from your two profile files
Unblock-File "$HOME\Documents\WindowsPowerShell\profile.ps1"
Unblock-File "$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"

# 4) Reload both profiles into this session (or just open a new window)
. $PROFILE.CurrentUserAllHosts
. $PROFILE

# 5) Quick sanity check
Get-Command Edit-Profile
```

If `Get-Command Edit-Profile` shows the function, you’re good. Open a **new** Windows PowerShell window and it’ll auto-load without the error.

### If step 2 says policy is locked by Group Policy

`Get-ExecutionPolicy -List` will show `UserPolicy` or `MachinePolicy` set (e.g., `AllSigned`). You have two options:

* **Quick workaround per shortcut (bypass at launch):**
  Create a shortcut that launches:

  ```
  %SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass
  ```

  (More permissive; fine on a dev box you control.)

* **Proper way (advanced):** keep `AllSigned` and **sign your profiles** with a self-signed code-signing cert. If you want this route, tell me and I’ll give you the exact commands to create a cert, trust it, and sign your `*.ps1`.

## If you also use PowerShell 7 (pwsh)

PowerShell 7 has its **own** execution policy scope. Open **pwsh** and run the same two commands:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
Unblock-File "$HOME\Documents\PowerShell\profile.ps1"
Unblock-File "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
```

Then restart **pwsh**.

---

### Why this works (super short)

* `RemoteSigned` lets **local** scripts run and allows **downloaded** scripts once you `Unblock-File` (which removes the internet zone mark).
* After that, your override (`profile.ps1`) loads first, the base profile loads second, and your `_Override` settings point updates at **your fork** automatically.

---

# Windows PowerShell 5.1 Errors

This happens when you’re loading the profile in **Windows PowerShell 5.1** (“Desktop”), but parts of the script assume **PowerShell 7+**:

* `Test-Connection -TimeoutSeconds` → **only in PS7** (5.1 doesn’t have that param).
* `Set-PSReadLineOption -PredictionSource ...` → **Predictive IntelliSense is PS7-only** (PSReadLine 2.1+ on PS7).

You’ve got two clean paths. Pick **A (recommended)** if you want the best developer experience; pick **B** if you need to stay on 5.1.

---

# A) Recommended: use PowerShell 7 (pwsh)

## 1) Install and open pwsh

```powershell
winget install --id Microsoft.PowerShell -e
# Open a new "PowerShell 7" window (pwsh). Confirm:
$PSVersionTable.PSEdition   # should say Core
```

## 2) Create your PS7 override (so updates point to your fork)

```powershell
$override = $PROFILE.CurrentUserAllHosts   # -> C:\Users\david\Documents\PowerShell\Profile.ps1
$dir = Split-Path $override
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
if (-not (Test-Path $override)) { New-Item -ItemType File -Path $override | Out-Null }

@'
# === david's PS7 overrides ===
$repo_root_Override      = "https://raw.githubusercontent.com/davidabad98"
$timeFilePath_Override   = "$HOME\Documents\PowerShell\LastExecutionTime.txt"
$updateInterval_Override = 7
$EDITOR_Override         = "code"

function Get-Theme_Override {
  if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh | Invoke-Expression
  }
}

# PS7 supports predictions; keep it
function Set-PredictionSource_Override {
  Set-PSReadLineOption -PredictionSource HistoryAndPlugin
  Set-PSReadLineOption -MaximumHistoryCount 20000
}
'@ | Set-Content -Encoding UTF8 $override
```

## 3) Pull your fork’s base profile in PS7

```powershell
. $PROFILE.CurrentUserAllHosts
. $PROFILE    # if it exists already; else run your setup against PS7 once
Update-Profile
```

## 4) Make PS7 your default in Windows Terminal (optional but nice)

* Settings → Default profile → **PowerShell** (the one with `pwsh.exe`).
* You can leave WinPS 5.1 installed but rarely use it.

**Result:** all errors go away (params exist in PS7), you keep the same override/update model, and you get better performance + features.

---

# B) Stay on Windows PowerShell 5.1 (make your fork 5.1-safe)

Since you control the fork, tweak **your** `Microsoft.PowerShell_profile.ps1` to be 5.1-compatible. Two minimal edits:

## 1) Replace the GitHub connectivity check (no `-TimeoutSeconds` in 5.1)

**Find** (near top):

```powershell
$global:canConnectToGitHub = Test-Connection github.com -Count 1 -Quiet -TimeoutSeconds 1
```

**Replace with**:

```powershell
try {
    $p = New-Object System.Net.NetworkInformation.Ping
    $reply = $p.Send("github.com", 1000)  # 1000ms timeout
    $global:canConnectToGitHub = ($reply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success)
} catch {
    $global:canConnectToGitHub = $false
}
```

## 2) Guard PSReadLine predictions (not supported on 5.1)

**A.** Remove `PredictionSource` and `PredictionViewStyle` from the initial hashtable, and set only universal options:

```powershell
$PSReadLineOptions = @{
    EditMode = 'Windows'
    HistoryNoDuplicates = $true
    HistorySearchCursorMovesToEnd = $true
    Colors = @{
        Command = '#87CEEB'
        Parameter = '#98FB98'
        Operator = '#FFB6C1'
        Variable = '#DDA0DD'
        String = '#FFDAB9'
        Number = '#B0E0E6'
        Type = '#F0E68C'
        Comment = '#D3D3D3'
        Keyword = '#8367c7'
        Error = '#FF6347'
    }
    BellStyle = 'None'
}
Set-PSReadLineOption @PSReadLineOptions
```

**B.** Later in the file (where it calls `Set-PredictionSource`), change it to only apply on PS7:

```powershell
function Set-PredictionSource {
    if (Get-Command -Name "Set-PredictionSource_Override" -ErrorAction SilentlyContinue) {
        Set-PredictionSource_Override
    } else {
        # Only enable predictions on PS7+ (Core) with PSReadLine >= 2.1
        $isPS7 = ($PSVersionTable.PSEdition -eq 'Core')
        $prl   = Get-Module -ListAvailable PSReadLine | Sort-Object Version -Descending | Select-Object -First 1
        if ($isPS7 -and $prl.Version -ge [version]'2.1.0') {
            Set-PSReadLineOption -PredictionSource HistoryAndPlugin
            Set-PSReadLineOption -MaximumHistoryCount 10000
        } else {
            # 5.1 fallback: no predictions
            Set-PSReadLineOption -MaximumHistoryCount 10000
        }
    }
}
Set-PredictionSource
```

(You can also keep your **override** `Set-PredictionSource_Override` and perform the same check there.)

## 3) Commit & push those changes to **your fork**, then update locally

In **Windows PowerShell 5.1**:

```powershell
Update-Profile
```

Restart the console; the parameter errors should be gone.

---

## Sanity checks

* Which shell am I in?

```powershell
$PSVersionTable.PSEdition   # Desktop == WinPS 5.1; Core == PS7
```

* Do I have predictions (PS7)?

```powershell
Get-Module PSReadLine | Select Name, Version
# Predictions require PS7 + PSReadLine >= 2.1.0
```

* Where is my override file?

```powershell
$PROFILE.CurrentUserAllHosts
```

---

## My recommendation

Adopt **PS7** now (Path A), and keep your 5.1 profile minimal (maybe just a message reminding you to use PS7). You’ll avoid constant “works in PS7, not in 5.1” quirks and get faster startup, better modules, and modern features (predictions, ANSI, etc.).
