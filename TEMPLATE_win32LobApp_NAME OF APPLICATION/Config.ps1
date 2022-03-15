# 
$SetupFile = "ospw32.exe"
$SignFile = $True

# PS to EXE Required Parameters
$Title = $null
$Company = $null
$Version = $null
$RequireAdmin = $False
$noConsole = $False
# End of PS to EXE Required Parameters

$FilePath = (Get-ChildItem -File | where-object {$_.Name -match "intunewin$"}).FullName
$DisplayName = (Split-Path (Get-Location) -Leaf).Split("_")[1] #This grabs the display name from the folder name
$Description = ""
$Publisher = "PC@IBM"
$InstallCommandLine = ""
$UninstallCommandLine = ""
$InstallExperience = "system"
$RestartBehavior = "supress"
$Developer = ""
$Notes = "PC@IBM Required"
$Owner = ""
$InfomationURL = ""
$PrivacyURL = "https://w3.ibm.com/w3-privacy-notice"
$CompanyPortalFeaturedApp = $False

<#

    The following variables are built with scripts from the IntuneWin32App Module.  
    https://github.com/MSEndpointMgr/IntuneWin32App 

        Install-Module -Name "IntuneWin32App"

    They will need to be manually edited for each config file.
    Uncomment the below lines and edit using the cmdlets available in the IntuneWin32App Module.
    Use the documentation or "Get-command <cmdlet> -syntax" for help.
    ######################
$ScriptFile = (Resolve-Path "LocalAccountControls_Verify.ps1").Path
$DetectionRule = New-IntuneWin32AppDetectionRuleScript -ScriptFile $ScriptFile -EnforceSignatureCheck $False -RunAs32Bit $False

$RequirementRule = $null

DO NOT INCLUDE RETURN CODES; THOSE ARE POPULATED BY DEFAULT
$ReturnCode0 = New-IntuneWin32AppReturnCode -ReturnCode 0 -Type "success"
$ReturnCode1707 = New-IntuneWin32AppReturnCode -ReturnCode 1707 -Type "success"
$ReturnCode3010 = New-IntuneWin32AppReturnCode -ReturnCode 3010 -Type "softReboot"
$ReturnCode1641 = New-IntuneWin32AppReturnCode -ReturnCode 1641 -Type "hardReboot"
$ReturnCode1618 = New-IntuneWin32AppReturnCode -ReturnCode 1618 -Type "retry"
$ReturnCode = @($ReturnCode0,$ReturnCode1707,$ReturnCode3010,$ReturnCode1641,$ReturnCode1618)


$Icon = New-IntuneWin32AppIcon -FilePath .\icon.png
#>

#################################################

<#
After importing this config file, use the following command to manually deploy the application.

Add-IntuneWin32App `
-FilePath $FilePath `
-DisplayName $DisplayName `
-Description $Description `
-Publisher $Publisher `
-InstallCommandLine $InstallCommandLine `
-UninstallCommandLine $UninstallCommandLine `
-InstallExperience $InstallExperience `
-RestartBehavior $RestartBehavior `
-DetectionRule $DetectionRule `
-Developer $Developer `
-Owner $Owner `
-Notes $Notes `
-InformationURL $InfomationURL `
-PrivacyURL $PrivacyURL `
-CompanyPortalFeaturedApp $CompanyPortalFeaturedApp `
-RequirementRule $RequirementRule `
-ReturnCode $ReturnCode `
-Icon $Icon
#>