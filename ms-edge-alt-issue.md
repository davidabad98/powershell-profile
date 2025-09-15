# Problem: Disable Alt Key focuses on the Ellipses menu
https://learn.microsoft.com/en-us/answers/questions/2403208/disable-alt-key-from-microsoft-edge-as-it-interfer

A fix is possible, and the snippet you found is the right policy. Here’s exactly what to do in **Registry Editor** and how to test it.

# Do this in Registry Editor (per-user)

1. In `HKEY_CURRENT_USER\SOFTWARE\Policies\Microsoft\Edge`
   (create any missing keys), **New → String Value (REG\_SZ)**.

2. Name it: `ConfigureKeyboardShortcuts`

3. Set its **value data** to:

   ```
   {"disabled":["focus_settings_and_more"]}
   ```

   (type it exactly like that — JSON is case-sensitive).

4. **Close all Edge windows** (policy requires a browser restart).

5. Reopen Edge, go to **edge://policy**, and click **Reload policies**. You should see `ConfigureKeyboardShortcuts` listed with your JSON and no errors. ([Microsoft Learn][1])

# How to verify it worked

* Press **Alt** or **F10**: the “Settings and more …” (ellipsis) button should **no longer get focus**.
* Shortcuts like **Alt+Left/Right** (Back/Forward) and **Alt+Home** will still work — you only disabled the command that focuses the ellipsis, not other Alt combos. The specific command you disabled is `focus_settings_and_more`. ([go.microsoft.com][2])

# Optional: do it for all users on the device

If you want this enforced machine-wide, create the same `ConfigureKeyboardShortcuts` string under:

```
HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge
```

(Edge reads policies from HKLM and HKCU.) ([Microsoft Learn][1])

# Prefer Group Policy or Intune?

* **GPO path:** Computer or User Configuration → Administrative Templates → **Microsoft Edge** → **Configure the list of commands for which to disable keyboard shortcuts**. Put `{"disabled":["focus_settings_and_more"]}` into the policy’s JSON. ([Microsoft Learn][1])
* **Intune:** Settings catalog → Microsoft Edge → same policy, paste the same JSON. ([Microsoft Learn][3])

# Notes & gotchas

* This policy is **per profile** and **not dynamically refreshed** — a simple browser restart is needed. ([Microsoft Learn][1])
* If you’re signed into a **personal Microsoft account profile**, some policies may not apply; use a work-managed profile. ([Microsoft Learn][4])

# Quick rollback

Delete the `ConfigureKeyboardShortcuts` value (or remove `focus_settings_and_more` from the JSON), restart Edge.

[1]: https://learn.microsoft.com/en-us/deployedge/microsoft-edge-browser-policies/configurekeyboardshortcuts "Microsoft Edge Browser Policy Documentation ConfigureKeyboardShortcuts | Microsoft Learn"
[2]: https://go.microsoft.com/fwlink/?linkid=2186950 "Configurable Microsoft Edge commands | Microsoft Learn"
[3]: https://learn.microsoft.com/en-us/intune/intune-service/configuration/settings-catalog-configure-edge?utm_source=chatgpt.com "Configure Microsoft Edge policy settings in Microsoft Intune"
[4]: https://learn.microsoft.com/en-us/deployedge/microsoft-edge-policies?utm_source=chatgpt.com "Microsoft Edge Browser Policy Documentation | Microsoft Learn"


# Why edge://policy shows it with “no value”

That view lists *all* supported policies. If you only see **ConfigureKeyboardShortcuts** after turning on “Show policies with no value,” Edge didn’t find a valid setting in the registry. The most common reasons:

1. **Wrong registry path**
   Make sure you’re under the **Policies** branch, not the normal app settings branch. The exact per-user path is:
   `HKEY_CURRENT_USER\SOFTWARE\Policies\Microsoft\Edge`
   (“Policies” is required.) The policy is a **REG\_SZ** named `ConfigureKeyboardShortcuts` whose data is JSON. ([Microsoft Learn][1])

