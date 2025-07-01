# P2V User Management

This project contains PowerShell scripts used to administer users for the P2V environment. The main entry point is `P2V_UserMgmt_20.ps1` which provides a Windows Forms user interface to query tenants, update accounts and synchronize data.

## Prerequisites

- **PowerShell 5.1** or later. The modules rely on Windows-specific features such as `System.Windows.Forms`.
- The repository ships with several modules that must be available next to the script: `P2V_config.psd1`, `P2V_include.psd1`, `P2V_dialog_func.psd1`, `P2V_AD_func.psd1` and `P2V_PS_func.psd1`. `P2V_UserMgmt_20.ps1` imports them automatically when started.

## Running the script

1. Open a PowerShell console.
2. Change to the directory containing this repository.
3. Execute the script:
   ```powershell
   .\P2V_UserMgmt_20.ps1
   ```

On start, the script loads all required modules and opens the graphical interface.

### Working directory

During initialisation the function `P2V_init` sets the variable `$workdir` based on the location of the script. No manual path configuration is required; relative paths inside the modules resolve automatically.
