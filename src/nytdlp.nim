import std/uri
import std/net
import nytdlp/consts
import nytdlp/texts
import httpclient
import json
import strformat
import os
import strutils


# Make an innertube request
proc innertubeRequest(
    endpoint: string,
    body: JsonNode,
    clientContext: JsonNode
  ): JsonNode =
  let url = fmt"https://www.youtube.com/youtubei/v1/{endpoint}?key={APIKey}"
  let client = newHttpClient()

  echo "URL: ", url
  echo "BODY: ", body
  echo "CLIENTCONTEXT: ", clientContext
  echo "ENDPOINT: ", endpoint, "\n\n"

  # Ensure headers are properly set
  client.headers.add("User-Agent", clientContext["client"]["userAgent"].getStr())
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

  if urlParam.len() == 0 or urlParam.len() < 5:
    raise newException(ValueError, "URL parameter not found in signature cipher")

  return decodeUrl(urlParam.split('=')[1].replace("url=", ""))


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


# Download the fucking thing
proc downloadFile(url: string, outputPath: string) =
  let client = newHttpClient()

  try:
    let content = client.getContent(url)
    writeFile(outputPath, content)
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
    downloadFile(downloadUrl, "output.opus")
  else:
    downloadFile(downloadUrl, "output.mp4")

  echo "Downloaded to current directory."


main()
