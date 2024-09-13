import
  strformat,
  nancy


type
  MediaFormat* = object
    videoId*: string
    title*: string
    itag*: int
    fps*: int
    bitrate*: int64
    mimeType*: string
    lengthSeconds*: int64
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


proc asString*(media: MediaFormat): string =
  result = fmt"""
  Itag             | {media.itag}
  ------------------------------------------------------------
  Bitrate          | {media.bitrate} bps
  ------------------------------------------------------------
  Mime Type        | {media.mimeType}
  ------------------------------------------------------------
  Length           | {media.lengthSeconds} seconds
  ------------------------------------------------------------
  Content Length   | {media.contentLength} bytes
  ------------------------------------------------------------
  Audio Sample Rate| {media.audioSampleRate} hz
  ------------------------------------------------------------
  Audio Channels   | {media.audioChannels}
  ------------------------------------------------------------
  Projection Type  | {media.projectionType}
  ------------------------------------------------------------
  Quality          | {media.quality}
  ------------------------------------------------------------
  Audio Quality    | {media.audioQuality}
  ------------------------------------------------------------
  """


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
