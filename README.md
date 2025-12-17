![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=for-the-badge&logo=powershell&logoColor=white)
![License](https://img.shields.io/github/license/bigjoestretch/powershell-toolkit?style=for-the-badge)
![GitHub last commit](https://img.shields.io/github/last-commit/bigjoestretch/powershell-toolkit?style=for-the-badge)
![GitHub issues](https://img.shields.io/github/issues/bigjoestretch/powershell-toolkit?style=for-the-badge)

# PowerShell Toolkit

A comprehensive collection of PowerShell scripts for enterprise IT administration. Built from 20 years of hands-on experience in healthcare IT environments, these scripts solve real-world challenges across Microsoft infrastructure.

These aren't theoretical examples - they're battle-tested tools from actual production environments, shared freely with the IT community.

---

## What's Inside

This toolkit provides automation solutions for:

- **Active Directory & Domain Services** - User management, group policy, domain administration
- **VMware vSphere & PowerCLI** - Virtual infrastructure automation, reporting, and management
- **Microsoft 365** - Exchange Online, SharePoint, Teams, and tenant administration
- **Azure & Entra ID** - Cloud identity management and Azure resource automation
- **Microsoft Intune** - Device management, policy deployment, and compliance
- **Windows Server** - System administration, certificate services, and deployment automation

---

## Repository Structure

```
powershell-toolkit/
├── ActiveDirectory/        # AD user, group, and domain management scripts
├── Azure Runbook/          # Azure Automation runbook scripts
├── AzureAD/               # Azure AD / Entra ID administration
├── Exchange/              # Exchange Server and Exchange Online scripts
├── Intune/                # Microsoft Intune device and policy management
├── MsGraph/               # Microsoft Graph API automation
├── Office365/             # Microsoft 365 tenant administration
├── PowerShell/            # General PowerShell utilities and helpers
├── SharePoint/            # SharePoint Online administration
├── Teams/                 # Microsoft Teams management
├── VMWare/PowerCLI/       # VMware vSphere automation scripts
└── Windows/               # Windows Server administration scripts
```

---

## Getting Started

### Prerequisites

Most scripts require:
- **PowerShell 5.1** or later (PowerShell 7+ recommended)
- **Appropriate PowerShell modules** for your target platform:
  - `ActiveDirectory` - For AD scripts
  - `VMware.PowerCLI` - For VMware scripts
  - `Microsoft.Graph` - For Microsoft 365/Azure scripts
  - `ExchangeOnlineManagement` - For Exchange Online scripts
  - `Microsoft.Online.SharePoint.PowerShell` - For SharePoint scripts

### Installation

1. Clone or download this repository:
```powershell
git clone https://github.com/bigjoestretch/powershell-toolkit.git
```

2. Navigate to the appropriate folder for your task

3. Review the script comments and parameters before running

4. Execute with appropriate permissions for your environment

---

## Usage Examples

### Active Directory Management
```powershell
# Example: User account management
.\ActiveDirectory\Get-ADUserReport.ps1 -SearchBase "OU=Users,DC=domain,DC=com"
```

### VMware Automation
```powershell
# Example: VM inventory report
.\VMWare\PowerCLI\Get-VMInventory.ps1 -VCenterServer "vcenter.domain.com"
```

### Microsoft 365 Administration
```powershell
# Example: Exchange Online mailbox report
.\Exchange\Get-MailboxSizeReport.ps1 -ExportPath "C:\Reports"
```

---

## Best Practices

- **Always test scripts in a non-production environment first**
- Review and understand what each script does before running
- Ensure you have appropriate permissions for the target environment
- Backup data before running scripts that make changes
- Modify scripts to fit your specific environment needs
- Follow your organization's change management procedures

---

## Contributing

Found a bug? Have an improvement? Contributions are welcome!

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

## License

This project is licensed under the GPL-3.0 License - see the [LICENSE](LICENSE) file for details.

---

## About the Author

**Joel Cottrell** - Systems Engineer with 20 years of experience in enterprise IT infrastructure, specializing in Microsoft technologies and automation for healthcare environments.

---

## Disclaimer

THE SOFTWARE (SCRIPTS) ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

**Always test scripts in a development environment before using in production.**

---

## Support

If you find these scripts helpful, please:
- ⭐ Star this repository
- 🐛 Report issues you encounter
- 💡 Share your improvements
- 📢 Tell other IT professionals

---

![VMware](https://img.shields.io/badge/VMware-607078?style=flat&logo=vmware&logoColor=white)
![Microsoft 365](https://img.shields.io/badge/Microsoft_365-0078D4?style=flat&logo=microsoft&logoColor=white)
![Azure](https://img.shields.io/badge/Azure-0089D6?style=flat&logo=microsoft-azure&logoColor=white)
![Active Directory](https://img.shields.io/badge/Active_Directory-0078D4?style=flat&logo=windows&logoColor=white)
