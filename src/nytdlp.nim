import
  os,
  nytdlp/downloads/[dl, dlinf]


export
  downloadYtAudio,
  downloadYtVideo,
  downloadBestYtVideo,
  getMediaInfo


when isMainModule:
  if paramCount() < 1:
    echo "usage: nytdlp [-v|-a] <yt video url>"
    quit(1)

  let url = if paramCount() == 2: paramStr(2) else: paramStr(1)
  let isAudio = paramCount() == 1 or paramStr(1) == "-a"
  let isInfo = paramCount() == 1 or paramStr(1) == "-i"

  if isInfo:
    getMediaInfo(url)
    quit(0)
  if isAudio:
    downloadYtAudio(url)
    quit(0)

  downloadYtVideo(url)
