import std/uri
import std/net
import nytdlp/consts
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

  echo "BODY: ", body
  echo "CLIENTCONTEXT: ", clientContext
  echo "ENDPOINT: ", endpoint

  # Ensure headers are properly set
  client.headers.add("User-Agent", clientContext["client"]["userAgent"].getStr())
  client.headers.add("Accept", "application/json")
  client.headers.add("Content-Type", "application/json")

  # Merge the client context with the request body
  # Create a new JSON object that combines the body and the context
  var fullBody = %*{
    "context": clientContext["context"]
  }

  for k, v in body.pairs:
    fullBody[k] = v

  var response: string

  try:
    # Convert JSON to string
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


# Extract video and audio stream URLs
proc extractStreams(videoInfo: JsonNode): (JsonNode, JsonNode) =
  var videoStream: JsonNode = nil
  var audioStream: JsonNode = nil

  for stream in videoInfo["streamingData"]["adaptiveFormats"].items:
    let mimeType = stream["mimeType"].getStr()
    if mimeType.startsWith("video/") and stream.hasKey("bitrate"):
      if videoStream.isNil or (stream["bitrate"].getInt() > videoStream[
          "bitrate"].getInt()):
        videoStream = stream
    elif mimeType.startsWith("audio/"):
      if audioStream.isNil or (stream["bitrate"].getInt() > audioStream[
          "bitrate"].getInt()):
        audioStream = stream

  if videoStream.isNil or audioStream.isNil:
    raise newException(ValueError, "No valid video/audio streams found")

  return (videoStream, audioStream)


# Download the fucking thing
proc downloadFile(url: string, outputPath: string) =
  let client = newHttpClient()
  try:
    let content = client.getContent(url)
    writeFile(outputPath, content)
  except HttpRequestError as e:
    echo "Error downloading file: ", e.msg
    quit(1)


proc extractVideoId(url: string): string =
  result = url.split("=")[^1]


# Run the CLI
proc main() =
  if paramCount() < 1:
    echo "Usage: nytdlp [-v|-a] <YouTube video URL>"
    quit(1)

  let url = if paramCount() == 2: paramStr(2) else: paramStr(1)
  let videoId = extractVideoId(url)
  let videoInfo = getVideoInfo(videoId)

  echo "Video Info: ", videoInfo

  let (videoStream, audioStream) = extractStreams(videoInfo)

  if paramCount() == 1 or paramStr(1) == "-a":
    downloadFile(audioStream["url"].getStr(), "output.opus")
  elif paramStr(1) == "-v":
    downloadFile(videoStream["url"].getStr(), "output.mp4")
  else:
    echo "Invalid option provided."
    echo "Usage: nytdlp [-v|-a] <YouTube video URL>"
    quit(1)

  echo "Downloaded to current directory."


main()
