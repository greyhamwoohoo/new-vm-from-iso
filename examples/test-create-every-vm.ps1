#
# This test script is set up to work from my machine (ISO location, Cloned Repository location etc)
# You will need to download the specific ISOs to get this up and running
#

#Requires -Version 5
#Requires -RunAsAdministrator
#Requires -PSEdition Desktop
#Requires -Modules Hyper-V
Set-StrictMode -Version 5

$ErrorActionPreference="Continue"
$VerbosePreference="Continue"

Remove-Module ConvertTo-WindowsInstallation -Force -ErrorAction SilentlyContinue
Import-Module .\powershell-modules\ConvertTo-WindowsInstallation\ConvertTo-WindowsInstallation.psm1


# Point this somewhere with a lot of space; a subfolder will be created for each Virtual Machine
$vmsRootFolder = "C:\HVVMAuto"
# Credentials for an Administrator user; this used is created in the Unattend.Xml files I provide for each OS and Edition
$username = "GreyhamWooHoo"
$plainTextPassword = "p@55word1"                               

$availableExternalSwitches = (Get-VMSwitch).Where{$_.SwitchType -eq "External"}    
if($availableExternalSwitches.Count -ne 1) {
    throw "ERROR: You do not have exactly one External Switch so we cannot choose one automatically. Use Get-VMSwitch to identify the switches and then specify its name in the 'externalSwitchName' variable. "
}
$externalSwitchName = $availableExternalSwitches[0].Name




$allTestedIsos = @(
    @{
        IsoPath="G:\ISOs\OperatingSystems\WIndows10\en-us_windows_10_consumer_editions_version_22h2_updated_july_2023_x64_dvd_0ee9325c.iso"
        VmName="GH0723W10PRO64"
        UnattendPath="F:\greyhamwoohoo\new-vm-from-iso\unattend-files\en-us_windows_10_consumer_editions_version_22h2_updated_july_2023_x64_dvd_0ee9325c\Windows 10 Pro.Xml"
        Edition="Windows 10 Pro"
    },
    @{
        IsoPath="G:\ISOs\OperatingSystems\WIndows11\en-us_windows_11_consumer_editions_version_21h2_updated_july_2023_x64_dvd_16543cb9.iso"
        VmName="GH0723W11PRO64"
        UnattendPath="F:\greyhamwoohoo\new-vm-from-iso\unattend-files\en-us_windows_11_consumer_editions_version_21h2_updated_july_2023_x64_dvd_16543cb9\Windows 11 Pro.Xml"
        Edition="Windows 11 Pro"
    } 
<#  @{
        IsoPath="G:\ISOs\OperatingSystems\Windows10\en_windows_10_consumer_editions_version_1809_updated_dec_2018_x64_dvd_d7d23ac9.iso"
        VmName="GH1809W10PRO64"
        UnattendPath="F:\greyhamwoohoo\new-vm-from-iso\unattend-files\en_windows_10_consumer_editions_version_1809_updated_dec_2018_x64_dvd_d7d23ac9\Windows 10 Pro.Xml"
        Edition="Windows 10 Pro"
    }
 <#   @{
        IsoPath="G:\ISOs\OperatingSystems\Windows10\en_windows_10_consumer_editions_version_1809_updated_dec_2018_x64_dvd_d7d23ac9.iso"
        VmName="GH1809W10HOM64"
        UnattendPath="F:\greyhamwoohoo\new-vm-from-iso\unattend-files\en_windows_10_consumer_editions_version_1809_updated_dec_2018_x64_dvd_d7d23ac9\Windows 10 Home.Xml"
        Edition="Windows 10 Home"
    }
    @{
        IsoPath="G:\ISOs\OperatingSystems\WindowsServer2016\en_windows_server_version_1709_updated_jan_2018_x64_dvd_100492040.iso"
        VmName="GH17092K16SJ18"
        UnattendPath="F:\greyhamwoohoo\new-vm-from-iso\unattend-files\en_windows_server_version_1709_updated_jan_2018_x64_dvd_100492040\Windows Server Standard.Xml"
        Edition="Windows Server Standard"
    }#>
    <#@{
        IsoPath="G:\ISOs\OperatingSystems\WindowsServer2016\en_windows_server_2016_updated_feb_2018_x64_dvd_11636692.iso"
        VmName="GH17092K16SF18"
        UnattendPath="F:\greyhamwoohoo\new-vm-from-iso\unattend-files\en_windows_server_2016_updated_feb_2018_x64_dvd_11636692\Windows Server 2016 Standard.Xml"
        Edition="Windows Server 2016 Standard"
    }
    @{
        IsoPath="G:\ISOs\OperatingSystems\WindowsServer2016\en_windows_server_2016_updated_feb_2018_x64_dvd_11636692.iso"
        VmName="GH17092K16DEF18"
        UnattendPath="F:\greyhamwoohoo\new-vm-from-iso\unattend-files\en_windows_server_2016_updated_feb_2018_x64_dvd_11636692\Windows Server 2016 Standard (Desktop Experience).Xml"
        Edition="Windows Server 2016 Standard (Desktop Experience)"
    }#>
)



($allTestedIsos).ForEach{
    #
    # Create the VM (and Vhdx) and get it ready to configure on first boot
    #
    $result = New-VmFromIso -VmsRootFolder $vmsRootFolder -VmName $_.VmName -UnattendPath $_.UnattendPath -Edition $_.Edition -IsoPath $_.IsoPath

    Add-VMNetworkAdapter -VMName $_.VmName -SwitchName $externalSwitchName

    $vm = Get-VM -Name $result.VmName
    Checkpoint-VM -VM $vm -SnapshotName "BeforeFirstBoot"



    #
    # Install Windows Updates
    #
    Restore-VMSnapshot -VMName $_.VmName -Name "BeforeFirstBoot" -Confirm:$false

    Start-VM -Name $_.VmName
    $vm = Get-VM -Name $_.VmName
    $credential = New-CredentialWithoutPrompting -Username $username -PlainTextPassword $plainTextPassword

    Write-Verbose "Waiting for Network Connectivity..."
    # TODO: Move this into Wait-NetworkConnectivity
    Wait-PowerShellDirectState -Vm $vm -Credential $credential -TimeoutInMinutes 10 -ScriptBlock { try { Invoke-RestMethod -Method GET -Uri "https://google.com.au"; Write-Output $True } catch { Write-Output $False } }
    Write-Verbose "Network Connectivity achieved"
    Wait-LogonScreen -Vm $vm -Credential $credential
    Update-OperatingSystem -Vm $vm -Credential $credential -UpdateKind "WindowsUpdate"
    
    # OPTIONAL:
    # Update-OperatingSystem -Vm $vm -Credential $credential -UpdateKind "MicrosoftUpdate"

    Stop-VmWithShutdown -VM $vm -Credential $credential
    Checkpoint-VM -VM $vm -SnapshotName "AfterWindowsUpdates"
}

#
# KNOWN ISSUES
# A few :-)
# Timeouts are currently hard coded; need to parameterize per Cmdlet and/or extract to variable/global setting
#
