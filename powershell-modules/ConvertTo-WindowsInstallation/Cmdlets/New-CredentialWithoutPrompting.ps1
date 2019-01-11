<#
.SYNOPSIS
Helper method to create a Credential object

.PARAMETER UserName
User name

.PARAMETER PlainTextPassword
Plain text password
#>
function New-CredentialWithoutPrompting {
    
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory,HelpMessage="Enter the Username")]
        [string] $Username,
        [Parameter(Mandatory,HelpMessage="Plain text password")]
        [string] $PlainTextPassword
    )
    Process {
        $password = ConvertTo-SecureString $PlainTextPassword -AsPlainText -Force

        $cred = New-Object -Typename System.Management.Automation.PSCredential -argumentlist $Username, $password

        Write-Output $cred
    }
}
