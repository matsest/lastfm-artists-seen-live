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
        [string]
        $Number = "100"
    )

    $topArtistsUri = "https://ws.audioscrobbler.com/2.0/?method=user.gettopartists&user=$UserName&api_key=$ApiKey&format=json&limit=$Number"
    $res = Invoke-RestMethod -Uri $topArtistsUri
    #todo: add error handling for rest call
    $artists = $res.topartists.artist

    $artists | ForEach-Object {
        [PSCustomObject]@{
            Name      = $_.name
            PlayCount = $_.playcount
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
        [string]
        $Limit = "500"
    )

    $safeTagName = [uri]::EscapeDataString($TagName)

    $seenLiveUri = "https://ws.audioscrobbler.com/2.0/?method=user.getpersonaltags&user=$UserName&tag=$safeTagName&taggingtype=artist&api_key=$ApiKey&format=json&limit=$Limit"
    $res = Invoke-RestMethod -Uri $seenLiveUri
    #todo: add error handling for rest call
    $artists = $res.taggings.artists.artist
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
        [Parameter(HelpMessage = "List of non active artists")]
        [String[]]
        $InactiveArtists = @()
    )
    $res = @()
    foreach ($artist in $TopArtists) {
        $current = [PSCustomObject]@{
            Name      = $artist.Name
            PlayCount = $artist.PlayCount
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
    | Select-Object Name, PlayCount
}