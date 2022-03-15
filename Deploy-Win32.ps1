<#
.SYNOPSIS
    Deploy the Intune Deliverable from source using the configuration file.
                
.DESCRIPTION
    Deploy script imports the configuration from Config.ps1 and automates the deployment of the .intunewin file.
                
.NOTES
    Required Dependencies
        Install-Module -Name IntuneWin32App
#>    

param(
        [parameter(Mandatory = $false, HelpMessage = "Specify the folder to be built.  If not specified all folders will be built")]
        [ValidateNotNullOrEmpty()]
        [string]$Win32Folder = $null
    )

# Import Functions from Library
. ./lib/Functions.ps1

##################################
############## MAIN ##############
##################################

$scriptpath = Split-Path ($MyInvocation.MyCommand.Path)

If ("" -eq $Win32Folder) {
        Write-Host "Processing All Folders"
        $win32Folders = Get-Win32Folders
        ForEach ($win32Folder in $win32Folders) {
            try {
                Write-Host "Processing Folder $win32Folder"
                $path = (Resolve-Path $win32Folder).Path
                #Write-Host $path
                $app = $null
                $app = Deploy-Directories -Folder $path
                if ($app) {
                    New-AppBackup -clientApp $app
                }
                Set-Location $scriptpath
            }
            catch {
                Write-Host "Error Deploying Directory $Win32Folder "
                Write-Warning $PSItem
                Set-Location $scriptpath
            }
        }        
    }
else {
    try {
        $path = (Resolve-Path $Win32Folder)
        $app = Deploy-Directories -Folder $path
        if ($app) {
            New-AppBackup -clientApp $app
        }
        Set-Location $scriptpath
    }
    catch {
        Write-Host "Error Deploying Directory $Win32Folder "
        Write-Warning $PSItem
        Set-Location $scriptpath
    }
}