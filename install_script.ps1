#Set-ExecutionPolicy Bypass
#$Script = Invoke-WebRequest 'https://raw.githubusercontent.com/ArcusIT/Azure-WindowsVirtualDesktop/main/install_script.ps1' -UseBasicParsing
#$ScriptBlock = [Scriptblock]::Create($Script.Content)
#Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList ($args + @('someargument'))

#region Start logging
#if (-not (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {   
#    Write-warning "Start het script in een elevated PowerShell"  
#    Break
#}

try {
    Write-host "Importeren module PSFramework" -ForegroundColor Green
    Import-module PSFramework -ErrorAction Stop
    Write-PSFMessage -Message "Start logging" -level verbose
} Catch {
    Write-host "Module niet gevonden; Probeer de module te installeren" -ForegroundColor Green
    Write-warning "Er kunnen meldingen komen om Nuget te installeren en/of je uit onbetrouwbare bronnen wilt installeren; Kies bij beide voor ja."
    install-module -name PSFramework -Scope CurrentUser -Confirm:$False -Force -ErrorAction Stop
    Try {
        import-module PSFramework -ErrorAction Stop
        Write-PSFMessage -Message "Start logging" -level verbose
        Write-PSFMessage -Message "Module PSFramework geïnstalleerd" -level host
    } Catch {
        Write-host "Kan module PSFramework niet importeren; Bestaat de module wel? Installeer de module handmatig." -ForegroundColor Red -ErrorAction Stop
        Exit
    }
}
#endregion Import modules en start logging

#region Functions
Function Start-ImportModule {
    Param(
        [string]$Module
    )
    try {
        Write-PSFMessage -Message "Importeren module $Module" -level host
        Import-module $Module -ErrorAction Stop
    } Catch {
        Write-PSFMessage -Message "Module niet gevonden; Probeer de module te installeren." -level Warning
        Install-Module -Name $Module -Scope CurrentUser -Confirm:$False -Repository PSGallery -Force -ErrorAction Stop
        Try {
            Import-module $Module -ErrorAction Stop
            Write-PSFMessage -Message "Module $Module geïnstalleerd" -level host
        } Catch {
            Write-PSFMessage -Message "Kan module $Module niet importeren; Bestaat de module wel? Installeer de module handmatig." -level Warning
            Exit
        }
    }
}

Function Start-AzConnection{
    Param(
        [string]$Tenant,
        [string]$Subscription
    )
    $Parameters = @{}
    $Parameters = @{
        ErrorAction = "Stop"
    }
    If ($Tenant) { $Parameters += @{Tenant = $Tenant}}
    If ($Subscription) { $Parameters += @{Subscription = $Subscription}}
    Clear-AzContext -Force | Out-Null
    Write-PSFMessage -Message "Verbinden met Azure" -level host
    Try {
        Connect-AzAccount @Parameters | Out-Null 
        Write-PSFMessage -Message "Verbonden met Azure" -level Verbose
    } Catch {
        Write-PSFMessage -Message "Kon niet verbinden met Azure" -Level Warning -ErrorRecord $_
        Exit
    } 
    
}

Function Start-Deployment{
    Param(
        [string]$TemplateUri,
        [string]$vmName,
        [string]$DomainName,
        [string]$Username,
        [securestring]$Password,
        [string]$Prefix,
        [string]$workspaceResourceId
    )
    $Parameters = @{}
    $Parameters = @{
        ResourceGroupName = $ResourceGroupName
        TemplateUri = $TemplateUri
        ErrorAction = "Stop"
    }
    If ($vmName) { $Parameters += @{vmName = $vmName}}
    If ($DomainName) { $Parameters += @{domainName = $DomainName}}
    If ($Username) { $Parameters += @{Username = $Username}}
    If ($Password) { $Parameters += @{Password = $Password}}
    If ($Prefix) { $Parameters += @{Prefix = $Prefix}}
    If ($workspaceResourceId) { $Parameters += @{workspaceResourceId = $workspaceResourceId}}
    Try {
        Write-PSFMessage -Message "Start deployment: $TemplateUri" -level host
        New-AzResourceGroupDeployment @Parameters | Out-Null
        Write-PSFMessage -Message "Deployment van $TemplateUri goed gegaan" -level Verbose
    } Catch {
        Write-PSFMessage -Message "Kon de deployment niet uitvoeren..." -Level Warning -ErrorRecord $_
        Exit
    } 
}

