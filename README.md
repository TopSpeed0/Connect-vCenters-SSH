# Connect-vCenters-SSH
Connect to vCenter and Lets you decided to what Cluster to start and stop SSH, also set the policy to off for batter security.

# PowerShell VMware Script

This PowerShell script is designed to perform Start or Stop operations on the SSH service of VMware VMHosts. It connects to specified vCenter Servers and prompts the user to choose between Start or Stop for the SSH service.

## Prerequisites

- VMware PowerCLI module (VMware.VimAutomation.Core)
- VMware vCenter Server credentials
- AES key and password file for vCenter Server authentication

## Usage

### Parameters

- **StartSSH**: Switch to start the SSH service.
- **StopSSH**: Switch to stop the SSH service.

### Usage Example

```powershell
.\VMwareScript.ps1 -StartSSH
```

### Note
Both switches cannot be set at the same time. Choose either Start or Stop.

### Configuration
Update the ```$keyFile``` and ```$pswdFile``` variables with the correct paths to your AES key and password file.
Set the vCenter Server information in the ```$Site1, $Site2, $Site3, $Site4, and $Site5 variables ```

### Logging
Error logs are saved to the C:\Logs\VMwareScriptErrors.log file.

### Contributing
Feel free to contribute to the development of this script by opening issues or submitting pull requests.

### License
This project is licensed under the MIT License - see the [MIT License](LICENSE)  file for details.
