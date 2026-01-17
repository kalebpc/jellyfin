<#

    Simple script for copying new files to jellyfin server.

#>

[CmdletBinding()]
param(
    [Parameter(Position = 0, ValueFromPipelineByPropertyName = $true)]
    [String]$Source,
    
    [Parameter(Position = 1, ValueFromPipelineByPropertyName = $true)]
    [String]$Destination,

    [Parameter(Position = 2, ValueFromPipelineByPropertyName = $true, HelpMessage = "Ex. 'Ubuntu'")]
    [String]$SshConfig,

    [Switch]$Whatif
)

# Remote drive path
$path = "/mnt/sata_drive/Jellyfin"

$Source = $Source.Trim()
$Destination = $Destination.Trim()
$SshConfig = $SshConfig.Trim()

If ( $SshConfig -ne "" ) {
    $Destination = "{0}/{1}" -f $path, $Destination.Replace("\","/")
}

If ($Whatif) {
    "scp -r {0} {1}" -f $Source, $("{0}:'{1}'" -f $SshConfig, $Destination)
} Else {
    scp -r $Source $("{0}:'{1}'" -f $SshConfig, $Destination)
}
