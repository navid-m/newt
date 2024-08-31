import
  httpclient,
  json,
  strformat,
  strutils

import ../primitives/randoms


# Constants for InnerTube API
const INNERTUBE_API_URL = "https://www.youtube.com/youtubei/v1/player"
const INNERTUBE_API_KEY = "AIzaSyA8eiZmM1FaDVjRy-df2KTyQ_vz_yYM39w"
const INNERTUBE_CLIENT_NAME = "ANDROID"
const INNERTUBE_CLIENT_VERSION = "18.11.34"
const ANDROID_USER_AGENT = "com.google.android.youtube/18.11.34 (Linux; U; Android 11) gzip"


# Build InnerTube API request payload
proc buildInnertubePayload(videoId: string): JsonNode =
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


proc getVideoInfo(videoId: string, client: HttpClient): JsonNode =
  ## Get video info using InnerTube API
  let userAgentToUse = randomUserAgent()

  client.headers = newHttpHeaders(titleCase = true)

  client.headers.add("User-Agent", userAgentToUse)
  client.headers.add("Content-Type", "application/json")
  client.headers.add("Accept", "application/json")
  client.headers.add("Sec-Fetch-Mode", "navigate")
  client.headers.add(
    "Cookie",
    "CONSENT=YES+cb.20210328-17-p0.en+FX+" & randomConsentID()
  )

  var response: string

  try:
    let url = fmt"{INNERTUBE_API_URL}?key={INNERTUBE_API_KEY}"
    let payload = buildInnertubePayload(videoId)
    response = client.postContent(url, $payload)
  except HttpRequestError as e:
    echo "Error fetching video info: ", e.msg
    return nil

  return parseJson(response)


proc getVideo(videoInfo: JsonNode): JsonNode =
  ## Get highest quality video stream.
  var bestStream: JsonNode = nil

  for stream in videoInfo["streamingData"]["adaptiveFormats"].items:
    if stream["mimeType"].getStr().startsWith("video/") and stream.hasKey("audioQuality"):
      if bestStream.isNil or (
        stream["bitrate"].getInt() > bestStream["bitrate"].getInt()
      ):
        bestStream = stream

  if bestStream.isNil:
    raise newException(ValueError, "No video found")

  return bestStream


proc getAudio(videoInfo: JsonNode): JsonNode =
  ## Get highest quality audio stream.
  var bestStream: JsonNode = nil

  for stream in videoInfo["streamingData"]["adaptiveFormats"].items:
    if stream["mimeType"].getStr().startsWith("audio/"):
      if bestStream.isNil or (
        stream["bitrate"].getInt() > bestStream["bitrate"].getInt()
      ):
        bestStream = stream

  if bestStream.isNil:
    raise newException(ValueError, "No audio found")

  return bestStream


proc downloadStream(
    client: HttpClient,
    downloadUrl: string,
    outputPath: string
  ) =
  ## Download the stream using the same HttpClient for authenticated access.
  try:
    echo "Downloading: " & downloadUrl & " to " & outputPath

    client.timeout = 4200

    client.headers.add("Accept-Language", "en-US,en;q=0.9")
    client.headers.add("Sec-Fetch-Dest", "empty")
    client.headers.add("Sec-Fetch-Mode", "cors")
    client.headers.add("Sec-Fetch-Site", "cross-site")
    client.headers.add("Referer", "https://youtube.com")
    client.headers.add(
      "Cookie",
      "CONSENT=YES+cb.20210328-17-p0.en+FX+" & randomConsentID()
    )

    # Really, REALLY slow...eventually fails after getting 150KB...
    # Need to download in chunks.
    client.downloadFile(downloadUrl, outputPath)

    echo fmt"Downloaded stream to {outputPath}"
  except HttpRequestError as e:
    echo "Error downloading stream: ", e.msg


proc downloadInnerStream*(url: string, isAudio: bool) =
  ## Main download procedure
  let extractedVideoId = url.split("=")
  let videoId = extractedVideoId[^1]
  let client = newHttpClient()
  let videoInfo = getVideoInfo(videoId, client)

  if videoInfo.isNil:
    raise newException(ValueError, "Failed to retrieve video information")

  client.headers.del("Accept")
  client.headers.add("Accept", "application/octet-stream")
  client.headers.add("Content-Disposition", "attachment")

  var downloadUrl: string

  if isAudio:
    let audioInfo = getAudio(videoInfo)
    downloadUrl = audioInfo["url"].getStr()
    downloadStream(client, downloadUrl, "audio.weba")

  else:
    let videoInfo = getVideo(videoInfo)
    downloadUrl = videoInfo["url"].getStr()
    downloadStream(client, downloadUrl, "video.webm")
