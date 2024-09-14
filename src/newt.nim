import
  os,
  strutils,
  newt/meta/info,
  newt/models/mediamods,
  newt/downloads/[dl, dlinf]


export
  downloadYtAudio,
  downloadYtVideo,
  downloadYtStreamById,
  downloadBestYtVideo,
  getVideoInfo


when isMainModule:
  if paramCount() < 1:
    echo "usage: newt [-v|-a|-f|-df|-i] <video-url> <options>"
    quit(1)

  let url = if paramCount() == 2: paramStr(2) else: paramStr(1)
  let isAudio = paramCount() == 1 or paramStr(1) == "-a"
  let isVideo = paramStr(1) == "-v"
  let isInfo = paramStr(1) == "-f"
  let isGetById = paramStr(1) == "-df"
  let isVideoInfo = paramStr(1) == "-i"
  let isVersion = paramStr(1) == "--version"
  let isAbout = paramStr(1) == "--about"

  if isVersion:
    echo(getVersion())
    quit(0)

  if isAbout:
    showAbout()
    quit(0)

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
