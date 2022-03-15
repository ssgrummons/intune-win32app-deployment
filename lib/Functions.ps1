Function ConnectMSGraph{
    # Connect to MS Graph
    Update-MSGraphEnvironment -SchemaVersion "beta"
    Connect-MSGraph -ForceInteractive
    #Connect-AzureAD
}
Function MyFolder{
    if ($null -ne $MyInvocation.MyCommand.Path){
        $folder = Split-Path ($MyInvocation.MyCommand.Path)
    }
    else {
        $folder = (Get-Location).path
    }
    return $folder
}
Function Get-Win32Folders{
    $folders = Get-ChildItem -Directory | Where-Object {$_.Name -match "^win32LobApp_"}
    return $folders
}

Function Ensure-SignedCode{
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the full path of the file to be signed.")]
        [ValidateNotNullOrEmpty()]
        [string]$File
    )
    $output = Get-AuthenticodeSignature -FilePath $File
    if ($output.Status -ne "Valid"){
        Write-Host "Signing File $File"
        $cert=Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert
        Set-AuthenticodeSignature -FilePath $File -Certificate $cert
    }
}

Function Set-Intunewin{
    param(
        [parameter(Mandatory = $true, HelpMessage = "Specify the name of the executable to be ran")]
        [string]$SetupFile
    )
    $SourceFolder = (Resolve-Path ".\src").Path
    $OutputFolder = (Resolve-Path ".").Path
    New-IntuneWin32AppPackage -SourceFolder $SourceFolder -OutputFolder $OutputFolder -SetupFile $SetupFile -Verbose 
}

