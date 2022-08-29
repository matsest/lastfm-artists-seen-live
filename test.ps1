[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $lastFmUserName = "matsest",
    [Parameter()]
    [string]
    $numberOfArtists = "200",
    [Parameter(Mandatory)]
    [string]
    $apiKey,
    [Parameter()]
    [string]
    $nonActiveArtistsFile = "nonActiveArtists.txt"
)

# Get non active artists from config file
$nonActiveArtists = Get-Content $nonActiveArtistsFile

# Lookup the users current top artists
$topArtistsUri = "https://ws.audioscrobbler.com/2.0/?method=user.gettopartists&user=$lastFmUserName&api_key=$apiKey&format=json&limit=$numberOfArtists"

$res = Invoke-RestMethod -Uri $topArtistsUri
$artists = $res.topartists.artist
$topArtists = $artists | Select-Object name, playcount -First $numberOfArtists
$topArtistsToConsider = $topArtists | Where { $_.name -notin $nonActiveArtists }

# Find the artists with seen live tag - should support paging..
$seenLiveUri = "https://ws.audioscrobbler.com/2.0/?method=user.getpersonaltags&user=$lastFmUserName&tag=seen%20live&taggingtype=artist&api_key=$apiKey&format=json&limit=500"

$res2 = Invoke-RestMethod -Uri $seenLiveUri
$artistsSeenLive = $res2.taggings.artists.artist

# Go through an list all artists not seen live
$i = 1
Write-Host "Not seen live:"
foreach($a in $topArtistsToConsider){
    if ($a.name -notin $artistsSeenLive.name){
        Write-Host "$i $($a.name) ($($a.playcount))"
    }
    $i++
}