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

.PARAMETER UpdateKind
The kind of updates to install. One of: WindowsUpdate or MicrosoftUpdate
#>
function Update-OperatingSystem {

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory,HelpMessage="The virtual machine to be updated")]
        [ValidateNotNullOrEmpty()]
        [object] $Vm,

        [Parameter(Mandatory,HelpMessage="Administrator credentials to connect to the virtual machine")]
        [ValidateNotNullOrEmpty()]
        [object] $Credential,

        [Parameter(Mandatory,HelpMessage="Whether to install WindowsUpdates or MicrosoftUpdates")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("WindowsUpdate", "MicrosoftUpdate")]
        [string] $UpdateKind
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

                if($UpdateKind -eq "WindowsUpdate") {
                    $windowsUpdates = @(Get-WindowsUpdate -WindowsUpdate -Download -AcceptAll -Install -IgnoreReboot -IgnoreUserInput)
                } else {
                    $windowsUpdates = @(Get-WindowsUpdate -MicrosoftUpdate -Download -AcceptAll -Install -IgnoreReboot -IgnoreUserInput)
                }

<#              Each windowsUpdates object has these properties - the object is enriched with some of the NoteProperty's depending if one or more of -Install -AcceptAll -Download is specified. 

                Name                            MemberType   Definition
                ----                            ----------   ----------
                AcceptEula                      Method       void AcceptEula ()
                CopyFromCache                   Method       void CopyFromCache (string, bool)
                CopyToCache                     Method       void CopyToCache (IStringCollection)
                ChooseResult                    NoteProperty string ChooseResult=Accepted
                ComputerName                    NoteProperty string ComputerName=GH0723W11PRO64
                DownloadResult                  NoteProperty string DownloadResult=Downloaded
                KB                              NoteProperty string KB=KB5011048
                Result                          NoteProperty string Result=Downloaded
                Size                            NoteProperty string Size=68MB
                Status                          NoteProperty string Status=AD-----
                X                               NoteProperty int X=2
                AutoDownload                    Property     AutoDownloadMode AutoDownload () {get}
                AutoSelection                   Property     AutoSelectionMode AutoSelection () {get}
                AutoSelectOnWebSites            Property     bool AutoSelectOnWebSites () {get}
                BrowseOnly                      Property     bool BrowseOnly () {get}
                BundledUpdates                  Property     IUpdateCollection BundledUpdates () {get}
                CanRequireSource                Property     bool CanRequireSource () {get}
                Categories                      Property     ICategoryCollection Categories () {get}
                CveIDs                          Property     IStringCollection CveIDs () {get}
                Deadline                        Property     Variant Deadline () {get}
                DeltaCompressedContentAvailable Property     bool DeltaCompressedContentAvailable () {get}
                DeltaCompressedContentPreferred Property     bool DeltaCompressedContentPreferred () {get}
                DeploymentAction                Property     DeploymentAction DeploymentAction () {get}
                Description                     Property     string Description () {get}
                DownloadContents                Property     IUpdateDownloadContentCollection DownloadContents () {get}
                DownloadPriority                Property     DownloadPriority DownloadPriority () {get}
                EulaAccepted                    Property     bool EulaAccepted () {get}
                EulaText                        Property     string EulaText () {get}
                HandlerID                       Property     string HandlerID () {get}
                Identity                        Property     IUpdateIdentity Identity () {get}
                Image                           Property     IImageInformation Image () {get}
                InstallationBehavior            Property     IInstallationBehavior InstallationBehavior () {get}
                IsBeta                          Property     bool IsBeta () {get}
                IsDownloaded                    Property     bool IsDownloaded () {get}
                IsHidden                        Property     bool IsHidden () {get} {set}
                IsInstalled                     Property     bool IsInstalled () {get}
                IsMandatory                     Property     bool IsMandatory () {get}
                IsPresent                       Property     bool IsPresent () {get}
                IsUninstallable                 Property     bool IsUninstallable () {get}
                KBArticleIDs                    Property     IStringCollection KBArticleIDs () {get}
                Languages                       Property     IStringCollection Languages () {get}
                LastDeploymentChangeTime        Property     Date LastDeploymentChangeTime () {get}
                MaxDownloadSize                 Property     decimal MaxDownloadSize () {get}
                MinDownloadSize                 Property     decimal MinDownloadSize () {get}
                MoreInfoUrls                    Property     IStringCollection MoreInfoUrls () {get}
                MsrcSeverity                    Property     string MsrcSeverity () {get}
                PerUser                         Property     bool PerUser () {get}
                RebootRequired                  Property     bool RebootRequired () {get}
                RecommendedCpuSpeed             Property     int RecommendedCpuSpeed () {get}
                RecommendedHardDiskSpace        Property     int RecommendedHardDiskSpace () {get}
                RecommendedMemory               Property     int RecommendedMemory () {get}
                ReleaseNotes                    Property     string ReleaseNotes () {get}
                SecurityBulletinIDs             Property     IStringCollection SecurityBulletinIDs () {get}
                SupersededUpdateIDs             Property     IStringCollection SupersededUpdateIDs () {get}
                SupportUrl                      Property     string SupportUrl () {get}
                Title                           Property     string Title () {get}
                Type                            Property     UpdateType Type () {get}
                UninstallationBehavior          Property     IInstallationBehavior UninstallationBehavior () {get}
                UninstallationNotes             Property     string UninstallationNotes () {get}
                UninstallationSteps             Property     IStringCollection UninstallationSteps () {get}                
