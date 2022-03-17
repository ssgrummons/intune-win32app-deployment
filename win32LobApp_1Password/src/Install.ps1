 $WINDIR = $Env:windir

   $CurrentDir = $PSScriptRoot

   $MSISource = "1PasswordSetup-7.7.805.msi"
   # $MSTSource = "Cisco_JabberClient_12.9.3.mst"

$LogPath = "$WINDIR\Temp"

If (!(Test-Path $LogPath)) 
{

   New-Item -Path $LogPath -ItemType Directory

}

$LogLocation="$LogPath\Cisco_JabberClient_12.9.3_Install.log"

$InstallArg = "/i `"$CurrentDir\$MSISource`" /l*V `"$LogLocation`" /q"


start-process -FilePath "msiexec.exe" -Argumentlist $InstallArg -WindowStyle Hidden -wait

