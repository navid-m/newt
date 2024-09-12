import
  os,
  nytdlp/downloads/dl


export downloadAudio, downloadVideo


when isMainModule:
  if paramCount() < 1:
    echo "usage: nytdlp [-v|-a] <yt video url>"
    quit(1)

  let url = if paramCount() == 2: paramStr(2) else: paramStr(1)
  let isAudio = paramCount() == 1 or paramStr(1) == "-a"

  if isAudio:
    downloadAudio(url)
    quit(0)

  downloadVideo(url)
