<#
.SYNOPSIS
Helper to launch an executable with arguments and capture the StdErr and StdOut. 

.DESCRIPTION
This will throw an exception if the ExitCode is non-zero. 

.PARAMETER Path
Path to the executable

.PARAMETER Arguments
An array of arguments to pass to the executable

.PARAMETER WorkingFolder
Folder where the output will be captured

.EXAMPLE
C:\PS>Invoke-Executable -Path "cmd.exe" -Arguments @("/c dir C:\temp") -WorkingFolder "C:\temp" -Verbose
<output from dir command>
#>
function Invoke-Executable
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,HelpMessage="Path of the executable to run")]
        [string]
        [ValidateNotNullOrEmpty()]
        $Path,

        [Parameter(Mandatory,HelpMessage="Arguments")]
        [string[]]
        [ValidateNotNullOrEmpty()]
        $Arguments,

        [Parameter(Mandatory,HelpMessage="Working Folder where StdOut and StdErr will be written.")]
        [string[]]
        [ValidateNotNullOrEmpty()]
        $WorkingFolder
    )

    New-Item -Path $WorkingFolder -ItemType Directory -ErrorAction SilentlyContinue

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss-fff"
    $stdErrPath = [System.IO.Path]::Combine($WorkingFolder, "$($timestamp)-StdErr.txt")
    $stdOutPath = [System.IO.Path]::Combine($WorkingFolder, "$($timestamp)-StdOut.txt")

    Write-Verbose "StdErr will be redirected to $($stdErrPath)"
    Write-Verbose "StdOut will be redirected to $($stdOutPath)"

    Write-Verbose "TRY: To run: $Path $Arguments"
    $result = Start-Process -FilePath $Path -ArgumentList $Arguments -NoNewWindow -Wait -Passthru -RedirectStandardError $stdErrPath -RedirectStandardOutput $stdOutPath
    Write-Verbose "DONE: Exit code was $($result.ExitCode)."

    Write-Verbose "STDOUT:"
    (Get-Content $stdOutPath).ForEach{Write-Verbose $_}
    Write-Verbose "STDERR:"
    (Get-Content $stdErrPath).ForEach{Write-Error $_} 

    if ($result.ExitCode -ne 0)
    {
        throw "Executing '$($Path)' failed with code $($result.ExitCode)"
    }
}