2. **JSON not exactly right**
   The value must be double-quoted JSON. A known-good example to disable the Alt/F10 focus is:
   `{"disabled":["focus_settings_and_more"]}`
   (`focus_settings_and_more` is the command that Alt/F10 triggers to focus the “Settings and more …” button.) ([go.microsoft.com][2])

3. **Edge profile type**
   This policy **doesn’t apply to profiles signed in with a personal Microsoft account (MSA)**. If the active Edge profile is an MSA, the policy is ignored. Test with a local (not-signed-in) profile or a work/Entra ID profile. ([Microsoft Learn][1])
   (And as of Edge 116, Microsoft tightened this behavior for some policies.) ([Microsoft Learn][3])

4. **Browser not fully restarted**
   The policy isn’t dynamically refreshed—**close all Edge windows** (ensure no `msedge.exe` remain in Task Manager) and reopen, then go to **edge://policy** and click **Reload policies**. ([Microsoft Learn][1])

---

# Exactly what to do (quick, reliable)

## A) Per-user (HKCU)

1. In **Regedit**, go to:
   `HKEY_CURRENT_USER\SOFTWARE\Policies\Microsoft\Edge`
   (Create the missing **Policies → Microsoft → Edge** keys if needed.)
2. Create **String Value (REG\_SZ)** named: `ConfigureKeyboardShortcuts`
3. Set its **Data** to:
   `{"disabled":["focus_settings_and_more"]}`
4. Close all Edge windows → reopen → **edge://policy → Reload policies**. You should now see the JSON under ConfigureKeyboardShortcuts. ([Microsoft Learn][1])

## B) All users (HKLM) — answering your question

> “inside the Microsoft folder i dont have an Edge folder, should i create it?”

**Yes.** Create it—policies are read from that path even if you create it yourself. Use admin rights and add the same value here:
`HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge` → **String (REG\_SZ)** `ConfigureKeyboardShortcuts` = `{"disabled":["focus_settings_and_more"]}`. ([Microsoft Learn][1])

---

# Safer, copy-paste commands (less typo-prone)

**PowerShell (current user):**

```powershell
New-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft" -Name "Edge" -Force | Out-Null
New-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Edge" -Name "ConfigureKeyboardShortcuts" `
  -PropertyType String -Value '{"disabled":["focus_settings_and_more"]}' -Force | Out-Null
```

**PowerShell (all users, run as Admin):**

```powershell
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft" -Name "Edge" -Force | Out-Null
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "ConfigureKeyboardShortcuts" `
  -PropertyType String -Value '{"disabled":["focus_settings_and_more"]}' -Force | Out-Null
```

Restart Edge and check **edge://policy** again (Reload).

---

# Quick verification

* Press **Alt** or **F10** in a page: the ellipsis (… “Settings and more”) **should no longer get focus**.
* Other Alt shortcuts like **Alt+Left/Right/Home** still work; only the specific command `focus_settings_and_more` is disabled. ([go.microsoft.com][2])

If it still shows “no value” after doing the above:

* Double-check you used the **Policies** path (not `…\SOFTWARE\Microsoft\Edge`). ([Microsoft Learn][1])
* Sign out of any **personal Microsoft account** in Edge (or switch to a work/local profile) and restart. ([Microsoft Learn][1])
* Confirm Edge is **version 101+** (edge://version). ([Microsoft Learn][1])

[1]: https://learn.microsoft.com/en-us/deployedge/microsoft-edge-browser-policies/configurekeyboardshortcuts "Microsoft Edge Browser Policy Documentation ConfigureKeyboardShortcuts | Microsoft Learn"
[2]: https://go.microsoft.com/fwlink/?linkid=2186950 "Configurable Microsoft Edge commands | Microsoft Learn"
[3]: https://learn.microsoft.com/en-us/deployedge/microsoft-edge-policies?utm_source=chatgpt.com "Microsoft Edge Browser Policy Documentation | Microsoft Learn"

