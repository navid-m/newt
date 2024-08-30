import httpclient
import json
import strformat
import os
import strutils
import random
import std/uri
import std/net

# Generate random agent
proc randomUserAgent(): string =
  result = sample(@[
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.3 Safari/605.1.15",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Firefox/102.0",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36",
    "Mozilla/5.0 (iPhone; CPU iPhone OS 15_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.5 Mobile/15E148 Safari/604.1"
  ])

# Get video info using API
proc getVideoInfo(videoId: string, invidiousInstanceUrl: string = "iv.ggtyler.dev"): JsonNode =
  let client = newHttpClient()
  let userAgentToUse = randomUserAgent()

  client.headers = newHttpHeaders(titleCase = true)

  client.headers.add("User-Agent", userAgentToUse)
  client.headers.add("Accept", "application/json")
  client.headers.add("Referer", fmt"http://{invidiousInstanceUrl}/")
  client.headers.add("Accept-Language", "en-US,en;q=0.9")

  var response: string
  try:
    response = client.getContent(fmt"http://{invidiousInstanceUrl}/api/v1/videos/{encodeUrl(videoId)}")
  except HttpRequestError as e:
    echo "Error fetching video info: ", e.msg
    quit(1)

  return parseJson(response)

# Get the video URL from the JSON node
proc extractVideoUrl(videoInfo: JsonNode): string =
  for stream in videoInfo["adaptiveFormats"].items:
    if stream["type"].getStr().contains("video/mp4"):
      return stream["url"].getStr()

  raise newException(ValueError, "No valid video URL found")

# Download the fucking thing
proc downloadVideo(url: string, outputPath: string) =
  let client = newHttpClient(userAgent = randomUserAgent())

  client.headers.add("Accept", "*/*")
  client.headers.add("Referer", "http://iv.ggtyler.dev/")
  client.headers.add("Accept-Language", "en-US,en;q=0.9")

  var videoContent: string

  try:
    videoContent = client.getContent(url)
  except HttpRequestError as e:
    echo "Error downloading video: ", e.msg
    quit(1)

  writeFile(outputPath, videoContent)

# Mix video and audio files using ffmpeg
proc mergeAudioAndVideo(
    videoPath: string,
    audioPath: string,
    outputPath: string
  ) =
  discard execShellCmd(fmt"ffmpeg -i {videoPath} -i {audioPath} -c copy {outputPath}")

# Run the CLI
proc main() =
  if paramCount() < 1:
    echo "Usage: nytdlp <YouTube video URL>"
    quit(1)

  let videoInfo = getVideoInfo(paramStr(1).split("=")[^1])
  let videoFile = "video.mp4"

  downloadVideo(extractVideoUrl(videoInfo), videoFile)

  echo "Downloaded video to ", videoFile

  if videoInfo.hasKey("adaptiveFormats"):
    let audioFile = "audio_output.m4a"
    let outputFile = "video_output.mp4"

    downloadVideo(videoInfo["adaptiveFormats"][0]["url"].getStr(), audioFile)
    mergeAudioAndVideo(videoFile, audioFile, outputFile)

    echo "Downloaded audio to: ", audioFile
    echo "Merged video and audio to: ", outputFile

  else:
    echo "(Video does not have a separate audio stream)"

main()
