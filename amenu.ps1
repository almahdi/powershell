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
.NOTES
    Author: Ali Almahdi (https://www.ali.ac)
    License: GNU AGPL-3.0 with Commons Clause
    Source: https://github.com/almahdi/powershell
    Requires: PowerShell 5.1 or higher, Windows
#>
<#
.SYNOPSIS
    A dmenu/rofi-like selectable menu for PowerShell.

.DESCRIPTION
    Provides a minimalist, filterable, and keyboard-navigable menu.
    It can be used to select from a list of items, such as open windows. The selected item object is returned to the pipeline.

.PARAMETER InputObject
    Accepts input from the pipeline to be displayed in the menu.

.PARAMETER Windows
    When specified, the script lists all processes with a main window title for selection.

.PARAMETER Switch
    Used with -Windows. If provided, the script will switch focus to the selected window.

.EXAMPLE
    .\menu.ps1 -Windows -Switch
    Displays the window list and, after selection, activates the chosen window.

.EXAMPLE
    "Restart", "Shutdown", "Log Off" | .\menu.ps1
    Displays a menu with the provided strings for selection.
#>

param(
    [Parameter(ParameterSetName='InputObject', ValueFromPipeline=$true)]
    [object[]]$InputObject,

    [Parameter(ParameterSetName='WindowsList')]
    [switch]$Windows,

    [Parameter(ParameterSetName='WindowsList')]
    [switch]$Switch
)

begin {
    # --- Required Assemblies, Win32 API, and Helper Functions ---
    # All definitions are placed in the 'begin' block to ensure they are
    # loaded once before any pipeline processing begins.

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    if (-not ("PSMenuWin32Api" -as [type])) {
        Add-Type @"
            using System;
            using System.Runtime.InteropServices;
            public class PSMenuWin32Api {
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

    function Get-WindowTitles {
        Get-Process | Where-Object { $_.MainWindowTitle -ne "" } | Select-Object MainWindowTitle, Id, MainWindowHandle
    }

    function Set-ActiveWindow {
        param(
            [Parameter(Mandatory=$true)]
            [IntPtr]$WindowHandle
        )
        
        if ([PSMenuWin32Api]::IsIconic($WindowHandle)) {
            [PSMenuWin32Api]::ShowWindow($WindowHandle, 9) # 9 is SW_RESTORE
        }
        
        try {
            $wshell = New-Object -ComObject wscript.shell
            $wshell.SendKeys('%')
            Start-Sleep -Milliseconds 50
        } catch {
            Write-Warning "Failed to create WScript.Shell object. Focus may not switch correctly. Error: $_"
        }
        
        [PSMenuWin32Api]::SetForegroundWindow($WindowHandle)
    }

    function Show-Menu {
        param(
            [Parameter(Mandatory=$true)]
            [object[]]$Items,
            [string]$DisplayMember = ""
        )

        $form = New-Object System.Windows.Forms.Form
        $form.FormBorderStyle = 'None'
        $form.StartPosition = 'CenterScreen'
        $form.TopMost = $true
        $form.KeyPreview = $true
        $form.Size = New-Object System.Drawing.Size(600, 350)
        
        $inputBox = New-Object System.Windows.Forms.TextBox
        $inputBox.Dock = 'Top'
        $inputBox.Font = New-Object System.Drawing.Font("Consolas", 12)

        $listBox = New-Object System.Windows.Forms.ListBox
        $listBox.Dock = 'Fill'
        $listBox.Font = New-Object System.Drawing.Font("Consolas", 11)
        $listBox.BorderStyle = 'None'
        
        if ($DisplayMember -and $Items.Count -gt 0 -and $Items[0].PSObject.Properties[$DisplayMember]) {
            $listBox.DisplayMember = $DisplayMember
        }
        
        $allItems = $Items
        $script:selectedItem = $null

        $form.Add_Load({
            $listBox.Items.AddRange($allItems)
            if ($listBox.Items.Count -gt 0) { $listBox.SelectedIndex = 0 }
        })

        $form.Add_Shown({
            # Forcefully bring the form to the foreground and then focus the input box.
            Set-ActiveWindow -WindowHandle $form.Handle
            $inputBox.Focus()
        })

        $inputBox.Add_KeyDown({
            $e = $_
            if ($e.KeyCode -eq 'Enter') {
                if ($listBox.SelectedItem) {
                    $script:selectedItem = $listBox.SelectedItem
                    $form.Close()
                }
                $e.Handled = $true
                $e.SuppressKeyPress = $true
            }
        })

        $inputBox.Add_TextChanged({
            $filterText = $inputBox.Text
            $listBox.BeginUpdate()
            $listBox.Items.Clear()
            $filteredItems = if ($DisplayMember) { $allItems | Where-Object { $_.$DisplayMember -like "*$filterText*" } } else { $allItems | Where-Object { $_ -like "*$filterText*" } }
            $listBox.Items.AddRange($filteredItems)
            if ($listBox.Items.Count -gt 0) { $listBox.SelectedIndex = 0 }
            $listBox.EndUpdate()
        })
        
        $form.Add_KeyDown({
            $e = $_
            switch ($e.KeyCode) {
                'Escape' {
                    $script:selectedItem = $null
                    $form.Close()
                }
                'ArrowDown' {
                    if ($listBox.Items.Count -gt 0) {
                        $newIndex = [Math]::Min($listBox.SelectedIndex + 1, $listBox.Items.Count - 1)
                        $listBox.SelectedIndex = $newIndex
                    }
                    $e.Handled = $true
                }
                'ArrowUp' {
                    if ($listBox.Items.Count -gt 0) {
                        $newIndex = [Math]::Max($listBox.SelectedIndex - 1, 0)
                        $listBox.SelectedIndex = $newIndex
                    }
                    $e.Handled = $true
                }
            }
        })

        $listBox.Add_DoubleClick({ 
            if ($listBox.SelectedItem) { 
                $script:selectedItem = $listBox.SelectedItem
                $form.Close()
            } 
        })

        $form.Controls.AddRange(@($listBox, $inputBox))
        $form.ShowDialog() | Out-Null

        return $script:selectedItem
    }

    # Initialize a list to hold all items from the pipeline.
    $script:collectedItems = [System.Collections.Generic.List[object]]::new()
}

process {
    # This block runs for each item piped to the script.
    # We add each item to our collection list.
    if ($null -ne $InputObject) {
        foreach ($item in $InputObject) {
            $script:collectedItems.Add($item)
        }
    }
}

end {
    # This block runs only once, after all piped items have been processed or if run directly.
    if ($Windows.IsPresent) {
        $items = Get-WindowTitles
        $selectedWindow = Show-Menu -Items $items -DisplayMember "MainWindowTitle"
        
        if ($selectedWindow) {
            if ($Switch.IsPresent) {
                Set-ActiveWindow -WindowHandle $selectedWindow.MainWindowHandle
            }
            Write-Output $selectedWindow
        }
    } 
    elseif ($script:collectedItems.Count -gt 0) {
        $selectedItem = Show-Menu -Items $script:collectedItems.ToArray()
        if ($selectedItem) {
            Write-Output $selectedItem
        }
    }
}
