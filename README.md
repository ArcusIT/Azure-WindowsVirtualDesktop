# Azure-WindowsVirtualDesktop

<h2>PowerShell deployment</h2>

```PowerShell
Set-ExecutionPolicy Bypass
$Script = Invoke-WebRequest 'https://raw.githubusercontent.com/ArcusIT/Azure-WindowsVirtualDesktop/main/install_script.ps1' -UseBasicParsing
$ScriptBlock = [Scriptblock]::Create($Script.Content)
Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList ($args + @('someargument'))
```