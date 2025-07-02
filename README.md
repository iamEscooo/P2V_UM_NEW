# P2V User Management

## Overview

**P2V_UserMgmt_20** is a comprehensive PowerShell toolkit for managing users and permissions in complex enterprise environments. It provides a Windows Forms GUI for both Active Directory operations and seamless integration with the Plan2Value (P2V) REST API, supporting bulk operations, profile synchronization, group mapping, and more.

This project is modular, highly configurable via CSV files, and suitable for multi-tenant scenarios.

---

## Features

- **Windows Forms GUI** for intuitive user and group management.
- **Active Directory Integration:**  
  - Query users, groups, and memberships  
  - Export user lists  
  - Interactive selection dialogs
- **P2V REST API Integration:**  
  - Sync users and group memberships  
  - Activate, deactivate, lock, unlock users  
  - Patch and update user profiles, workgroups, and access rights
- **Bulk Operations:**  
  - Execute batch jobs via scripts in `lib/`
  - Automate group and profile assignments
- **Configurable:**  
  - All tenants, groups, and profiles defined in CSV files (under `P2V_scripts/config/`)
- **Logging:**  
  - Detailed logs written per session in `P2V_UM_data/output/logs/`
- **Extensible:**  
  - Modular design with self-contained PowerShell modules
- **Multi-tenant aware:**  
  - Designed for environments with multiple AD domains and P2V tenants

---

## Repository Layout

```plaintext
P2V_UserMgmt_20.ps1         # Main script (launches the GUI and imports all modules)
P2V_module/                 # Module manifests (.psd1)
    P2V_config.psd1
    P2V_dialog_func.psd1
    P2V_AD_func.psd1
    P2V_PS_func.psd1
    P2V_include.psd1
P2V_include/                # Actual module implementations (.psm1)
    P2V_config.psm1
    P2V_dialog_func.psm1
    P2V_AD_func.psm1
    P2V_PS_func.psm1
    P2V_include.psm1
lib/                        # Stand-alone/bulk PowerShell scripts
P2V_scripts/
    config/                 # Configuration CSV files (tenants, groups, profiles, etc.)
P2V_UM_data/                # Output directory (logs, dashboards, data exports)
Getting Started
Prerequisites
PowerShell 5.1 (Windows PowerShell)

Active Directory Module
(Install via RSAT or Install-WindowsFeature -Name "RSAT-AD-PowerShell")

Network connectivity to your AD and P2V REST API endpoints

Properly configured CSV files in P2V_scripts/config/ (see below)

Installation
Clone the repository:

sh
Copy
Edit
git clone https://github.com/<your-org>/P2V_UserMgmt_20.git
Adjust configuration:

Edit CSV files in P2V_scripts/config/ for tenants, AD groups, profiles, etc.

Launch the GUI:

sh
Copy
Edit
powershell -ExecutionPolicy Bypass -File .\P2V_UserMgmt_20.ps1
Configuration
All tenant, group, and profile definitions are managed via CSV files in P2V_scripts/config/:

File	Purpose
P2V_tenants.csv	List of tenants, API endpoints, etc.
P2V_adgroups.csv	Mapping of AD groups to P2V profiles
P2V_profiles.csv	Profile definitions
data_groups.csv	Data group mappings
TAG_config.csv	Tagging and metadata settings
P2V_BD.csv	Business Domain group mapping
P2V_BD_projects.csv	Project-specific group mapping
P2V_menu.csv	Customization of the GUI menu

Sample templates are provided in the repo. Ensure you update these to reflect your environment.

Module Breakdown
Each module is defined by a manifest (.psd1) and implemented in a .psm1 file under P2V_include/:

Module	Purpose
P2V_config	Global variables, directory paths, init functions
P2V_dialog_func	Windows Forms dialogs, user prompts, confirmations
P2V_AD_func	Active Directory queries, user/group lookups
P2V_PS_func	REST API (P2V) interactions and user management
P2V_include	Utility functions, logging, orchestration, glue code

Usage
General workflow:

Launch the main script (P2V_UserMgmt_20.ps1)

Use the GUI to:

Query and manage AD users/groups

Sync users between AD and P2V tenants

Patch, activate, deactivate, lock, or unlock users

Run bulk operations from the "lib" menu

All changes and errors are logged under P2V_UM_data/output/logs/

Development & Contribution
All code is PowerShell 5.1 compatible.

Module loading and variable exporting follow PowerShell best practices.

PRs welcome! Please submit issues for bugs or enhancement requests.

License
MIT License (or your actual license here)

Author
Martin Kufner
with enhancements and maintenance by [your name or GitHub handle]