#>
                # Windows 11 sometimes appears to get stuck in a loop bringing the same Windows Updates time after time (even though .Result was Installed).
                #    Not sure if this is in PSWindowsUpdate or otherwise. 
                # 
                # In particular: the follow update would be installed... but would then show up in the next Get-WindwsUpdate causing an infinite loop:
                # Update for Windows Security platform antimalware platform - KB5007651 (Version 1.0.2306.10002)
                #
                # I am not sure the root cause of this. 
                # HACK: To get around this, I fetch a list of remaining updates and bail if all of them were previosuly installed. 
                if($windowsUpdates.Count -eq 0) {
                    Write-Verbose "No information was returned from Get-WindowsUpdate. Assuming everything we need is installed. "
                    $result.AllUpdatesInstalled = $true
                } else {

                    Write-Verbose "WINDOWS UPDATES - INITIAL FETCH"
                    Write-Verbose (($windowsUpdates).ForEach{ $_ | Format-List } | Out-String)

                    $justInstalledUpdates = @($windowsUpdates | Where-Object { $_.IsInstalled -or $_.Result -eq "Installed" })
                    $justInstalledUpdatesTitles = @($justInstalledUpdates | %{ $_.Title } | Select-Object -Unique)

                    if($UpdateKind -eq "WindowsUpdate") {
                        $windowsUpdates = @(Get-WindowsUpdate -WindowsUpdate -AcceptAll -IgnoreReboot -IgnoreUserInput)
                    } else {
                        $windowsUpdates = @(Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -IgnoreUserInput)
                    }       

                    Write-Verbose "WINDOWS UPDATES - SECOND FETCH"
                    Write-Verbose (($windowsUpdates).ForEach{ $_ | Format-List } | Out-String)                

                    #
                    # Work out if there are any Windows Updates that were NOT previously installed
                    #
                    $notInstalledUpdates = @($windowsUpdates | Where-Object { -NOT ($justInstalledUpdatesTitles -contains $_.Title ) } )

                    Write-Verbose "WINDOWS UPDATES - NOT YET INSTALLED"
                    Write-Verbose (($notInstalledUpdates).ForEach{ $_ | Format-List } | Out-String)   

                    if($notInstalledUpdates.Count -eq 0) {

                        Write-Verbose "It looks like all updates have already been installed; breaking out. "
                        $result.AllUpdatesInstalled = $true
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
            Write-Verbose "$updateResults"
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
