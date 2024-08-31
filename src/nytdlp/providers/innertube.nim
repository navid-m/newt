import
  httpclient,
  json,
  strformat,
  strutils,
  streams,
  threadpool

import ../primitives/randoms
import ../primitives/inners
import ../diagnostics/logger


type
  DownloadChunk = object
    start: int
    ender: int
    data: string


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
    LogError("Error fetching video info: " & e.msg)
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


proc downloadChunk(url: string, start, ender: int): DownloadChunk =
  ## Download a chunk
  let client = newHttpClient()
  client.headers = newHttpHeaders({
    "Accept-Language": "en-US,en;q=0.9",
    "Sec-Fetch-Dest": "empty",
    "Sec-Fetch-Mode": "cors",
    "Sec-Fetch-Site": "cross-site",
    "Referer": "https://youtube.com",
    "Range": fmt"bytes={start}-{ender}",
    "Cookie": "CONSENT=YES+cb.20210328-17-p0.en+FX+" & randomConsentID()
  })
  result = DownloadChunk(start: start, ender: ender, data: client.get(url).body)


proc downloadStream(
    downloadUrl: string,
    outputPath: string
) =
  ## Download the whole stream
  try:
    LogInfo("Downloading: " & downloadUrl & " to " & outputPath)

    let client = newHttpClient()
    const chunkSize = 1024 * 1024 * 5

    client.headers = newHttpHeaders({
      "Accept-Language": "en-US,en;q=0.9",
      "Sec-Fetch-Dest": "empty",
      "Sec-Fetch-Mode": "cors",
      "Sec-Fetch-Site": "cross-site",
      "Referer": "https://youtube.com",
      "Cookie": "CONSENT=YES+cb.20210328-17-p0.en+FX+" & randomConsentID()
    })

    client.headers.add("Range", "bytes=0-0")

    let headResponse = client.head(downloadUrl)
    let contentLength = parseInt(
      headResponse.headers["Content-Range"].split("/")[1]
    )
    let numChunks = (contentLength div chunkSize) + 1
    var chunks: seq[FlowVar[DownloadChunk]]

    for i in 0 ..< numChunks:
      let start = i * chunkSize
      var ender = (i + 1) * chunkSize - 1
      if ender >= contentLength:
        ender = contentLength - 1

      chunks.add(spawn downloadChunk(downloadUrl, start, ender))

    var outputStream = newFileStream(outputPath, fmWrite)
    if outputStream == nil:
      raise newException(IOError, "Unable to open output file")

    defer: outputStream.close()

    var totalBytesWritten: int64 = 0

    for chunkFv in chunks:
      let chunk = ^chunkFv
      outputStream.write(chunk.data)
      totalBytesWritten += chunk.data.len
      LogInfo(fmt"Downloaded {totalBytesWritten}/{contentLength} bytes ({(totalBytesWritten.float / contentLength.float * 100):0.2f}%)")

    LogInfo(fmt"Downloaded stream to {outputPath}")

  except HttpRequestError as e:
    LogError("Error downloading stream: " & e.msg)


proc downloadInnerStream*(url: string, isAudio: bool) =
  ## Main download procedure
  let extractedVideoId = url.split("=")
  let videoId = extractedVideoId[^1]
  let client = newHttpClient()
  let videoInfo = getVideoInfo(videoId, client)

  if videoInfo.isNil:
    raise newException(ValueError, "Failed to retrieve video information")

  var downloadUrl: string

  if isAudio:
    let audioInfo = getAudio(videoInfo)
    downloadUrl = audioInfo["url"].getStr()
    downloadStream(downloadUrl, "audio.weba")
  else:
    let videoInfo = getVideo(videoInfo)
    downloadUrl = videoInfo["url"].getStr()
    downloadStream(downloadUrl, "video.webm")
