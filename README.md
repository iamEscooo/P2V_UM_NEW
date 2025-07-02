# P2V User Management Suite

[![PowerShell Gallery](https://img.shields.io/badge/PowerShell-5.1%2B-blue)](https://docs.microsoft.com/en-us/powershell/)
[![Platform: Windows](https://img.shields.io/badge/platform-Windows-blue.svg)](https://www.microsoft.com/en-us/windows)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
![Maintenance](https://img.shields.io/badge/status-active-brightgreen)

**A modular PowerShell toolkit and GUI for managing users and permissions across Active Directory and multiple Plan2Value (P2V) tenants.**  
Built for IT admins and automation engineers who want a clean workflow for hybrid AD/cloud user management, with full REST API and GUI support.

---

## 🚀 Features

- **Modern Windows Forms GUI:** Intuitive AD and tenant management.
- **AD Integration:** Query, export, and sync Active Directory users and groups.
- **Multi-Tenant Support:** Manage users across several P2V environments via REST APIs.
- **Bulk Operations:** Mass import/export, group assignments, profile sync.
- **Flexible Config:** CSV-based config files for tenants, groups, and user profiles.
- **Logging:** Every action is logged for auditing.
- **Extensible:** Fully modular—add your own scripts and modules as needed.

---

## 📸 Screenshots

<img src="docs/screenshot_main_gui.png" alt="Main GUI" width="600">

<img src="docs/screenshot_ad_export.png" alt="Export AD Users" width="600">

---

## 🛠️ Getting Started

### Prerequisites

- Windows 10/11 with **PowerShell 5.1 or higher**
- Active Directory domain membership
- REST API access to Plan2Value (P2V) tenants
- CSV configuration files (see below)

### Installation

```powershell
git clone https://github.com/your-org/P2V_UserMgmt.git
cd P2V_UserMgmt
````

Edit your configuration files in `P2V_scripts/config/` as described in [Configuration Guide](README.d/02-configuration.md).

### Running the GUI

```powershell
.\P2V_UserMgmt_20.ps1
```

---

## ⚙️ Project Structure

```plaintext
P2V_UserMgmt_20.ps1            # Main GUI launcher
P2V_module/
  ├─ P2V_config.psd1/.psm1     # Config variables, global settings
  ├─ P2V_dialog_func.psd1/.psm1# Dialog helpers (MessageBoxes, prompts)
  ├─ P2V_AD_func.psd1/.psm1    # Active Directory utilities
  ├─ P2V_PS_func.psd1/.psm1    # REST/tenant functions
P2V_scripts/config/            # All CSV config files (tenants, groups, profiles)
lib/                           # Standalone scripts for bulk ops
P2V_UM_data/output/            # Output logs, dashboards, exports
```

---

## 📖 Documentation

* [Introduction](README.d/01-intro.md)
* [Configuration Guide](README.d/02-configuration.md)
* [Usage Examples](README.d/03-usage-examples.md)
* [Modules Overview](README.d/04-modules.md)
* [Troubleshooting](README.d/05-troubleshooting.md)
* [FAQ](README.d/06-faq.md)
* [Changelog](README.d/99-changelog.md)

---

## 💻 Usage Examples

### Export all users in a group to CSV

```powershell
Import-Module .\P2V_module\P2V_AD_func.psd1
P2V_export_AD_users -GroupName "Your-AD-Group" -OutputPath "C:\Exports\users.csv"
```

### Sync user profile with tenant

```powershell
Import-Module .\P2V_module\P2V_PS_func.psd1
P2V_sync_user -xkey "user123"
```

---

## 📝 Configuration

Edit the CSV files in `P2V_scripts/config/` to match your environment.

Example `P2V_tenants.csv` entry:

```csv
tenant,ServerURL,API,ADgroup,base64AuthInfo
OMV_Prod,https://ps.omv.com,APIKEY,ADGroup1,<base64>
```

**See the [Configuration Guide](README.d/02-configuration.md) for details.**

---

## 🤔 FAQ

**Q:** Can I use this on macOS or Linux?
**A:** No. Requires Windows and PowerShell 5.1+.

**Q:** Where are logs stored?
**A:** `P2V_UM_data/output/logs/`

**Q:** How do I add a new tenant?
**A:** Edit `P2V_tenants.csv` and restart the GUI.
