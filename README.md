Perfect! Here’s a **polished, modern README.md draft** for your repo, styled for public/open GitHub use.
I’ll base it on your structure, module layout, and audience (PowerShell/IT admins, likely in a corporate/enterprise AD environment).

---

```markdown
# P2V User Management Suite

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?logo=powershell)
![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey)
![Status](https://img.shields.io/badge/status-active-brightgreen)
![License](https://img.shields.io/badge/license-Custom-lightgrey)

> **Enterprise PowerShell GUI for AD & P2V REST-based user management**  
> _Seamless Active Directory & multi-tenant user operations from a single pane._

---

## ✨ Features

- **User-friendly Windows Forms GUI**  
  Manage AD users, group assignments, and P2V tenant permissions
- **Bulk operations** for users, groups, and profiles (import/export, sync, audit)
- **REST API integration** with multiple P2V tenants
- **Configurable**: Easy module-based architecture with CSV-based configuration
- **Automated logging** and reporting
- **Enterprise-ready**: Designed for secure, auditable operations

---

## 🗂️ Repository Layout

```

P2V\_UserMgmt\_20.ps1        # Main GUI entry point
P2V\_module/                # Module manifests + core include folder
└─ P2V\_include/
P2V\_config.psm1      # Global variables, directory setup
P2V\_dialog\_func.psm1 # Dialog utilities, confirmation prompts
P2V\_AD\_func.psm1     # AD query helpers
P2V\_PS\_func.psm1     # REST API calls, tenant ops
P2V\_scripts/lib/           # Bulk operation scripts (export, group calc, etc)
P2V\_scripts/config/        # CSV configs for tenants, groups, profiles
P2V\_UM\_data/               # Output/log directory (auto-created)

````

---

## 🚦 Quick Start

1. **Clone this repository**

    ```powershell
    git clone https://github.com/your-org/P2V_UserMgmt_20.git
    cd P2V_UserMgmt_20
    ```

2. **Prepare configuration files**  
   _Edit the CSVs in `P2V_scripts/config/` to match your environment._

3. **Run the main script**

    ```powershell
    .\P2V_UserMgmt_20.ps1
    ```

4. **Start managing users!**

---

## 💡 Example: Bulk Export of AD Users

```powershell
Import-Module .\P2V_module\P2V_AD_func.psd1
P2V_export_AD_users -GroupName "Your-AD-Group" -OutputPath "C:\Exports\users.csv"
````

---

## 📖 Documentation

* **[Configuration Guide](docs/configuration.md)**
* **[User Guide](docs/user_guide.md)**
* **[Advanced Usage & Troubleshooting](docs/troubleshooting.md)**
* **Example configs and more inside `P2V_scripts/config/`**

---

## 🛠️ Module Overview

| Module                 | Purpose                              |
| ---------------------- | ------------------------------------ |
| P2V\_config.psm1       | Global variables, paths, and setup   |
| P2V\_dialog\_func.psm1 | Dialog/confirmation UI utilities     |
| P2V\_AD\_func.psm1     | Active Directory queries/helpers     |
| P2V\_PS\_func.psm1     | REST API, P2V tenant ops             |
| lib/                   | Stand-alone scripts for bulk actions |

---

## 📷 Screenshots

> *Add your own!*

<img src="docs/img/main_gui.png" width="600" alt="Main GUI" />

---

## 🤝 Contributing

* PRs, issues, and feedback are welcome!
* See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## ⚠️ License

This project uses a custom or internal license. See [LICENSE](LICENSE) or contact the author for details.

---

## 🙏 Credits

* Main author: Martin Kufner
* Enterprise support by OMV Group
* Special thanks to all testers and contributors

---

```

---

**Tips:**
- Add a screenshot of the GUI (e.g., to `docs/img/main_gui.png`)
- Fill in your GitHub org/repo link and license details
- Optionally, add FAQ, changelog, or more detailed docs as your project grows

---

Want this as a file, or should I tailor for private/internal use?  
If you give me a screenshot (or mockup), I’ll add it!
```
