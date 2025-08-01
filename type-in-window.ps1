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
.NOTES
    Author: Ali Almahdi (https://www.ali.ac)
    License: GNU AGPL-3.0 with Commons Clause
    Source: https://github.com/almahdi/powershell
    Requires: PowerShell 5.1 or higher, Windows
#>

# Import required assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class Win32 {
        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
    }
"@

function Get-WindowTitles {
    $windows = Get-Process | Where-Object {$_.MainWindowTitle -ne ""} | 
        Select-Object MainWindowTitle, MainWindowHandle
    return $windows
}

function Set-ActiveWindow {
    param([IntPtr]$WindowHandle)
    try {
        [Win32]::SetForegroundWindow($WindowHandle)
        Start-Sleep -Milliseconds 100
        return $true
    } catch {
        Write-Warning "Failed to activate window: $_"
        return $false
    }
}

function Send-KeyStrokes {
    param([string]$Text)
    try {
        [System.Windows.Forms.SendKeys]::SendWait($Text)
        return $true
    } catch {
        Write-Warning "Failed to send keystrokes: $_"
        return $false
    }
}

function Show-AboutWindow {
    $aboutForm = New-Object System.Windows.Forms.Form
    $aboutForm.Text = "About"
    $aboutForm.Size = New-Object System.Drawing.Size(300,200)
    $aboutForm.StartPosition = "CenterParent"
    $aboutForm.FormBorderStyle = "FixedDialog"
    $aboutForm.MaximizeBox = $false
    $aboutForm.MinimizeBox = $false

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10,20)
    $label.Size = New-Object System.Drawing.Size(280,120)
    $label.Text = "Type in Window by Ali Almahdi`nhttps://www.ali.ac`n`nVersion 1.0`n`nA simple utility to type text into other windows.`n`nCreated with PowerShell"
    
    $aboutForm.Controls.Add($label)
    $aboutForm.ShowDialog()
}

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Type in Window"
$form.Size = New-Object System.Drawing.Size(400,240)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false

# Window selection label
$windowLabel = New-Object System.Windows.Forms.Label
$windowLabel.Location = New-Object System.Drawing.Point(10,10)
$windowLabel.Size = New-Object System.Drawing.Size(280,15)
$windowLabel.Text = "Select Window:"

# Window selection combo box
$comboBox = New-Object System.Windows.Forms.ComboBox
$comboBox.Location = New-Object System.Drawing.Point(10,30)
$comboBox.Size = New-Object System.Drawing.Size(280,20)

# Refresh button
$refreshButton = New-Object System.Windows.Forms.Button
$refreshButton.Location = New-Object System.Drawing.Point(300,30)
$refreshButton.Size = New-Object System.Drawing.Size(80,20)
$refreshButton.Text = "Refresh"
$refreshButton.Add_Click({
    $comboBox.Items.Clear()
    Get-WindowTitles | ForEach-Object {
        $comboBox.Items.Add($_)
    }
})

# Text input label
$textLabel = New-Object System.Windows.Forms.Label
$textLabel.Location = New-Object System.Drawing.Point(10,60)
$textLabel.Size = New-Object System.Drawing.Size(370,15)
$textLabel.Text = "Text to Type:"

# Text input
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(10,80)
$textBox.Size = New-Object System.Drawing.Size(370,20)

# Send button
$sendButton = New-Object System.Windows.Forms.Button
$sendButton.Location = New-Object System.Drawing.Point(10,120)
$sendButton.Size = New-Object System.Drawing.Size(370,30)
$sendButton.Text = "Type Text in Selected Window"
$sendButton.Add_Click({
    if ($comboBox.SelectedItem -and $textBox.Text) {
        $window = $comboBox.SelectedItem
        if (Set-ActiveWindow -WindowHandle $window.MainWindowHandle) {
            Send-KeyStrokes -Text $textBox.Text
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Please select a window and enter text")
    }
})

# About button
$aboutButton = New-Object System.Windows.Forms.Button
$aboutButton.Location = New-Object System.Drawing.Point(10,160)
$aboutButton.Size = New-Object System.Drawing.Size(370,30)
$aboutButton.Text = "About"
$aboutButton.Add_Click({ Show-AboutWindow })

# Add controls to form
$form.Controls.AddRange(@($windowLabel, $comboBox, $refreshButton, $textLabel, $textBox, $sendButton, $aboutButton))

# Initial window list population
$refreshButton.PerformClick()

# Show form
$form.ShowDialog()
