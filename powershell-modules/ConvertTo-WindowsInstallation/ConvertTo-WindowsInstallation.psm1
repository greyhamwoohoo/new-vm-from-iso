# ConvertTo-WindowsInstallation.psm1
# 
# Description: Convert an ISO into an bootable Vhdx containing an installed Windows Operating System.
#              The Vhdx will boot as far as the Login Screen
# 
# Author: Greyhamwoohoo

$here = Split-Path -Parent $MyInvocation.MyCommand.Path

. $here\CmdLets\Enable-BootableWindowsPartition.ps1
. $here\CmdLets\Get-WindowsImageIndex.ps1
. $here\CmdLets\Initialize-Vhd.ps1
. $here\CmdLets\Invoke-Executable.ps1
. $here\CmdLets\ConvertTo-BootableVhdx.ps1

Export-ModuleMember -Function "ConvertTo-BootableVhdx"
