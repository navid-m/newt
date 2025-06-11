import
    httpclient,
    json,
    strformat,
    strutils,
    streams,
    times,
    os,
    osproc,
    uri

import
    ../primitives/[randoms, texts, links, visitors],
    ../diagnostics/[envchk, logger],
    ../models/[mediamods],
    ../flags/vidflags


proc extractUrlFromSignatureCipher(cipher: string): string =
    ## Extracts the `url` parameter from a signatureCipher string.
    var parts = cipher.split('&')
    for part in parts:
        if part.startsWith("url="):
            let encodedUrl = part[4..^1] # skip 'url='
            return decodeUrl(encodedUrl)
    raise newException(ValueError, "No 'url' parameter found in signatureCipher")


proc addHeaders(client: HttpClient) =
    client.headers = newHttpHeaders(titleCase = true)
    client.headers.add("User-Agent", "com.google.ios.youtube/19.45.4 (iPhone16,2; U; CPU iOS 18_1_0 like Mac OS X;)")
    client.headers.add("Content-Type", "application/json")
    client.headers.add("Accept", "application/json")
    client.headers.add("X-Youtube-Client-Name", "3")
    client.headers.add("X-Youtube-Client-Version", "19.45.4")
    client.headers.add("Origin", "https://youtube.com")
    client.headers.add("Referer", "https://youtube.com")
    client.headers.add(
      "Cookie",
      "CONSENT=YES+cb.20210328-17-p0.en+FX+" & randomConsentID()
    )


proc getVideoInfo(videoId: string, client: HttpClient): JsonNode =
    ## Get video info using InnerTube API

    addHeaders(client)
    var alterResponse: Response

    try:
        let url = "https://www.youtube.com/youtubei/v1/player?key=AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8"
        let payload = %* {
            "videoId": videoId,
            "context": {
            "client": {
            "hl": "en",
            "gl": "US",
            "clientName": "WEB",
            "clientVersion": "2.20240418.01.00",
            "userAgent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)...",
            "timeZone": "UTC",
            "utcOffsetMinutes": 0,
            "visitorData": randomVisitorData("US")
            }
        },
        "contentCheckOk": true,
        "racyCheckOk": true
        }


        # echo "| \x1b[31murl: ", url, "\x1b[0m |"
        # echo "| \x1b[31mpayload: ", $payload, "\x1b[0m |"
        alterResponse = client.post(url, $payload)
        # echo "| \x1b[31malterResponse: ", alterResponse.body(), "\x1b[0m |"

    except HttpRequestError as e:
        logError("Error fetching video info: " & e.msg)
        return nil

    return parseJson(alterResponse.body())


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


proc getVideo(videoInfo: JsonNode, filter = "adaptiveFormats"): (JsonNode, JsonNode) =
    ## Get highest quality video stream
    var bestStream: JsonNode = nil
    for stream in videoInfo["streamingData"][filter].items:
        if stream["mimeType"].getStr().startsWith("video/"):
            if bestStream.isNil or (
              stream["bitrate"].getInt() > bestStream["bitrate"].getInt()
            ):
                bestStream = stream

    if bestStream.isNil:
        raise newException(ValueError, "No video found")

    return (bestStream, getAudio(videoInfo))


import ../primitives/consts

proc postWithApiKey*(url: string, apiKey: string, body: JsonNode): string =
    let client = newHttpClient()
    client.headers = newHttpHeaders({
      "Content-Type": "application/json",
      "User-Agent": "com.google.android.youtube/18.14.35 (Linux; U; Android 12)"
    })
    let fullUrl = url & "?key=" & APIKey

    return client.postContent(fullUrl, $body)


proc downloadStream*(
  downloadUrl: string,
  outputPath: string,
  apiKey: string = "",
  postBody: JsonNode = nil
) =
    echo downloadUrl
    echo "yo"
    echo "dl url is: ", downloadUrl
    ## Download the stream (chunked if supported, else fallback to GET/POST)
    try:
        logInfo("Downloading: " & downloadUrl & " to " & outputPath)
        let client = newHttpClient()
        addHeaders(client)

        var outputStream = newFileStream(outputPath, fmWrite)
        if outputStream == nil:
            raise newException(IOError, "Unable to open output file")
        defer: outputStream.close()

        var body: string
        if apiKey.len > 0 and postBody != nil:
            logInfo("Using POST request with API key")
            body = postWithApiKey(downloadUrl, apiKey, postBody)
        else:
            logInfo("Using fallback GET request")
            body = client.getContent(downloadUrl)

        outputStream.write(body)
        logInfo(fmt"Downloaded full stream to {outputPath}")

    except HttpRequestError as e:
        logError("Error downloading stream: " & e.msg)
    except IOError as e:
        logError("IO error while saving stream: " & e.msg)


