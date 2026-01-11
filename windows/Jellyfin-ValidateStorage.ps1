
<#PSScriptInfo

.VERSION 1.0

.GUID 9f47b056-f91d-40bd-9cb8-ea418f5ce02e

.AUTHOR https://github.com/kalebpc/handbrakecli

.COMPANYNAME 

.COPYRIGHT 2025 https://github.com/kalebpc/handbrakecli

.TAGS 

.LICENSEURI 

.PROJECTURI 

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES


#>

<# 

.DESCRIPTION 
    Check storage folders and files against known correct values using regex. 
        https://jellyfin.org/docs/general/server/media/movies/
        https://jellyfin.org/docs/general/server/media/music-videos/
        https://jellyfin.org/docs/general/server/media/shows/

.PARAMETER LiteralPath
    Path to root folder to begin validation.

.PARAMETER Recurse
    Recursive file validation.

.PARAMETER PrintValid
    Make script print valid file names along with the invalid ones.

.PARAMETER OmitList
    List of names to add to accepted name lists.

.EXAMPLE
    ./Jellyfin-ValidateStorage.ps1 -LiteralPath 'G:\Jellyfin\' -Recurse

.EXAMPLE
    ./Jellyfin-ValidateStorage.ps1 -LiteralPath 'G:\Jellyfin\' -Recurse -OmitList "Name","Another Name"

.EXAMPLE
    ./Jellyfin-ValidateStorage.ps1 -LiteralPath 'G:\Jellyfin\' -PrintValid

.EXAMPLE
    "C:\Users\kaleb\Desktop\Jellyfin" | .\Jellyfin-ValidateStorage.ps1 -OmitList $(Get-Content -literalpath "./validnames.txt") -Recurse

.EXAMPLE
    "C:\Users\kaleb\Desktop\Jellyfin" | .\Jellyfin-ValidateStorage.ps1 -PrintValid

#> 


[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [String]$LiteralPath,
    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [Switch]$Recurse,
    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [Switch]$PrintValid,
    [Parameter(ValueFromPipelineByPropertyName = $true, Helpmessage = "List of names to add to accepted name lists.")]
    [String[]]$OmitList
)

If ( ! $(Test-Path -LiteralPath $LiteralPath) ) { "System can not find '{0}'" -f $LiteralPath ; Exit }
If ( $OmitList ) { If ( Test-Path -LiteralPath $OmitList ) { $OmitList = Get-Content -LiteralPath $OmitList } }

[String[]]$libraryFolderNames = @(
    "Movies",
    "Music",
    "Shows",
    "Books",
    "Home Videos and Photos",
    "Music Videos",
    "Mixed Movies and Shows",
    "Radio",
    "Live TV",
    "Movie Trailers",
    "Workout Videos",
    "MKV Videos",
    "Images"
)

[String[]]$librarySubFolderNames = @(
    "behind the scenes",
    "deleted scenes"
    "interviews",
    "scenes",
    "samples",
    "shorts",
    "featurettes",
    "clips",
    "other",
    "extras",
    "trailers"
)

[String[]]$libraryFileNames = @(
    "logo",
    "poster",
    "thumb",
    "folder",
    "backdrop"
)

If ( $OmitList.Count -gt 0 ) {
    ForEach ( $x In $OmitList ) {
        $libraryFolderNames+=$x.Trim()
        $libraryFileNames+=$x.Trim()
    }
}

function Remove-Extension {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [String]$File,
        [Switch]$RemoveTrail
    )
    $File = $File -replace "(\.\b)(?!.*\1).*$",""
    If ($RemoveTrail) { $File = $File -replace "\ -[^\w]? .*$","" }
    return $File
}

