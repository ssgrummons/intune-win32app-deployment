$WINDIR = $Env:windir
$LogPath = "$WINDIR\Temp"

If (!(Test-Path $LogPath)) 
{

   New-Item -Path $LogPath -ItemType Directory

}

$LogLocation="$LogPath\1PasswordSetup-7.7.805_UnInstall.log"

start-process -FilePath "msiexec.exe" -Argumentlist "/x{8A0007E4-9D8E-4F82-828B-177A53AFF519} /l*V $LogLocation /q" -WindowStyle Hidden -wait
