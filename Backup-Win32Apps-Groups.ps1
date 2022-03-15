# Import Functions from Library
if ($null -ne $MyInvocation.MyCommand.Path){
    $folder = Split-Path ($MyInvocation.MyCommand.Path)
} else {
    $folder = $PSScriptRoot.path
}

. ./lib/Functions.ps1

############## MAIN ##############

try {
    ConnectMSGraph
    #BackupClientApp -Path (MyFolder)
    BackupClientAppAssignment -Path (MyFolder)
    ClientAppFilter -Path (MyFolder)
    BackupGroups -groupIds (GetAssignmentGroups)
}
catch {
    Write-Host "Unable to Backup Win32 Apps"
    $_
}