Function Start-CreateResourceGroup{
    $Parameters = @{}
    $Parameters = @{
        ResourceGroupName = $ResourceGroupName
        ErrorVariable = "notPresent"
        ErrorACtion = "SilentlyContinue"
    }
    Try {
        Write-PSFMessage -Message "Controleren op bestaan ResourceGroup $ResourceGroupName" -level host
        Get-AzResourceGroup @Parameters | Out-Null
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
Function Start-GetAzVM{
    $AzVMs = Get-AzVM -ResourceGroupName $ResourceGroupName
    if ($AzVMs.count -eq 2) {
        Write-PSFMessage -Message "Gecontorleerd en VM's $($AzVMs.name[0]) en $($AzVMs.name[1]) bestaan" -level Verbose
        Return $AzVMs
    }
    Else {
        Write-PSFMessage -Message "VM's zijn niet goed aangemaakt" -Level Warning
        Exit
    }
}

Function Start-RestartAzVM {
    param (
        [string]$vmName
    )
    Try {
        Write-PSFMessage -Message "Herstarten van vm $vmName" -level host
        Restart-AzVM -Name $vmName -ResourceGroupName $ResourceGroupName -ErrorAction Stop | Out-Null
        Write-PSFMessage -Message "Herstarten van vm $vmName succesvol" -level verbose
    } Catch {
        Write-PSFMessage -Message "Herstarten van vm $vmName niet goed gegaan" -Level Warning -ErrorRecord $_
    }
}

Function Start-UserInput{
    Param(
        [string]$Prompt,
        [int]$InputMinLength,
        [int]$InputMaxLength,
        [bool]$Password,
        [string]$Default
    )
    $Parameters = @{}
    If ($InputMinLength -and $InputMaxLength) { $Prompt += " (invoer tussen $InputMinLength en $InputMaxLength characters)" }
    If ($Default) { $Prompt += " (Standaard: $Default)"}
    If ($Prompt) { $Parameters += @{Prompt = $Prompt}}
    If ($Password) { $Parameters += @{AsSecureString = $true}}
    do {
        $Input = Read-Host @Parameters
        If ($Default -and $Input.Length -eq 0) {
            $Input = $Default
            $Valid = $true
        }
        If ($InputMinLength -and $InputMaxLength) {
            $Valid = $InputMinLength -le $Input.Length -and $InputMaxLength -ge $Input.Length
            if (-not $Valid) {
                Write-host "Ongeldige invoer"
            }
        } Else {
            $Valid = $true
        }
    } until ($Valid)
    Return $Input
}

Function Start-SetDHCP {
    $DNSIPs = "10.0.0.11","10.0.0.12"
    $vnet = Get-AzVirtualNetwork -name "VNET-WE-P-01" -resourcegroup $resourcegroupname
    $vnet.DhcpOptions.DnsServers = $null
    foreach ($IP in $DNSIPs) {        
        $vnet.DhcpOptions.DnsServers += $IP
    }
    Try {
        Write-PSFMessage -Message "Aanpassen DNS servers" -level host
        Set-AzVirtualNetwork -VirtualNetwork $vnet -ErrorAction Stop | Out-Null
        Write-PSFMessage -Message "Aanpassen DNS servers gelukt" -level verbose
    } Catch {
        Write-PSFMessage -Message "Aanpassen DNS servers niet goed gegaan" -Level Warning -ErrorRecord $_
    }
}

Function Start-SetAutomationSoftwareUpdate {
    Try {
        Write-PSFMessage -Message "Aanmaken Automation Schedule" -level host
        $duration = New-TimeSpan -Hours 2
        $StartTime = (Get-Date "02:00:00").AddDays(5)
        [System.DayOfWeek[]]$WeekendDay = [System.DayOfWeek]::Tuesday
        $AutomationAccountName = (Get-AzAutomationAccount -ResourceGroupName $ResourceGroupName).AutomationAccountName
        $LogAnalyticsWorkspaceName = (Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName).Name
        #Create a Weekly Scedule 
        $Schedule = New-AzAutomationSchedule -AutomationAccountName $AutomationAccountName -Name "WeeklyCriticalSecurity" -StartTime $StartTime -WeekInterval 1 -DaysOfWeek $WeekendDay -ResourceGroupName $ResourceGroupName
        $VMIDs = (Get-AzVM -ResourceGroupName $ResourceGroupName).Id 
        New-AzAutomationSoftwareUpdateConfiguration -ResourceGroupName $ResourceGroupName -Schedule $Schedule -Windows -AzureVMResourceId $VMIDs -Duration $duration -IncludedUpdateClassification Critical,Security,Definition -AutomationAccountName $AutomationAccountName -ErrorAction Stop | Out-Null
        Write-PSFMessage -Message "Aanmaken Automation Schedule gelukt" -level verbose
    } Catch {
        Write-PSFMessage -Message "Aanmaken Automation Schedule niet goed gegaan" -Level Warning -ErrorRecord $_
    }
}

#endregion Functions

#region Variables
$ResourceGroupName = "RGR-WE-P-WVD"
$ResourceGroupLocation = "westeurope"
$AutomationAccountName = "AUT-WE-P-INFRA-01"
#endregion Variables

#region Main
Start-ImportModule -Module "Az.Resources"
Start-ImportModule -Module "Az.Network"
Start-ImportModule -Module "Az.OperationalInsights"
Start-AzConnection
$Prefix = Start-UserInput -Prompt "Klantprefix" -InputMinLength 2 -InputMaxLength 4
$AD_DomainName = Start-UserInput -Prompt "AD Domeinnaam"
$Username = Start-UserInput -Prompt "Username" -Default "arcusadmin"
$Password = Start-UserInput -Prompt "Password" -Password $true -InputMinLength 12 -InputMaxLength 25
Start-CreateResourceGroup
Start-Deployment -TemplateUri "https://raw.githubusercontent.com/ArcusIT/Azure-WindowsVirtualDesktop/main/Deploy_UMSolution.json" 
Start-Deployment -TemplateUri "https://raw.githubusercontent.com/ArcusIT/Azure-WindowsVirtualDesktop/main/Deploy_baseline.json" -Username $Username -Password $Password -Prefix $Prefix
$VMs = Start-GetAzVM
Start-Deployment -TemplateUri "https://raw.githubusercontent.com/ArcusIT/Azure-WindowsVirtualDesktop/main/Deploy_ADDS_Forest.json" -vmName $VMs.name[0] -DomainName $AD_DomainName -Username $Username -Password $Password
Start-RestartAzVM -vmName $VMs.name[0]
Start-SetDHCP
Start-RestartAzVM -vmName $VMs.name[1]
Start-Deployment -TemplateUri "https://raw.githubusercontent.com/ArcusIT/Azure-WindowsVirtualDesktop/main/Deploy_ADDS_DC.json" -vmName $VMs.name[1] -DomainName $AD_DomainName -Username "$AD_DomainName\$Username" -Password $Password
Start-RestartAzVM -vmName $VMs.name[1]
Start-SetAutomationSoftwareUpdate
$Workspace = get-AzOperationalInsightsWorkspace
Start-Deployment -TemplateUri "https://raw.githubusercontent.com/ArcusIT/Azure-WindowsVirtualDesktop/main/Onboard_VmToWorkspace.json" -vmName $VMs.name[0] -workspaceResourceId $Workspace.ResourceId
Start-Deployment -TemplateUri "https://raw.githubusercontent.com/ArcusIT/Azure-WindowsVirtualDesktop/main/Onboard_VmToWorkspace.json" -vmName $VMs.name[1] -workspaceResourceId $Workspace.ResourceId
Pause
#endregion Main


