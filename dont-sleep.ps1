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
This is a simple script that prevents the computer from going to sleep by sending the SCROLLLOCK key every 30 seconds.
#>

Write-Host "Preventing the computer from going to sleep... Press CTRL+C to stop the script." -ForegroundColor Green

# Create a new WScript.Shell COM object
$wshell = New-Object -ComObject wscript.shell;

# Infinite loop to keep the script running
while($true) {
    # Send the SCROLLLOCK key to toggle it on
    $wshell.sendKeys("{SCROLLLOCK}");
    # Wait for 300 milliseconds
    Start-Sleep -Milliseconds 300
    # Send the SCROLLLOCK key to toggle it off
    $wshell.sendKeys("{SCROLLLOCK}");
    # Wait for 30 seconds before repeating
    Start-Sleep -Seconds 30
}