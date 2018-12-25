<#
.SYNOPSIS
Creates a new Vhd(x) containing a single partition. 

.DESCRIPTION
Creates a new Vhd(x) containing a single partition. 

.PARAMETER VHDPath
Fully qualified path to the VHD(x) file to create

.PARAMETER SizeBytes
Size of the VHD(x) in Bytes

.EXAMPLE
C:\PS>Initialize-VHD -VHDPath "C:\temp\woo.vhdx" -SizeBytes 128000000000
Kind:         InitializeVhdResult
WindowsDrive: I
SystemDrive:  I

.NOTES
This Initialize-VHD CmdLet is a narrow/specific implementation based on this original: https://github.com/MicrosoftDocs/Virtualization-Documentation/tree/master/hyperv-tools/Convert-WindowsImage
#>
function Initialize-VHD {

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory,HelpMessage="Fully qualified path of the Vhd disk to create")]
        [ValidateNotNullOrEmpty()]
        [string] $VHDPath,
        [Parameter(Mandatory,HelpMessage="Size of the new VHD in bytes")]
        [long] $SizeBytes
    )

    PROCESS 
    {
        $newVhd = New-VHD -Path $VHDPath -SizeBytes $SizeBytes  -Dynamic

        $disk = $newVhd | Mount-VHD -PassThru | Get-Disk

        $initializeDisk = Initialize-Disk -Number $disk.Number -PartitionStyle MBR
                    
        $volume = New-Partition -DiskNumber $disk.Number -UseMaximumSize -MbrType IFS -IsActive -AssignDriveLetter | Format-Volume -FileSystem NTFS -Force -Confirm:$false

        $drive = $(Get-Partition -Volume $volume).AccessPaths[0].substring(0,2)
        Write-Verbose "Windows path ($drive) has been assigned."

        $result = New-Object System.Management.Automation.PSObject
        $result | Add-Member -MemberType NoteProperty -Name "Kind" -Value "InitializeVhdResult"
        $result | Add-Member -MemberType NoteProperty -Name "WindowsDrive" -Value $drive
        $result | Add-Member -MemberType NoteProperty -Name "SystemDrive" -Value $drive

        Write-Output $result
    }
}