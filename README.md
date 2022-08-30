# Top Artists seen live

[![Run](https://github.com/matsest/lastfm-artists-seen-live/actions/workflows/run.yaml/badge.svg)](https://github.com/matsest/lastfm-artists-seen-live/actions/workflows/run.yaml)

> Which of my most listened to artists have I not seen live?

## Background

Using scrobbles from [my last.fm account](https://www.last.fm/user/matsest), the ['seen live' tag](https://www.last.fm/tag/seen+live) on last.fm artists and the [Last.FM API](https://www.last.fm/api) together with some PowerShell this repo keeps track of which of my top artists I've seen/not seen live.

## Usage

Prerequisites:
  - [PowerShell 7.x](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell)
  - [Last.FM API Account](https://www.last.fm/api/account/create)

### Run script

```powershell
$env:API_KEY = "<API Key>"
./main.ps1 [[-LastFmUserName] <string>] `
         [[-NumberOfArtists] <string>] `
         [[-InactiveArtistsFile] <string>]
```

See the latest run of the script in [Actions](https://github.com/matsest/lastfm-artists-seen-live/actions).

## License

[MIT License](./LICENSE)