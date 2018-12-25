#
# This test script is set up to work from my machine (ISO location, Cloned Repository location etc)
# You will need to download the specific ISOs to get this up and running
#

#Requires -Version 5
#Requires -RunAsAdministrator
#Requires -PSEdition Desktop
#Requires -Modules Hyper-V
Set-StrictMode -Version 5

$ErrorActionPreference="Stop"
$VerbosePreference="Continue"

Import-Module .\powershell-modules\ConvertTo-WindowsInstallation\ConvertTo-WindowsInstallation.psm1

# Point this at a drive that has lots of space
$vmsRootFolder = "D:\HVVM"

$allTestedIsos = @(
    <#@{
        IsoPath="G:\ISOs\OperatingSystems\Windows10\en_windows_10_consumer_editions_version_1809_updated_dec_2018_x64_dvd_d7d23ac9.iso"
        VmName="GH1809W10PRO64"
        UnattendPath="F:\greyhamwoohoo\new-vm-from-iso\unattend-files\en_windows_10_consumer_editions_version_1809_updated_dec_2018_x64_dvd_d7d23ac9\Windows 10 Pro.Xml"
        Edition="Windows 10 Pro"
    }
    @{
        IsoPath="G:\ISOs\OperatingSystems\Windows10\en_windows_10_consumer_editions_version_1809_updated_dec_2018_x64_dvd_d7d23ac9.iso"
        VmName="GH1809W10HOM64"
        UnattendPath="F:\greyhamwoohoo\new-vm-from-iso\unattend-files\en_windows_10_consumer_editions_version_1809_updated_dec_2018_x64_dvd_d7d23ac9\Windows 10 Home.Xml"
        Edition="Windows 10 Home"
    }
    @{
        IsoPath="G:\ISOs\OperatingSystems\WindowsServer2016\en_windows_server_version_1709_updated_jan_2018_x64_dvd_100492040.iso"
        VmName="GH17092K16SJ18"
        UnattendPath="F:\greyhamwoohoo\new-vm-from-iso\unattend-files\en_windows_server_version_1709_updated_jan_2018_x64_dvd_100492040\Windows Server Standard.Xml"
        Edition="Windows Server Standard"
    }
    @{
        IsoPath="G:\ISOs\OperatingSystems\WindowsServer2016\en_windows_server_2016_updated_feb_2018_x64_dvd_11636692.iso"
        VmName="GH17092K16SF18"
        UnattendPath="F:\greyhamwoohoo\new-vm-from-iso\unattend-files\en_windows_server_2016_updated_feb_2018_x64_dvd_11636692\Windows Server 2016 Standard.Xml"
        Edition="Windows Server 2016 Standard"
    }#>
    @{
        IsoPath="G:\ISOs\OperatingSystems\WindowsServer2016\en_windows_server_2016_updated_feb_2018_x64_dvd_11636692.iso"
        VmName="GH17092K16DEF18"
        UnattendPath="F:\greyhamwoohoo\new-vm-from-iso\unattend-files\en_windows_server_2016_updated_feb_2018_x64_dvd_11636692\Windows Server 2016 Standard (Desktop Experience).Xml"
        Edition="Windows Server 2016 Standard (Desktop Experience)"
    }
)

($allTestedIsos).ForEach{

    $candidateVmFolder = [System.IO.Path]::Combine($vmsRootFolder, $_.VmName)
    if(Test-Path $candidateVmFolder) {
        throw "ERROR: There is already a folder (virtual machine?) at $($candidateVmFolder). Please remove that folder first. "
    }

    $candidateExistingVm = Get-VM -Name $_.VmName -ErrorAction SilentlyContinue
    if($candidateExistingVm) {
        throw "ERROR: There is already a virtual machine called $($_.VmName). Please remove the VM before continuing"
    }

    $vm = New-VM -Name $_.VmName -MemoryStartupBytes 8000MB -NoVHD -Path $vmsRootFolder
    $vmHardDisksFolder = [System.IO.Path]::Combine($vmsRootFolder, $_.VmName, "Virtual Hard Disks")
    $bootableVhd = ConvertTo-BootableVhdx -IsoPath $_.IsoPath -Edition $_.Edition -UnattendPath $_.UnattendPath -WorkingFolder $vmHardDisksFolder -Force
    $vmHardDiskDrive = Add-VMHardDiskDrive -VMName $_.VmName -Path $bootableVhd.Path -Passthru

    Start-VM -Name $_.VmName -Passthru
}

