#Set-ExecutionPolicy Bypass
#$Script = Invoke-WebRequest 'https://raw.githubusercontent.com/ArcusIT/Azure-WindowsVirtualDesktop/main/install_script.ps1' -UseBasicParsing
#$ScriptBlock = [Scriptblock]::Create($Script.Content)
#Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList ($args + @('someargument'))

Import-Module PowerShellGet

#region Start logging
if (-not (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {   
    Write-warning "Het script starten als administrator"  
    Break
}

try {
    Write-host "Importeren module PSFramework..." -ForegroundColor Green
    Import-module PSFramework -ErrorAction Stop
    Write-PSFMessage -Message "Start logging" -level verbose
} Catch {
    Write-host "Module niet gevonden. Probeer de module te installeren..." -ForegroundColor Green
    Write-warning "Er kunnen meldingen komen om Nuget te installeren en/of je uit onbetrouwbare bronnen wilt installeren. Kies bij beide voor ja..."
    install-module -name PSFramework -ErrorAction Stop
    Try {
        import-module PSFramework -ErrorAction Stop
        Write-PSFMessage -Message "Start logging" -level verbose
        Write-PSFMessage -Message "Module PSFramework geïnstalleerd" -level host
    } Catch {
        Write-host "Kan module PSFramework niet importeren...Bestaat de module wel? Installeer de module handmatig..." -ForegroundColor Red -ErrorAction Stop
        Pause
        Exit
    }
}
#endregion Start logging
