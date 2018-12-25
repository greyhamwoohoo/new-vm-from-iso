<#
.SYNOPSIS
Return the Index from the Wim of the chosen Edition. 

.DESCRIPTION
A WIM file - typically found under the source\install.wim location on an ISO - can contain many different versions/images/editions. 
This Cmdlet will find the index of the given Edition.

.PARAMETER SourcePath
Path to the .wim file (typically: [ISODrive]:\sources\install.wim)

.PARAMETER Edition
Name of the Edition to install. This must be an exact match. 

.EXAMPLE
C:\PS>Get-WindowsImageIndex -SourcePath "C:\woo\install.wim" -Edition "Windows 10 Pro"
Kind:      GetWindowsImageIndexResult
Index:     5

.EXAMPLE
C:\PS>Get-WindowsImage -ImagePath "C:\woo\install.wim"
Windows 10 Home
Windows 10 Home N
Windows 10 Home Single Language
Windows 10 Education
Windows 10 Education N
Windows 10 Pro
Windows 10 Pro N

.NOTES
This Get-WindowsImageIndex CmdLet is a narrow/specific implementation based on this original: https://github.com/MicrosoftDocs/Virtualization-Documentation/tree/master/hyperv-tools/Convert-WindowsImage
#>
function Get-WindowsImageIndex {

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory,HelpMessage="Path of the .wim file. Typically: [MAPPEDISOPATH]:\sources\install.wim")]
        [ValidateNotNullOrEmpty()]
        [string] $SourcePath,
        [Parameter(Mandatory,HelpMessage="Name of the Edition to install. This must be an exact match. To see which Editions are available, run something like: 'Get-WindowsImage -ImagePath `$SourcePath'")]
        [ValidateNotNullOrEmpty()]
        [string] $Edition
    )

    Process
    {
        $windowsImage = Get-WindowsImage -ImagePath $SourcePath | Where-Object {$_.ImageName -eq $Edition}

        if (-not $windowsImage)
        {
            throw "The requested Edition $($Edition) was not found at $($SourcePath). Use 'Get-WindowsImage -ImagePath `$SourcePath' to see which editions are available to install from this media. "
        }

        $imageIndex = $windowsImage[0].ImageIndex

        $result = New-Object System.Management.Automation.PSObject
        $result | Add-Member -MemberType NoteProperty -Name "Kind" -Value "GetWindowsImageIndexResult"
        $result | Add-Member -MemberType NoteProperty -Name "Index" -Value $imageIndex

        Write-Output $result
    }
}
