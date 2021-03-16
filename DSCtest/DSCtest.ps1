Configuration DSCtest
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.String]
        $folderName
    )

    Node localhost
    {
        File CreateFolder
        {
            Type            = 'Directory'
            DestinationPath = $folderName
            Ensure          = "Present"
        }
    }
}