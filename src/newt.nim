import
  os,
  strutils,
  newt/models/mediamods,
  newt/downloads/[dl, dlinf]


export
  downloadYtAudio,
  downloadYtVideo,
  downloadYtStreamById,
  downloadBestYtVideo,
  getMediaInfo


when isMainModule:
  if paramCount() < 1:
    echo "usage: newt [-v|-a|-f|-df|-i] <yt video url> <extra options>"
    quit(1)

  let url = if paramCount() == 2: paramStr(2) else: paramStr(1)
  let isAudio = paramCount() == 1 or paramStr(1) == "-a"
  let isInfo = paramStr(1) == "-f"
  let isGetById = paramStr(1) == "-df"
  let isVideoInfo = paramStr(1) == "-i"

  if isInfo:
    getMediaInfo(url).showAvailableFormats()
    quit(0)
  if isVideoInfo:
    getMediaInfo(url).showVideoDetails()
    quit(0)
  if isAudio:
    downloadYtAudio(url)
    quit(0)
  if isGetById:
    if paramCount() > 2:
      try:
        downloadYtStreamById(paramStr(2), paramStr(3).parseInt)
      except:
        echo("Error during YTS processing: ", getCurrentException().msg)
        quit(1)
    else:
      echo "Invalid paramater count."
      quit(1)
    quit(0)

  downloadYtVideo(url)
