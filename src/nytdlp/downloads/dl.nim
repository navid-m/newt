import
  ../providers/[ivtube, innertube],
  ../diagnostics/logger


proc downloadStream(url: string, isAudio: bool) =
  try:
    downloadInnerStream(url, isAudio)
  except:
    LogInfo(
      "Falling back to IV, as Innertube request failed. Only video can be downloaded this way",
      "Details:", getCurrentException().msg
    )
    downloadIvStream(url)


proc downloadYtAudio*(url: string) = downloadStream(url, true)
proc downloadYtVideo*(url: string) = downloadStream(url, false)
