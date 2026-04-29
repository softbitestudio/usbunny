<#
.SYNOPSIS
    Windows Repair & Malware Audit Script (Online + WinRE Offline) 🐾
.DESCRIPTION
    Normal Windows mode: Runs SFC/DISM repairs + deep malware-persistence audit (sniffing for bad mice).
    WinRE mode: Performs offline SFC/DISM/chkdsk against an unbootable Windows install (emergency bunny medic).
.NOTES
    Run as Administrator (normal Windows) or from WinRE Command Prompt.
    Malware hooks are AUDIT-ONLY. They flag artifacts for review but do not auto-remediate. *purrs*
#>

#Requires -RunAsAdministrator

#region Environment Detection & Config x
function Test-WinRE {
    if ($env:SystemDrive -eq "X:") { return $true }
    if (Test-Path "X:\Windows\System32\winpeshl.exe") { return $true }
    if (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\MiniNT" -ErrorAction SilentlyContinue) { return $true }
    return $false
}

$inWinRE = Test-WinRE
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).ProviderPath }
$LogDir    = if ($inWinRE) { "$ScriptDir\RepairLogs" } else { "$env:SystemDrive\RepairLogs" }
$LogFile   = "$LogDir\Repair_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$script:SuspiciousFindings = @()
#endregion

#region Helper Functions
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$ts] [$Level] $Message"
    if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }
    Add-Content -Path $LogFile -Value $line -ErrorAction SilentlyContinue
    switch ($Level) {
        "ERROR"   { Write-Host $line -ForegroundColor Red }
        "WARN"    { Write-Host $line -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $line -ForegroundColor Green }
        "ALERT"   { Write-Host $line -ForegroundColor Magenta }
        default   { Write-Host $line }
    }
}

function Add-Finding {
    param([string]$Category, [string]$Details)
    $script:SuspiciousFindings += [PSCustomObject]@{
        Category = $Category
        Details  = $Details
        Time     = Get-Date
    }
    Write-Log "[$Category] $Details" "ALERT"
}

function Invoke-WithLog {
    param([string]$Description, [scriptblock]$Action)
    Write-Log "START: $Description *twitching nose*"
    try {
        $result = & $Action
        Write-Log "SUCCESS: $Description *happy hops*" "SUCCESS"
        return $result
    } catch {
        Write-Log "ERROR: $Description - $($_.Exception.Message) *hisses*" "ERROR"
    }
}

function Select-OfflineWindows {
    $vols = Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -eq 'Fixed' } | Select-Object -ExpandProperty DriveLetter
    $targets = @()
    foreach ($v in $vols) {
        if ((Test-Path "$($v):\Windows\System32\config\SYSTEM") -and (Test-Path "$($v):\Windows\System32")) {
            $targets += "$($v):"
        }
    }
    if ($targets.Count -eq 0) { Write-Log "No Windows installations found... *sad meow*" "ERROR"; return $null }
    Write-Host "`nDetected Windows installations (found the cozy spots!):" -ForegroundColor Cyan
    for ($i = 0; $i -lt $targets.Count; $i++) { Write-Host "  [$i] $($targets[$i])\Windows" }
    $sel = Read-Host "Select target by number, meow"
    if ($sel -match '^\d+$' -and [int]$sel -lt $targets.Count) { return $targets[[int]$sel] }
    return $null
}
#endregion

