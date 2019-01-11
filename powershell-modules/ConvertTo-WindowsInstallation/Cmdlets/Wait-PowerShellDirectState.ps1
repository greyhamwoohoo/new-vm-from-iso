<#
.SYNOPSIS
Invoke a function on a machine using PowerShell Direct until ScriptBlock returns $True

.PARAMETER Vm
The virtual machine. The Vm should be in a state that is capable of receiving PowerShell Direct calls. 

.PARAMETER Credential
Credential to invoke the script as. 

.PARAMETER ScriptBlock
The ScriptBlock to execute on the virtual machine. The script must return $True when the state has converged; $False otherwise. 

.PARAMETER TimeoutInMinutes
Amount of time to wait until the ScriptBlock returns $True. An exception will be thrown if the timeout is exceeded. 
#>
function Wait-PowerShellDirectState {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory,HelpMessage="Virtual Machine")]
        [object] $Vm,
        [Parameter(Mandatory,HelpMessage="Credential to access the machine via PowerShell Driect")]
        [object] $Credential,
        [Parameter(Mandatory,HelpMessage="The ScriptBlock to execute on the remote machine. Will contain until the script returns True or TimeoutInMinutes is exceeded")]
        [ScriptBlock] $ScriptBlock,
        [Parameter(Mandatory=$false,HelpMessage="Optional timeout in minutes for PowerShell Direct to become available")]
        [int] $TimeoutInMinutes
    )
    Process {

        # Reference: https://blogs.technet.microsoft.com/virtualization/2016/10/11/waiting-for-vms-to-restart-in-a-complex-configuration-script-with-powershell-direct/
        Write-Verbose "Waiting to execute PowerShell Direct on '$($Vm.Name)' to verify state..."
        $startTime = Get-Date
        $stateConverged = $false
        do 
        {
            $now = $(Get-Date) - $startTime
            if ($($now).TotalMinutes -ge $TimeoutInMinutes)
            {
                throw "Could not connect to PowerShell Direct on Vm $($Vm.Name) within $($TimeoutInMinutes)"
            } 
            Sleep 1
            $stateConverged = Invoke-Command -VMId $VM.VMId -Credential $Credential -ScriptBlock $ScriptBlock -ErrorAction SilentlyContinue
            Write-Verbose "Polled..."
        } 
        until ($stateConverged)
        Write-Verbose "State has converged"
    }
}