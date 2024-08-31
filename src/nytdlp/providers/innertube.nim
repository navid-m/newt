import ../primitives/consts
import std/uri
import std/net
import httpclient
import json
import strformat
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
proc extractHighestStream(videoInfo: JsonNode, isAudio: bool): JsonNode =
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


# Download
proc downloadContentViaInner*(url: string, outputPath: string, isAudio: bool) =
  let client = newHttpClient()

  try:
    client.headers.add("User-Agent", DownloaderAgent)
    client.headers.add("Connection", "keep-alive")
    client.headers.add("Origin", "https://youtube.com")

    var fullBody = %*{
      "context": DownloaderClientContext
    }

    for k, v in GlobalBody.pairs:
      fullBody[k] = v


    let infoAsJson: JsonNode = getVideoInfo(url)

    echo "Endpoint:\n", url
    echo "\n\nBody:\n", $fullBody
    echo "\n\nClient headers:\n", client.headers

    let highestQualStreamInfo: JsonNode = extractHighestStream(infoAsJson, isAudio)
    let bestStreamUrl = extractDownloadLink(highestQualStreamInfo.getStr("signatureCipher"))

    var extension = "webm"

    if (isAudio):
      extension = "opus"

    client.downloadFile(bestStreamUrl, fmt"output.{extension}")


  except HttpRequestError as e:
    echo "Error downloading file: ", e.msg
    quit(1)

