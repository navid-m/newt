import httpclient
import json
import strformat
import strutils
import ../primitives/randoms


# Constants for InnerTube API
const INNERTUBE_API_URL = "https://www.youtube.com/youtubei/v1/player"
const INNERTUBE_API_KEY = "AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8"
const INNERTUBE_CLIENT_NAME = "WEB"
const INNERTUBE_CLIENT_VERSION = "2.20210621.00.00"


# Build InnerTube API request payload
proc buildInnertubePayload(videoId: string): JsonNode =
  return %*{
    "context": {
      "client": {
        "clientName": INNERTUBE_CLIENT_NAME,
        "clientVersion": INNERTUBE_CLIENT_VERSION
    }
  },
    "videoId": videoId
  }


# Get video info using InnerTube API
proc getVideoInfo(videoId: string): JsonNode =
  let client = newHttpClient()
  let userAgentToUse = randomUserAgent()

  client.headers = newHttpHeaders(titleCase = true)
  client.headers.add("User-Agent", userAgentToUse)
  client.headers.add("Content-Type", "application/json")
  client.headers.add("Accept", "application/json")

  var response: string

  try:
    let url = fmt"{INNERTUBE_API_URL}?key={INNERTUBE_API_KEY}"
    let payload = buildInnertubePayload(videoId)
    response = client.postContent(url, $payload)
  except HttpRequestError as e:
    echo "Error fetching video info: ", e.msg
    quit(1)

  return parseJson(response)


# Get highest quality video stream.
proc getVideo(videoInfo: JsonNode): JsonNode =
  var bestStream: JsonNode = nil
  for stream in videoInfo["streamingData"]["adaptiveFormats"].items:
    if stream["mimeType"].getStr().startsWith("video/") and stream.hasKey("audioQuality"):
      if bestStream.isNil or (stream["bitrate"].getInt() > bestStream[
          "bitrate"].getInt()):
        bestStream = stream
  if bestStream.isNil:
    raise newException(ValueError, "No video found")
  return bestStream


# Get highest quality audio stream.
proc getAudio(videoInfo: JsonNode): JsonNode =
  var bestStream: JsonNode = nil
  for stream in videoInfo["streamingData"]["adaptiveFormats"].items:
    if stream["mimeType"].getStr().startsWith("audio/"):
      if bestStream.isNil or (stream["bitrate"].getInt() > bestStream[
          "bitrate"].getInt()):
        bestStream = stream
  if bestStream.isNil:
    raise newException(ValueError, "No audio found")
  return bestStream


# Download
proc downloadInnerStream*(url: string, isAudio: bool) =
  try:
    let extractedVideoId = url.split("=")
    let videoId = extractedVideoId[^1]
    let videoInfo = getVideoInfo(videoId)
    if (isAudio):
      echo getAudio(videoInfo)
    else:
      echo getVideo(videoInfo)

  except CatchableError as e:
    echo "Error here: ", e.msg
    quit(1)
