import
  ../models/mediamods,
  ../models/filtermods,
  strutils


proc getBestFormat*(formats: seq[MediaFormat], ftype: FormatType): MediaFormat =
  var mimeFilter = "video"
  var bestFormat: MediaFormat

  if ftype == FormatType.audio:
    mimeFilter = "audio"

  for format in formats:
    if format.mimeType.startsWith("audio") and
        (bestFormat.bitrate < format.bitrate):
      bestFormat = format
  return bestFormat
