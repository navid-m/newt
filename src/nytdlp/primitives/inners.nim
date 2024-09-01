import json


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
        "clientName": INNERTUBE_CLIENT_NAME,
        "clientVersion": INNERTUBE_CLIENT_VERSION,
        "androidSDKVersion": 30,
        "userAgent": ANDROID_USER_AGENT,
        "timeZone": "UTC",
        "utcOffsetMinutes": 0,
        "gl": "US",
        "hl": "en"
    }
  },
    "videoId": videoId,
    "contentCheckOk": true,
    "racyCheckOk": true,
    "params": "CgIQBg=="
  }
