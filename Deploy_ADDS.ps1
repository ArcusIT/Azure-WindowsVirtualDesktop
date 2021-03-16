Configuration ADDomain_NewForest_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $domainName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SafeModePassword
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ActiveDirectoryDsc

    node 'localhost'
    {
        WindowsFeature 'ADDS'
        {
            Name   = 'AD-Domain-Services'
            Ensure = 'Present'
        }

        WindowsFeature 'RSAT'
        {
            Name   = 'RSAT-AD-PowerShell'
            Ensure = 'Present'
        }

        ADDomain $domainName
        {
            DomainName                    = $domainName
            Credential                    = $Credential
            SafemodeAdministratorPassword = $SafeModePassword
            ForestMode                    = 'WinThreshold'
        }
    }
}