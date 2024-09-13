import
  strformat,
  strutils,
  terminal,
  nancy


type
  MediaFormat* = object
    itag*: int
    fps*: int
    bitrate*: int64
    mimeType*: string
    contentLength*: int64
    audioSampleRate*: int64
    audioChannels*: int
    projectionType*: string
    width*: int
    height*: int
    quality*: string
    qualityLabel*: string
    audioQuality*: string

type
  VideoInfo* = object
    videoId*: string
    title*: string
    lengthSeconds*: int64
    formats*: seq[MediaFormat]


proc showAvailableFormats*(video: VideoInfo) =
  styledEcho(
    styleBright,
    repeat("─", 100) & "\n" &
    "Available formats for: " & video.title, &" [{video.videoId}]\n" &
    repeat("─", 100) & "\n"
  )

  var table: TerminalTable

  table.add(
    "Itag", "Bitrate", "Mime Type", "Size", "Audio Sample Rate",
    "Audio Channels", "Projection", "Quality", "Audio Quality", "FPS"
  )

  for format in video.formats:
    table.add(
      $format.itag,
      $format.bitrate,
      format.mimeType,
      $format.contentLength,
      $format.audioSampleRate,
      $format.audioChannels,
      format.projectionType,
      format.quality,
      format.audioQuality,
      $format.fps
    )

  table.echoTableSeps(seps = boxSeps)
