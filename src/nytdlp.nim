import std/uri
import std/net
import nytdlp/randoms
import httpclient
import json
import strformat
import os
import strutils


# Get video info using API
proc getVideoInfo(videoId: string, invidiousInstanceUrl: string = randomIvInstance()): JsonNode =
  let client = newHttpClient()
  let userAgentToUse = randomUserAgent()

  client.headers = newHttpHeaders(titleCase = true)

  client.headers.add("User-Agent", userAgentToUse)
  client.headers.add("Accept", "application/json")
  client.headers.add("Referer", fmt"http://{invidiousInstanceUrl}/")
  client.headers.add("Accept-Language", "en-US,en;q=0.9")

  var response: string

  try:
    let url = fmt"http://{invidiousInstanceUrl}/api/v1/videos/{encodeUrl(videoId)}"
    echo url
    response = client.getContent(url)
  except HttpRequestError as e:
    echo "Error fetching video info: ", e.msg
    quit(1)

  return parseJson(response)


# Get highest quality video stream.
proc getVideo(videoInfo: JsonNode): JsonNode =
  var bestStream: JsonNode = nil
  for stream in videoInfo["adaptiveFormats"].items:
    if stream["type"].getStr().startsWith("video/") and stream.hasKey("audioQuality"):
      if bestStream.isNil or (stream["bitrate"].getInt() > bestStream[
          "bitrate"].getInt()):
        bestStream = stream
  if bestStream.isNil:
    raise newException(ValueError, "No video found")
  return bestStream


# Get highest quality audio stream.
proc getAudio(videoInfo: JsonNode): JsonNode =
  var bestStream: JsonNode = nil
  for stream in videoInfo["adaptiveFormats"].items:
    if stream["type"].getStr().startsWith("audio/"):
      if bestStream.isNil or (stream["bitrate"].getInt() > bestStream[
          "bitrate"]
        .getInt()
      ):
        bestStream = stream
  if bestStream.isNil:
    raise newException(ValueError, "No audio found")
  return bestStream


# Download the fucking thing
proc downloadFile(url: string, outputPath: string) =
  let client = newHttpClient(userAgent = randomUserAgent())

  client.headers.add("Accept", "*/*")
  client.headers.add("Referer", "http://google.com.bz/")
  client.headers.add("Accept-Language", "en-US,en;q=0.9")

  var fileContent: string

  try:
    fileContent = client.getContent(url)
  except HttpRequestError as e:
    echo "Error downloading file: ", e.msg
    quit(1)

  writeFile(outputPath, fileContent)


# Run the CLI
proc main() =
  if paramCount() < 1:
    echo "Usage: nytdlp [-v|-a] <YouTube video URL>"
    quit(1)

  let url = if paramCount() == 2: paramStr(2) else: paramStr(1)

  var extractedVideoId: seq[string]

  extractedVideoId = url.split("=")

  let videoInfo = getVideoInfo(extractedVideoId[^1])

  echo extractedVideoId
  echo videoInfo

  if paramCount() == 1 or paramStr(1) == "-a":
    downloadFile(getAudio(videoInfo)["url"].getStr(), "output.opus")

  elif paramStr(1) == "-v":
    downloadFile(getVideo(videoInfo)["url"].getStr(), "output.mp4")

  else:
    echo "Invalid option provided."
    echo "Usage: nytdlp [-v|-a] <YouTube video URL>"
    quit(1)

  echo "Downloaded to current directory."


main()
