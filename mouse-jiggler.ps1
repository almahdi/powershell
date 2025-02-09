<#
Copyright (C) 2024 Ali Almahdi

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
   Keeps the computer awake by simulating mouse movements.

.DESCRIPTION
   This script simulates slight mouse movements at a defined interval to prevent the computer from going to sleep or activating the screen saver.
   The script can be toggled on/off using the Scroll Lock key. When Scroll Lock is ON, the mouse jiggler is active.

.PARAMETER SleepInterval
   The interval (in seconds) between mouse movements. Default is 3 seconds.

.PARAMETER MovePixels
   The number of pixels the mouse will move horizontally. Default is 10 pixels.

.EXAMPLE
   .\mouse-jiggler.ps1 -SleepInterval 5 -MovePixels 15
   This will start the mouse jiggler, moving the mouse 15 pixels every 5 seconds when Scroll Lock is ON.

.NOTES
   - Requires Windows.
   - Requires the use of Scroll Lock key to toggle the jiggler ON/OFF.
   - The script will continue to run until stopped manually (Ctrl+C).
#>
param(
    [Parameter(Mandatory=$false)]
    [int]$SleepInterval = 3,
    
    [Parameter(Mandatory=$false)]
    [int]$MovePixels = 10
)

# Mouse Jiggler Script

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class MouseSimulator
{
    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int x, int y);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool GetCursorPos(out POINT lpPoint);

    [StructLayout(LayoutKind.Sequential)]
    public struct POINT
    {
        public int X;
        public int Y;
    }
}
"@

# Remove the KeyboardHook class and add ScrollLock checker
Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;

    public class ScrollLockHelper {
        [DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)]
        public static extern short GetKeyState(int keyCode);
    }
"@

# Add Toast Notification Support
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Show-ToastNotification {
    param([string]$Message)
    
    $notifyIcon = New-Object System.Windows.Forms.NotifyIcon
    $notifyIcon.Icon = [System.Drawing.SystemIcons]::Information
    $notifyIcon.BalloonTipTitle = "Mouse Jiggler"
    $notifyIcon.BalloonTipText = $Message
    $notifyIcon.Visible = $true
    
    # Show balloon tip for 2 seconds
    $notifyIcon.ShowBalloonTip(2000)
    
    # Cleanup after 3 seconds
    Start-Sleep -Seconds 3
    $notifyIcon.Dispose()
}

function Get-ScrollLockState {
    # ScrollLock virtual key code is 0x91
    # Cast to boolean to prevent output
    [bool]([ScrollLockHelper]::GetKeyState(0x91) -band 1) | Out-Null
    return [bool]([ScrollLockHelper]::GetKeyState(0x91) -band 1)
}

function Move-MouseBack-And-Forth {
    if (-not (Get-ScrollLockState)) { return }
    
    $point = New-Object MouseSimulator+POINT
    [MouseSimulator]::GetCursorPos([ref]$point) | Out-Null
    
    # Move right
    [MouseSimulator]::SetCursorPos($point.X + $MovePixels, $point.Y) | Out-Null
    Start-Sleep -Milliseconds 100
    
    # Move back
    [MouseSimulator]::SetCursorPos($point.X, $point.Y) | Out-Null
    
    # Write-Host "Mouse moved at $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Green
}

Write-Host "Mouse jiggler started. Press Ctrl+C to stop." -ForegroundColor Cyan
Write-Host "Use SCROLL LOCK key to toggle jiggler ON/OFF" -ForegroundColor Yellow
Write-Host "Moving mouse every $SleepInterval seconds when ScrollLock is ON..." -ForegroundColor Cyan

$previousState = Get-ScrollLockState
try {
    while ($true) {
        $currentState = Get-ScrollLockState
        if ($currentState -ne $previousState) {
            $status = if ($currentState) { "ENABLED" } else { "DISABLED" }
            $color = if ($currentState) { "Green" } else { "Red" }
            Write-Host "`nJiggler $status" -ForegroundColor $color
            
            # Show toast notification
            Show-ToastNotification "Mouse Jiggler $status"
            
            $previousState = $currentState
        }
        
        Move-MouseBack-And-Forth
        Start-Sleep -Seconds $SleepInterval
    }
}
catch {
    Write-Host "`nMouse jiggler stopped." -ForegroundColor Red
}
