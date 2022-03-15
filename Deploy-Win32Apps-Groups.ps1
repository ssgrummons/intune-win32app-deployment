# Import Functions from Library
if ($null -ne $MyInvocation.MyCommand.Path){
    $folder = Split-Path ($MyInvocation.MyCommand.Path)
} else {
    $folder = $PSScriptRoot.path
}

. ./lib/Functions.ps1

############## MAIN ##############

. $folder/lib/Functions.ps1

try {
    ConnectMSGraph
    RestoreClientAppAssignment -Path (MyFolder)
}
catch {
    Write-Host "Unable to deploy App Assignments"
}
