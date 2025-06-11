import
    ../models/mediamods,
    ../diagnostics/logger,
    ../flags/vidflags,
    ../providers/[ivtube, innertube],
    ../primitives/inners


proc downloadStream(url: string, isAudio: bool) =
    try:
        downloadInnerStream(url, isAudio)
    except:
        logInfo(
          "Falling back to IV, as Innertube request failed. Only video can be downloaded this way",
          "Details:", getCurrentException().msg
        )
        downloadIvStream(url)


proc downloadYtAudio*(url: string) = downloadStream(url, true)
proc downloadYtVideo*(url: string) = downloadStream(url, false)
proc downloadYtStreamById*(url: string, id: int) = downloadInnerStreamById(url, id)
proc downloadYtStreamByFormat*(
  form: MediaFormat,
  fnameWithoutExtension: string) =
    innertube.downloadStream(
      form.url,
      fnameWithoutExtension & "." & form.extension,
      inners.INNERTUBE_API_KEY,
      inners.buildInnertubePayload(inners.extractYouTubeId(form.url))
    )


proc downloadBestYtVideo*(url: string) =
    ## This finds the best audio and video stream and merges them using FFMPEG.
    ## Requires FFMPEG to be installed.
    useHighQualityVideoMerging(true)
    downloadYtVideo(url)
