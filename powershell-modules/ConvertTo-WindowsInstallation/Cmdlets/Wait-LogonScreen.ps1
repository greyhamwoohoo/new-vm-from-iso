<#
.SYNOPSIS
Wait for the Logon Screen to appear

.PARAMETER Vm
The virtual machine. The Vm should be in a state that is capable of receiving PowerShell Direct calls. 

.PARAMETER Credential
Credential to invoke the script as. 
#>
function Wait-LogonScreen {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory,HelpMessage="Virtual Machine")]
        [object] $Vm,
        [Parameter(Mandatory,HelpMessage="Credential to access the machine via PowerShell Driect")]
        [object] $Credential
    )
    Process {

        # TODO: What is the best way to wait for this? 
        Wait-PowerShellDirectState -Vm $vm -Credential $credential -TimeoutInMinutes 10 -ScriptBlock { 
            $logonUis = @(Get-Process -Name "LogonUI"); Write-Output $($logonUis.Count -gt 0) 
        }  

    }
}
