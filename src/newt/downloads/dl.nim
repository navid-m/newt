import
  ../providers/[ivtube, innertube],
  ../diagnostics/logger,
  ../flags/vidflags


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
proc downloadYtStreamById*(url: string, id: int) = downloadInnerStreamById(url, id)


proc downloadBestYtVideo*(url: string) =
  ## This finds the best audio and video stream and merges them using FFMPEG.
  ## Requires FFMPEG to be installed.
  UseHighQualityVideoMerging(true)
  downloadYtVideo(url)
