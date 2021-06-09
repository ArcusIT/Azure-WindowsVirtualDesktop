Param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory=$true)]
    [string]$HostPoolName
)

$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "

    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName

    "Logging in to Azure..."
    $connectionResult =  Connect-AzAccount -Tenant $servicePrincipalConnection.TenantID `
                             -ApplicationId $servicePrincipalConnection.ApplicationID   `
                             -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint `
                             -ServicePrincipal
    "Logged in."

}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

$arraysessionhost = @()
$i = 0 

get-azwvdsessionhost -HostPoolName HP-WVD01 -ResourceGroupName RGR-WE-T-WVD01 | ForEach-Object {
    $s = $_.name -replace "$HostPoolName/"
    $s = $s.Substring(0,$s.IndexOf('.'))
    Write-Output "Starting $s..."
    Start-AzVM -ResourceGroupName $ResourceGroupName -Name $s
}