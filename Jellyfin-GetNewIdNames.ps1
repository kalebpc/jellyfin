<#
    
    Temp script for getting imdb ids and renaming folders.

    # Handle Apikey from file.
    $fileContent = Get-Content -Path ".env" | Where { $_ -imatch "omdbapikey" }
    $keyapi = $($fileContent -split "=")[1].Replace("'","")
    $keyapi = $keyapi.Replace('"','').Trim()

#>


[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [System.IO.DirectoryInfo[]]$Folders,
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [String]$Apikey,
    [Parameter(Mandatory = $true, Position = 2, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [String]$OutFile,
    [Parameter(HelpMessage = "Seconds between api requests.", ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [Int32]$RateLimit = 5,
    [Switch]$WhatIf
)

[String[]]$list = @()
ForEach ( $folder In $Folders ) {
    # Only select folders that dont have ids.
    If ( $folder.Name -inotmatch  ".*imdbid.*" ) {
        $list+=$folder.Name
    }
}

[Int64]$eta = $($list.Count * $RateLimit) / 60

# Get ids.
If ($WhatIF) {
    "Be Patient. This will take some time depending on the length of your list...`nEstimated time left : '{0}' minutes." -f $eta
    $result = ./Get-imdbID.ps1 -Apikey $Apikey -Source $list -RateLimit $RateLimit -WhatIF
} Else {
    "Be Patient. This will take some time depending on the length of your list...`nEstimated time left : '{0}' minutes." -f $eta
    $result = ./Get-imdbID.ps1 -Apikey $Apikey -Source $list -RateLimit $RateLimit
}

If ( $Outfile -ine "" ) {
    If ( Test-Path -LiteralPath $OutFile ) {
        Set-Content -LiteralPath $OutFile -Value "" -Force
    } Else {
        New-Item -Path $OutFile -ItemType "File" -Force
    }
    Start-Sleep -seconds 3
    ForEach ( $name In $result.Processed ) {
        Add-Content -LiteralPath $OutFile -Value $name -Force
    }
    Start-Sleep -seconds 3
    Add-Content -LiteralPath $OutFile -Value "`n" -Force
    Start-Sleep -seconds 3
    ForEach ( $name In $result.Skipped ) {
        Add-Content -LiteralPath $OutFile -Value $name -Force
    }
    Start-Sleep -seconds 3
    Add-Content -LiteralPath $OutFile -Value "`n" -Force
    Start-Sleep -seconds 3
    ForEach ( $name In $result.Errors ) {
        Add-Content -LiteralPath $OutFile -Value $name -Force
    }
}

"New Names with id : '{0}'" -f $result.Processed.Count
"Skipped names     : '{0}'" -f $result.Skipped.Count
"Errors            : '{0}'" -f $result.Errors.Count

return $result
