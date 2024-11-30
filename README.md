# PowerShell Automation Scripts

A collection of PowerShell scripts and modules that automate various tasks in enterprise environments where installing third-party applications requires permissions.

## Table of Contents
- [Scripts](#scripts)
  - [Type in Window](#type-in-window)
    - [Features](#features)
    - [Usage](#usage)
  - [Don't Sleep](#dont-sleep)
    - [Features](#features-1)
    - [Usage](#usage-1)
    
- [Requirements](#requirements)
- [Author](#author)
- [License](#license)
- [Contributing](#contributing)

## Scripts

### Type in Window
A utility that allows you to type text into any window programmatically. Useful for:
- Auto-typing long text during Microsoft Teams meetings
- Automated form filling during testing
- Any scenario where you need to input text into another window

#### Features
- Select target window from a dropdown list
- Refresh window list on demand
- Type any text into the selected window
- Simple and intuitive GUI interface

#### Usage
##### Remote
```pwsh
iex (iwr https://raw.githubusercontent.com/almahdi/powershell/refs/heads/main/type-in-window.ps1).Content
```
##### Local
1. Run the script: `.\type-in-window.ps1`
2. Select the target window from the dropdown
3. Enter the text you want to type
4. Click "Type Text in Selected Window"

### Don't Sleep
A utility that prevents your computer from going to sleep by simulating a key press (SCROLLLOCK) every 30 seconds. Useful for:
- Keeping your computer awake during long downloads
- Preventing sleep during remote sessions
- Maintaining presence status in communication apps
- Any scenario where system sleep is undesirable

#### Features
- Zero configuration required
- Lightweight and resource-friendly
- Uses built-in Windows features
- No administrative privileges needed

#### Usage
##### Remote
```pwsh
iex (iwr https://raw.githubusercontent.com/almahdi/powershell/refs/heads/main/dont-sleep.ps1).Content
```
##### Local
1. Run the script: `.\dont-sleep.ps1`
2. The script will start running in the background
3. To stop the script, close the PowerShell window

## Requirements
- Windows OS
- PowerShell 5.1 or higher

## Author
Created and maintained by [Ali Almahdi](https://www.ali.ac)

## License
Licensed under GNU AGPL-3.0 with Commons Clause License Condition v1.0.
For commercial licensing inquiries, please visit https://www.ali.ac/contact

## Contributing
Feel free to submit issues and pull requests for improvements or new scripts.
