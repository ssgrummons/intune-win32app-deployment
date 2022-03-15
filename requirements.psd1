<#
Use PSDepend to import requirements.  PSDepend, at this point, will need to be run at an administrative prompt. 
If we implement a Unit Testing framework for this repository, then the following steps will need to be done during Travis Setup to install the module and import dependencies
    Install-Module PSDepend 
    Invoke-PSDepend -Force

#>

@{
    IntuneWin32App          = 'latest'
    'Microsoft.Graph.Intune'  = 'latest'
}