# Windows Logoff Artifact Cleanup

A PowerShell script that clears selected Windows user-activity artefacts automatically on logoff. Written for a System Security and Forensics assignment on residual user data in Windows.

## What it cleans

One artefact per category, chosen to be user-scoped and safely deletable without side effects on the OS:

| Category | Artefact | Location |
|---|---|---|
| File system | Jump Lists | `%APPDATA%\Microsoft\Windows\Recent\{AutomaticDestinations, CustomDestinations}` |
| Registry | RecentDocs | `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs` |
| App database | Browser history | `History` file for Chrome, Edge, Brave, and Opera (whichever are present) |

## Requirements

- Windows PowerShell 5.1+ (or PowerShell 7+)
- Run under the user account whose artefacts should be cleared (uses `HKCU` and per-user `%APPDATA%`/`%LOCALAPPDATA%` paths)

## Usage

Run directly:

```powershell
.\Invoke-LogoffCleanup.ps1
```

Or call the function with custom paths (e.g. non-default browser install locations):

```powershell
Invoke-LogoffCleanup -RecentDocsPath "HKCU:\...\RecentDocs" -BrowserPaths @{ "Chrome" = "D:\CustomProfile\History" }
```

## Script structure

- `Remove-JumpList` — clears Automatic/Custom Jump List destinations
- `Remove-RecentDocs` — clears RecentDocs subkeys and top-level MRU values
- `Remove-BrowserHistory` — checks for installed browsers and clears whichever history files exist
- `Invoke-LogoffCleanup` — orchestrator; runs each cleanup independently so one failure doesn't block the others

Errors are reported via `Write-Host` only (console), not logged to a file — a persistent log of what the script cleaned would itself become a new residual artefact, which defeats the purpose of the cleanup.

## Running on logoff

Register the script as a **logoff script** via one of:

- **Group Policy** (`gpedit.msc` → User Configuration → Windows Settings → Scripts → Logoff)
- **Task Scheduler**, triggered on the logoff event (Event ID 4647, Security log, or the built-in "On workstation unlock/logoff" trigger)

## Scope and limitations

This script targets three specific artefacts. It does **not** achieve full anti-forensic cleanup — overlapping traces of the same activity can remain in other artefacts not covered here (e.g. `UserAssist`, Prefetch, `$MFT`/USN Journal, Volume Shadow Copies, thumbnail cache). See the assignment report for a discussion of cross-artefact recoverability.

## Disclaimer

Built for academic coursework on digital forensics. Not intended as a privacy or anti-forensic tool for production use.
