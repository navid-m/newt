import
  os,
  strutils,
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
    echo "usage: newt [-v|-a|-f|-df|-i] <video-url> <options>"
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

  if isVersion: showVersion(); quit(0)
  if isAbout: showAbout(); quit(0)

  if isVideo:
    if paramCount() < 2:
      echo "Invalid param count."
      quit(1)
    downloadYtVideo(url)

  if isInfo:
    getVideoInfo(url).showAvailableFormats()

  if isVideoInfo:
    getVideoInfo(url).showVideoDetails()

  if isAudio:
    downloadYtAudio(url)

  if isGetById:
    if paramCount() > 2:
      try:
        downloadYtStreamById(paramStr(2), paramStr(3).parseInt)
      except:
        echo("Error during YTS processing: ", getCurrentException().msg)
        quit(1)
    else:
      echo "Invalid param count."
      quit(1)