proc parseSignatureCipher(signatureCipher: string): string =
    ## Extract the URL from signatureCipher parameter
    let decodedCipher = decodeUrl(signatureCipher)
    let params = decodedCipher.split("&")

    for param in params:
        let keyValue = param.split("=", 1)
        if keyValue.len == 2 and keyValue[0] == "url":
            return decodeUrl(keyValue[1])

    return ""


proc getInnerStreamData*(url: string): VideoInfo =
    ## Get the corresponding VideoInfo given the video URL
    let vidId = url.split("=")[^1]
    let vidInf = getVideoInfo(vidId, newHttpClient())
    var vidDetails: JsonNode

    try:
        vidDetails = vidInf["videoDetails"]
    except:
        raise newException(CatchableError, &"No details found for {url}")

    var mediaSeq: seq[MediaFormat] = @[]
    var lastKnownAdaptiveClength = 0
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
      description: vidDetails["shortDescription"].getStr,
      thumbnailUrls: getVideoThumbnailUrls(vidId)
    )

    proc populateFormatsViaIdentifier(formatLookupIdentifier: string) =
        for format in vidInf["streamingData"][formatLookupIdentifier].items:
            echo format
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
            var lastModifiedAsTime: Time

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

            try:
                lastModifiedAsTime = fromUnix(
                  int64(format["lastModified"].getStr.parseInt / 1_000_000)
                )
            except:
                discard

            if (currentAdaptiveClength != 0):
                lastKnownAdaptiveClength = currentAdaptiveClength
            else:
                currentAdaptiveClength = lastKnownAdaptiveClength

            var (mimeType, codec) = parseMimeType(format["mimeType"].getStr)
            var averageBitrate: int = 0

            try:
                averageBitrate = format["averageBitrate"].getInt
            except:
                discard

            var videoUrl = ""
            try:
                videoUrl = format["url"].getStr
            except:
                try:
                    let signatureCipher = format["signatureCipher"].getStr
                    videoUrl = parseSignatureCipher(signatureCipher)
                except:
                    echo "Warning: Could not extract URL from format"

            mediaSeq.add(MediaFormat(
              itag: format["itag"].getInt,
              mimeType: mimeType,
              extension: mapMimeToPlain(mimeType),
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
              averageBitrate: averageBitrate,
              lastModified: lastModifiedAsTime,
              url: videoUrl
            ))

    populateFormatsViaIdentifier("adaptiveFormats")
    populateFormatsViaIdentifier("formats")

    video.formats = mediaSeq

    return video


proc downloadInnerStreamById*(url: string, id: int) =
    ## Download stream given the itag of the media, and the URL of the source
    let vidInf = getInnerStreamData(url)
    var success = false
    for format in vidInf.formats:
        if format.itag == id:
            downloadStream(
              format.url,
              removeNonAlphanumericModified(vidInf.title) & "." &
              format.extension
            )
            success = true
            break
    if not success:
        raise newException(ValueError, "Invalid itag was passed")


proc downloadInnerStream*(url: string, isAudio: bool) =
    ## Main download procedure
    let videoInfo = getVideoInfo(url.split("=")[^1], newHttpClient())
    let dlName = videoInfo["videoDetails"]["title"].str &
      " [" & videoInfo["videoDetails"]["videoId"].str & "]"

    if videoInfo.isNil:
        raise newException(ValueError, "Failed to retrieve video information")

    var downloadUrl: string

    logInfo("Getting highest quality stream...")

    if isAudio:
        let audioInfo = getAudio(videoInfo)
        downloadUrl = extractUrlFromSignatureCipher(audioInfo[
                "signatureCipher"].getStr())
        downloadStream(downloadUrl, fmt"{dlName}.weba")
    else:
        var filter = "formats"

        if getHighQualMergeStatus():
            filter = "adaptiveFormats"

        let fullVideoInfo = getVideo(videoInfo, filter)
        let audioDownloadUrl = extractUrlFromSignatureCipher(fullVideoInfo[1][
                "signatureCipher"].getStr())
        let videoName = fmt"{dlName}.mp4"

        downloadUrl = extractUrlFromSignatureCipher(fullVideoInfo[0][
                "signatureCipher"].getStr())

        if getHighQualMergeStatus():
            let tempVideoName = "temp_video.webm"
            let tempAudioName = "temp_audio.weba"

            downloadStream(downloadUrl, tempVideoName)
            downloadStream(audioDownloadUrl, tempAudioName)

            proc fallbackOp() = moveFile(tempVideoName, videoName)

            if currentSysHasFfmpeg():
                let res = execCmdEx(
                  "ffmpeg -i {tempVideoName} -i {tempAudioName} -c:v copy -map 0:v:0 -map 1:a:0 -shortest \"{videoName}\" -y".fmt
                )
                if res.exitCode != 0:
                    logInfo("Failed merge with exit code: ", res.exitCode, res.output)
                    fallbackOp()
            else:
                logInfo("FFmpeg is not installed. Using initial downloaded stream instead of merging.")
                fallbackOp()

            removeFile(tempVideoName)
            removeFile(tempAudioName)
        else:
            downloadStream(downloadUrl, videoName)
