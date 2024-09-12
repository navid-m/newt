import ../providers/[ivtube, innertube]


proc downloadStream(url: string, isAudio: bool) =
  try:
    downloadInnerStream(url, isAudio)
  except:
    echo "Falling back to IV, as Innertube request failed. Only video can be downloaded this way"
    echo "Details: ", getCurrentException().msg
    downloadIvStream(url)

proc downloadAudio*(url: string) =
  downloadStream(url, true)

proc downloadVideo*(url: string) =
  downloadStream(url, false)
