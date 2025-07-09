# Test Last.fm API access
function Test-LFMApiAccess {
    [OutputType([bool])]
    param (
        [Parameter(Mandatory, HelpMessage = "Last.fm username to test API access with")]
        [string]
        $UserName,
        [Parameter(HelpMessage = "Last.fm API key")]
        [string]
        $ApiKey = $env:API_KEY
    )

    if (!$ApiKey) {
        Write-Error "API_KEY environment variable is not set"
        return $false
    }

    try {
        $testUri = "https://ws.audioscrobbler.com/2.0/?method=user.getinfo&user=$UserName&api_key=$ApiKey&format=json"
        $test = Invoke-WebRequest -Uri $testUri -ErrorAction Stop

        if ($test.StatusCode -ne 200) {
            Write-Error "API returned invalid status: $($test.StatusCode) $($test.StatusDescription)"
            return $false
        }

        Write-Verbose "API access test successful for user '$UserName'"
        return $true
    } catch {
        Write-Error "Something went wrong when calling the API: $_"
        return $false
    }
}

# https://www.last.fm/api/show/user.getTopArtists
function Invoke-LFMTopArtists {
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(HelpMessage = "Last.fm username to get top artists for")]
        [string]
        $UserName,
        [Parameter(HelpMessage = "Last.fm API key")]
        [string]
        $ApiKey = $env:API_KEY,
        [Parameter(HelpMessage = "Number of top artists to get")]
        [int]
        $Limit = 100
    )

    $topArtistsUri = "https://ws.audioscrobbler.com/2.0/?method=user.gettopartists&user=$UserName&api_key=$ApiKey&format=json&limit=$Limit"

    try {
        $res = Invoke-RestMethod -Uri $topArtistsUri -ErrorAction Stop
    } catch {
        Write-Error "Failed to fetch top artists. Error: $_"
        return
    }

    $artists = $res.topartists.artist
    Write-Verbose "Found $($artists.Count) top artists for user '$UserName'"

    $artists | ForEach-Object {
        [PSCustomObject]@{
            Name      = $_.name
            PlayCount = $_.playcount
            Rank      = $_.'@attr'.rank
        }
    }
}

# https://www.last.fm/api/show/user.getPersonalTags
function Invoke-LFMSeenLiveArtists {
    [OutputType([String[]])]
    param (
        [Parameter(HelpMessage = "Last.fm username to get top artists for")]
        [string]
        $UserName,
        [Parameter(HelpMessage = "Tag used to track artists seen live")]
        [string]
        $TagName = "seen live",
        [Parameter(HelpMessage = "Last.fm API key")]
        [string]
        $ApiKey = $env:API_KEY,
        [Parameter(HelpMessage = "Maximum number of artists to get")]
        [int]
        $Limit = 1000
    )

    $safeTagName = [uri]::EscapeDataString($TagName)
    $seenLiveUri = "https://ws.audioscrobbler.com/2.0/?method=user.getpersonaltags&user=$UserName&tag=$safeTagName&taggingtype=artist&api_key=$ApiKey&format=json&limit=$Limit"

    try {
        $res = Invoke-RestMethod -Uri $seenLiveUri
    } catch {
        Write-Error "Failed to fetch seen live artists. Error: $_"
        return
    }

    $artists = $res.taggings.artists.artist
    Write-Verbose "Found $($artists.Count) artists tagged with '$TagName' for user '$UserName'"
    $artists.Name
}

# Combines top artists, artists seen live and inactive artists
function Get-LFMTopArtistsStatus {
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(HelpMessage = "List of top artists from Invoke-LFMTopArtists")]
        [PSCustomObject[]]
        $TopArtists,
        [Parameter(HelpMessage = "List of seen live artists from Invoke-LFMSeenLiveArtists")]
        [String[]]
        $SeenLiveArtists,
        [Parameter(HelpMessage = "List of inactive artists")]
        [String[]]
        $InactiveArtists = @()
    )
    $res = @()
    foreach ($artist in $TopArtists) {
        $current = [PSCustomObject]@{
            Name      = $artist.Name
            PlayCount = $artist.PlayCount
            Rank      = $artist.Rank
            SeenLive  = $false
            IsActive  = $true
        }
        if ($artist.Name -in $InactiveArtists) {
            $current.IsActive = $False
        }
        if ($artist.name -in $SeenLiveArtists) {
            $current.SeenLive = $true
        }
        $res += $current
    }
    $res
}

# Filter function
function Select-LFMArtists {
    param (
        [Parameter()]
        [PSCustomObject[]]
        $Artists,
        [bool]$Active = $true,
        [bool]$SeenLive = $true
    )
    $artists `
    | Where-Object { $_.SeenLive -eq $SeenLive -and $_.IsActive -eq $Active } `
    | Select-Object Name, Rank, PlayCount
}

# Helper function

Function ConvertTo-Markdown {
    <#
    .Synopsis
       Converts a PowerShell object to a Markdown table.
    .EXAMPLE
       $data | ConvertTo-Markdown
    .EXAMPLE
       ConvertTo-Markdown($data)
    #>
    [CmdletBinding()]
    [OutputType([string])]
    Param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true
        )]
        [PSObject[]]$collection
    )

    Begin {
        $items = @()
        $columns = [ordered]@{}
    }

    Process {
        ForEach ($item in $collection) {
            $items += $item

            $item.PSObject.Properties | ForEach-Object {
                if (-not $columns.Contains($_.Name) -or $columns[$_.Name] -lt $_.Value.ToString().Length) {
                    $columns[$_.Name] = $_.Value.ToString().Length
                }
            }
        }
    }

    End {
        ForEach ($key in $($columns.Keys)) {
            $columns[$key] = [Math]::Max($columns[$key], $key.Length)
        }

        $header = @()
        ForEach ($key in $columns.Keys) {
            $header += ('{0,-' + $columns[$key] + '}') -f $key
        }
        $header -join ' | '

        $separator = @()
        ForEach ($key in $columns.Keys) {
            $separator += '-' * $columns[$key]
        }
        $separator -join ' | '

        ForEach ($item in $items) {
            $values = @()
            ForEach ($key in $columns.Keys) {
                $values += ('{0,-' + $columns[$key] + '}') -f $item.($key)
            }
            $values -join ' | '
        }
    }
}