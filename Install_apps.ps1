$Installer7Zip = $env:TEMP + "\7z1900-x64.msi";
Invoke-WebRequest "https://www.7-zip.org/a/7z1900-x64.msi" -OutFile $Installer7Zip;
msiexec /i $Installer7Zip /qb;
Remove-Item $Installer7Zip;