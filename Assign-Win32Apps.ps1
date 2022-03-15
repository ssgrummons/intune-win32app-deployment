<#
.SYNOPSIS
    Assign win32 apps based on a csv input file 
                
.DESCRIPTION
    Using an input .csv file with format:

        DisplayName,Entitled (Y/N)

    If Entitled = 'n' then assign to all users
    If Entitled = 'y' then assign to group with name like slm-grp-PCteam-<DisplayName>
                
.NOTES
    Required Dependencies
        Install-Module -Name IntuneWin32App
#>    

param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the input .csv file")]
        [ValidateNotNullOrEmpty()]
        [string]$csvFileName = $null
    )


##################################
############## MAIN ##############
##################################
$null = Update-MSGraphEnvironment -SchemaVersion beta
$Graph = Connect-MSGraph
$cache = [Microsoft.IdentityModel.Clients.ActiveDirectory.TokenCache]::DefaultShared.ReadItems()
$Global:AuthToken = @{
    "Content-Type" = "application/json"
    "Authorization" = -join("Bearer ", $cache.AccessToken)
    "ExpiresOn" = $cache.ExpiresOn
}


#Import-Csv $csvFileName | ForEach-Object {

Import-Csv 'KyndrylApps.csv' | ForEach-Object {
    Write-Host "$($_.DisplayName) - Entitled = $($_.Entitled)"
    # get the ID of this App
    try {
        $appList = Get-IntuneWin32App -DisplayName $_.DisplayName
        $appID = $null
        ForEach ($app in $appList) {
            # We have to check for -eq on DisplayName because Get-IntuneWin32App does a -like with wildcards on either end.
            if ( ($app.displayName -eq $_.DisplayName) ) {
                $appID = $app.ID 
                if ($_.Entitled.ToLower() -eq 'n') {
                    $null = Add-IntuneWin32AppAssignmentAllUsers -ID $appID -Intent 'available'
                } else {
                    $grpName = "grp-slm-PCteam-" + $app.displayName
                    $grpList = Get-Groups -Filter "startswith(displayName,'$($grpName)')"  -Select @('id','displayName')
                    $grpExists = $false
                    ForEach ($grp in $grpList) {
                        if ( ($grp.displayName -eq $grpName) ) {
                            $grpExists = $true
                            $null = Add-IntuneWin32AppAssignmentGroup -Include -ID $appID -GroupID $grp.ID -Intent 'available'
                        }
                    }
                    if (-not $grpExists) {
                        Write-Warning "Group:  $($grpName)  Does not exist"
                    }
                }
            }
        }
        if (-not $appID) {
            Write-Warning "App: $($_.DisplayName) Not Found"
        }
    } catch {
        Write-Warning "Failed..."
        Write-Warning $Error[0]
    }



}


