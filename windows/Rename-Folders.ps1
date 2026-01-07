<#
    Rename 'Folders' with names found in 'NewNames' list.

    Example :
        ./Rename-Folders -Folders $(Get-ChildItem -Path "G:\Movies" -Exclude "*imdbid*") -NewNames $(Get-ChildItem -Path "G:\Movies updated")

    Example :
        ./Rename-Folders -Folders $(Get-ChildItem -Path "G:\Movies" -Exclude "*imdbid*") -NewNames $(Get-Content -Path "G:\fileWithUpdatedNames.txt")
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true, HelpMessage = "List to folders.")]
    [System.IO.DirectoryInfo[]]$Folders,
    [Parameter(Position = 1, ValueFromPipelineByPropertyName = $true, HelpMessage = "List with updated folder names.")]
    [String[]]$NewNames,
    [Switch]$WhatIF
)

[Int64]$folderCount = $Folders.Count

[Int64]$count = 0

ForEach ( $folder In $Folders ) {
    $title = $($folder.Name -replace "\(.*$","").Trim()
    # "{0}" -f $folder.FullName
    ForEach ( $name In $NewNames ) {
        If ( $name -ilike "*$title*" ) {
            If ( ! $(Test-Path -LiteralPath "$(Split-Path -Path $folder.FullName -Parent)\$name" ) ) {
                If ($WhatIF) {
                    "Rename-Item -LiteralPath '{0}' -NewName '{1}'" -f $folder.FullName, $name
                } Else {
                    Rename-Item -LiteralPath "$($folder.FullName)" -NewName "$name"
                }
                $count+=1
            }
        }
    }
}

"`nTotal folders     : '{0}'`nProcessed folders : '{1}'" -f $folderCount, $count
