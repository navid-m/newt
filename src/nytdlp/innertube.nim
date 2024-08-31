# import std/uri
# import std/net
# import consts
# import httpclient
# import json
# import strformat
# import strutils

# var GlobalBody: JsonNode


# # Make an innertube request
# proc innertubeRequest(
#     endpoint: string,
#     body: JsonNode,
#     clientContext: JsonNode
#   ): JsonNode =

#   GlobalBody = body

#   let url = fmt"https://www.youtube.com/youtubei/v1/{endpoint}?key={APIKey}"
#   let client = newHttpClient()

#   echo "URL: ", url
#   echo "BODY: ", body
#   echo "CLIENTCONTEXT: ", clientContext
#   echo "ENDPOINT: ", endpoint, "\n\n"

#   client.headers.add("User-Agent", Agent)
#   client.headers.add("Accept", "application/json")
#   client.headers.add("Content-Type", "application/json")

#   var fullBody = %*{
#     "context": clientContext
#   }

#   for k, v in body.pairs:
#     fullBody[k] = v

#   var response: string

#   try:
#     response = client.postContent(url, $fullBody)
#   except HttpRequestError as e:
#     echo "Error making Innertube request: ", e.msg
#     quit(1)

#   return parseJson(response)


# # Get video info using the Innertube API
# proc getVideoInfo(videoId: string): JsonNode =
#   let body = %*{
#     "videoId": videoId
#   }
#   return innertubeRequest("player", body, ClientContext)


# # Extract DL from JSON response
# proc extractDownloadLink(signatureCipher: string): string =
#   var urlParam: string = ""
#   for param in signatureCipher.split('&'):
#     if param.startsWith("url="):
#       urlParam = param
#       break

#   if urlParam.len() == 0:
#     raise newException(ValueError, "URL parameter not found in signature cipher")

#   return decodeUrl(urlParam.split('=')[1])


# # Extract the highest quality audio/video stream based on the parameter
# proc extractHighestStream(videoInfo: JsonNode, isAudio: bool = true): JsonNode =
#   var bestStream: JsonNode = nil
#   var highestBitrate = 0

#   for stream in videoInfo["streamingData"]["adaptiveFormats"].items:
#     let mimeType = stream["mimeType"].getStr()
#     if (isAudio and mimeType.startsWith("audio/")) or
#        (not isAudio and mimeType.startsWith("video/") and stream.hasKey("bitrate")):
#       let bitrate = stream["bitrate"].getInt()
#       if bitrate > highestBitrate:
#         highestBitrate = bitrate
#         bestStream = stream

#   if bestStream.isNil:
#     raise newException(ValueError, "No suitable stream found")

#   return bestStream

# # Download the fucking thing
# proc getStuff(url: string, outputPath: string) =
#   let client = newHttpClient()
#   try:
#     # Set up necessary headers
#     client.headers.add("User-Agent", DownloaderAgent)
#     client.headers.add("Connection", "keep-alive")
#     client.headers.add("Origin", "https://youtube.com")

#     var fullBody = %*{
#       "context": DownloaderClientContext
#     }

#     for k, v in GlobalBody.pairs:
#       fullBody[k] = v


#     let urlToUse = decodeUrl(url) & "?key=" & APIKey & "?userAgent=" &
#         encodeUrl(
#         "com.google.android.youtube/18.11.34 (Linux; U; Android 11) gzip") &
#         "?androidVersion=30?name=ANDROID?version=" & encodeUrl("18.11.34")

#     echo "Endpoint:\n", url
#     echo "\n\nBody:\n", $fullBody
#     echo "\n\nClient headers:\n", client.headers
#     echo "\n\nPayload:\n", urlToUse

#     client.downloadFile(urlToUse, "outter.mp4")
#     #writeFile(outputPath, content)

#   except HttpRequestError as e:
#     echo "Error downloading file: ", e.msg
#     quit(1)

