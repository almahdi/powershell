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
        Select-Object MainWindowTitle, MainWindowHandle, ProcessName
    return $windows
}

function Set-ActiveWindow {
    param([IntPtr]$WindowHandle)

    # Add Win32 API helpers if not already present
    if (-not ([System.Management.Automation.PSTypeName]'Win32ApiHelper').Type) {
        Add-Type @"
            using System;
            using System.Runtime.InteropServices;
            public class Win32ApiHelper {
                private const int SW_RESTORE = 9;

                [DllImport("user32.dll")]
                public static extern bool SetForegroundWindow(IntPtr hWnd);

                [DllImport("user32.dll")]
                public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

                [DllImport("user32.dll")]
                public static extern bool IsIconic(IntPtr hWnd);
            }
"@
    }

    # Restore if minimized
    if ([Win32ApiHelper]::IsIconic($WindowHandle)) {
        [Win32ApiHelper]::ShowWindow($WindowHandle, 9) # SW_RESTORE
    }
    Start-Sleep -Milliseconds 300

    try {
        $wshell = New-Object -ComObject wscript.shell
        $wshell.SendKeys('%')
        Start-Sleep -Milliseconds 50
    } catch {
        Write-Warning "Failed to create WScript.Shell object. Focus may not switch correctly. Error: $_"
    }

    [Win32ApiHelper]::SetForegroundWindow($WindowHandle)
    Start-Sleep -Milliseconds 100
    return $true
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
    $aboutForm.StartPosition = "CenterParent"
    $aboutForm.FormBorderStyle = "FixedDialog"
    $aboutForm.MaximizeBox = $false
    $aboutForm.MinimizeBox = $false
    $aboutForm.Padding = New-Object System.Windows.Forms.Padding(20)
    $aboutForm.AutoSize = $true
    $aboutForm.AutoSizeMode = "GrowAndShrink"

    $layoutPanel = New-Object System.Windows.Forms.TableLayoutPanel
    $layoutPanel.Dock = "Fill"
    $layoutPanel.AutoSize = $true
    $layoutPanel.ColumnCount = 1
    $layoutPanel.RowCount = 6

    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "Type in Window"
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $titleLabel.AutoSize = $true
    $titleLabel.Margin = New-Object System.Windows.Forms.Padding(0,0,0,10)

    $authorLabel = New-Object System.Windows.Forms.LinkLabel
    $authorLabel.Text = "by Ali Almahdi (https://www.ali.ac)"
    $authorLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $authorLabel.AutoSize = $true
    $authorLabel.Margin = New-Object System.Windows.Forms.Padding(0,0,0,20)
    $authorLabel.Links.Add(17, 18, "https://www.ali.ac") | Out-Null
    $authorLabel.add_LinkClicked({
        param($sender, $e)
        Start-Process $e.Link.LinkData
    })

    $descriptionLabel = New-Object System.Windows.Forms.Label
    $descriptionLabel.Text = "A simple utility to type text into other windows, created with PowerShell."
    $descriptionLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $descriptionLabel.AutoSize = $true
    $descriptionLabel.Margin = New-Object System.Windows.Forms.Padding(0,0,0,20)

    $githubLinkLabel = New-Object System.Windows.Forms.LinkLabel
    $githubLinkLabel.Text = "Source code on GitHub"
    $githubLinkLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $githubLinkLabel.AutoSize = $true
    $githubLinkLabel.Margin = New-Object System.Windows.Forms.Padding(0,0,0,20)
    $githubLinkLabel.Links.Add(0, $githubLinkLabel.Text.Length, "https://github.com/almahdi/powershell") | Out-Null
    $githubLinkLabel.add_LinkClicked({
        param($sender, $e)
        Start-Process $e.Link.LinkData
    })

    $licenseLabel = New-Object System.Windows.Forms.LinkLabel
    $licenseLabel.Text = "Licensed under GNU AGPL-3.0 with Commons Clause"
    $licenseLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $licenseLabel.AutoSize = $true
    $licenseLabel.Margin = New-Object System.Windows.Forms.Padding(0,0,0,20)
    $licenseLabel.Links.Add(0, $licenseLabel.Text.Length, "LICENSE") | Out-Null
    $licenseLabel.add_LinkClicked({
        param($sender, $e)
        Start-Process -FilePath (Join-Path $PSScriptRoot $e.Link.LinkData)
    })

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $okButton.Dock = "Fill"

    $layoutPanel.Controls.Add($titleLabel)
    $layoutPanel.Controls.Add($authorLabel)
    $layoutPanel.Controls.Add($descriptionLabel)
    $layoutPanel.Controls.Add($githubLinkLabel)
    $layoutPanel.Controls.Add($licenseLabel)
    $layoutPanel.Controls.Add($okButton)

    $aboutForm.Controls.Add($layoutPanel)
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

# Set focus to the form on load and populate window list
$form.Add_Load({
    $form.Activate()
    $refreshButton.PerformClick()
})

# Show form
$form.ShowDialog()
