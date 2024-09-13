import
  os,
  newt/models/mediamods,
  newt/downloads/[dl, dlinf]


export
  downloadYtAudio,
  downloadYtVideo,
  downloadBestYtVideo,
  getMediaInfo


when isMainModule:
  if paramCount() < 1:
    echo "usage: newt [-v|-a] <yt video url>"
    quit(1)

  let url = if paramCount() == 2: paramStr(2) else: paramStr(1)
  let isAudio = paramCount() == 1 or paramStr(1) == "-a"
  let isInfo = paramCount() == 1 or paramStr(1) == "-i"
  let isVideoInfo = paramCount() == 1 or paramStr(1) == "-vi"

  if isInfo:
    getMediaInfo(url).showAvailableFormats()
    quit(0)
  if isVideoInfo:
    getMediaInfo(url).showVideoDetails()
    quit(0)
  if isAudio:
    downloadYtAudio(url)
    quit(0)

  downloadYtVideo(url)
