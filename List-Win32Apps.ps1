<#
.SYNOPSIS
    List all the apps in the current branch
                
.DESCRIPTION
    
                
.NOTES
    Required Dependencies
     
#>    

param(
        [parameter(Mandatory = $false, HelpMessage = "Specify the folder to be listed.  If not specified all folders will be listed")]
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
                #Write-Host "Processing Folder $win32Folder.Name"
                $path = (Resolve-Path $win32Folder).Path
                Set-Location -Path $path
                # Dot Source the Config outside the script.  This will import any variables into this PS script.
                . ./Config.ps1
                Write-Host $DisplayName
                Set-Location $scriptpath
            } catch {
                Write-Host "Error Listting Directory $Win32Folder "
                Write-Warning $PSItem
                Set-Location $scriptpath
            }
        }        
    }
else {
    try {
        $path = (Resolve-Path $Win32Folder)
        Set-Location -Path $path
        # Dot Source the Config outside the script.  This will import any variables into this PS script.
        . ./Config.ps1
        Write-Host $DisplayName
        Set-Location $scriptpath
    }
    catch {
        Write-Host "Error Listting Directory $Win32Folder "
        Write-Warning $PSItem
        Set-Location $scriptpath
    }
}