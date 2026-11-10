function script:Remove-JumpList {
    param(
        [Parameter(Mandatory)][string] $AutomaticDir,
        [Parameter(Mandatory)][string] $CustomDir
    )
    $errorList = @()

    if (Test-Path $AutomaticDir) { Remove-Item "$AutomaticDir\*" -Force -ErrorAction SilentlyContinue }
    else { $errorList += "Folder not found: $AutomaticDir" }

    if (Test-Path $CustomDir) { Remove-Item "$CustomDir\*" -Force -ErrorAction SilentlyContinue }
    else { $errorList += "Folder not found: $CustomDir" }

    if ($errorList.Count -gt 0) { throw ($errorList -join "; ") }
}

function script:Remove-RecentDocs {
    param(
        [Parameter(Mandatory)][string] $RecentDocsPath
    )
    if (-not (Test-Path $RecentDocsPath)) { throw "Path not found: $RecentDocsPath" }

    Get-ChildItem -Path $RecentDocsPath -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-Item -Path $_.PsPath -Recurse -Force
    }
    Get-Item -Path $RecentDocsPath | Select-Object -ExpandProperty Property | ForEach-Object {
        Remove-ItemProperty -Path $RecentDocsPath -Name $_ -Force -ErrorAction SilentlyContinue
    }
}

function script:Remove-BrowserHistory {
    param(
        [Parameter(Mandatory)][hashtable] $BrowserPaths
    )
    $errorList = @()

    foreach ($browser in $BrowserPaths.Keys) {
        $path = $BrowserPaths[$browser]
        if (Test-Path $path) {
            Remove-Item -Path $path -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$path-journal" -Force -ErrorAction SilentlyContinue
        } else {
            $errorList += "Clean failed for $browser with path: $path"
        }
    }

    if ($errorList.Count -gt 0) { throw ($errorList -join "; ") }
}

function Invoke-LogoffCleanup {
    param(
        [string] $JumpListAutoPath   = "$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations",
        [string] $JumpListCustomPath = "$env:APPDATA\Microsoft\Windows\Recent\CustomDestinations",
        [string] $RecentDocsPath     = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs",
        [hashtable] $BrowserPaths    = @{
            "Chrome" = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\History"
            "Edge"   = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\History"
            "Brave"  = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\History"
            "Opera"  = "$env:APPDATA\Opera Software\Opera Stable\History"
        }
    )

    $tasks = @(
        @{ Name = "Jump Lists";      Action = { Remove-JumpList -AutomaticDir $JumpListAutoPath -CustomDir $JumpListCustomPath } },
        @{ Name = "RecentDocs";      Action = { Remove-RecentDocs -RecentDocsPath $RecentDocsPath } },
        @{ Name = "Browser History"; Action = { Remove-BrowserHistory -BrowserPaths $BrowserPaths } }
    )

    foreach ($task in $tasks) {
        try { & $task.Action }
        catch { Write-Host "[ERROR] $($task.Name): $($_.Exception.Message)" -ForegroundColor Red }
    }
}