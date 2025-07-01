# P2V User Management

This repository hosts the PowerShell implementation used to manage users and permissions in the **Plan2Value** (P2V) environment. The primary entry point is `P2V_UserMgmt_20.ps1` which launches a Windows Forms interface for Active Directory lookups and for interacting with multiple P2V tenants via REST APIs.

## Repository layout

- **P2V_UserMgmt_20.ps1** – GUI script that imports all modules and provides buttons for the common tasks.
- **P2V_module/** – manifest files plus the `P2V_include` folder containing the actual modules:
  - `P2V_config.psm1` – defines global variables and helper `P2V_init`.
  - `P2V_dialog_func.psm1` – small dialog utilities like `ask_continue`.
  - `P2V_AD_func.psm1` – functions for querying Active Directory.
  - `P2V_PS_func.psm1` – functions that call the P2V REST API.
- **lib/** – stand‑alone scripts for bulk operations such as exporting users, setting profiles or calculating group assignments.
- **P2V_scripts/config/** – configuration CSV files for tenants, groups and profiles.
- **P2V_UM_data/** – output directory where logs and exports are written.

## Prerequisites

- **PowerShell 5.1** or later on Windows (the GUI relies on `System.Windows.Forms`).
- Network access to the P2V tenants and Active Directory.

## Usage

Start a PowerShell console, change to this directory and run:

```powershell
.\P2V_UserMgmt_20.ps1
```

The form offers actions like:

- Searching AD users and checking their P2V accounts.
- Locking/unlocking or activating/deactivating users across tenants.
- Synchronising AD group memberships with P2V profiles.
- Exporting user and group information for reporting.

`P2V_init` automatically sets `$workdir` based on the script location so no additional configuration is required.

## Suggested enhancements

- **Module refactor** – combining the individual `*.psm1` files into a proper PowerShell module would simplify deployment and allow versioning.
- **Automated tests** – unit tests for the helper functions (e.g. in `P2V_AD_func.psm1`) would improve reliability.
- **Non‑interactive mode** – exposing core functionality as cmdlets would enable automation without the GUI.
- **Configuration** – consider migrating the CSV configuration files to a structured format such as JSON for easier validation.

## License

This project currently has no explicit license. Add one if distribution is intended.
