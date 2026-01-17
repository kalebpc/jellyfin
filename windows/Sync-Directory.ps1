<#

    simple script copying files from windows to linux drive

#>

[String[]]$Exclude = "Music"

[String]$localpath = "G:\Jellyfin"

# Exclude paths with certain folder name.
[Object[]]$localdirinfos = Get-ChildItem -Path $localpath -Recurse | ? { $_.FullName -notmatch $("^.*\\{0}\\.*$" -f $Exclude) }

[String[]]$localfiles = @()

ForEach ( $x In $localdirinfos ) {
    $localfiles+=$x.FullName
}

$localfiles = $localfiles | Sort-Object

[String[]]$remotefiles = ssh debian "find /mnt/sata_drive/Jellyfin -type d -print" | ? { $_ -notmatch $("^.*\/{0}\/.*$" -f $Exclude)}

# $localfiles = $localfiles[0..10]
# $remotefiles = $remotefiles[0..10]

[String[]]$localmatchfiles = @()

# turn remote paths into their local equivalents.
ForEach ( $x in $remotefiles) {
    $localmatchfiles+="{0}{1}" -f $localpath, $(($x -split "Jellyfin")[1] -replace "\/","\")
}

$localmatchfiles = $localmatchfiles | Sort-Object

[Object[]]$itemstocopy = @()

# ForEach ( $directory In $localfiles ) {
#     $directory.FullName
ForEach ( $directory In $localmatchfiles ) {
    # If ( ! $(Test-Path -LiteralPath $directory) ) {
    #     "no exist : {0}" -f $directory
    # } Else {
    #     # "   exist : {0}" -f $directory
    # }
    If ( $directory -notin $localfiles ) {
        # $itemstocopy+=$directory
        "not  in : {0}" -f $directory
    } Else {
        # "is in : {0}" -f $directory
    }
}

"local count : {0}`nremat count : {1}`nremot count : {2}" -f $localfiles.Count, $localmatchfiles.Count, $remotefiles.Count

# ForEach ( $directory In $itemstocopy ) {
#     [Boolean]$exists = $false
#     If ( Test-Path -LiteralPath $directory ) { $exists = $true }
#     "exists : {1} | copy: {0}" -f $directory, $exists
# }
