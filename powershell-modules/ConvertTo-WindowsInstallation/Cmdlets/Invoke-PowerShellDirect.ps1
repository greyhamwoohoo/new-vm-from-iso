<#
.SYNOPSIS
Invoke a function on a machine using PowerShell Direct

.PARAMETER Vm
The virtual machine. The Vm should be in a state that is capable of receiving PowerShell Direct calls. 

.PARAMETER Credential
Credential to invoke the script as. 

.PARAMETER ScriptBlock
The ScriptBlock to execute on the virtual machine. 
#>
function Invoke-PowerShellDirect {

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory,HelpMessage="Virtual Machine")]
        [ValidateNotNullOrEmpty()]
        [object] $Vm,
        [Parameter(Mandatory,HelpMessage="Credential to access the machine via PowerShell Driect")]
        [ValidateNotNullOrEmpty()]
        [object] $Credential,
        [Parameter(Mandatory,HelpMessage="The ScriptBlock to execute on the remote machine.")]
        [ValidateNotNullOrEmpty()]
        [ScriptBlock] $ScriptBlock
    )
    Process {
        $result = Invoke-Command -VMId $VM.VMId -Credential $Credential -ScriptBlock $ScriptBlock
        Write-Output $result
    }

}