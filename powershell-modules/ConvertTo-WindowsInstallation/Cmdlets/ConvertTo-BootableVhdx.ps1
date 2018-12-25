<#
.SYNOPSIS
Convert Windows Installation Media (ISO) into a bootable Vhdx drive

.DESCRIPTION
This will create a bootable Vhdx drive with one partition. The Edition from the ISO Image will be laid down onto the Windows Partition and the file at UnattendPath will be copied as 'unattend.xml to the root of that partition. 
On first boot in a Vm, the drive will boot and automatically configure itself. It will stop at the Login Screen. 

.PARAMETER IsoPath
Fully qualified path of the Iso file to mount that contains the Windows Image

.PARAMETER Edition
The Edition of windows to install. The available options can be got by manually mounting the ISO and running (typically): Get-WindowsImage -ImagePath [ISODRIVE]:\sources\install.wim

.PARAMETER UnattendPath
Path of the Unattend to automate the configuration on first boot (OOBE). This file will be placed at the root of the Windows Partition of the Vhdx as 'Unattend.xml'.

.PARAMETER WorkingFolder
Folder in which the Vhdx and all logs will be placed. Typically: this is the 'Virtual Hard Disks' folder of the Vm

.PARAMETER Force
Optional parameter. Will delete the Vhdx file if it already exists

.EXAMPLE
C:\PS> Convert-ToBootableVhd -IsoPath "F:\ISOs\en_windows_10_consumer_edition_version_1803_updated_jul_2018_x64_dvd_12712603.iso" -Edition "Windows 10 Pro" -UnattendPath "F:\temp\oobe.xml" -WorkingFolder "F:\HVVM\TheVm\Virtual Hard Disks" -Force
Kind         : ConvertToBootableVhdResult
Path         : F:\ISOs\en_windows_10_consumer_edition_version_1803_updated_jul_2018_x64_dvd_12712603-Windows-10-Pro.vhdx
Edition      : Windows 10 Pro
EditionIndex : 6
DismLogs     : F:\HVVM\TheVm\Virtual Hard Disks\DismLogs.log
#>
function ConvertTo-BootableVhdx {

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory,HelpMessage="Path to the original ISO Image")]
        [ValidateNotNullOrEmpty()]
        [string] $IsoPath,
        [Parameter(Mandatory,HelpMessage="The Edition of Windows to install. Use the 'Get-WindowsImage' Cmdlet to find the supported Editions. ")]
        [ValidateNotNullOrEmpty()]
        [string] $Edition,
        [Parameter(Mandatory,HelpMessage="Path to the automated response file (this will become 'unattend.xml' on the image)")]
        [ValidateNotNullOrEmpty()]
        [string] $UnattendPath,
        [Parameter(Mandatory,HelpMessage="Path of the working folder. ")]
        [ValidateNotNullOrEmpty()]
        [string] $WorkingFolder,
        [Parameter(HelpMessage="Overwrite the existing vhdx if it exists.")]
        [Switch] $Force,
        [Parameter(Mandatory=$false,HelpMessage="Alternative path of the BCDBoot.exe application")]
        [string] $BCDBoot="BCDBoot.exe",
        [Parameter(Mandatory=$false,HelpMessage="Alternative path of the BCDEdit.exe application")]
        [string] $BCDEdit="BCDEdit.exe",
        [Parameter(Mandatory=$false,HelpMessage="Alternative (maximum) size of the Virtual Hard Disk to create. Default: 128GB")]
        [long] $SizeBytes=137438953472
    )
    PROCESS
    {
        if(-NOT (Test-Path $UnattendPath)) {
            throw "ERROR: The file '$($UnattendPath)' does not exist. You must specify the path of an Unattend.XML file (the file can be called anything - this script will place it in the VHDX Image root drive and called it 'unattend.xml')"
        }

        mkdir $WorkingFolder -Force -ErrorAction SilentlyContinue | Out-Null

        $VhdPath      = Join-Path $WorkingFolder "$([System.IO.Path]::GetFileNameWithoutExtension($IsoPath))-$($Edition -replace ' ','-').vhdx"
        Write-Verbose "VhdPath will be $($VhdPath)"

        if((Test-Path $VhdPath)) {
            if($Force) {
                Remove-Item -Path $VhdPath -Force
            } else {
                throw "ERROR: The file $($VhdPath) already exists. Either remove the file or use the -Force switch"
            }
        }

        Dismount-VHD $VhdPath -ErrorAction SilentlyContinue
        Dismount-DiskImage $IsoPath -ErrorAction SilentlyContinue

        $mountedIsoDiskImage     = Mount-DiskImage -ImagePath $IsoPath -StorageType ISO -PassThru
        $mountedIsoDriveLetter = ($mountedIsoDiskImage | Get-Volume).DriveLetter
        $wimPath  = "$($mountedIsoDriveLetter):\sources\install.wim"
        $dismLogsPath = "$($WorkingFolder)\DismLogs.log"

        if (!(Test-Path $wimPath))
        {
            throw "The Windows Installation Media is expected to have a file at $($wimPath)"
        }

        try {
            Write-Verbose "TRY: To find the Index of the Edition $($Edition) in the Installation Media $($wimPath)"
            $imageIndexResult = Get-WindowsImageIndex -SourcePath $wimPath -Edition $Edition
            Write-Verbose "DONE: The index is $($imageIndexResult)"

            Write-Verbose "TRY: To initialize a new VHD at $($VhdPath): the Vhd will have a bootable System partition and a Windows partition"
            $newVhd = Initialize-VHD -VHDPath $VhdPath -SizeBytes $SizeBytes
            Write-Verbose "DONE: newVhd = $($newVhd)"

            Write-Verbose "TRY: To expand the installation media to $($newVhd.WindowsDrive) so that it can be configured on first boot. "
            Expand-WindowsImage -ApplyPath $newVhd.WindowsDrive -ImagePath $wimPath -Index $imageIndexResult.Index -LogPath $dismLogsPath | Out-Null
            Write-Verbose "DONE: The installation media has been expanded to the Vhd. "

            $targetPath = (Join-Path $newVhd.WindowsDrive "unattend.xml")
            Copy-Item -Path $UnattendPath -Destination $targetPath -Force | Out-Null

            Enable-BootableWindowsPartition -SystemDrive $newVhd.SystemDrive -WindowsDrive $newVhd.WindowsDrive -BCDBoot $BCDBoot -BCDEdit $BCDEdit -WorkingFolder $WorkingFolder | Out-Null

            $vhd = Get-DiskImage -ImagePath $VhdPath

            $result = New-Object System.Management.Automation.PSObject
            $result | Add-Member -MemberType NoteProperty -Name "Kind" -Value "ConvertToBootableVhdResult"
            $result | Add-Member -MemberType NoteProperty -Name "Path" -Value $VhdPath
            $result | Add-Member -MemberType NoteProperty -Name "Edition" -Value $Edition
            $result | Add-Member -MemberType NoteProperty -Name "EditionIndex" -Value $imageIndexResult.Index
            $result | Add-Member -MemberType NoteProperty -Name "DismLogs" -Value $dismLogsPath

            Write-Verbose $result
            Write-Output $result
        }
        finally {
            Dismount-VHD $VhdPath -ErrorAction SilentlyContinue
            Dismount-DiskImage $IsoPath -ErrorAction SilentlyContinue
        }

    }
}
