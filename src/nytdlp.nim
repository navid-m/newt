import std/uri
import std/net
import nytdlp/consts
import nytdlp/texts
import httpclient
import json
import strformat
import os
import strutils

var GlobalBody: JsonNode


# Make an innertube request
proc innertubeRequest(
    endpoint: string,
    body: JsonNode,
    clientContext: JsonNode
  ): JsonNode =

  GlobalBody = body

  let url = fmt"https://www.youtube.com/youtubei/v1/{endpoint}?key={APIKey}"
  let client = newHttpClient()

  echo "URL: ", url
  echo "BODY: ", body
  echo "CLIENTCONTEXT: ", clientContext
  echo "ENDPOINT: ", endpoint, "\n\n"

  # Ensure headers are properly set
  client.headers.add("User-Agent", Agent)
  client.headers.add("Accept", "application/json")
  client.headers.add("Content-Type", "application/json")

  var fullBody = %*{
    "context": clientContext
  }

  for k, v in body.pairs:
    fullBody[k] = v

  var response: string

  try:
    response = client.postContent(url, $fullBody)
  except HttpRequestError as e:
    echo "Error making Innertube request: ", e.msg
    quit(1)

  return parseJson(response)


# Get video info using the Innertube API
proc getVideoInfo(videoId: string): JsonNode =
  let body = %*{
    "videoId": videoId
  }
  return innertubeRequest("player", body, ClientContext)


# Extract DL from JSON response
proc extractDownloadLink(signatureCipher: string): string =
  var urlParam: string = ""
  for param in signatureCipher.split('&'):
    if param.startsWith("url="):
      urlParam = param
      break

  if urlParam.len() == 0:
    raise newException(ValueError, "URL parameter not found in signature cipher")

  return decodeUrl(urlParam.split('=')[1])


# Extract the highest quality audio/video stream based on the parameter
proc extractHighestStream(videoInfo: JsonNode, isAudio: bool = true): JsonNode =
  var bestStream: JsonNode = nil
  var highestBitrate = 0

  for stream in videoInfo["streamingData"]["adaptiveFormats"].items:
    let mimeType = stream["mimeType"].getStr()
    if (isAudio and mimeType.startsWith("audio/")) or
       (not isAudio and mimeType.startsWith("video/") and stream.hasKey("bitrate")):
      let bitrate = stream["bitrate"].getInt()
      if bitrate > highestBitrate:
        highestBitrate = bitrate
        bestStream = stream

  if bestStream.isNil:
    raise newException(ValueError, "No suitable stream found")

  return bestStream


proc onProgressChanged(total, progress, speed: BiggestInt) =
  echo("Downloaded ", progress, " of ", total)
  echo("Current rate: ", speed div 1000, "kb/s")


# Download the fucking thing
# Simple function to download content and save to a file
proc getStuff(url: string, outputPath: string) =
  let client = newHttpClient()
  try:
    # Set up necessary headers
    client.headers.add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.159 Safari/537.36")
    client.headers.add("Connection", "keep-alive")
    client.headers.add("Origin", "https://youtube.com")
    client.onProgressChanged = onProgressChanged

    var fullBody = %*{
      "context": DownloaderClientContext
    }

    for k, v in GlobalBody.pairs:
      fullBody[k] = v

    client.downloadFile("https://download.samplelib.com/mp4/sample-30s.mp4", "out.mp4")


  except HttpRequestError as e:
    echo "Error downloading file: ", e.msg
    quit(1)

# Run the CLI
proc main() =
  if paramCount() < 1:
    echo "Usage: nytdlp [-v|-a] <YouTube video URL>"
    quit(1)

  let url = if paramCount() == 2: paramStr(2) else: paramStr(1)
  let isAudio = paramCount() == 1 or paramStr(1) == "-a"
  let stream = extractHighestStream(getVideoInfo(extractVideoId(url)), isAudio)
  let downloadUrl = extractDownloadLink(stream["signatureCipher"].getStr())

  if isAudio:
    getStuff(downloadUrl, "output.opus")
  else:
    getStuff(downloadUrl, "output.mp4")

  echo "Downloaded to current directory."


main()
