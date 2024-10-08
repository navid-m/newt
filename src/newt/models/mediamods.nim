import
  strformat,
  strutils,
  terminal,
  times,
  nancy


type
  MediaFormat* = object
    itag*: int
    url*: string
    fps*: int
    bitrate*: int64
    averageBitrate*: int64
    mimeType*: string
    codec*: string
    extension*: string
    contentLength*: int64
    audioSampleRate*: int64
    audioChannels*: int
    projectionType*: string
    width*: int
    height*: int
    quality*: string
    qualityLabel*: string
    audioQuality*: string
    lastModified*: Time

type
  VideoInfo* = object
    videoId*: string
    title*: string
    lengthSeconds*: int64
    views*: int
    description*: string
    author*: string
    liveContent*: bool
    private*: bool
    ratingsEnabled*: bool
    channelId*: string
    thumbnailUrls*: seq[string]
    formats*: seq[MediaFormat]


proc showVideoDetails*(video: VideoInfo) =
  styledEcho(
    styleBright, repeat("─", 100),
    &"\nDetails for {video.videoId}\n", repeat("─", 100)
  )

  var descToShow = video.description.split(".")[0]
  if (len(video.description) > 82):
    descToShow = descToShow & "..."

  echo(
    &"Title: {video.title}",
    &"\nLength: {video.lengthSeconds div 60} minutes {video.lengthSeconds mod 60} seconds",
    &"\nViews: {video.views}",
    &"\nVideo ID: {video.videoId}",
    &"\nChannel ID: {video.channelId}",
    &"\nRatings Enabled: " & ($video.ratingsEnabled),
    &"\nLive Content: " & ($video.liveContent),
    &"\nPrivate: " & ($video.private),
    &"\nAuthor: {video.author}",
    "\n" & repeat("─", 100) & &"\nDescription:\n\n{descToShow}\n" &
           repeat("─", 100),
    &"\nThumbnail URLs:\n"
  )

  for tn in video.thumbnailUrls:
    echo(" * " & tn)

  styledEcho(styleBright, repeat("─", 100))


proc showAvailableFormats*(video: VideoInfo) =
  styledEcho(
    styleBright,
    repeat("─", 100) & "\n" &
    "Available formats for: " & video.title, &" [{video.videoId}]\n" &
    repeat("─", 100) & "\n"
  )

  var table: TerminalTable

  table.add(
    "ID", "Bitrate", "Mime Type", "Codec", "Size",
    "Audio Sample Rate", "Audio Channels", "Dimensions",
    "Quality", "Audio Quality", "FPS"
  )

  for format in video.formats:
    var dimsToShow = "N/A"

    if format.height > 0:
      dimsToShow = &"{format.width}x{format.height}"

    table.add(
      $format.itag,
      $format.bitrate,
      format.mimeType,
      format.codec,
      $format.contentLength,
      $format.audioSampleRate,
      $format.audioChannels,
      dimsToShow,
      format.quality,
      format.audioQuality,
      $format.fps
    )

  table.echoTableSeps(seps = boxSeps)
