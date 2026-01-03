
<#

    Random script for moving oldext files to extras folder after the newext file creation date is greater than hours/minutes.

#>

[CmdletBinding(DefaultParameterSetName = "Hours")]
param(
    
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
    [System.IO.DirectoryInfo[]]$Folders,
    
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [String]$Oldext,
    
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [String]$Newext,
    
    [Parameter(HelpMessage = "Age of new file in hours before moving.", Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = "Hours")]
    [Int32]$Hours,
    
    [Parameter(HelpMessage = "Age of new file in Minutes before moving.", Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = "Minutes")]
    [Int32]$Minutes,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [Switch]$PrintMoved,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [Switch]$PrintWaiting,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [Switch]$WhatIf

)

[String[]]$moved = @()

[String[]]$waiting = @()

ForEach ( $folder In $Folders ) {
    
    [String]$extrasPath = "{0}\extras" -f $folder.FullName

    If ( ! $(Test-Path -LiteralPath $extrasPath) ) { New-Item -Path $extrasPath -ItemType "Directory" -Force }

    function Replace-Extension {
        
        [CmdletBinding()]
        param(

            [Parameter(Mandatory = $true, Position = 0)]
            [String]$S

        )

        return $($S -replace "\..*$",$(".{0}" -f $Oldext))

    }

    [Object[]]$items = Get-ChildItem -LiteralPath $folder.FullName | Where { $_.Name -imatch $("^.*\.{0}" -f $Newext) }

    If ( $items -ne $null ) {


        [System.Management.Automation.PSObject[]]$newfiles = @()

        ForEach ( $x In $items ) {

            [PSObject]$temp = New-Object PSObject

            $temp | Add-Member -MemberType NoteProperty -Name "File" -Value $x.FullName
            
            If ($Minutes) {

                $temp | Add-Member -MemberType NoteProperty -Name "Age" -Value $($(New-TimeSpan -Start $($x.CreationTime) -End $(Get-Date)).TotalMinutes)
            
            } Else {
                
                $temp | Add-Member -MemberType NoteProperty -Name "Age" -Value $($(New-TimeSpan -Start $($x.CreationTime) -End $(Get-Date)).TotalHours)
            
            }

            $newfiles+=$temp

        }

        ForEach ( $x In $newfiles ) {

            [String]$temp = $(Replace-Extension $x.File) | Split-Path -Leaf

            [System.IO.FileSystemInfo]$oldfile = $(Get-ChildItem -LiteralPath $folder.FullName) | Where { $_ -imatch "^.*$([Regex]::Escape($temp))" }

            If ( $oldfile -ne "" -and $oldfile -ne $null ) {

                function Move-File {

                    Move-Item -LiteralPath $oldfile.FullName -Destination $("{0}\{1}" -f $extrasPath, $oldfile.Name) -Force

                }

                function Print-MoveFile {

                    "Move-Item`n -LiteralPath`n {0}`n -Destination`n {1}`n -Force" -f $oldfile.FullName, $("{0}\{1}" -f $extrasPath, $oldfile.Name)

                }

                If ($Minutes) {

                    If ( $x.Age -gt $Minutes ) {

                        If ($WhatIf) {
                
                            $moved+=$("{0}\{1}" -f $extrasPath, $oldfile.Name)

                            Print-MoveFile

                        } Else {
                
                            $moved+=$("{0}\{1}" -f $extrasPath, $oldfile.Name)

                            Move-File

                        }
                    } Else {

                        $waiting+=$oldfile.FullName

                    }
                } Else {

                    If ( $x.Age -gt $Hours ) {

                        If ($WhatIf) {
                
                            $moved+=$("{0}\{1}" -f $extrasPath, $oldfile.Name)

                            Print-MoveFile

                        } Else {
                
                            $moved+=$("{0}\{1}" -f $extrasPath, $oldfile.Name)
                            
                            Move-File

                        }
                    } Else {

                        $waiting+=$oldfile.FullName

                    }
                }
            }
        }
    }
}

function Print-List {
    
    [CmdletBinding()]
    param(

        [Parameter(Mandatory = $true, Position = 0)]
        [String[]]$L

    )

    ForEach ( $x In $L ) {

        "{0}" -f $x

    }

}

If ($PrintWaiting) {

    If ( $waiting.Count -gt 0 ) {

        "`nFiles Waiting :`n"

        Print-List $waiting

    }

}

If ($PrintMoved) {

    If ( $moved.Count -gt 0 ) {
        
        "`nMoved Files :`n"

        Print-List $moved
        
    }
}

"`n`nMoved Files   : {0}`nFiles Waiting : {1}`n" -f $moved.Count, $waiting.Count
