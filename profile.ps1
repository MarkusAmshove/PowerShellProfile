trap { Write-Warning ($_.ScriptStackTrace | Out-String) }
# This timer is used by Trace-Message, I want to start it immediately
$TraceVerboseTimer = New-Object System.Diagnostics.Stopwatch
$TraceVerboseTimer.Start()

## Set the profile directory first, so we can refer to it from now on.
Set-Variable ProfileDir (Split-Path $MyInvocation.MyCommand.Path -Parent) -Scope Global -Option AllScope, Constant -ErrorAction SilentlyContinue

# Ensure that PSHome\Modules is there so we can load the default modules
$Env:PSModulePath += ";$PSHome\Modules"
$Env:PSModulePath += ";$ProfileDir\Modules"

# These will get loaded automatically, but it's faster to load them explicitly all at once
Remove-PSReadLineKeyHandler -Chord 'Alt+c'
Import-Module PSFzf -ArgumentList $null, $null, $null, $null -WarningAction SilentlyContinue
Import-Module Microsoft.PowerShell.Management,
              Microsoft.PowerShell.Security,
              Microsoft.PowerShell.Utility,
              Environment,
              Configuration,
              posh-git,
              Profile,
              PoshGrep,
              Get-ChildItemColor,
              DefaultParameter -Verbose:$false
#$VerbosePreference = "Continue"


$GitPromptSettings.EnableStashStatus = $true

Trace-Message "Modules Imported" -Stopwatch $TraceVerboseTimer

if($ProfileDir -ne (Get-Location)) { Set-Location $ProfileDir }

# Load Configurations from Scriptdir
@('PSFzfConfig') | % { . "$ProfileDir\Scripts\$($_).ps1" }

$Env:PSModulePath = Select-UniquePath "$ProfileDir\Modules" (Get-SpecialFolder *Modules -Value) ${Env:PSModulePath} "${Home}\Projects\Modules"
Trace-Message "Env:PSModulePath Updated"

function Reset-Module {
    <#
    .Synopsis
        Remove and re-import a module to force a full reload
    #>
    param($ModuleName)
    Microsoft.PowerShell.Core\Remove-Module $ModuleName
    Microsoft.PowerShell.Core\Import-Module $ModuleName -force -pass | Format-Table Name, Version, Path -Auto
}

Trace-Message "Profile Finished!" -KillTimer
Remove-Variable TraceVerboseTimer

Set-Alias ls Get-ChildItemColor -Option AllScope
Set-Alias l ls -Option AllScope
Set-Alias which Get-Command
Set-Alias grep Find-Matches

function rmrf($path) {
  rm -Recurse -Force $path
}

function mkcd($path) {
  mkdir $path
  cd $path
}

function ltr() {
    ls | Sort-Object { $_.LastWriteTime }
}

## Relax the code signing restriction so we can actually get work done
try { Set-ExecutionPolicy RemoteSigned Process } catch [PlatformNotSupportedException] {}

$VerbosePreference = "SilentlyContinue"

function Test-IsAdmin
{
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal $identity
    return $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

function gstatus() {
        gvim +Gstatus "+call ToggleFullscreenGui()" .\gitignore
}

$defaultForeground = $Host.UI.RawUI.ForegroundColor

function prompt {
    $Host.UI.RawUI.ForegroundColor = $defaultForeground
    $time = (Get-Date).ToString("HH:mm:ss")
    $username = (gc env:\USERNAME).ToLower()
    $computername = (gc env:\COMPUTERNAME).ToLower()
    $currentPath = (pwd).Path.Replace((gc env:\USERPROFILE), '~')

    $userForeground = 'Yellow'
    if(Test-IsAdmin) {
        $userForeground = 'DarkRed'
    }

    Write-Host -NoNewline "$time "
    Write-Host -NoNewline $username -ForegroundColor $userForeground
    Write-Host -NoNewline '@'
    Write-Host -NoNewline $computername
    Write-Host -NoNewline ':'
    Write-Host -NoNewline '[' -ForegroundColor Cyan
    Write-Host -NoNewline $currentPath -ForegroundColor Cyan
    Write-Host -NoNewline ']' -ForegroundColor Cyan
    Write-VcsStatus
    Write-Host -NoNewline ' $'

    if(Get-Command Update-ZLocation -ErrorAction SilentlyContinue) {
        Update-ZLocation $pwd
    }

    return ' '
}

# PowerShell parameter completion shim for the dotnet CLI
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
    param($commandName, $wordToComplete, $cursorPosition)
        dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
           [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}

$env:EDITOR = 'gvim'
$env:LESS = '-iFR'
$env:LESSCHARSET = 'UTF-8'
$env:LC_ALL = 'C.UTF-8'

function .. { cd .. }
function ~ { cd ~ }
