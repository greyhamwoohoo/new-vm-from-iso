<#
.SYNOPSIS
Stop a Vm using the guest 'shutdown.exe' call; then wait until the state has converged on 'Off'. 

.DESCRIPTION
This Cmdlet is intended to graciously handle 'long shutdowns' that can occur when a large windows update has been installed; 
this appproach also seems to address the issue of Hyper-V getting 'stuck' occasionally when the normal Stop-VM Cmdlet is used. 

.PARAMETER Vm
Virtual Machine (must be running and ready to receive PowerShellDirect)

.PARAMETER Credential
Credential to use to log onto machine
#>
function Stop-VMWithShutdown {

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory,HelpMessage="The virtual machine to be stopped")]
        [ValidateNotNullOrEmpty()]
        [object] $Vm,
        [Parameter(Mandatory,HelpMessage="Administrator credentials to connect to the virtual machine")]
        [ValidateNotNullOrEmpty()]
        [object] $Credential,
        [Parameter(Mandatory=$false,HelpMessage="Timeout in minutes until we forcibly turn off the virtual machine")]
        [long] $ShutdownTimeLimitInMinutes = 30
    )
    Process {
        Write-Verbose "WAIT: Until the Vm State is 'Off'"
        $currentVmState = "--undefined--"
        Wait-PowerShellDirectState -Vm $Vm -Credential $Credential -TimeoutInMinutes 10 -ScriptBlock { $shutdown = Start-Process -FilePath "shutdown.exe" -ArgumentList @("/s /t 30") ; Write-Output $true }
        $startTime = Get-Date
        Write-Verbose "Starting to shut down Vm at: "
        Write-Verbose $startTime.ToString("yyyy-MM-dd-HH:mm:ss")

        do 
        {
            sleep 30
            $currentVm = Get-VM -Name $Vm.Name
            $currentVmState = $currentVm.State

            $now = $(Get-Date) - $startTime
            Write-Verbose "$($now.ToString('hh\:mm\:ss')) - Waiting for VmState of 'Off'. Current VM State is: $($currentVmState). Will force reboot after a total of $($ShutdownTimeLimitInMinutes) minutes wait"

        } until( ($currentVmState -eq "Off") -or ($($now).TotalMinutes -ge $ShutdownTimeLimitInMinutes) )

        if(-NOT ($currentVmState -eq "Off")) {
            Write-Verbose "The machine did not fully stop in $($ShutdownTimeLimitInMinutes) minutes. We will now force a TurnOff"
            Stop-VM -Name $Vm.Name -TurnOff
        }

        Write-Verbose "Vm State has stopped (it is 'Off'). Exiting Stop-VMHelper..."
    }

}
