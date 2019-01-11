<#
.SYNOPSIS
Create a new Vm from an Iso

.DESCRIPTION
Create a new Vm from an Iso; the Iso will be mounted, a Vhdx created containing the installation media and the Unattend.Xml file placed in the root folder.
A Vm will then be created and the Vhdx attached. When the Vm is started, it will configure itself as far as the Login screen. 

.PARAMETER VmsRootFolder
Folder that will contain the virtual machine. This method will create a subfolder called 'VmName' to hold the Vm and its virtual hard disks. 

.PARAMETER VmName
Name of the virtual machine. NOTE: This is not the actual machine name (DNS) - that is set in the Unattend.Xml file. 

.PARAMETER UnattendPath
Path of the Unattend.Xml file to use. The file can be called anything providing it is the correct format; it will be placed in the root of the Vhdx file as Unattend.Xml and read on first boot. 

.PARAMETER Edition
Edition of Windows to install. Each ISO contains a number of different editions; this should be the exact name returned using the 'Get-WindowsImage' Cmdlet. 

.PARAMETER IsoPath
Path of the Iso file containing the installation media. 
#>
function New-VmFromIso {

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory,HelpMessage="Root path to be used to store virtual machines. Choose a drive with enough space. A sub-folder will be created to contain the virtual machine")]
        [ValidateNotNullOrEmpty()]
        [string] $VmsRootFolder,
        [Parameter(Mandatory,HelpMessage="Name of the Virtual Machine in Hyper-V. This is not the machine / DNS Name")]
        [ValidateNotNullOrEmpty()]
        [string] $VmName,
        [Parameter(Mandatory,HelpMessage="Path of the Unattend.Xml file. ")]
        [ValidateNotNullOrEmpty()]
        [string] $UnattendPath,
        [Parameter(Mandatory,HelpMessage="Edition to install. Look up Get-WindowsImage for more information on available editions. ")]
        [ValidateNotNullOrEmpty()]
        [string] $Edition,
        [Parameter(Mandatory,HelpMessage="Path of the .ISO file. ")]
        [ValidateNotNullOrEmpty()]
        [string] $IsoPath

    )
    Process {

        $candidateVmFolder = [System.IO.Path]::Combine($VmsRootFolder, $VmName)
        if(Test-Path $candidateVmFolder) {
            throw "ERROR: There is already a folder (virtual machine?) at $($candidateVmFolder). Please remove that folder first. "
        }

        $candidateExistingVm = Get-VM -Name $VmName -ErrorAction SilentlyContinue
        if($candidateExistingVm) {
            throw "ERROR: There is already a virtual machine called $($VmName). Please remove the VM before continuing"
        }

        $vm = New-VM -Name $VmName -MemoryStartupBytes 8000MB -NoVHD -Path $VmsRootFolder # -SwitchName "Vm-External-Switch"
        $vmHardDisksFolder = [System.IO.Path]::Combine($VmsRootFolder, $VmName, "Virtual Hard Disks")
        $bootableVhd = ConvertTo-BootableVhdx -IsoPath $IsoPath -Edition $Edition -UnattendPath $UnattendPath -WorkingFolder $vmHardDisksFolder -Force
        $vmHardDiskDrive = Add-VMHardDiskDrive -VMName $VmName -Path $bootableVhd.Path -Passthru

        $result = New-Object System.Management.Automation.PSObject
        $result | Add-Member -MemberType NoteProperty -Name "Kind" -Value "NewVmFromIsoResult"
        $result | Add-Member -MemberType NoteProperty -Name "VmName" -Value $VmName
        $result | Add-Member -MemberType NoteProperty -Name "Edition" -Value $Edition
        $result | Add-Member -MemberType NoteProperty -Name "VmsRootFolder" -Value $VmsRootFolder
        $result | Add-Member -MemberType NoteProperty -Name "IsoPath" -Value $IsoPath
        $result | Add-Member -MemberType NoteProperty -Name "UnattendPath" -Value $UnattendPath
        $result | Add-Member -MemberType NoteProperty -Name "DismLogs" -Value $bootableVhd.DismLogs
        $result | Add-Member -MemberType NoteProperty -Name "VhdxPath" -Value $bootableVhd.Path

        Write-Verbose $result
        Write-Output $result
    }
}
