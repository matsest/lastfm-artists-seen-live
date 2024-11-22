[CmdletBinding()]
param (
    [Parameter(Mandatory, HelpMessage = "Last.fm username")]
    [string]
    $LastFmUserName,
    [Parameter(HelpMessage = "Number of most listened to artists to fetch from Last.fm")]
    [string]
    $NumberOfArtists = "100",
    [Parameter(HelpMessage = "File with a list of artists that are no longer active (can't be seen live)")]
    [string]
    $InactiveArtistsFile = "$PSScriptRoot/nonActiveArtists.txt"
)

# Defaults
$ErrorActionPreference = 'Stop'
$InactiveArtists = Get-Content $InactiveArtistsFile

# Set API Key variable
$ApiKey = $env:API_KEY
if (!$ApiKey) {
    Write-Error "API_KEY environment variable is not set"
}

# Test API access
$test = try {
    Invoke-WebRequest -Uri "https://ws.audioscrobbler.com/2.0/?method=user.getinfo&user=$LastFmUserName&api_key=$ApiKey&format=json"
}
catch {
    Write-Warning $_
    Write-Error "Something went wrong when calling the API"
}
if ($test.StatusCode -ne 200) {
    Write-Error "API returned invalid status: $($test.StatusCode) $($test.StatusDescription)"
}

# Import module
Import-Module "$PSScriptRoot/lastfm.psm1" -Force

# Get artists
$topArtists = Invoke-LFMTopArtists -UserName $LastFmUserName -ApiKey $ApiKey -Number $NumberOfArtists
$artistsSeenLive = Invoke-LFMSeenLiveArtists -UserName $LastFmUserName -ApiKey $ApiKey
$artists = Get-LFMTopArtistsStatus -TopArtists $topArtists -SeenLiveArtists $artistsSeenLive -InactiveArtists $InactiveArtists

# Filter
$activeNotSeen = Select-LFMArtists $artists -Active $True -SeenLive $False
$activeSeen = Select-LFMArtists $artists -Active $True -SeenLive $True
$inactiveNotSeen = Select-LFMArtists $artists -Active $False -SeenLive $False
$inactiveSeen = Select-LFMArtists $artists -Active $False -SeenLive $True
$last10Seenlive = $artistsSeenLive | Select-Object -First 10

# Statistics
$totalActive = $activeSeen.Count + $activeNotSeen.Count
$totalInactive = $inactiveSeen.Count + $inactiveNotSeen.Count
$totalSeen = $activeSeen.Count + $inactiveSeen.Count
$totalNotSeen = $activeNotSeen.Count + $inactiveNotSeen.Count

# Print summary
Write-Output "## Seen Live Stats"
Write-Output "`nLast.fm user: [$LastFmUserName](https://www.last.fm/user/$LastFMUserName)"
Write-Output "`n- Number of artists seen live in total: $($artistsSeenLive.Length)"
Write-Output "`n- Number of fetched top artists: $($artists.Count) (Active: $totalActive Inactive: $totalInactive)"
Write-Output "`n- Number of top artists seen live: $totalSeen (Active: $($activeSeen.Count) Inactive: $($inactiveSeen.Count))"
Write-Output "`n- Number of top artists not seen live: $totalNotSeen (Active: $($activeNotSeen.Count) Inactive: $($inactiveNotSeen.Count))"

# Print last 10 seen live
Write-Output "`n## Last 10 artists seen live`n"
$last10SeenLiveObj = $last10SeenLive | ForEach-Object {
    [PSCustomObject]@{ Artist = $_; 'Seen live' = $true }
}
Write-Output ($last10SeenLiveObj | Select-Object Artist, 'Seen live' | ConvertTo-Markdown)

# Print lists
Write-Output "`n## Top $NumberOfArtists artists seen live ($totalSeen)`n"
Write-Output ($artists | ? { $_.SeenLive } | Select-Object Name, Rank, PlayCount | ConvertTo-Markdown)

Write-Output "`n## Active top $NumberOfArtists artists not seen live ($($activeNotSeen.Count))`n"
Write-Output ($activeNotSeen | ConvertTo-Markdown)

Write-Output "`n## Inactive top $NumberOfArtists artists not seen live ($($inactiveNotSeen.Count))`n"
Write-Output ($inactiveNotSeen | ConvertTo-Markdown)
