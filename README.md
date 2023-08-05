# new-vm-from-iso
Fully automate the creation of a new Hyper-V Virtual Machine and bootable Vhdx containing Windows installed from an ISO: on first boot, the Windows Vm will automatically configure itself using Unattend.Xml and stop at the Login Screen. All Windows Updates will be installed and pending reboots handled automatically. The script will closedown and Checkpoint the machine when all Windows Updates are installed. 

A number of Unattend files for 64-bit OS's are provided for various editions of Windows.

This solution is written using 100% PowerShell 5 - third party tools such as Packer, Sysprep and Vagrant are not used and neither is Interop-P/Invoke. 


## Requirements
A Windows 64-Bit Hyper-V Host (Tested on: Windows 10 Pro)<br>
PowerShellDirect Support on the Host 
PowerShellDirect Support on the Guest
PowerShell 5


## Quick Start
The process is straight forward: the best place to see the lifecycle of creating a Vm, creating a bootable Vhdx and attaching it to the Vm, is to:
1. Open:<br>
<code>'.\examples\test-create-every-vm.ps1'. </code>
2. Comment out the $allTestedIsos except the one you want to work with. 
3. Download and modify the ISO paths accordingly. 
4. From the repository root, then execute:<br>
<code>'.\examples\test-create-every-vm.ps1'</code>

'test-create-every-vm.ps1' contains all ISO's and Unattend files I've tested for this implementation so far. 


## Why?
I wanted a minimal set of 100% PowerShell scripts that could automatically create a Virtual Machine from an ISO; and a set of example Unattend.Xml files that work for a number of 64-bit Operating Systems.


## Customization (Passwords, Computer Names, Product/Activation Keys)
The Unattend file contains the default username (GreyhamWooHoo), Administrator password (p@55word1), GreyhamWooHoo password (p@55word1) and either a Generic Product Key or AVMA Key if required.


## Unattend.Xml
The Unattend files contain the bare minimum to get Windows to boot to the Login Screen - they do not specify (for example) Packages, LanguagePacks or SecurityUpdates: this is deliberate. You will need to import the Unattend.Xml files into the 'Windows System Image Manager' Tool to further customize what is installed. 

Generic Product and AVMA Activation Keys are included in the Unattend file only if they are required to get to the Login Screen. 

An Unattend.Xml file is included for each (ISO/Windows Edition) pair I have tested this with. If this is the first time you have used these scripts, it is recommended that you try to obtain the ISO's I have used to increase the chance that this will work first time :) 

That said, the Unattend files will (probably) work for that Edition from any recent US English ISO of the same architecture (x86/amd64). 

All Unattend files exist under the 'unattend-files' folder. 

## ISO Locations and Unattend.Xml filenames
| ISO | Edition/Unattend.Xml  |
| --- | -------- |
| en-us_windows_11_consumer_editions_version_21h2_updated_july_2023_x64_dvd_16543cb9 | Windows 11 Pro.Xml |
| en_windows_10_consumer_editions_version_1809_updated_dec_2018_x64_dvd_d7d23ac9 | Windows 10 Pro.Xml |
| - | Windows 10 Home.Xml |
| en_windows_server_version_1709_updated_jan_2018_x64_dvd_100492040 | Windows Server Standard.xml |
| en_windows_server_2016_updated_feb_2018_x64_dvd_11636692 | Windows Server 2016 Standard.Xml |
| - | Windows Server 2016 Standard (Desktop Edition).Xml |

## References
| Description | Link |
| ----------- | ---- |
| The Convert-WindowsImage script is used by the Hyper-V Team for testing and contains everything you need to automate setting up a bootable VHD(x) from Windows installation media. I used this script as a reference, took the bare minimum I needed and used 100% PowerShell instead of the Interop/P-Invoke<br><br>If you require more flexibility, it is clearly better you use this script rather than my cut-down ConvertTo-WindowsInstallation module in this repository | https://github.com/MicrosoftDocs/Virtualization-Documentation/tree/master/hyperv-tools/Convert-WindowsImage |
| Official Microsoft script (Convert-WindowsImage.ps1) which replaced WIM2VHD. Provides more history and context than the above reference | https://gallery.technet.microsoft.com/scriptcenter/Convert-WindowsImageps1-0fe23a8f |
| The best walkthru I could find of setting up an automated Windows 10 Installation from scratch (partition setup, OOBE, differences between Autounattend.xml and Unattend.xml etc). | https://www.tenforums.com/tutorials/96683-create-media-automated-unattended-install-windows-10-a.html |
| Landing Page for Out-Of-The-Box Experience. | https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/customize-oobe |
| Generic Product Keys: These keys will get us through the OOBE experience but will not activate windows | https://gist.github.com/jhermsmeier/5959110 |
| Windows System Image Manager: You can download the Windows ADK from this page and run the tool on Windows 10: this tool will allow you to configure the Unattend.Xml for any ISO images and other OS's you might have around | https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/wsim/windows-system-image-manager-technical-reference |
| AVMA (Automatic Virtual Machine Activation). The Windows 2016 Standard (Desktop Experience) Product Key is the AVMA Key from this reference. | https://docs.microsoft.com/en-us/windows-server/get-started-19/vm-activation-19 |
| PSWindowsUpdate is a PowerShell Gallery module for handling Windows Updates. I use PowerShell Direct to connect to the Vm Guest and execute this module. | https://www.powershellgallery.com/packages/PSWindowsUpdate/2.0.0.4 |
