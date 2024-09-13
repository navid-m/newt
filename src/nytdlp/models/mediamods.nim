import strformat

type
  Media* = object
    videoId*: string
    title*: string
    itag*: int
    bitrate*: int64
    mimeType*: string
    lengthSeconds*: int64
    contentLength*: int64
    audioSampleRate*: int64
    audioChannels*: int
    projectionType*: string
    quality*: string
    audioQuality*: string

proc asString*(media: Media): string =
  result = fmt"""
  ------------------------------------------------------------
  | Video ID         | {media.videoId}
  ------------------------------------------------------------
  | Title            | {media.title}
  ------------------------------------------------------------
  | Itag             | {media.itag}
  ------------------------------------------------------------
  | Bitrate          | {media.bitrate} bps
  ------------------------------------------------------------
  | Mime Type        | {media.mimeType}
  ------------------------------------------------------------
  | Length           | {media.lengthSeconds} seconds
  ------------------------------------------------------------
  | Content Length   | {media.contentLength} bytes
  ------------------------------------------------------------
  | Audio Sample Rate| {media.audioSampleRate} Hz
  ------------------------------------------------------------
  | Audio Channels   | {media.audioChannels}
  ------------------------------------------------------------
  | Projection Type  | {media.projectionType}
  ------------------------------------------------------------
  | Quality          | {media.quality}
  ------------------------------------------------------------
  | Audio Quality    | {media.audioQuality}
  ------------------------------------------------------------
  """

