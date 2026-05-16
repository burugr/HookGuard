if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {

    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs

    exit

}



$Url  = "https://raw.githubusercontent.com/burugr/HookGuard/main/HookGuard.exe"

$Dest = "$env:TEMP\HookGuard.exe"



Write-Host "Downloading and starting HookGuard..." -ForegroundColor Cyan

Invoke-WebRequest -Uri $Url -OutFile $Dest

Start-Process -FilePath $Dest -Wait



Remove-Item $Dest

Write-Host "Done." -ForegroundColor Green

Pause