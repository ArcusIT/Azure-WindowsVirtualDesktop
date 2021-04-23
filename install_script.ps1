#Set-ExecutionPolicy Bypass
#$Script = Invoke-WebRequest 'https://raw.githubusercontent.com/ArcusIT/Azure-WindowsVirtualDesktop/main/install_script.ps1' -UseBasicParsing
#$ScriptBlock = [Scriptblock]::Create($Script.Content)
#Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList ($args + @('someargument'))

#region Import modules en start logging
if (-not (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {   
    Write-warning "Start het script in een elevated PowerShell"  
    Break
}

try {
    Write-host "Importeren module PSFramework" -ForegroundColor Green
    Import-module PSFramework -ErrorAction Stop
    Write-PSFMessage -Message "Start logging" -level verbose
} Catch {
    Write-host "Module niet gevonden; Probeer de module te installeren" -ForegroundColor Green
    Write-warning "Er kunnen meldingen komen om Nuget te installeren en/of je uit onbetrouwbare bronnen wilt installeren; Kies bij beide voor ja."
    install-module -name PSFramework -Scope CurrentUser -Force -ErrorAction Stop
    Try {
        import-module PSFramework -ErrorAction Stop
        Write-PSFMessage -Message "Start logging" -level verbose
        Write-PSFMessage -Message "Module PSFramework geïnstalleerd" -level host
    } Catch {
        Write-host "Kan module PSFramework niet importeren; Bestaat de module wel? Installeer de module handmatig." -ForegroundColor Red -ErrorAction Stop
        Exit
    }
}

try {
    Write-PSFMessage -Message "Importeren module Az" -level host
    Import-module Az.Resources -ErrorAction Stop
} Catch {
    Write-PSFMessage -Message "Module niet gevonden; Probeer de module te installeren." -level Warning
    Install-Module -Name Az.Resources -Scope CurrentUser -Repository PSGallery -Force -ErrorAction Stop
    Try {
        Import-module Az.Resources -ErrorAction Stop
        Write-PSFMessage -Message "Module Az geïnstalleerd" -level host
    } Catch {
        Write-PSFMessage -Message "Kan module Az niet importeren; Bestaat de module wel? Installeer de module handmatig." -level Warning
        Exit
    }
}
#endregion Import modules en start logging

#region Functions
Function Start-AzConnection{
    Clear-AzContext -Force | Out-Null
    Write-PSFMessage -Message "Verbinden met Azure" -level host
    Try {
        Connect-AzAccount -ErrorAction Stop | Out-Null 
        Write-PSFMessage -Message "Verbonden met Azure" -level Verbose
    } Catch {
        Write-PSFMessage -Message "Kon niet verbinden met Azure" -Level Warning -ErrorRecord $_
        Exit
    } 
    
}

Function Start-Deployment{
    Param(
        [string]$TemplateUri
    )
    Try {
        Write-PSFMessage -Message "Start deployment: $TemplateUri" -level host
        New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateUri $TemplateUri -ErrorAction Stop | Out-Null
        Write-PSFMessage -Message "Deployment van $TemplateUri goed gegaan" -level Verbose
    } Catch {
        Write-PSFMessage -Message "Kon de deployment niet uitvoeren..." -Level Warning -ErrorRecord $_
        Exit
    } 
}

Function Start-CreateResourceGroup{
#    Param(
#        [string]$ResourceGroupName,
#        [string]$ResourceGroupLocation
#    )

    Try {
        Write-PSFMessage -Message "Controleren op bestaan ResourceGroup $ResourceGroupName" -level host
        Get-AzResourceGroup -Name $ResourceGroupName -ErrorVariable notPresent -ErrorAction SilentlyContinue | Out-Null
    } Catch {
        Write-PSFMessage -Message "Ophalen van ResourceGroups niet goed gegaan" -Level Warning -ErrorRecord $_
        Exit
    } 

    if ($notPresent) {
        Try {
            Write-PSFMessage -Message "ResourceGroup $ResourceGroupName bestaat niet; Aanmaken ResourceGroup." -level host
            New-AzResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation -ErrorAction Stop | Out-Null
            Write-PSFMessage -Message "Aanmaken van ResourceGroup $ResourceGroupName goed gegaan" -level Verbose
        } Catch {
            Write-PSFMessage -Message "Ophalen van ResourceGroups niet goed gegaan" -Level Warning -ErrorRecord $_
            Exit
        }
    } 
    Else {
        Write-PSFMessage -Message "ResourceGroup $ResourceGroupName bestaat al; Deployment kan niet twee keer uitgevoerd worden." -Level Warning
        Exit
    }        
}
#endregion Functions

#region Variables
$ResourceGroupName = "RGR-WE-P-WVD"
$ResourceGroupLocation = "westeurope"
#endregion Variables

Start-AzConnection
Start-CreateResourceGroup
Start-Deployment -TemplateUri "https://raw.githubusercontent.com/ArcusIT/Azure-WindowsVirtualDesktop/main/Deploy_baseline.json"
Pause


