# ConvertTo-WindowsInstallation.psm1
# 
# Description: Convert an ISO into an bootable Vhdx containing an installed Windows Operating System.
#              The Vhdx will boot as far as the Login Screen
# 
# Author: Greyhamwoohoo

$here = Split-Path -Parent $MyInvocation.MyCommand.Path

. $here\CmdLets\Stop-VmWithShutdown.ps1
. $here\CmdLets\Enable-BootableWindowsPartition.ps1
. $here\CmdLets\Get-WindowsImageIndex.ps1
. $here\CmdLets\Initialize-Vhd.ps1
. $here\CmdLets\Invoke-Executable.ps1
. $here\CmdLets\ConvertTo-BootableVhdx.ps1
. $here\CmdLets\New-CredentialWithoutPrompting.ps1
. $here\CmdLets\Wait-PowerShellDirectState.ps1
. $here\CmdLets\Invoke-PowerShellDirect.ps1
. $here\CmdLets\Update-OperatingSystem.ps1
. $here\CmdLets\New-VmFromIso.ps1
. $here\CmdLets\Wait-LogonScreen.ps1

Export-ModuleMember -Function "ConvertTo-BootableVhdx"
Export-ModuleMember -Function "New-CredentialWithoutPrompting"
Export-ModuleMember -Function "Wait-PowerShellDirectState"
Export-ModuleMember -Function "Invoke-PowerShellDirect"
Export-ModuleMember -Function "Update-OperatingSystem"
Export-ModuleMember -Function "New-VmFromIso"
Export-ModuleMember -Function "Wait-LogonScreen"
Export-ModuleMember -Function "Stop-VmWithShutdown"
