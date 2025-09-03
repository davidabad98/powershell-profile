# 🎨 PowerShell Profile (Pretty PowerShell)

A stylish and functional PowerShell profile that looks and feels almost as good as a Linux terminal.

## ⚡ One Line Install (Elevated PowerShell Recommended)

Execute the following command in an elevated PowerShell window to install the PowerShell profile:

```
irm "https://raw.githubusercontent.com/davidabad98/powershell-profile/main/setup.ps1" | iex

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

