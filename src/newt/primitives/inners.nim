import
    json,
    strutils,
    uri,
    ../primitives/visitors


# Constants for InnerTube API
const INNERTUBE_API_URL* = "https://www.youtube.com/youtubei/v1/player"
const INNERTUBE_API_KEY* = "AIzaSyA8eiZmM1FaDVjRy-df2KTyQ_vz_yYM39w"
const INNERTUBE_CLIENT_NAME* = "ANDROID"
const INNERTUBE_CLIENT_VERSION* = "18.11.34"
const ANDROID_USER_AGENT* = "com.google.android.youtube/18.11.34 (Linux; U; Android 11) gzip"


# Build InnerTube API request payload
proc buildInnertubePayload*(videoId: string): JsonNode =
    return %*{
      "context": {
        "client": {
          "hl": "en",
          "gl": "US",
          "clientName": INNERTUBE_CLIENT_NAME,
          "clientVersion": INNERTUBE_CLIENT_VERSION,
          "androidSDKVersion": 30,
          "userAgent": ANDROID_USER_AGENT,
          "timeZone": "UTC",
          "utcOffsetMinutes": 0,
          "visitorData": randomVisitorData("US")
        }
    },
      "videoId": videoId,
      "playbackContext": {
        "contentPlaybackContext": {
          "html5Preference": "HTML5_PREF_WANTS"
        }
    },
      "contentCheckOk": true,
      "racyCheckOk": true
    }


proc extractIdFallback(url: string): string =
    let lowerUrl = url.toLowerAscii()
    let vIndex = lowerUrl.find("v=")
    if vIndex != -1:
        let startIndex = vIndex + 2
        let remaining = url[startIndex..^1]
        let endIndex = remaining.find('&')
        if endIndex != -1:
            return remaining[0..<endIndex]
        else:
            return remaining
    let youtuBeIndex = lowerUrl.find("youtu.be/")
    if youtuBeIndex != -1:
        let startIndex = youtuBeIndex + 9
        let remaining = url[startIndex..^1]
        let endIndex = remaining.find('?')
        if endIndex != -1:
            return remaining[0..<endIndex]
        else:
            return remaining

    let embedIndex = lowerUrl.find("/embed/")
    if embedIndex != -1:
        let startIndex = embedIndex + 7
        let remaining = url[startIndex..^1]
        let endIndex = remaining.find('?')
        if endIndex != -1:
            return remaining[0..<endIndex]
        else:
            return remaining

    return ""


proc extractYouTubeId*(url: string): string =
    if url.len == 0:
        return ""

    try:
        let parsedUrl = parseUri(url)
        let host = parsedUrl.hostname.toLowerAscii()
        if host in ["www.youtube.com", "youtube.com", "m.youtube.com"]:
            if parsedUrl.path == "/watch":
                let query = parsedUrl.query
                for param in query.split('&'):
                    let keyValue = param.split('=', 1)
                    if keyValue.len == 2 and keyValue[0] == "v":
                        return keyValue[1]

            elif parsedUrl.path.startsWith("/embed/"):
                let id = parsedUrl.path[7..^1]
                if id.len > 0:
                    return id.split('?')[0]
            elif parsedUrl.path == "/watch":
                let query = parsedUrl.query
                for param in query.split('&'):
                    let keyValue = param.split('=', 1)
                    if keyValue.len == 2 and keyValue[0] == "v":
                        return keyValue[1]

        elif host == "youtu.be":
            let id = parsedUrl.path[1..^1]
            if id.len > 0:
                return id.split('?')[0]

        return ""

    except:
        return extractIdFallback(url)
