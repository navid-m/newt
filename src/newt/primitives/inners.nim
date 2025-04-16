import
    json,
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
