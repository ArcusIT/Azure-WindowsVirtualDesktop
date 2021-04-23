# Azure-WindowsVirtualDesktop

<h2>PowerShell deployment</h2>

```PowerShell
Set-ExecutionPolicy Bypass
$Script = Invoke-WebRequest 'https://raw.githubusercontent.com/ArcusIT/Azure-WindowsVirtualDesktop/main/install_script.ps1' -UseBasicParsing
$ScriptBlock = [Scriptblock]::Create($Script.Content)
Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList ($args + @('someargument'))
```



Klik hier om de WVD Baseline te deployen<br>
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FArcusIT%2FAzure-WindowsVirtualDesktop%2Fmain%2FDeploy_baseline.json)<br><br>
Klik hier om een nieuw ADDS forest te deployen<br>
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FArcusIT%2FAzure-WindowsVirtualDesktop%2Fmain%2FDeploy_ADDS_Forest.json)<br><br>
Klik hier om een extra ADDS DC te deployen<br>
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FArcusIT%2FAzure-WindowsVirtualDesktop%2Fmain%2FDeploy_ADDS_DC.json)<br><br>
Klik hier om 7-zip en Edge te deployen<br>
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FArcusIT%2FAzure-WindowsVirtualDesktop%2Fmain%2FInstall_apps.json)<br><br>
***DEMO*** Klik hier om de een powershell script uit te voeren<br>
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FArcusIT%2FAzure-WindowsVirtualDesktop%2Fmain%2FExtensiontest%2FExtensiontest.json)<br><br>
***DEMO*** Klik hier om een DSC te deployen<br>
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FArcusIT%2FAzure-WindowsVirtualDesktop%2Fmain%2FDSCtest%2FDSCtest.json)
