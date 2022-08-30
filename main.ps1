[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $LastFmUserName = "matsest",
    [Parameter()]
    [string]
    $NumberOfArtists = "100",
    [Parameter()]
    [string]
    $InactiveArtistsFile = "nonActiveArtists.txt"
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

# Statistics
$totalActive = $activeSeen.Count + $activeNotSeen.Count
$totalInactive = $inactiveSeen.Count + $inactiveNotSeen.Count
$totalSeen = $activeSeen.Count + $inactiveSeen.Count
$totalNotSeen = $activeNotSeen.Count + $inactiveNotSeen.Count

# Print summary
Write-Host "Number of top artists: $($artists.Count) (Active: $totalActive Inactive: $totalInactive)"
Write-Host "Number of top artists seen live $totalSeen (Active: $($activeSeen.Count) Inactive: $($inactiveSeen.Count))"
Write-Host "Number of top artists not seen live $totalNotSeen (Active: $($activeNotSeen.Count) Inactive: $($inactiveNotSeen.Count))"

# Print lists
Write-Host "`nTop $NumberOfArtists artists seen live ($totalSeen)"
Write-Host ($artists | ? { $_.SeenLive } | Select-Object Name, PlayCount | Format-Table | Out-String)

Write-Host "Active top $NumberOfArtists artists not seen live ($($activeNotSeen.Count))"
Write-Host ($activeNotSeen | Format-Table | Out-String)

Write-Host "Inactive top $NumberOfArtists artists not seen live ($($inactiveNotSeen.Count))"
Write-Host ($inactiveNotSeen | Format-Table | Out-String)