Function Build-Directories{
    param(
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Folder
    )
    Set-Location -Path $Folder
    # Dot Source the Config outside the script.  This will import any variables into this PS script.
    . ./Config.ps1

    $SetupFilePath = (Resolve-Path (".\src\" + $SetupFile)).Path

    If ($SignFile){
        Ensure-SignedCode -File $SetupFilePath
    }

    If ($SetupFile -match "ps1$"){
        Write-Host "Converting Powershell to EXE"
        $OutputEXE = ($SetupFilePath.Split('.')[0]) + ".exe"
        $ps2exeargs = @(
            "-inputfile",
            "`"$SetupFilePath`"",
            "-outputfile",
            "`"$OutputEXE`"",
            "-title",
            "`"$Title`"",
            "-company",
            "`"$Company`"",
            "-version",
            "`"$Version`"",
            "-noConfigfile"
        )
        if ($RequireAdmin){
            $ps2exeargs += "-requireAdmin"}

        if ($noConsole){
            $ps2exeargs += "-noConsole"
        }
        Write-Host $ps2exeargs
        
        try {
            Invoke-Expression "& '..\lib\ps2exe.ps1' $ps2exeargs"
        }
        catch {
            Write-Host "Conversion Process Failed"
            Write-Warning $Error[0]
        }
        If ($SignFile){
            Ensure-SignedCode -File $OutputEXE
        }
        $SetupFile = Split-Path $OutputEXE -Leaf
    }

    Set-Intunewin -SetupFile $SetupFile
}


Function Build-Command{
    $cmdParams = @{
        "FilePath"=$FilePath 
        "DisplayName"=$DisplayName 
        "Description"=$Description 
        "Publisher"=$Publisher 
        "InstallCommandLine"=$InstallCommandLine 
        "UninstallCommandLine"=$UninstallCommandLine 
        "InstallExperience"=$InstallExperience 
        "RestartBehavior"=$RestartBehavior 
        "DetectionRule"=$DetectionRule 
        "Developer"=$Developer 
        "Owner"=$Owner 
        "Notes"=$Notes 
        "InformationURL"=$InfomationURL 
        "PrivacyURL"=$PrivacyURL 
        "CompanyPortalFeaturedApp"=$CompanyPortalFeaturedApp 
        "RequirementRule"=$RequirementRule 
        "AdditionalRequirementRule"=$AdditionalRequirementRule
        "ReturnCode"=$ReturnCode 
        "Icon"=$Icon
        "Verbose"=$True
    }
    # Identify Empty Parameters
    $emptyParams = @{}
    $cmdParams.GetEnumerator() | ForEach-Object {
        if (($null -eq $_.Value) -or ("" -eq $_.Value)) {
            $emptyParams.Add($_.Key,$_.Value)
        }
    }
    # Remove Empty Parameters
    $emptyParams.GetEnumerator() | ForEach-Object {
        $cmdParams.Remove($_.Name)
    }
    return $cmdParams
}

Function Get-Token{

    Connect-MSGraph | Out-Null
    $cache = [Microsoft.IdentityModel.Clients.ActiveDirectory.TokenCache]::DefaultShared.ReadItems()

    <#
    $needNewToken = $false
    try {
        $cache = [Microsoft.IdentityModel.Clients.ActiveDirectory.TokenCache]::DefaultShared.ReadItems()
    } catch {
        # No Token at all
        $needNewToken = $true
    }
    $UTCDateTime = (Get-Date).ToUniversalTime()
    if ( ($needNewToken) -or ($null -eq $cache.AccessToken) -or ((($cache.ExpiresOn - $UTCDateTime).Minutes) -le 0)) {
        # We have a token but it expired, re connect then get the new ExpiresOn, AccessToken, etc
        Connect-MSGraph
        $cache = [Microsoft.IdentityModel.Clients.ActiveDirectory.TokenCache]::DefaultShared.ReadItems()
    }
    #>
   
    $Global:AuthToken = @{
        "Content-Type" = "application/json"
        "Authorization" = -join("Bearer ", $cache.AccessToken)
        "ExpiresOn" = $cache.ExpiresOn
    }
}

Function Deploy-Directories{
    param(
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Folder
    )
    Set-Location -Path $Folder
    # Dot Source the Config outside the script.  This will import any variables into this PS script.
    . ./Config.ps1
    try {
        Get-Token | Out-Null
        $app = $null
        $appExists = ChkExists-IntuneWin32App -DisplayName $DisplayName -DisplayVersion $DisplayVersion
        if (-not $appExists) {
            $cmdParams = Build-Command
            $app = Add-IntuneWin32App @cmdParams
            if ($DisplayVersion) {
                Set-IntuneWin32AppDisplayVersion $app $DisplayVersion
            }
            if ($AppCategory) {
                Set-IntuneWin32AppCategory $app $AppCategory
            }
            return $app
        } else {
            Write-Warning "win32LobApp: $($DisplayName) Version: $($DisplayVersion) -- Already Exists, skipping"
        }
    }
    catch {
        Write-Host "Deployment Failed"
        Write-Warning $PSItem
        Write-Warning $Error[0]
    }
}

<#
#   Update the Category of a win32 app after it's been added
#     Add-IntuneWin32App doesn't support Category
#>
Function Set-IntuneWin32AppCategory {
    param(
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $clientApp, 

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$categoryName
    )

    # Get all the categories and find the ID of the one we need
    $catID = ""
    $MACategories = Invoke-MSGraphRequest -HttpMethod GET -Url "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileAppCategories" 
    $MACategories.value | ForEach-Object {
        if ($_.displayName.Tolower() -eq $categoryName.ToLower()) {
            $catID = $_.id
        }
    }

    if ($catID -eq "") {
        # Category does not exist so create it
        Write-Host "Creating mobileAppCategory Category: $categoryName"
        $catJson = @"
            {
                "@odata.type": "#microsoft.graph.mobileAppCategory",
                "displayName": "$categoryName"
            }
"@
    
        $newCat = Invoke-MSGraphRequest -Url "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileAppCategories" -Content $catJson -HttpMethod POST -ErrorAction Stop
        $catID = $newCat.id
    }    

    $Json = @"
        {
            "@odata.id":"https://graph.microsoft.com/beta/deviceAppManagement/mobileAppCategories/$catID"
        }
"@
    if ($catID -ne "") {
        # 
        Invoke-MSGraphRequest -Url "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$($clientApp.id)/categories/`$ref" -Content $Json -HttpMethod POST -ErrorAction Stop
    } else {
        Write-Error "Category Name: $categoryName is not defined in InTune"
    }


return 
}

<#
#   Update the displayVersion of a win32 app after it's been added
#     Add-IntuneWin32App doesn't support displayVersion yet
#>
Function Set-IntuneWin32AppDisplayVersion {
    param(
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $clientApp, 

        [parameter(Mandatory = $false)]
        [string]$dispVer
    )
$DVJson = @"
{
    "@odata.type": "#microsoft.graph.win32LobApp",
    "displayVersion": "$DisplayVersion"
}
"@
    # 
    if ($dispVer) {
        Invoke-MSGraphRequest -HttpMethod PATCH -Url "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$($clientApp.id)" -Content $DVJson -ErrorAction Stop
    }

return 
}

Function ChkExists-IntuneWin32App {
    param(
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$DisplayName,

        [parameter(Mandatory = $false)]
        [string]$DisplayVersion
    )

    try {
        $appList = Get-IntuneWin32App -DisplayName $DisplayName
        ForEach ($app in $appList) {
            # We have to check for -eq on DisplayName because Get-IntuneWin32App does a -like with wildcards on either end.
            if ($DisplayVersion) {
                if ( ($app.displayName -eq $DisplayName) -and ($app.displayVersion -eq $DisplayVersion) ) {
                    return $true
                }
            } else {
                if ( ($app.displayName -eq $DisplayName) ) {
                    return $true
                }
            }
        }
    } catch {
        Write-Warning "ChkExists-IntuneWin32App Failed..."
        Write-Warning $Error[0]
    }

    return $false
}



Function New-AppBackup{
    param(
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $clientApp
    )
    $clientAppType = $clientApp.'@odata.type'.split('.')[-1]
    $fileName = ($clientApp.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
    $clientAppDetails = Invoke-MSGraphRequest -HttpMethod GET -Url "deviceAppManagement/mobileApps/$($clientApp.id)"
    $clientAppDetails | ConvertTo-Json | Out-File -FilePath ".\$($clientAppType)_$($fileName).json"
}

function BackupClientApp {    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    # Create folder if not exists
    if (-not (Test-Path "$Path\Client Apps")) {
        $null = New-Item -Path "$Path\Client Apps" -ItemType Directory
    }

    # Get all Client Apps
    $clientApps = Get-DeviceAppManagement_MobileApps | Get-MSGraphAllPages

    foreach ($clientApp in $clientApps) {
        Write-Output "Backing Up - Client App: $($clientApp.displayName)"
        $clientAppType = $clientApp.'@odata.type'.split('.')[-1]

        $fileName = ($clientApp.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $clientAppDetails = Invoke-MSGraphRequest -HttpMethod GET -Url "deviceAppManagement/mobileApps/$($clientApp.id)"
        $clientAppDetails | ConvertTo-Json | Out-File -LiteralPath "$path\Client Apps\$($clientAppType)_$($fileName).json"
    }
}
function ClientAppFilter{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    try{
        Get-ChildItem -Path "$Path\Client Apps"  | Where-Object {$_.Name -match "json$"} | ForEach-Object {
            $fullName = $_.FullName
            if(($fullName -match "managedAndroidStoreApp") -or ($fullName-match "managedIOSStoreApp")){
                Remove-Item $fullName
            }
        }
    }
    catch{
        write-host "Unable to filter files"
    }
}
function BackupClientAppAssignment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    # Create folder if not exists
    if (-not (Test-Path "$Path\Assignments")) {
        $null = New-Item -Path "$Path\Assignments" -ItemType Directory
    }

    # Get all assignments from all policies
    $clientApps = Get-DeviceAppManagement_MobileApps | Get-MSGraphAllPages

    foreach ($clientApp in $clientApps) {
        $assignments = Get-DeviceAppManagement_MobileApps_Assignments -MobileAppId $clientApp.id 
        if ($assignments) {
            Write-Output "Backing Up - Client App - Assignments: $($clientApp.displayName)"
            $fileName = ($clientApp.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            $assignments | ConvertTo-Json -Depth 3 | Out-File -LiteralPath "$path\Assignments\$($clientApp.displayName) - $fileName.json"
        }
    }
}
Function BackupGroups{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$groupIds
    )
    $folder = MyFolder
    if (-not (Test-Path "$folder\Groups")) {
        $null = New-Item -Path "$folder\Groups" -ItemType Directory
    }
    $Groups = @()
    foreach ($groupId in $groupIds) {
        $Groups += Get-Groups -groupId $groupId
    }

    ForEach ($item in $Groups){
        $type = "azureADGroup"
        $fileName = ($item.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        Write-Output "Saving:  $filename -- Type: $type"
        $item | ConvertTo-Json | Out-File -FilePath "$folder\Groups\$($type)_$($fileName).json"
    }
}
Function GetAssignmentGroups{
    $folder = MyFolder
    $files = Get-ChildItem -File "$folder\Assignments" | where-object {$_.Name -match "json$"} 
    $objects = @()

    ForEach ($file in $files){
        $objects += $file | Get-Content -Raw | ConvertFrom-Json
    }
    
    $groupIds = @()
    ForEach ($object in $objects){
        $groupIds += $object.target.groupId
    }

    return $groupIds | Where-Object {$_} | Get-Unique
}
Function EnsureGroupExists{
    #Pass in groupId to create/detect Group
    param(
        [Parameter(Mandatory = $true)]
        [string]$groupId
    )
    # Checkexistance of ID
    try{
        $group = Get-Groups -groupId $groupId
        Write-Host "Group:" $group.displayName "already exists." 
    }
    catch {
        $folder = MyFolder
        $files = Get-ChildItem -File "$folder\Groups" | where-object {$_.Name -match "json$" -and $_.Name -match "^azureADGroup_"} 
        $groups = @()
        ForEach ($file in $files){
            $groups += $file | Get-Content -Raw | ConvertFrom-Json
        }
        $requiredGroup = $groups | Where-Object {$_.id -eq $groupId}
        $filter = "DisplayName eq '" + $requiredGroup.displayname + "'"
        $group = Get-Groups -Filter $filter
        Write-Host "Ensuring Group Exists:" ($requiredGroup.displayname)
        if ($null -eq $group){
            try {
                    Write-Host "Deploying Group:" ($requiredGroup.displayname)
                    $content = ($requiredGroup | Select-Object -Property displayName, description, mailEnabled, mailNickname, securityEnabled, GroupTypes, membershipRule, membershipRuleProcessingState | ConvertTo-Json).toString()
                    $group = Invoke-MSGraphRequest -HttpMethod POST -Url "groups/" -Content $content   
                    Write-Host "Group was created successfully" -ForegroundColor Green   
            }    
            catch{
                Write-Output "-- Error deploying Groups"
                Write-Error $_ -ErrorAction Continue
            }
        } 
    }
    return $group
}
function RestoreClientAppAssignment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [bool]$RestoreById = $false
    )

    # Get all policies with assignments
    $clientApps = Get-ChildItem -Path "$Path\Assignments"
    foreach ($clientApp in $clientApps) {
        $clientAppAssignments = Get-Content -LiteralPath $clientApp.FullName | ConvertFrom-Json
        $clientAppId = $clientAppAssignments.mobileAppId | Select-Object -Unique
        $clientAppName = ($clientApp.BaseName -split " - ")[1]

        # Create the main requestBody
        $requestBody = @{
            mobileAppAssignments = @()
        }
        
        # Add assignments to restore to the request body
        foreach ($clientAppAssignment in $clientAppAssignments) {

            $clientAppAssignment.settings.installTimeSettings.PSObject.Properties | Foreach-Object {
                if ($null -ne $_.Value) {
                    if ($_.Value.GetType().Name -eq "DateTime") {
                        $_.Value = (Get-Date -Date $_.Value -Format s) + "Z"
                    }
                }
            }
            if($clientAppAssignment.target.groupId){
                write-host $clientAppAssignment.target.groupId -ForegroundColor cyan
                $clientAppAssignment.target.groupId = (EnsureGroupExists -groupId $clientAppAssignment.target.groupId).id
            }
            $requestBody.mobileAppAssignments += @{
                "target"   = $clientAppAssignment.target
                "intent"   = $clientAppAssignment.intent
                "settings" = $clientAppAssignment.settings
            }
        }

        # Convert the PowerShell object to JSON
        $requestBody = $requestBody | ConvertTo-Json -Depth 5
        # Get the Client App Data
        try {
            if ($restoreById) {
                $clientAppObject = Get-DeviceAppManagement_MobileApps -mobileAppId $clientAppId
            }
            else {
                $clientAppObject = Get-DeviceAppManagement_MobileApps | Get-MSGraphAllPages | Where-Object { $_.displayName -eq "$($clientAppName)" -and $_.'@odata.type' -ne "#microsoft.graph.managedAndroidStoreApp" -and $_.'@odata.type' -ne "#microsoft.graph.managedIOSStoreApp" }
                if (-not ($clientAppObject)) {
                    Write-Warning "Error retrieving Intune Client App for $($clientApp.FullName). Skipping assignment restore"
                    continue
                }
            }
        }
        catch {
            Write-Output "Error retrieving Intune Client App for $($clientApp.FullName), does it exist in the Intune tenant? Skipping assignment restore ..."
            Write-Error $_ -ErrorAction Continue
            continue
        }
        # Restore the assignments
        try {
            $null = Invoke-MSGraphRequest -HttpMethod POST -Content $requestBody.toString() -Url "deviceAppManagement/mobileApps/$($clientAppObject.id)/assign" -ErrorAction Stop
            Write-Output "$($clientAppObject.displayName) - Successfully restored Client App Assignment(s)"
        }
        catch {
            if ($_.Exception.Message -match "The MobileApp Assignment already exist") {
                Write-Output "$($clientAppObject.displayName) - The Client App Assignment already exists"
            }
            else {
                Write-Output "$($clientAppObject.displayName) - Failed to restore Client App Assignment(s)"
                Write-Error $_ -ErrorAction Continue
            }
        }
    }
}
