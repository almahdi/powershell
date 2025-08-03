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
if (-not ([System.Management.Automation.PSTypeName]'Win32').Type) {
    Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class Win32 {
        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
    }
"@
}

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
$form.Size = New-Object System.Drawing.Size(420, 270)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

# Set a modern color scheme
$form.BackColor = [System.Drawing.Color]::FromArgb(255, 240, 240, 240)
$form.ForeColor = [System.Drawing.Color]::FromArgb(255, 48, 48, 48)

# Window selection label
$windowLabel = New-Object System.Windows.Forms.Label
$windowLabel.Location = New-Object System.Drawing.Point(20, 20)
$windowLabel.Size = New-Object System.Drawing.Size(280, 15)
$windowLabel.Text = "Select Window:"

# Window selection combo box
$comboBox = New-Object System.Windows.Forms.ComboBox
$comboBox.Location = New-Object System.Drawing.Point(20, 40)
$comboBox.Size = New-Object System.Drawing.Size(280, 25)
$comboBox.DropDownStyle = "DropDownList"

# Refresh button
$refreshButton = New-Object System.Windows.Forms.Button
$refreshButton.Location = New-Object System.Drawing.Point(310, 39)
$refreshButton.Size = New-Object System.Drawing.Size(80, 27)
$refreshButton.Text = "Refresh"
$refreshButton.Add_Click({
    $comboBox.Items.Clear()
    Get-WindowTitles | ForEach-Object {
        $comboBox.Items.Add($_)
    }
})

# Text input label
$textLabel = New-Object System.Windows.Forms.Label
$textLabel.Location = New-Object System.Drawing.Point(20, 80)
$textLabel.Size = New-Object System.Drawing.Size(370, 15)
$textLabel.Text = "Text to Type:"

# Text input
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(20, 100)
$textBox.Size = New-Object System.Drawing.Size(370, 25)

# Send button
$sendButton = New-Object System.Windows.Forms.Button
$sendButton.Location = New-Object System.Drawing.Point(20, 140)
$sendButton.Size = New-Object System.Drawing.Size(370, 35)
$sendButton.Text = "Type Text in Selected Window"
$sendButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$sendButton.BackColor = [System.Drawing.Color]::FromArgb(255, 0, 122, 204)
$sendButton.ForeColor = [System.Drawing.Color]::White
$sendButton.FlatStyle = "Flat"
$sendButton.FlatAppearance.BorderSize = 0
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
$aboutButton.Location = New-Object System.Drawing.Point(20, 185)
$aboutButton.Size = New-Object System.Drawing.Size(370, 35)
$aboutButton.Text = "About"
$aboutButton.Add_Click({ Show-AboutWindow })

# Add controls to form
$form.Controls.AddRange(@($windowLabel, $comboBox, $refreshButton, $textLabel, $textBox, $sendButton, $aboutButton))

# Set focus to the form on load
$form.Add_Load({
    $form.Activate()
})

# Initial window list population
$refreshButton.PerformClick()

# Show form
$form.ShowDialog()
