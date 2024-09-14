import strutils


proc extractVideoId*(url: string): string =
  ## Extract video ID from URL
  result = url.split("=")[^1]


proc parseMimeType*(input: string): (string, string) =
  ## Parse mime type and return separate mime and codec
  let parts = input.split(";")
  return (
    parts[0].strip(),
    parts[1].strip().split("=")[1].strip(chars = {'"'})
  )


proc mapMimeToPlain*(mime: string): string =
  ## Map the mime type to the corresponding file extension
  if "audio/mp4" in mime:
    return "m4a"
  if "video/mp4" in mime:
    return "mp4"
  if "audio/webm" in mime:
    return "opus"
  return "webm"