#region Malware Audit Functions (Online Only)
function Test-MalwareHosts {
    $hosts = "$env:SystemRoot\System32\drivers\etc\hosts"
    if (-not (Test-Path $hosts)) { return }
    $lines = Get-Content $hosts | Where-Object {
        $_ -notmatch '^\s*#' -and $_ -notmatch '^\s*$' -and `
        $_ -notmatch '127\.0\.0\.1\s+(localhost|loopback)' -and $_ -notmatch '::1\s+localhost'
    }
    foreach ($line in $lines) { Add-Finding "HOSTS File" $line }
}

function Test-RunKeys {
    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
    )
    $suspicious = @('temp','tmp','appdata','roaming','powershell -enc','base64','bitsadmin','certutil','regsvr32','mshta','wscript','cscript','http','scrobj.dll')
    foreach ($p in $paths) {
        if (-not (Test-Path $p)) { continue }
        $item = Get-ItemProperty $p
        $item.PSObject.Properties | Where-Object {
            @('PSPath','PSParentPath','PSChildName','PSDrive','PSProvider','(default)') -notcontains $_.Name
        } | ForEach-Object {
            $val = $_.Value.ToString()
            if ($suspicious | Where-Object { $val -match $_ }) {
                Add-Finding "Run Key ($p)" "$($_.Name) = $val"
            }
        }
    }
}

function Test-SuspiciousServices {
    Get-CimInstance Win32_Service | Where-Object {
        $path = $_.PathName
        if (-not $path) { return $false }
        return ($path -match 'temp\\|\\users\\.*\\appdata\\|\\programdata\\') -or
               ($path -match '\.(bat|cmd|vbs|js|ps1|hta)$')
    } | ForEach-Object {
        Add-Finding "Suspicious Service" "$($_.Name) [$($_.DisplayName)] -> $($_.PathName)"
    }
}

function Test-ScheduledTasks {
    try {
        Get-ScheduledTask | Where-Object { $_.State -ne 'Disabled' } | ForEach-Object {
            $actions = ($_.Actions | ForEach-Object { "$($_.Execute) $($_.Arguments)" }) -join '; '
            if ($actions -match 'powershell.*-enc|base64|bitsadmin|certutil|regsvr32|mshta|wscript|cscript|http|\.bat|\.vbs|\.js|\.hta|temp\\|\\appdata\\|\\programdata\\') {
                Add-Finding "Scheduled Task" "$($_.TaskPath)$($_.TaskName) -> $actions"
            }
        }
    } catch { Write-Log "Scheduled task enumeration failed: $_" "WARN" }
}

function Test-WMIPersistence {
    try {
        $filters = Get-WmiObject -Namespace root\Subscription -Class __EventFilter -ErrorAction SilentlyContinue
        $consumers = Get-WmiObject -Namespace root\Subscription -Class __EventConsumer -ErrorAction SilentlyContinue
        foreach ($f in $filters)   { Add-Finding "WMI Filter" "$($f.Name): $($f.Query)" }
        foreach ($c in $consumers) {
            $cmd = if ($c.CommandLineTemplate) { $c.CommandLineTemplate } else { $c.ScriptText }
            Add-Finding "WMI Consumer" "$($c.Name): $cmd"
        }
    } catch { Write-Log "WMI check failed: $_" "WARN" }
}

function Test-NetworkConnections {
    Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue | Where-Object {
        $_.LocalAddress -notmatch '^127\.' -and $_.LocalAddress -notmatch '^::1'
    } | ForEach-Object {
        $proc = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
        if ($proc) {
            $path = $proc.Path
            if (($path -match '\\users\\') -and ($_.RemotePort -notin @(80,443,8080,993,995,587,465))) {
                Add-Finding "Suspicious Network" "$($proc.ProcessName) (PID $($_.OwningProcess)) -> $($_.RemoteAddress):$($_.RemotePort) [$path]"
            }
        }
    }
}

function Test-DNSCache {
    $cache = Get-DnsClientCache -ErrorAction SilentlyContinue | Where-Object {
        $_.Entry -notmatch '\.(microsoft|windows|office|live|msn|google|github|amazonaws|cloudfront|akamai|office365)\.'
    }
    if ($cache.Count -gt 100) {
        Add-Finding "DNS Cache" "Large non-standard DNS cache ($($cache.Count) entries). Review with: Get-DnsClientCache | Out-GridView"
    }
}

function Test-DefenderStatus {
    try {
        $mp = Get-MpPreference -ErrorAction Stop
        if ($mp.DisableRealtimeMonitoring)     { Add-Finding "Defender" "Real-time protection DISABLED (*scared squeak*)" }
        if ($mp.DisableBehaviorMonitoring)     { Add-Finding "Defender" "Behavior monitoring DISABLED" }
        if ($mp.DisableScriptScanning)         { Add-Finding "Defender" "Script scanning DISABLED" }
        if ($mp.ExclusionPath.Count -gt 0)     { Add-Finding "Defender" "Exclusions: $($mp.ExclusionPath -join ', ')" }
    } catch { Write-Log "Defender check skipped (not available)." "WARN" }
}

function Test-FirewallStatus {
    try {
        Get-NetFirewallProfile -ErrorAction Stop | Where-Object { $_.Enabled -eq 'False' } | ForEach-Object {
            Add-Finding "Firewall" "$($_.Name) profile is DISABLED (doors are wide open owo)"
        }
    } catch { Write-Log "Firewall check skipped." "WARN" }
}

function Test-ProxySettings {
    $proxy = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyServer -ErrorAction SilentlyContinue
    $enabled = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable -ErrorAction SilentlyContinue
    if ($enabled.ProxyEnable -eq 1) { Add-Finding "Proxy" "System proxy: $($proxy.ProxyServer)" }
}

function Test-PolicyRestrictions {
    $paths = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System"
    )
    foreach ($p in $paths) {
        if (-not (Test-Path $p)) { continue }
        $props = Get-ItemProperty $p
        if ($props.DisableTaskMgr)        { Add-Finding "Policy" "Task Manager disabled at $p (they hid the task manager! nya!)" }
        if ($props.DisableRegistryTools)  { Add-Finding "Policy" "Registry Editor disabled at $p" }
    }
}

function Test-ShadowCopies {
    $vss = Get-CimInstance Win32_ShadowCopy -ErrorAction SilentlyContinue
    if ($vss.Count -eq 0) {
        Add-Finding "VSS" "No Shadow Copies / Restore Points found. Malware might have eaten them, uwu."
    }
}

function Test-LocalAdmins {
    try {
        Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -notmatch 'Administrator|Domain Admins|NT AUTHORITY'
        } | ForEach-Object {
            Add-Finding "Local Admin" "Account: $($_.Name) [$($_.ObjectClass)]"
        }
    } catch { Write-Log "Local admin check failed." "WARN" }
}

function Invoke-MalwareAudit {
    Write-Host "`n=== MALWARE PERSISTENCE AUDIT (sniffing for bad mice) ===" -ForegroundColor Magenta
    Invoke-WithLog "Malware Audit" {
        Test-MalwareHosts
        Test-RunKeys
        Test-SuspiciousServices
        Test-ScheduledTasks
        Test-WMIPersistence
        Test-NetworkConnections
        Test-DNSCache
        Test-DefenderStatus
        Test-FirewallStatus
        Test-ProxySettings
        Test-PolicyRestrictions
        Test-ShadowCopies
        Test-LocalAdmins

        if ($script:SuspiciousFindings.Count -eq 0) {
            Write-Log "No obvious suspicious artifacts detected! Clean as a whistle! ✧˖°" "SUCCESS"
        } else {
            Write-Host "`n[!] Oh no! $($script:SuspiciousFindings.Count) suspicious findings detected:" -ForegroundColor Red
            $script:SuspiciousFindings | Format-Table -AutoSize | Out-Host
            $csv = "$LogDir\MalwareAudit_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
            $script:SuspiciousFindings | Export-Csv -Path $csv -NoTypeInformation
            Write-Log "Findings exported for review: $csv" "ALERT"
        }
    }
}
#endregion

#region Online Repair
function Invoke-OnlineRepair {
    Write-Host "`n=== ONLINE SYSTEM REPAIR (giving PC a bath) ===" -ForegroundColor Cyan

    Invoke-WithLog "SFC /scannow" {
        $proc = Start-Process sfc.exe -ArgumentList "/scannow" -Wait -PassThru -NoNewWindow
        return "Exit code: $($proc.ExitCode)"
    }

    Invoke-WithLog "DISM CheckHealth" { DISM /Online /Cleanup-Image /CheckHealth | Out-String }
    Invoke-WithLog "DISM ScanHealth"  { DISM /Online /Cleanup-Image /ScanHealth | Out-String }
    Invoke-WithLog "DISM RestoreHealth"{ DISM /Online /Cleanup-Image /RestoreHealth | Out-String }

    if ((Read-Host "`nRun DISM Component Cleanup to free up space? (y/N)") -match '^[Yy]') {
        Invoke-WithLog "DISM StartComponentCleanup" { DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase | Out-String }
    }

    if ((Read-Host "Schedule chkdsk on next boot? (y/N)") -match '^[Yy]') {
        Invoke-WithLog "Schedule chkdsk" { cmd /c "echo Y|chkdsk C: /f" | Out-String }
    }

    if ((Read-Host "Reset Windows Update components? (y/N)") -match '^[Yy]') {
        Invoke-WithLog "WU Reset" {
            Stop-Service wuauserv, cryptSvc, bits, msiserver -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 3 # Let the file locks release *purrs*
            @("$env:SystemRoot\SoftwareDistribution","$env:SystemRoot\System32\catroot2") | ForEach-Object {
                if (Test-Path $_) { Rename-Item $_ "$_.old" -Force -ErrorAction SilentlyContinue }
            }
            Start-Service wuauserv, cryptSvc, bits, msiserver
            return "Done"
        }
    }

    if ((Read-Host "Reset network stack? owo (winsock/TCP-IP)? (y/N)") -match '^[Yy]') {
        Invoke-WithLog "Network Reset" {
            netsh winsock reset | Out-String
            netsh int ip reset | Out-String
        }
    }
}
#endregion

#region Offline WinRE Repair
function Invoke-OfflineRepair {
    Write-Host "`n=== WINRE OFFLINE REPAIR (emergency bunny medic) ===" -ForegroundColor Cyan
    Write-Log "Running in Windows Recovery Environment"

    $target = Select-OfflineWindows
    if (-not $target) { return }
    Write-Log "Target volume found! *happy hops*: $target"

    Invoke-WithLog "Offline SFC" {
        sfc /scannow /offbootdir=$target\ /offwindir=$target\Windows | Out-String
    }

    Invoke-WithLog "Offline DISM RestoreHealth" {
        DISM /Image:$target /Cleanup-Image /RestoreHealth | Out-String
    }
    Invoke-WithLog "Offline DISM CheckHealth" {
        DISM /Image:$target /Cleanup-Image /CheckHealth | Out-String
    }

    if ((Read-Host "`nRun chkdsk on $target now? (y/N)") -match '^[Yy]') {
        Invoke-WithLog "Offline chkdsk" { chkdsk "$target" /f /r | Out-String }
    }

    Write-Log "Good Bunny! Offline repair complete. Restart with: wpeutil reboot" "SUCCESS"
}
#endregion

#region Main
Clear-Host
Write-Host "(=^･ω･^=)================================(ᐢ⑅ᐢ)" -ForegroundColor Cyan
Write-Host "     WINDOWS REPAIR & MALWARE AUDIT NYA~" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Log "Environment: $(if($inWinRE){'WinRE (Offline Medic)'}else{'Normal Windows (Online)'})"
Write-Log "Log path: $LogFile"

if ($inWinRE) {
    Invoke-OfflineRepair
} else {
    Write-Host "`nSelect mode:" -ForegroundColor Cyan
    Write-Host "  [1] Full Repair + Malware Audit (Recommended) uwu"
    Write-Host "  [2] Malware Audit Only (Just sniffing around)"
    Write-Host "  [3] System Repair Only (Just the bath)"
    switch (Read-Host "`nSelection") {
        '1' { Invoke-MalwareAudit; Invoke-OnlineRepair }
        '2' { Invoke-MalwareAudit }
        '3' { Invoke-OnlineRepair }
        default { Write-Log "Invalid selection. *sad meow*" "ERROR"; exit 1 }
    }

    $needsReboot = (Test-Path "$env:SystemRoot\WinSxS\pending.xml") -or
                   (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -ErrorAction SilentlyContinue)
    if ($needsReboot -or $script:SuspiciousFindings.Count -gt 0) {
        Write-Warning "`nA reboot is highly recommended Meow."
        if ((Read-Host "Reboot now? Nyah~♪ (y/N)") -match '^[Yy]') { Restart-Computer -Force }
    }
}

Write-Host "`nAll done! Press Enter to exit and take a nap. ( ˶ˆ꒳ˆ˵ )" -ForegroundColor Green
Read-Host
#endregion
