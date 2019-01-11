<#
.SYNOPSIS
Install Updates on the Operating System; this will reboot the machine as many times as necessary until all updates are downloaded and installed. 

.DESCRIPTION
Install Updates on the Operating System; this will reboot the machine as many times as necessary until all updates are downloaded and installed. 
The virtual machine must be running. 

.PARAMETER Vm
Virtual Machine (must be running and ready to receive PowerShellDirect)

.PARAMETER Credential
Credential to use to log onto machine
#>
function Update-OperatingSystem {

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory,HelpMessage="The virtual machine to be updated")]
        [ValidateNotNullOrEmpty()]
        [object] $Vm,
        [Parameter(Mandatory,HelpMessage="Administrator credentials to connect to the virtual machine")]
        [ValidateNotNullOrEmpty()]
        [object] $Credential
    )
    Process {

        Wait-PowerShellDirectState -Vm $vm -Credential $credential -TimeoutInMinutes 10 -ScriptBlock { $True }

        Invoke-PowerShellDirect -Vm $Vm -Credential $Credential -ScriptBlock {
            $ErrorActionPreference="Stop"
            $VerbosePreference="Continue"
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -Scope CurrentUser

            Install-PackageProvider -Name NuGET -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser
            Install-Module PSWindowsUpdate -Force -Scope CurrentUser
        }

        $allWindowsUpdatesInstalled = $false
        do 
        {
            Write-Verbose "About to invoke Windows Update"
            $updateResults = Invoke-PowerShellDirect -Vm $Vm -Credential $Credential -ScriptBlock {
                $ErrorActionPreference="Stop"
                $VerbosePreference="Continue"
                Import-Module PSWindowsUpdate -Force | Out-Null

                $result = New-Object System.Management.Automation.PSObject
                $result | Add-Member -MemberType NoteProperty -Name "AllUpdatesInstalled" -Value $false
                $result | Add-Member -MemberType NoteProperty -Name "RebootRequired" -Value $false

                $windowsUpdates = Get-WindowsUpdate -MicrosoftUpdate -WindowsUpdate -Download -AcceptAll -Install -IgnoreReboot -IgnoreUserInput
                if(-NOT $windowsUpdates) {
                    Write-Verbose "No information was returned from Get-WindowsUpdate. Assuming everything we need is installed. "
                    $result.AllUpdatesInstalled = $true
                } else {
                    ($windowsUpdates).ForEach{
                        Write-Verbose $_
                    }
                }

                $systemInfo = New-Object -ComObject "Microsoft.Update.SystemInfo"
                Write-Verbose "Reboot Required: $($systemInfo.RebootRequired)"
                if($systemInfo.RebootRequired) {
                    $result.RebootRequired = $true
                }
        
                Write-Verbose $result
                return $result
            }

            Write-Verbose "Windows Update invoked. "
            Write-Verbose $updateResults
            if($updateResults.RebootRequired) {
                Write-Verbose "Restarting virtual machine..."

                Stop-VmWithShutdown -VM $vm -Credential $credential

                Start-VM -Name $Vm.Name
                Write-Verbose "Waiting for the Logon Screen to become available again... "
                Wait-LogonScreen -Vm $Vm -Credential $Credential
                continue;
            }

            $allWindowsUpdatesInstalled = $updateResults.AllUpdatesInstalled

        } until($allWindowsUpdatesInstalled)

        Write-Verbose "All Updates have been installed. Exiting"
    }
}
