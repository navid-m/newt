import
  httpclient,
  json,
  strformat,
  strutils,
  streams,
  os,
  osproc,
  threadpool

import
  ../primitives/[randoms, inners, texts],
  ../diagnostics/[envchk, logger],
  ../models/[downloadmods, mediamods],
  ../flags/vidflags


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


proc getAudio(videoInfo: JsonNode): JsonNode =
  ## Get highest quality audio stream
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


proc getVideo(videoInfo: JsonNode): (JsonNode, JsonNode) =
  ## Get highest quality video stream
  var bestStream: JsonNode = nil
  for stream in videoInfo["streamingData"]["adaptiveFormats"].items:
    if stream["mimeType"].getStr().startsWith("video/"):
      if bestStream.isNil or (
        stream["bitrate"].getInt() > bestStream["bitrate"].getInt()
      ):
        bestStream = stream

  if bestStream.isNil:
    raise newException(ValueError, "No video found")

  return (bestStream, getAudio(videoInfo))


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
      LogInfo(
        fmt"Downloaded {totalBytesWritten}/{contentLength} bytes ({(totalBytesWritten.float / contentLength.float * 100):0.2f}%)"
      )

    LogInfo(fmt"Downloaded stream to {outputPath}")

  except HttpRequestError as e:
    LogError("Error downloading stream: " & e.msg)


proc getInnerStreamData*(url: string): VideoInfo =
  let vidInf = getVideoInfo(url.split("=")[^1], newHttpClient())
  let vidDetails = vidInf["videoDetails"]
  let rawDesc = vidDetails["shortDescription"].getStr

  var mediaSeq: seq[MediaFormat] = @[]

  var video = VideoInfo(
    videoId: vidDetails["videoId"].getStr,
    title: vidDetails["title"].getStr,
    lengthSeconds: vidDetails["lengthSeconds"].getStr.parseInt,
    author: vidDetails["author"].getStr,
    channelId: vidDetails["channelId"].getStr,
    views: vidDetails["viewCount"].getStr.parseInt,
    private: vidDetails["isPrivate"].getBool,
    liveContent: vidDetails["isLiveContent"].getBool,
    ratingsEnabled: vidDetails["allowRatings"].getBool,
    description: rawDesc[0 ..< min(150, len(rawDesc))]
  )

  var lastKnownAdaptiveClength = 0

  proc populateFormatsViaIdentifier(formatLookupIdentifier: string) =
    for format in vidInf["streamingData"][formatLookupIdentifier].items:
      var audioSampleRate = 0
      var audioChannels = 0
      var audioQuality = "N/A"

      try:
        audioSampleRate = format["audioSampleRate"].getStr.parseInt
        audioChannels = format["audioChannels"].getInt
        audioQuality = format["audioQuality"].getStr
      except:
        discard

      var width = 0
      var height = 0
      var fps = 0
      var quality = "N/A"
      var qualityLabel = "N/A"
      var projectionType = "N/A"
      var currentAdaptiveClength = 0

      try:
        width = format["width"].getInt
        height = format["height"].getInt
        fps = format["fps"].getInt
        quality = format["quality"].getStr
        qualityLabel = format["qualityLabel"].getStr
        projectionType = format["projectionType"].getStr
      except:
        discard

      try:
        currentAdaptiveClength = format["contentLength"].getStr.parseInt
      except:
        discard

      if (currentAdaptiveClength != 0):
        lastKnownAdaptiveClength = currentAdaptiveClength
      else:
        currentAdaptiveClength = lastKnownAdaptiveClength

      var (mimeType, codec) = parseMimeType(format["mimeType"].getStr)

      mediaSeq.add(MediaFormat(
        itag: format["itag"].getInt,
        url: format["url"].getStr,
        mimeType: mimeType,
        codec: codec.replace(", ", " + "),
        bitrate: format["bitrate"].getInt,
        audioSampleRate: audioSampleRate,
        audioChannels: audioChannels,
        width: width,
        height: height,
        fps: fps,
        audioQuality: audioQuality,
        quality: quality,
        qualityLabel: qualityLabel,
        contentLength: currentAdaptiveClength,
        projectionType: projectionType,
      ))

  populateFormatsViaIdentifier("adaptiveFormats")
  populateFormatsViaIdentifier("formats")

  video.formats = mediaSeq

  return video


proc downloadInnerStream*(url: string, isAudio: bool) =
  ## Main download procedure
  let videoId = url.split("=")[^1]
  let videoInfo = getVideoInfo(videoId, newHttpClient())
  let dlName = videoInfo["videoDetails"]["title"].str & " [" & videoInfo[
      "videoDetails"]["videoId"].str & "]"

  if videoInfo.isNil:
    raise newException(ValueError, "Failed to retrieve video information")

  var downloadUrl: string

  LogInfo("Getting highest quality stream...")

  if isAudio:
    let audioInfo = getAudio(videoInfo)
    downloadUrl = audioInfo["url"].getStr()
    downloadStream(downloadUrl, fmt"{dlName}.weba")
  else:
    let fullVideoInfo = getVideo(videoInfo)
    let audioDownloadUrl = fullVideoInfo[1]["url"].getStr()
    let videoName = fmt"{dlName}.mp4"

    downloadUrl = fullVideoInfo[0]["url"].getStr()

    if GetHighQualMergeStatus():
      let tempVideoName = "temp_video.webm"
      let tempAudioName = "temp_audio.weba"

      downloadStream(downloadUrl, tempVideoName)
      downloadStream(audioDownloadUrl, tempAudioName)

      proc fallbackOp() = moveFile(tempVideoName, videoName)

      if CurrentSysHasFfmpeg():
        let res = execCmdEx(
          "ffmpeg -i {tempVideoName} -i {tempAudioName} -c:v copy -map 0:v:0 -map 1:a:0 -shortest \"{videoName}\" -y".fmt
        )
        if res.exitCode != 0:
          LogInfo("Failed merge with exit code: ", res.exitCode, res.output)
          fallbackOp()
      else:
        LogInfo("FFmpeg is not installed. Using initial downloaded stream instead of merging.")
        fallbackOp()

      removeFile(tempVideoName)
      removeFile(tempAudioName)
    else:
      downloadStream(downloadUrl, videoName)