# Movie (year) [id] ; Movie (description year) [id] ; Movie (description year-), Movie (description year-year)
[String[]]$idTypes = @("imdbid","tmdbid","tvdbid")
[String[]]$IDtitlereglist = @("^[^\ ].*\ \((?!\ )\d{4}\)\ \[TYPE\-[t]{2}\d{7,24}\]$", "^[^\ ].*\ \((?!\ ).{0,24}\ (?!\ )\d{4}\)\ \[TYPE\-[t]{2}\d{7,24}\]$", "^[^\ ].*\ \((?!\ ).{0,24}\ (?!\ )\d{4}\-(?!\d)?\d{0,4}\)\ \[TYPE\-[t]{2}\d{7,24}\]$")
# Movie (year) ; Movie (description year) ; Movie (description year-), Movie (description year-year)
[String[]]$titlereglist = @("^[^\ ].*\ \((?!\ )\d{4}\)$", "^[^\ ].*\ \((?!\ ).{0,24}\ (?!\ )\d{4}\)$", "^[^\ ].*\ \((?!\ ).{0,24}\ (?!\ )\d{4}\-(?!\d)?\d{0,4}\)$")
function IsValid {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [String]$S,
        [Switch]$File
    )
    [Boolean]$ret = $false
    ForEach ( $t In $IDtitlereglist ) {
        If ($ret) { return $true }
        ForEach ( $i In $idTypes ) {
            If ($ret) { return $true }
            $reg = $t -replace "TYPE", $i
            If ($File) { $reg = $reg -replace "\$",".*\..+$" }
            If ( $S -imatch $reg ) { $ret = $true }
        }
    }
    ForEach ( $t In $titlereglist ) {
        If ($ret) { return $ret }
        If ($File) { $t = $t -replace "\$", ".*\..+$"}
        If ( $S -imatch $t ) { $ret = $true }
    }
    If ($File) { $S = Remove-Extension $S -RemoveTrail ; If ( $S -iin $libraryFileNames ) { return $true } } Else { If ( $S -iin $libraryFolderNames -or $S -ilike "season*" -or $S -iin $librarySubFolderNames ) { return $true } }
    return $false
}

If ($Recurse) {
    $folders = Get-ChildItem -LiteralPath $LiteralPath -Recurse
    ForEach ( $folderfile In $folders ) {
        If ($folderfile.PSIsContainer) {
            If ( IsValid $folderfile.Name ) {
                If ($PrintValid) {
                    "Valid Folder Name             : {0}" -f $folderfile.FullName
                }
            } Else { "Invalid Folder Name           : {0}" -f $folderfile.FullName }
        } ElseIf ( IsValid $folderfile.Name -File ) {
            $temp = Split-Path -Path $folderfile.FullName -Parent | Split-Path -Parent | Split-Path -Leaf
            If ( $temp -iin $libraryFolderNames ) {
                $temp = Split-Path -Path $folderfile.FullName -Parent | Split-Path -Leaf
            } ElseIf ( $folderfile.FullName -imatch "^.*Season.*$" -and $(Split-Path -Path $folderfile.FullName -Parent | Split-Path -Leaf) -iin $librarySubFolderNames ) {
                $temp = Split-Path -Path $folderfile.FullName -Parent | Split-Path -Parent | Split-Path -Parent | Split-Path -Leaf
            }
            $temp1 = Remove-Extension $folderfile.Name -RemoveTrail
            If ( $temp1 -inotin $temp -and $(Remove-Extension $folderfile.Name -RemoveTrail) -inotin $libraryFileNames ) {
                "`n{0}`n{1}" -f $temp, $temp1
                "WRONG  File  Name             : {0}" -f $folderfile.FullName
            }
            If ($PrintValid) {
                "Valid  File  Name             : {0}" -f $folderfile.FullName
            }
        } Else {
            "Invalid File Name             : {0}" -f $folderfile.FullName
        }
    }
} Else {
    $folders = Get-ChildItem -LiteralPath $LiteralPath
    ForEach ( $folderfile In $folders ) {
        If ($folderfile.PSIsContainer) {
            If ( IsValid $folderfile.Name ) {
                If ($PrintValid) {
                    "Valid Folder Name             : {0}" -f $folderfile.FullName
                }
            } ElseIf ( $folderfile.Name -inotin $libraryFolderNames ) {
                "Invalid Folder Name           : {0}" -f $folderfile.FullName
            } ElseIf ($PrintValid) {
                "Valid Folder Name             : {0}" -f $folderfile.FullName
            }
        } ElseIf ( IsValid $folderfile.Name -File ) {
            $temp = Split-Path -Path $folderfile.FullName -Parent | Split-Path -Parent | Split-Path -Leaf
            If ( $temp -iin $libraryFolderNames ) {
                $temp = Split-Path -Path $folderfile.FullName -Parent | Split-Path -Leaf
            } ElseIf ( $folderfile.FullName -imatch "^.*Season.*$" -and $(Split-Path -Path $folderfile.FullName -Parent | Split-Path -Leaf) -iin $librarySubFolderNames ) {
                $temp = Split-Path -Path $folderfile.FullName -Parent | Split-Path -Parent | Split-Path -Parent | Split-Path -Leaf
            }
            $temp1 = Remove-Extension $folderfile.Name -RemoveTrail
            If ( $temp1 -inotin $temp -and $(Remove-Extension $folderfile.Name -RemoveTrail) -inotin $libraryFileNames ) {
                "`n{0}`n{1}" -f $temp, $temp1
                "WRONG  File  Name             : {0}" -f $folderfile.FullName
            }
            If ($PrintValid) {
                "Valid  File  Name             : {0}" -f $folderfile.FullName
            }
        } Else {
            "Invalid File Name             : {0}" -f $folderfile.FullName
        }
    }
}
