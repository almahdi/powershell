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

# Set the sleep interval (in seconds)
$SleepInterval = 10
$movePixels = 10

function Move-MouseBack-And-Forth {
    $point = New-Object MouseSimulator+POINT
    [MouseSimulator]::GetCursorPos([ref]$point)
    
    # Move right
    [MouseSimulator]::SetCursorPos($point.X + $movePixels, $point.Y)
    Start-Sleep -Milliseconds 100
    
    # Move back
    [MouseSimulator]::SetCursorPos($point.X, $point.Y)
    
    Write-Host "Mouse moved at $(Get-Date -Format 'HH:mm:ss')"
}

Write-Host "Mouse jiggler started. Press Ctrl+C to stop."
Write-Host "Moving mouse every $SleepInterval seconds..."

try {
    while ($true) {
        Move-MouseBack-And-Forth
        Start-Sleep -Seconds $SleepInterval
    }
}
catch {
    Write-Host "`nMouse jiggler stopped."
}
