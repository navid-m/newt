import
  strformat,
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


proc showTable*(media: MediaFormat) =
  var table: TerminalTable
  table.add "Itag", $media.itag
  table.add "Bitrate", $media.bitrate & " bps"
  table.add "Mime Type", media.mimeType
  table.add "Content Length", $media.contentLength & " bytes"
  table.add "Audio Sample Rate", $media.audioSampleRate & " hz"
  table.add "Audio Channels", $media.audioChannels
  table.add "Projection Type", media.projectionType
  table.add "Quality", media.quality
  table.add "Audio Quality", media.audioQuality
  table.echoTableSeps(seps = boxSeps)

proc showAvailableFormats*(video: VideoInfo) =
  echo(
    "Available formats for: ",
    video.title, &" [{video.videoId}]\n"
  )

  var table: TerminalTable

  table.add(
    "Itag", "Bitrate", "Mime Type", "Content Length",
    "Audio Sample Rate", "Audio Channels", "Projection Type", "Quality", "Audio Quality"
  )

  for format in video.formats:
    table.add(
      $format.itag,
      $format.bitrate & " bps",
      format.mimeType,
      $format.contentLength & " bytes",
      $format.audioSampleRate & " hz",
      $format.audioChannels,
      format.projectionType,
      format.quality,
      format.audioQuality
    )

  table.echoTableSeps(seps = boxSeps)

