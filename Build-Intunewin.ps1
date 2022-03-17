<#
.SYNOPSIS
    Build the Intune Deliverable from source using the configuration file.
                
.DESCRIPTION
    Build script imports the configuration from Config.ps1 and automates the build of the .intunewin file.
                
.NOTES
    In order for content to be signed, a Code Signing Certificate must be installed in your local certificate store
    Required Dependencies
        Install-Module -Name IntuneWin32App
#>    

param(
        [parameter(Mandatory = $false, HelpMessage = "Specify the folder to be built.  If not specified all foldes will be built")]
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
                Write-Host "Processing Folder $win32Folder.Name"
                $path = (Resolve-Path $win32Folder).Path
                Write-Host $path
                Build-Directories -Folder $path
                Set-Location $scriptpath
            }
            catch {
                Write-Host "Error Building Directory $win32Folder.Name"
                Set-Location $scriptpath
            }
        }        
    }
else {
    try {
        $path = (Resolve-Path $Win32Folder).Path
        Build-Directories -Folder $path
        Set-Location $scriptpath
    }
    catch {
        Write-Host "Error Building Directory $Win32Folder"
        Write-Warning $PSItem
        Set-Location $scriptpath
    }
}



