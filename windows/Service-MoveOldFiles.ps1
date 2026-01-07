
<#

    Service to run moving old files while i am encoding movies to webm.

#>

[CmdletBinding()]
param(

    [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
    [String]$Folder,

    [Parameter(HelpMessage = "Time in 'minutes'.", Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)]
    [Int32]$Time

)

[String]$log = "$Env:LocalAppData\Scripts\Jellyfin\Services\logs\Service-MoveOldFiles.log"

[String]$temp = $log | Split-Path -Parent

If ( ! $(Test-Path -LiteralPath $temp) ) { New-Item -Path $temp -ItemType "Directory" -Force }

"Log located at:`n  '{0}'`n" -f $log

function Add-Log {
    
    [CmdletBinding()]
    param(

        [Parameter(Mandatory = $true, Position = 0)]
        [String]$Content

    )
    Try {

        $temp = "`n------------`n[{0}] {1}`n------------`n" -f $(Get-Date -Format "yyyy.MM.dd - hh:mm:ss tt"), $Content

        $temp | Out-File -LiteralPath $log -Encoding unicode -Append
    
    } Catch {
    
        "`nError: Could not add content to '{0}'.`n`n{1}`n`n" -f $log, $_.Exception.Message
    
    }

}

function Format-Time {
    
    [CmdletBinding()]
    param(

        [Parameter(Mandatory = $true, Position = 0)]
        [System.TimeSpan]$T

    )

    return $("{0} hours {1} minutes {2} seconds {3} milliseconds" -f $T.Hours, $T.Minutes, $T.Seconds, $T.Milliseconds)

}

function Run {

    [System.DateTime]$starttime = Get-Date

    Add-Log "Getting new list of folders."

    [System.IO.DirectoryInfo[]]$list = Get-Childitem -LiteralPath $Folder

    Add-Log "Running 'Move-OldFiles.ps1'."

    ./Move-OldFiles $list -newext "webm" -oldext "mp4" -Minutes $Time -Printwaiting -Printmoved | Out-FIle -LiteralPath $log -Encoding unicode -Append

    [System.DateTime]$endtime = Get-Date

    Add-Log $("Finished in {0}." -f $(Format-Time $(New-TimeSpan -Start $starttime -End $endtime)))

}

While ($true) { Run ; Start-Sleep -Seconds $($Time*60)}
