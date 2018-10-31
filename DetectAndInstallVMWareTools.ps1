<#
.SYNOPSIS
    Detect if the BIOS is VMWare, and install VMWare Tools.

.DESCRIPTION
    My laziness knows no bounds, and I'm tried of installing VMWare Tools during deployment testing.
    This script will detect if the BIOS is VMWare, and then install VMWare Tools. If it's a real machine,
    the script just exits quietly.

    Since this script is designed to run during an OS deployment, I'm not going to reboot the system after
    the installation of VMWare Tools since the system is going to reboot eventually to finish deployment.

    Also, it's 2017. If you're using a 32-bit OS, it's time to move on. 

.INPUTS
    None.

.OUTPUTS
    I attempt to output any log files at C:\Windows\Temp\DetectAndInstallVMWareTools.log.

.NOTES
  Version:        1.0
  Author:         Matthew Harding
  Creation Date:  August 02, 2017
  Purpose/Change: Initial script development
  
.EXAMPLE
  .\DetectAndInstallVMWareTools.ps1

#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference = "SilentlyContinue"

#Dot Source required Function Libraries
. "%SystemDrive%\KACE\Applications\48\Logging_Functions.ps1"

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Script Version
$sScriptVersion = "1.0"

#Log File Info
$sLogPath = "C:\Windows\Temp"
$sLogName = "DetectAndInstallVMWareTools.log"
$sLogFile = Join-Path -Path $sLogPath -ChildPath $sLogName

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function Verify-VMwareToolsInstallation()
{
    $vmtInstall = gwmi "Win32_Product" | Where-Object {$_.Name -match "VMWare Tools"}
   
    return ($vmtInstall -ne $null)
}

function Install-VMwareTools()
{
    $VMWareToolsx86 = Get-ChildItem %SystemDrive%\KACE\Applications\48\ | Where-Object {$_.name -match "setup.exe"}
    $VMWareToolsx64 = Get-ChildItem %SystemDrive%\KACE\Applications\48\ | Where-Object {$_.name -match "setup64.exe"}
   
    $OS = Get-OperatingSystem
    $VMWareToolsInstalled = Verify-VMwareToolsInstallation 
    $reboot = $false
   
    if (!$VMWareToolsInstalled)
    {
        if ($OS.OSArchitecture -match "64-bit")
        {
            $VMWareToolsLocationPath = $VMWareToolsx64.fullname
        }
        else
        {
            $VMWareToolsLocationPath = $VMWareToolsx86.fullname
        }
       
        $command = "$VMWareToolsLocationPath"
        $arguments = "/s /v "/qn reboot=r""
       
        if (Test-Path $VMWareToolsLocationPath)
        {   
            try
            {
                $process = [diagnostics.process]::start($command, $arguments)
                $process.WaitForExit()
                $reboot = $true
                write-host "The installation of VMWare Tools have been completed."
            }
            catch
            {
                write-warning "There was an error when installing VMWare Tools. You'll need to install VMWare Tools manually."
            }
        }
        else
        {
            write-warning "Unable to find VMware Tools Installer. You'll need to install VMWare Tools manually."
        }
    }
    else
    {
        write-host "VMware Tools has already installed."
    }
}

function Verify-VMwareModel()
{
    $vmtInstall = gwmi "Win32_ComputerSystem" | Where-Object {$_.Model -match "VMware Virtual Platform"}
   
    return ($vmtInstall -ne $null)
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

Log-Start -LogPath $sLogPath -LogName $sLogName -ScriptVersion $sScriptVersion

Write-Host "====================================="
Write-Host "|  Detect and Install VMWare Tools  |"
Write-Host "====================================="
Write-Host

$virtualMachine = Verify-VMwareModel

if ($virtualMachine)
{
    write-host "Install VMware Tools" -ForegroundColor "white"
    Write-Host "--------------------"
    $reboot = Install-VMwareTools
    Write-Host
}
else
{
    write-warning "This does not appear to be a VMWare virtual machine."
    write-host "The script will not install VMWareTools."
}

Log-Finish -LogPath $sLogFile