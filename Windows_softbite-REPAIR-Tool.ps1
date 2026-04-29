<#
.SYNOPSIS
    Comprehensive Windows Repair Script
.DESCRIPTION
    Runs SFC, DISM, CheckDisk scheduling, and optional component store cleanup.
    Requires Administrator privileges.
.NOTES
    File Name      : Repair-Windows.ps1
    Run As         : Administrator
#>

#Requires -RunAsAdministrator

#region Configuration
$LogDir  = "$env:SystemDrive\RepairLogs"
$LogFile = "$LogDir\Repair_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
#endregion

#region Helper Functions
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $line
    switch ($Level) {
        "ERROR" { Write-Host $line -ForegroundColor Red }
        "WARN"  { Write-Host $line -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $line -ForegroundColor Green }
        default { Write-Host $line }
    }
}

function Invoke-WithLog {
    param(
        [string]$Description,
        [scriptblock]$Action
    )
    Write-Log "START: $Description"
    try {
        $result = & $Action
        Write-Log "SUCCESS: $Description" "SUCCESS"
        return $result
    } catch {
        Write-Log "ERROR: $Description - $($_.Exception.Message)" "ERROR"
        return $null
    }
}
#endregion

#region Setup
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}
Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "     WINDOWS REPAIR UTILITY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Log file: $LogFile`n"
Write-Log "Repair session started on $env:COMPUTERNAME by $env:USERNAME"
#endregion

#region 1. System File Checker (SFC)
Invoke-WithLog "System File Checker (sfc /scannow)" {
    $proc = Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -Wait -PassThru -NoNewWindow
    if ($proc.ExitCode -ne 0) {
        throw "SFC exited with code $($proc.ExitCode)"
    }
    return "SFC completed with exit code $($proc.ExitCode)"
}
#endregion

#region 2. DISM Image Health Checks
Invoke-WithLog "DISM CheckHealth" {
    $out = DISM /Online /Cleanup-Image /CheckHealth 2>&1
    if ($LASTEXITCODE -ne 0) { throw "DISM CheckHealth failed: $out" }
    return ($out | Out-String)
}

Invoke-WithLog "DISM ScanHealth" {
    $out = DISM /Online /Cleanup-Image /ScanHealth 2>&1
    if ($LASTEXITCODE -ne 0) { throw "DISM ScanHealth failed: $out" }
    return ($out | Out-String)
}

Invoke-WithLog "DISM RestoreHealth" {
    $out = DISM /Online /Cleanup-Image /RestoreHealth 2>&1
    if ($LASTEXITCODE -ne 0) { throw "DISM RestoreHealth failed: $out" }
    return ($out | Out-String)
}

# Optional: Limit WinSxS component store cleanup (can take a while)
$response = Read-Host "`nRun DISM StartComponentCleanup? (y/N)"
if ($response -match '^[Yy]') {
    Invoke-WithLog "DISM StartComponentCleanup" {
        $out = DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase 2>&1
        if ($LASTEXITCODE -ne 0) { throw "Component cleanup failed: $out" }
        return ($out | Out-String)
    }
}
#endregion

#region 3. CheckDisk Schedule
$response = Read-Host "`nSchedule CheckDisk (chkdsk) on next reboot for C:\ ? (y/N)"
if ($response -match '^[Yy]') {
    Invoke-WithLog "Schedule chkdsk on reboot" {
        $out = chkntfs /c C: 2>&1
        $out2 = echo 'Y' | chkdsk C: /f 2>&1
        return "$out`n$out2"
    }
    Write-Log "CheckDisk scheduled. A reboot is required." "WARN"
} else {
    Write-Log "CheckDisk skipped by user."
}
#endregion

#region 4. Windows Update Reset (Optional)
$response = Read-Host "`nReset Windows Update components? (y/N)"
if ($response -match '^[Yy]') {
    Invoke-WithLog "Stopping Windows Update services" {
        Stop-Service wuauserv, cryptSvc, bits, msiserver -Force -ErrorAction SilentlyContinue
        return "Services stopped."
    }

    Invoke-WithLog "Renaming SoftwareDistribution & CatRoot2" {
        $paths = @(
            "$env:SystemRoot\SoftwareDistribution",
            "$env:SystemRoot\System32\catroot2"
        )
        foreach ($p in $paths) {
            if (Test-Path $p) {
                Rename-Item $p "$p.old" -Force -ErrorAction SilentlyContinue
            }
        }
        return "Folders renamed."
    }

    Invoke-WithLog "Restarting Windows Update services" {
        Start-Service wuauserv, cryptSvc, bits, msiserver
        return "Services restarted."
    }
}
#endregion

#region 5. Network Stack Reset (Optional)
$response = Read-Host "`nReset TCP/IP and Winsock? (y/N)"
if ($response -match '^[Yy]') {
    Invoke-WithLog "Resetting Winsock" {
        netsh winsock reset | Out-String
    }
    Invoke-WithLog "Resetting TCP/IP" {
        netsh int ip reset | Out-String
    }
    Write-Log "Network reset complete. Reboot recommended." "WARN"
}
#endregion

#region Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "           REPAIR COMPLETE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Log "Repair session completed. Log saved to: $LogFile" "SUCCESS"

$rebootNeeded = $false
if ((Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -ErrorAction SilentlyContinue) -or
    (Test-Path "$env:SystemRoot\WinSxS\pending.xml")) {
    $rebootNeeded = $true
}

if ($rebootNeeded) {
    Write-Warning "A reboot is required to complete repairs."
    $rb = Read-Host "Reboot now? (y/N)"
    if ($rb -match '^[Yy]') {
        Restart-Computer -Force
    }
} else {
    Write-Host "No pending reboot detected." -ForegroundColor Green
}

Read-Host "`nPress Enter to exit"
#endregion