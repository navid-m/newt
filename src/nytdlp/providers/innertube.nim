import
  httpclient,
  json,
  strformat,
  strutils,
  streams

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

    client.headers = newHttpHeaders({
      "Accept-Language": "en-US,en;q=0.9",
      "Sec-Fetch-Dest": "empty",
      "Sec-Fetch-Mode": "cors",
      "Sec-Fetch-Site": "cross-site",
      "Referer": "https://youtube.com",
      "Cookie": "CONSENT=YES+cb.20210328-17-p0.en+FX+" & randomConsentID()
    })

    var outputStream = newFileStream(outputPath, fmWrite)
    if outputStream == nil:
      raise newException(IOError, "Unable to open output file")

    defer: outputStream.close()

    var totalBytesRead: int64 = 0
    const chunkSize = 8192 * 10

    var buffer = newString(chunkSize)

    client.onProgressChanged = proc (total, progress, speed: BiggestInt) =
      echo fmt"Downloaded {progress}/{total} bytes ({(progress.float / total.float * 100):0.2f}%) at {speed/1000:0.2f} KB/s"

    var response = client.request(downloadUrl)
    while not response.bodyStream.atEnd():
      let bytesRead = response.bodyStream.readData(addr(buffer[0]), chunkSize)
      if bytesRead <= 0:
        break
      outputStream.writeData(addr(buffer[0]), bytesRead)
      totalBytesRead += bytesRead

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
