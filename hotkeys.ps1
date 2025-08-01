<#
Copyright (C) 2025 Ali Almahdi

This script is part of Ali's powershell scripts repository on GitHub
Licensed under GNU AGPL-3.0 with Commons Clause License Condition v1.0

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version, with Commons Clause License Condition v1.0.

For commercial licensing inquiries, contact: https://www.ali.ac/contact
#>
<#
.SYNOPSIS
    Registers global, system-wide hotkeys to execute PowerShell commands.

.DESCRIPTION
    This script registers one or more global hotkeys that can be used from any application in Windows.
    It uses the standard Windows RegisterHotKey API via P/Invoke, which is a safe and reliable method
    that should not be flagged as a keylogger by antivirus or DLP software.

    Keyloggers typically work by installing a low-level keyboard hook (like WH_KEYBOARD_LL) to
    intercept *all* keyboard input. This script, in contrast, simply tells the operating system:
    "Please notify me only when this specific key combination is pressed." The OS handles the
    monitoring and sends a simple message to the script when a hotkey is triggered.

    The script is configured via the $hotkeyDefinitions array. You can easily add, remove, or modify
    hotkeys and their associated actions.

    To stop the script and unregister all hotkeys, press Ctrl+C in the PowerShell console window
    where the script is running.

.NOTES
    Author: Ali Almahdi (https://www.ali.ac)
    License: GNU AGPL-3.0 with Commons Clause
    Source: https://github.com/almahdi/powershell
    Requires: PowerShell 5.1 or higher, Windows

.EXAMPLE
    # To run the script, save it as a .ps1 file and execute it from a PowerShell prompt:
    .\hotkeys.ps1

    # The console will remain open, listening for hotkeys.
    # Press the configured hotkeys (e.g., Ctrl+Alt+C) to trigger the actions.
    # To stop, press Ctrl+C in the console window.
#>



# --- Load required .NET assemblies ---
Add-Type -AssemblyName System.Windows.Forms

# --- Add Win32 static methods only (no enums/structs) ---
if (-not ([System.Management.Automation.PSTypeName]'Win32').Type) {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class Win32 {
    [DllImport("user32.dll", SetLastError=true)]
    public static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, int vk);
    [DllImport("user32.dll", SetLastError=true)]
    public static extern bool UnregisterHotKey(IntPtr hWnd, int id);
    public const int WM_HOTKEY = 0x0312;
    [StructLayout(LayoutKind.Sequential)]
    public struct MSG {
        public IntPtr hwnd;
        public uint message;
        public IntPtr wParam;
        public IntPtr lParam;
        public uint time;
        public int pt_x;
        public int pt_y;
    }
    [DllImport("user32.dll")]
    public static extern bool PeekMessage(out MSG lpMsg, IntPtr hWnd, uint wMsgFilterMin, uint wMsgFilterMax, uint wRemoveMsg);
    [DllImport("user32.dll")]
    public static extern bool TranslateMessage(ref MSG lpMsg);
    [DllImport("user32.dll")]
    public static extern IntPtr DispatchMessage(ref MSG lpmsg);
}
"@
}

# --- Modifier constants (from WinUser.h) ---
$MOD_ALT     = 0x0001
$MOD_CONTROL = 0x0002
$MOD_SHIFT   = 0x0004
$MOD_WIN     = 0x0008

# --- Hotkey configuration ---
$hotkeyDefinitions = @(
    @{ Id = 1; Modifiers = @($MOD_CONTROL, $MOD_ALT); Key = 'C'; Action = { Write-Host "Hotkey 'Ctrl+Alt+C' pressed. Launching Calculator..."; Start-Process calc.exe } },
    @{ Id = 2; Modifiers = @($MOD_CONTROL, $MOD_ALT); Key = 'E'; Action = { Write-Host "Hotkey 'Ctrl+Alt+E' pressed. Launching Excel..."; try { Start-Process excel.exe -ErrorAction Stop } catch { Write-Warning "Could not start Excel. Is it installed?" } } },
    @{ Id = 3; Modifiers = @($MOD_CONTROL, $MOD_ALT); Key = 'N'; Action = { Write-Host "Hotkey 'Ctrl+Alt+N' pressed. Launching Notepad..."; Start-Process notepad.exe } },
    @{ Id = 4; Modifiers = @($MOD_CONTROL, $MOD_SHIFT); Key = 'X'; Action = { Write-Host "Hotkey 'Ctrl+Shift+X' pressed. Running custom command..."; $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"; Write-Host "The current time is $timestamp"; Get-Process | Sort-Object WS -Descending | Select-Object -First 5 } }
)

$registeredHotkeys = @{}
Write-Host "Registering global hotkeys. Press Ctrl+C to exit."
foreach ($def in $hotkeyDefinitions) {
    $modValue = 0
    foreach ($m in $def.Modifiers) { $modValue = $modValue -bor $m }
    $vk = [int][System.Windows.Forms.Keys]::$($def.Key)
    $success = [Win32]::RegisterHotKey([IntPtr]::Zero, $def.Id, $modValue, $vk)
    if ($success) {
        $registeredHotkeys[$def.Id] = $def
        $modifierNames = ($def.Modifiers | ForEach-Object {
            switch ($_)
            {
                $MOD_CONTROL { 'Control' }
                $MOD_ALT     { 'Alt' }
                $MOD_SHIFT   { 'Shift' }
                $MOD_WIN     { 'Win' }
                default      { $_ }
            }
        }) -join ' + '
        Write-Host "  [SUCCESS] Registered ID $($def.Id): $modifierNames + $($def.Key)"
    } else {
        $error = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
        Write-Warning "Failed to register hotkey with ID $($def.Id). Win32 Error Code: $error"
        Write-Warning "This hotkey combination might already be in use by another application."
    }
}

if ($registeredHotkeys.Count -eq 0) {
    Write-Error "No hotkeys were successfully registered. Exiting."
    return
}

Write-Host "Listening for hotkey presses..."
$msg = New-Object "Win32+MSG"

try {
    while ($true) {
        while ([Win32]::PeekMessage([ref]$msg, [IntPtr]::Zero, 0, 0, 1)) {
            if ($msg.message -eq [Win32]::WM_HOTKEY) {
                $hotkeyId = $msg.wParam.ToInt32()
                Write-Host "Hotkey message received for ID: $hotkeyId"
                if ($registeredHotkeys.ContainsKey($hotkeyId)) {
                    & $registeredHotkeys[$hotkeyId].Action
                }
            }
            [Win32]::TranslateMessage([ref]$msg) | Out-Null
            [Win32]::DispatchMessage([ref]$msg) | Out-Null
        }
        Start-Sleep -Milliseconds 50
    }
} finally {
    Write-Host "`nCleaning up and unregistering all hotkeys..."
    foreach ($id in $registeredHotkeys.Keys) {
        [Win32]::UnregisterHotKey([IntPtr]::Zero, $id)
        Write-Host "  Unregistered hotkey with ID: $id"
    }
    Write-Host "Cleanup complete. Exiting."
}
