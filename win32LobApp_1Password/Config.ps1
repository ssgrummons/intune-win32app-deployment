## $SetupFile is used to name the intunewin file
$SetupFile = "1PasswordSetup-7.7.805.msi"

$SignFile = $False

$FilePath = (Get-ChildItem -File | where-object {$_.Name -match "intunewin$"}).FullName
$DisplayName = (Split-Path (Get-Location) -Leaf).Split("_")[1] #This grabs the display name from the folder name
$DisplayVersion = "7.7.805"
$AppCategory =  "Utilities"

$Description = "1Password is a password wallet. 1Password can help you securely store and sync passwords and other information between devices."

$Publisher = "1Password"
$InstallCommandLine = "powershell.exe -Executionpolicy Bypass -File Install.ps1"
$UninstallCommandLine = "powershell.exe -Executionpolicy Bypass -File Uninstall.ps1"
$InstallExperience = "system"
$RestartBehavior = "suppress"
$Developer = "Your Name"
$Notes = ""
$Owner = "Your Company"
$InfomationURL = "www.1password.com"
$PrivacyURL = "https://privacyinfo.mycompany.com"
$CompanyPortalFeaturedApp = $False

$IconPath = (Resolve-Path "1pwd.png")
$Icon = New-IntuneWin32AppIcon -FilePath $IconPath

$RequirementRule = New-IntuneWin32AppRequirementRule -Architecture x64 -MinimumSupportedOperatingSystem 1607

$DetectionRule1 = New-IntuneWin32AppDetectionRuleMSI -ProductCode "{8A0007E4-9D8E-4F82-828B-177A53AFF519}"
$DetectionRule = @($DetectionRule1)


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