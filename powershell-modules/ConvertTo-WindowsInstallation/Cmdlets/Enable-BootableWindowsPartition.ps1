<#
.SYNOPSIS
Configure the VHD(x) Windows and System Partition to boot. 

.PARAMETER SystemDrive
The drive letter of the MOUNTED VHD(x) System Partition whose boot configuration you want to change. THis is NOT the drive letter of your hosted machine!

.PARAMETER WindowsDrive
The drive letter of the MOUNTED VHD(x) whose configuration you want to change. This is NOT the drive letter of your host machine!

.PARAMETER BCDBoot
Name of the BCDBoot application to use. Typically: bcdboot.exe

.PARAMETER BCDEdit
Name of the BCDEdit application to use. Typically: bcdedit.exe

.PARAMETER WorkingFolder
Folder where the output will be captured

.NOTES
This Enable-BootableWindowsPartition CmdLet is a narrow/specific implementation based on this original: https://github.com/MicrosoftDocs/Virtualization-Documentation/tree/master/hyperv-tools/Convert-WindowsImage
#>
function Enable-BootableWindowsPartition {

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory,HelpMessage="Drive letter of the mounted VHD(x) System Partition")]
        [ValidateNotNullOrEmpty()]
        [string] $SystemDrive,
        [Parameter(Mandatory,HelpMessage="Drive letter of the mounted VHD(x) Windows Partition")]
        [ValidateNotNullOrEmpty()]
        [string] $WindowsDrive,
        [Parameter(Mandatory,HelpMessage="Path (or filename) of the BCDBoot application. Typically: bcdboot.exe")]
        [ValidateNotNullOrEmpty()]
        [string] $BCDBoot,
        [Parameter(Mandatory,HelpMessage="Path (or filename) of the BCDEdit application. Typically: bcdedit.exe")]
        [ValidateNotNullOrEmpty()]
        [string] $BCDEdit,
        [Parameter(Mandatory,HelpMessage="Working Folder that will capture any outputs and logs")]
        [ValidateNotNullOrEmpty()]
        [string] $WorkingFolder
    )
    Process 
    {
        if (Test-Path "$($systemDrive)\boot\bcd")
        {
            Write-Verbose  "Image already has BIOS BCD store..."
        }
        else
        {
            Write-Verbose "Making image bootable..."
            $bcdBootArgs = @("$($windowsDrive)\Windows","/s $systemDrive","/v","/f BIOS")
            Write-Verbose "Args: $($bcdBootArgs)"

            #
            # These BCD Commands might cause a non-terminating error by writing output to STDERR. 
            # 
            # We want to surface but continue in the case of all non-terminating errors.
            #
            # Examples of output include:
            # BFSVC Warning: Failed to flush system volume. Error = 0x5
            # BFSVC Warning: Failed to flush system partition. Error = [5]
            #
            Invoke-Executable -Path $BCDBoot -Arguments $bcdBootArgs -WorkingFolder $WorkingFolder -ErrorAction Continue

            Invoke-Executable -Path $BCDEdit -Arguments @("/store $($systemDrive)\boot\bcd","/set `{bootmgr`} device locate") -WorkingFolder $WorkingFolder -ErrorAction Continue
            Invoke-Executable -Path $BCDEdit -Arguments @("/store $($systemDrive)\boot\bcd","/set `{default`} device locate") -WorkingFolder $WorkingFolder -ErrorAction Continue
            Invoke-Executable -Path $BCDEdit -Arguments @("/store $($systemDrive)\boot\bcd","/set `{default`} osdevice locate") -WorkingFolder $WorkingFolder -ErrorAction Continue
        } 
    }
}
