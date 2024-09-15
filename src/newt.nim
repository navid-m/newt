import
  os,
  strutils,
  strformat,
  sugar,
  newt/filters/format,
  newt/meta/info,
  newt/diagnostics/logger,
  newt/models/[mediamods, filtermods],
  newt/downloads/[dl, dlinf]


export
  downloadYtAudio,
  downloadYtVideo,
  downloadYtStreamById,
  downloadYtStreamByFormat,
  downloadBestYtVideo,
  showAvailableFormats,
  showVideoDetails,
  getVideoInfo,
  getBestFormat,
  announceLogs,
  MediaFormat,
  VideoInfo,
  FormatType


when isMainModule:
  if paramCount() < 1:
    echo("usage: newt [-v|-a|-f|-df|-i] <video-url> <options>")
    quit(1)

  let
    url = if paramCount() == 2: paramStr(2) else: paramStr(1)
    isAudio = paramCount() == 1 or paramStr(1) == "-a"
    isVideo = paramStr(1) == "-v"
    isInfo = paramStr(1) == "-f"
    isGetById = paramStr(1) == "-df"
    isVideoInfo = paramStr(1) == "-i"
    isVersion = paramStr(1) == "--version"
    isAbout = paramStr(1) == "--about"

  if isVersion:
    showVersion()
    quit(0)

  if isAbout:
    showAbout()
    quit(0)

  if (
    (isVideo or isInfo or isGetById or isVideoInfo) and paramCount() < 2) or
    (isAudio and paramCount() == 1 and not paramStr(1).startsWith("http")
  ):
    echo("Invalid params.")
    quit(1)

  proc doAction(action: proc(), cstring = "Error") =
    try:
      action()
    except:
      echo(&"{cstring}: ", getCurrentException().msg)
      quit(1)

  if isVideo:
    doAction(() => downloadYtVideo(url))

  if isInfo:
    doAction(() => getVideoInfo(url).showAvailableFormats())

  if isVideoInfo:
    doAction(() => getVideoInfo(url).showVideoDetails())

  if isAudio:
    doAction(() => downloadYtAudio(url))

  if isGetById:
    doAction(() => downloadYtStreamById(paramStr(2), paramStr(3).parseInt), "Error during YTS processing")
