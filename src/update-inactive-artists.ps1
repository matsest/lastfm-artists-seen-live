[CmdletBinding()]
param (
    [Parameter(Mandatory, HelpMessage = "Last.fm username")]
    [string]
    $LastFmUserName,
    [Parameter(HelpMessage = "Number of most listened to artists to fetch from Last.fm")]
    [int]
    $NumberOfArtists = 100,
    [Parameter(HelpMessage = "File with a list of artists that are no longer active (can't be seen live)")]
    [string]
    $InactiveArtistsFile = "$PSScriptRoot/nonActiveArtists.txt"
)

# Defaults
$ErrorActionPreference = 'Stop'
$InactiveArtists = Get-Content $InactiveArtistsFile

# Import module
Import-Module "$PSScriptRoot/lastfm.psm1" -Force

# Test API access
$null = Test-LFMApiAccess -UserName $LastFmUserName -ApiKey $env:API_KEY

# Get artists
$topArtists = Invoke-LFMTopArtists -UserName $LastFmUserName -ApiKey $env:API_KEY -Limit $NumberOfArtists
# remove artists that are not active anymore and assign to a new variable
$activeTopArtists = $topArtists.Name | Where-Object { $_ -notin $InactiveArtists }

$estimatedSeconds = $activeTopArtists.Count
$timeSpan = [TimeSpan]::FromSeconds($estimatedSeconds)
$timeFormatted = if ($estimatedSeconds -lt 60) {
    "$estimatedSeconds seconds"
} else {
    $timeSpan.ToString("mm\m\:ss\s")
}
Write-Host "Checking activity status for $($activeTopArtists.Count) artists... This will take approximately $timeFormatted (due to API throttling).`n"

foreach ($artist in $activeTopArtists) {
    Start-Sleep -Seconds 1 # to avoid hitting API rate limits
    $isStillActive = Get-ArtistStatus -ArtistName $artist
    if (!$isStillActive) {
        Write-Host "- $artist is reported as inactive - adding to inactive artists list."
        $InactiveArtists += $artist
    }
}

# Save updated inactive artists to file
$InactiveArtists | Set-Content $InactiveArtistsFile -Force

Write-Host "`nUpdated inactive artists list saved to $InactiveArtistsFile."
Write-Host "Remember to review the changes and commit the updated file to the repo!"